import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';

import '../analysis/analysis.dart';
import '../ast/ast.dart';
import '../helpers.dart' as helpers;
import '../models/models.dart';
import 'base_generator.dart';
import 'copywith_generator.dart';

/// Generates the compile-time JSON-Pointer resolver for a Zorphy class
/// (issue #186).
///
/// Emits one static entry point per generated class:
///
/// ```dart
/// static ZorphyLens<UiNode, Object?>? resolvePath(String pointer)
/// ```
///
/// The table is a Dart 3 `switch` expression over the pointer's own segments,
/// so one lookup costs one switch step per segment — O(depth) — with no regex,
/// no `dart:mirrors` and no reflective field lookup, which keeps it valid under
/// AOT compilation.
///
/// Three cases, in resolution order:
///
/// 1. **Nested** (`/editDraft/price`) — the head segment names a field whose
///    type is another annotated class, so the remainder is handed to that
///    type's own `resolvePath` and the two lenses are composed with
///    [ZorphyLens.then]. Every level therefore pays exactly one lookup.
/// 2. **Visible here** (`/contractId` on any node) — the field is part of this
///    class's own surface (declared on it or inherited into it), so the lens
///    reads and writes `root.<field>` directly.
/// 3. **Subtype-only** (`/enabled` on `UiNode`) — the field exists somewhere in
///    the hierarchy but not on this class, so the lens dispatches on the
///    RUNTIME subtype and its fallback arm answers `null` (read) / the
///    receiver unchanged (write). That is what makes
///    `UiNode.resolvePath('/enabled')` safe on a `ZfaTextNode`.
///
/// `resolvePath` is static on purpose: Dart forbids a static member that
/// shadows an inherited instance member (`conflicting_static_and_instance`),
/// so a hierarchy cannot express one shared instance method, and statics do
/// not inherit — every class declares its own table.
class JsonPointerGenerator extends UniversalGenerator {
  /// Creates a JSON-Pointer resolver generator.
  JsonPointerGenerator();

  static const _zorphyChecker = TypeChecker.fromUrl(
    'package:zorphy_annotation/src/annotations.dart#Zorphy',
  );

  final Map<ClassElement, ClassMetadata> _metadataCache = {};
  Map<String, ClassElement> _annotatedClasses = const {};

  @override
  bool shouldGenerate(GenerationContext context) {
    final fields = _coveredFields(context);
    if (fields.isEmpty) return false;
    // A lens without a writer cannot exist: [ZorphyLens.set] rebuilds through
    // `copyWith`, so a hierarchy where NO class generated one (a sealed root
    // whose subtypes are all abstract without `generateCopyWithFn`) emits no
    // resolver at all rather than a table of unusable lenses.
    if (_hasWriter(context)) return true;
    return fields.any((f) => f.declaredOn.any(_subtypeHasWriter));
  }

  /// Whether this class's own generated surface carries a writer the lens `set`
  /// can route through.
  ///
  /// This mirrors [CopyWithGenerator.shouldGenerate] instead of re-deriving the
  /// rule: a sealed root whose subtypes were declared explicitly is emitted
  /// with interface getters only (no `copyWith`), and a sealed/abstract base is
  /// only given one when `generateCopyWithFn` is on. Emitting
  /// `root.copyWith(...)` where that generator declined is exactly the
  /// `undefined_instance_member_read` regression this gate prevents.
  bool _hasWriter(GenerationContext context) =>
      CopyWithGenerator().shouldGenerate(context);

  @override
  List<Spec> generateSpec(GenerationContext context) {
    if (!shouldGenerate(context)) return [];
    return [_buildResolvePath(context)];
  }

  // ── Table assembly ──────────────────────────────────────────────

  /// Every pointer segment this class's table answers.
  ///
  /// The class's own surface — declared fields plus the ones it inherits —
  /// comes first, resolved without dispatch. Then the fields of every annotated
  /// subtype in the same library are folded in as dispatch arms, which is what
  /// lets a root resolve a segment only its interactive branch carries.
  List<_PointerField> _coveredFields(GenerationContext context) {
    final metadata = context.metadata;
    final annotated = metadata.allAnnotatedClasses;
    _annotatedClasses = annotated;

    String? nestedOf(String typeName) {
      final base = typeName.replaceAll('?', '').split('<').first;
      return annotated.containsKey(base) || annotated.containsKey('\$$base')
          ? base
          : null;
    }

    final byName = <String, _PointerField>{};

    void add(String name, String type, ClassElement owner, bool visible) {
      final existing = byName[name];
      if (existing == null) {
        byName[name] = _PointerField(
          name: name,
          type: type,
          types: {owner: type},
          declaredOn: [owner],
          isVisibleHere: visible,
          nestedClass: nestedOf(type),
        );
        return;
      }
      existing.types[owner] = type;
      if (!existing.declaredOn.contains(owner)) existing.declaredOn.add(owner);
      if (visible) existing.isVisibleHere = true;
    }

    for (final field in metadata.allFields) {
      if (field.isGetterOnly) continue;
      add(
        field.name,
        helpers.replaceDollarTypesWithConcrete(field.type ?? 'dynamic'),
        metadata.classElement,
        true,
      );
    }

    for (final element in _strictSubtypes(context)) {
      for (final field in element.fields) {
        if (field.isStatic) continue;
        final name = field.name;
        if (name == null || name == 'hashCode' || name == 'runtimeType') {
          continue;
        }
        add(name, field.type.getDisplayString(), element, false);
      }
    }

    return byName.values.toList();
  }

  /// The annotated classes of the same library that are strict subtypes of
  /// this class.
  List<ClassElement> _strictSubtypes(GenerationContext context) {
    final self = context.metadata.classElement;
    final subtypes = <ClassElement>[];
    for (final candidate in context.metadata.allAnnotatedClasses.values) {
      if (candidate == self) continue;
      if (candidate.allSupertypes.any((t) => t.element == self)) {
        subtypes.add(candidate);
      }
    }
    return subtypes;
  }

  // ── Emission ────────────────────────────────────────────────────

  Method _buildResolvePath(GenerationContext context) {
    final className = context.metadata.cleanName.replaceAll(r'$', '');
    final fields = _coveredFields(context);
    final hasWriter = _hasWriter(context);
    final exhaustive = _isExhaustive(context);

    return Method((m) {
      m.name = 'resolvePath';
      m.static = true;
      m.returns = referType('ZorphyLens<$className, Object?>?');
      m.requiredParameters.add(
        Parameter((p) {
          p.name = 'pointer';
          p.type = refer('String');
        }),
      );
      m.docs.add(
        '/// Resolves a JSON Pointer into a [ZorphyLens] over '
        '[$className] — one',
      );
      m.docs.add('/// switch step per segment, so a pointer costs O(depth).');
      m.docs.add('///');
      m.docs.add(
        '/// A pointer this class does not carry answers `null`; a pointer',
      );
      m.docs.add(
        '/// only SOME subtype carries still resolves, and its lens answers',
      );
      m.docs.add('/// `null` on a node that lacks the field.');
      m.body = Code(_body(className, fields, hasWriter, exhaustive));
    });
  }

  /// The method body: nested delegation first (a nested pointer carries a
  /// second `/`, so it can never equal a single-segment arm), then one
  /// `switch` expression over the exact pointer.
  String _body(
    String className,
    List<_PointerField> fields,
    bool hasWriter,
    bool exhaustive,
  ) {
    final lines = <String>[];
    final nested = fields
        .where((f) => _isNested(f) && _emit(f, hasWriter))
        .toList();

    if (nested.isNotEmpty) {
      lines.add("final separator = pointer.indexOf('/', 1);");
      lines.add('if (separator > 0) {');
      lines.add('final remainder = pointer.substring(separator);');
      for (final field in nested) {
        lines.add("if (pointer.startsWith('/${field.name}/')) {");
        lines.add(
          'final nested = ${_fieldTypeName(field)}.resolvePath(remainder);',
        );
        lines.add('if (nested != null) {');
        lines.add(
          'return ZorphyLens<$className, ${field.type}>('
          "path: '/${field.name}', "
          'get: ${_getter(field, exhaustive)}, '
          'set: ${_setter(field, hasWriter, exhaustive, typedValue: true)}, '
          ').then(nested);',
        );
        lines.add('}');
        lines.add('}');
      }
      lines.add('}');
    }

    lines.add('return switch (pointer) {');
    for (final field in fields.where((f) => _emit(f, hasWriter))) {
      lines.add(
        "'/${field.name}' => ZorphyLens<$className, Object?>("
        "path: '/${field.name}', "
        'get: ${_getter(field, exhaustive)}, '
        'set: ${_setter(field, hasWriter, exhaustive)}),',
      );
    }
    lines.add('_ => null,');
    lines.add('};');

    return lines.join('\n');
  }

  /// Whether [field] can carry an arm at all.
  ///
  /// A field only a subtype declares needs that subtype to have a writer for
  /// the `set` half; when none does, the arm would reference a member that does
  /// not exist, so it is dropped rather than emitted broken. A pointer that is
  /// this class's own always emits, because the reader exists regardless.
  bool _emit(_PointerField field, bool hasWriter) {
    if (field.isVisibleHere && hasWriter) return true;
    return _hasWritingDeclarer(field);
  }

  /// Whether any declaring subtype of [field] generated a writer.
  bool _hasWritingDeclarer(_PointerField field) =>
      field.declaredOn.any(_subtypeHasWriter);

  /// Whether [element]'s generated class carries `copyWith`.
  ///
  /// The analyzer element reports the SOURCE class, not the generated one, so
  /// the answer comes from the same [ClassMetadata] the generators see: a
  /// sealed root with explicit subtypes is emitted with interface getters only
  /// (no constructor to rebuild through), which is why
  /// [CopyWithGenerator.shouldGenerate] declines it.
  bool _subtypeHasWriter(ClassElement element) {
    final metadata = _metadataFor(element);
    if (metadata == null) return false;
    return CopyWithGenerator().shouldGenerate(
      GenerationContext(metadata: metadata, config: _configFor(metadata)),
    );
  }

  /// Analyses [element] into the metadata the generator pipeline uses.
  ClassMetadata? _metadataFor(ClassElement element) {
    final cached = _metadataCache[element];
    if (cached != null) return cached;
    final annotation = _zorphyChecker.firstAnnotationOf(element);
    if (annotation == null) return null;
    final reader = ConstantReader(annotation);
    final metadata = ClassAnalyzer.analyze(
      element,
      reader,
      _annotatedClasses,
      const {},
    );
    _metadataCache[element] = metadata;
    return metadata;
  }

  GenerationConfig _configFor(ClassMetadata metadata) =>
      GenerationConfig.fromAnnotationOptions(
        AnnotationParser.parse(
          ConstantReader(
            _zorphyChecker.firstAnnotationOf(metadata.classElement),
          ),
        ),
        outputExtension: '.zorphy.dart',
        factoryMethods: metadata.factoryMethods,
        ownFields: metadata.ownFieldNames,
      );

  /// The `get` closure.
  ///
  /// A field visible on this class reads directly: the receiver's own type
  /// carries the getter, so no dispatch is needed. A field that only a subtype
  /// declares dispatches on the runtime subtype and falls through to `null`.
  ///
  /// The dispatch is a `switch` STATEMENT inside a block-bodied closure, not a
  /// `switch` expression: used directly as a named argument's value, a
  /// `switch (x) { ... }` is parsed as a PATTERN, so the arms would be read as
  /// pattern/guard text and the result assigned where a closure belongs.
  String _getter(_PointerField field, bool exhaustive) {
    if (field.isVisibleHere) {
      return '(root) => root.${field.name}';
    }
    final arms = <String>[];
    for (final element in field.declaredOn) {
      final name = (element.name ?? element.displayName).replaceAll(r'$', '');
      arms.add('case $name _node:');
      arms.add('  return _node.${field.name};');
    }
    return '(root) {\n'
        'switch (root) {\n${arms.join('\n')}\n'
        '${exhaustive ? '' : 'default:\n  return null;\n'}'
        '}\n'
        '}';
  }

  /// The `set` closure, routed through a writer that actually accepts the
  /// field: this class's own `copyWith` when it generated one, otherwise the
  /// declaring subtypes' — a sealed root has no constructor to rebuild through,
  /// so the write dispatches to the concrete subtypes instead.
  String _setter(
    _PointerField field,
    bool hasWriter,
    bool exhaustive, {
    bool typedValue = false,
  }) {
    if (field.isVisibleHere && hasWriter) {
      final value = typedValue ? 'value' : 'value as ${field.type}';
      return '(root, value) => root.copyWith(${field.name}: $value)';
    }
    final arms = <String>[];
    for (final element in field.declaredOn) {
      if (!_subtypeHasWriter(element)) continue;
      final name = (element.name ?? element.displayName).replaceAll(r'$', '');
      final type = field.types[element] ?? field.type;
      final value = typedValue ? 'value as $type' : 'value as $type';
      arms.add('case $name _node:');
      arms.add('  return _node.copyWith(${field.name}: $value);');
    }
    return '(root, value) {\n'
        'switch (root) {\n${arms.join('\n')}\n'
        '${exhaustive ? '' : 'default:\n  return root;\n'}'
        '}\n'
        '}';
  }

  /// Whether every possible value of this class is one the emitted arms
  /// already name, so a `default:` arm would be dead code.
  ///
  /// A `sealed` root covers its whole hierarchy by construction; the analyzer
  /// then reports `unreachable_switch_default` and the analyze-clean release
  /// gate fails. Any other base keeps its fallback.
  bool _isExhaustive(GenerationContext context) {
    final metadata = context.metadata;
    if (!metadata.isSealed) return false;
    final emitted = _strictSubtypes(
      context,
    ).map((s) => (s.name ?? s.displayName).replaceAll(r'$', '')).toSet();
    if (emitted.isEmpty) return false;
    final declared = metadata.explicitSubtypes
        .map((s) => s.interfaceName.replaceAll(r'$', ''))
        .toSet();
    if (declared.isEmpty) return false;
    return declared.length == emitted.length && declared.containsAll(emitted);
  }

  /// Whether this field's type is another annotated class of the same library
  /// and not nullable, so the remainder of a nested pointer can be delegated to
  /// its own table.
  bool _isNested(_PointerField field) =>
      field.nestedClass != null && !field.type.endsWith('?');

  String _fieldTypeName(_PointerField field) =>
      field.nestedClass!.replaceAll(r'$', '');
}

/// One JSON-Pointer segment and the classes that carry it.
class _PointerField {
  /// The field name, which is also the pointer segment (`/<name>`).
  final String name;

  /// The field's type as this class sees it, ready for emission.
  final String type;

  /// The type each declaring class uses, so a covariant redeclaration casts
  /// with its own type rather than the first one seen.
  final Map<ClassElement, String> types;

  /// The classes that declare this field.
  final List<ClassElement> declaredOn;

  /// Whether this class's own surface carries the field (declared on it or
  /// inherited into it) — the condition for a direct, dispatch-free lens.
  bool isVisibleHere;

  /// The annotated class this field is typed as, when it is one — the
  /// delegation target for a nested pointer.
  final String? nestedClass;

  _PointerField({
    required this.name,
    required this.type,
    required this.types,
    required this.declaredOn,
    required this.isVisibleHere,
    this.nestedClass,
  });
}
