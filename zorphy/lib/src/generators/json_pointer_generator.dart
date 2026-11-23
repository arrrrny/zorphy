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

  /// Per-class metadata and writer answers, so the emission pass does not
  /// re-analyse the hierarchy it just walked.
  ///
  /// The generator instance is a process-wide singleton in
  /// `Orchestrator._generators`, so these maps outlive one class's generation.
  /// That is safe only because every entry is keyed by `ClassElement` and
  /// derived purely from that element — no answer depends on which class is
  /// being generated — and because [_coveredFields] resets [_annotatedClasses]
  /// on each call rather than accumulating across classes.
  final Map<ClassElement, ClassMetadata> _metadataCache = {};
  final Map<ClassElement, bool> _writerCache = {};

  /// The annotated classes of the library currently being generated.
  Map<String, ClassElement> _annotatedClasses = const {};

  @override
  bool shouldGenerate(GenerationContext context) {
    // A static member cannot reference the class's type parameters
    // (`type_parameter_referenced_by_static`), and a static cannot bind them
    // either, so a generic model gets no resolver at all — the same decline
    // [LensGenerator] makes for the lens registry.
    if (context.metadata.generics.isNotEmpty) return false;
    // The instance caches below are populated here and reused by the emission
    // pass (`_metadataFor` / `_annotatedClasses`), which is only correct
    // because this is the first call for the class being generated.
    final fields = _coveredFields(context);
    if (fields.isEmpty) return false;
    // A lens without a writer cannot exist: [ZorphyLens.set] rebuilds through
    // `copyWith`, so a hierarchy where NO class generated one (a sealed root
    // whose subtypes are all abstract without `generateCopyWithFn`) emits no
    // resolver at all rather than a table of unusable lenses.
    if (_hasWriter(context)) return true;
    // A `$$` root never generates `copyWith`, but its concrete descendants do
    // — and they inherit its fields, so a shared field is still writable.
    return fields.any((f) => _writerArms(f).isNotEmpty);
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
      // The subtype's WHOLE writable surface, not just the members it
      // redeclares: a concrete descendant of a `$$` root writes an inherited
      // `id` through the `copyWith(id: …)` it generated without declaring it,
      // so reading only the declared members would never record that writer
      // against `/id` and the root's shared-field arm would be dropped.
      for (final field in _writableFieldsOf(element)) {
        add(
          field.name,
          helpers.replaceDollarTypesWithConcrete(field.type),
          element,
          false,
        );
      }
    }

    return byName.values.toList();
  }

  /// The fields [element]'s own generated `copyWith` accepts: its whole
  /// writable surface, inherited members included.
  ///
  /// Mirrors [CopyWithGenerator]'s own selection — [ClassMetadata.allFields]
  /// minus getter-only members, which have no storage to replace.
  List<_FieldShape> _writableFieldsOf(ClassElement element) {
    final metadata = _metadataFor(element);
    if (metadata == null) {
      // Not annotated in this library: fall back to what it declares, so a
      // cross-library subtype still contributes its own fields.
      return [
        for (final field in element.fields)
          if (!field.isStatic &&
              field.name != null &&
              field.name != 'hashCode' &&
              field.name != 'runtimeType')
            _FieldShape(field.name!, field.type.getDisplayString()),
      ];
    }
    return [
      for (final field in metadata.allFields)
        if (!field.isGetterOnly) _FieldShape(field.name, field.type ?? 'dynamic'),
    ];
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
        '/// Resolves a JSON Pointer into a [ZorphyLens] over [$className].',
      );
      m.docs.add('///');
      m.docs.add('/// One switch step per segment, so a pointer costs');
      m.docs.add('/// O(depth) — no regex, no mirrors, no reflective lookup.');
      m.docs.add('///');
      m.docs.add('/// A pointer this class does not carry answers `null`.');
      m.docs.add(
        '/// A pointer only SOME subtype carries still resolves, and its',
      );
      m.docs.add('/// lens answers `null` on a node that lacks the field.');
      m.body = Code(_body(className, fields, hasWriter, context));
    });
  }

  /// The method body: nested delegation first (a nested pointer carries a
  /// second `/`, so it can never equal a single-segment arm), then one
  /// `switch` expression over the exact pointer.
  String _body(
    String className,
    List<_PointerField> fields,
    bool hasWriter,
    GenerationContext context,
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
        if (field.isVisibleHere) {
          // The receiver's own type carries the getter, so the value is
          // non-null and [ZorphyLens.then] composes it directly.
          lines.add(
            'return ZorphyLens<$className, ${field.type}>('
            "path: '/${field.name}', "
            'get: ${_getter(field, context)}, '
            'set: ${_setter(field, context, hasWriter, typedValue: true)}, '
            ').then(nested);',
          );
        } else {
          // Only SOME subtype carries this parent, so the composed read has to
          // answer `null` on a sibling that does not — [ZorphyLens.then] calls
          // the child accessor unconditionally on the parent getter's result,
          // which cannot express that. The composition is therefore written out
          // here with both levels guarded.
          lines.add(
            _guardedComposition(className, field, context, hasWriter),
          );
        }
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
        'get: ${_getter(field, context)}, '
        'set: ${_setter(field, context, hasWriter)}),',
      );
    }
    lines.add('_ => null,');
    lines.add('};');

    return lines.join('\n');
  }

  /// The composition for a parent field that only SOME subtypes carry.
  ///
  /// [ZorphyLens.then] composes `root -> value -> child value` unconditionally,
  /// so it cannot express "this root has no such value": the child accessor
  /// would be handed `null`. The composition is therefore written out — read
  /// guarded at both levels, write guarded at the parent and routed through the
  /// nested lens's own `set` when the value is present — which keeps the lens
  /// laws for a receiver that carries the field and answers `null` for one that
  /// does not.
  String _guardedComposition(
    String className,
    _PointerField field,
    GenerationContext context,
    bool hasWriter,
  ) {
    final parentGet = _getter(field, context);
    final parentSet = _setter(field, context, hasWriter, typedValue: false);
    return 'return ZorphyLens<$className, Object?>(\n'
        "path: '/${field.name}\${nested.path}',\n"
        'get: (root) {\n'
        'final parent = $parentGet(root);\n'
        'if (parent == null) return null;\n'
        'return nested.get(parent);\n'
        '},\n'
        'set: (root, value) {\n'
        'final parent = $parentGet(root);\n'
        'if (parent == null) return root;\n'
        'return $parentSet(root, nested.set(parent, value));\n'
        '},\n'
        ');';
  }

  /// Whether [field] can carry an arm at all.
  ///
  /// A field only a subtype declares needs that subtype to have a writer for
  /// the `set` half; when none does, the arm would reference a member that does
  /// not exist, so it is dropped rather than emitted broken.
  ///
  /// A field visible on this class always emits, for the same reason: the read
  /// side exists on the receiver whatever the write side does, and dropping the
  /// arm would make `resolvePath` answer `null` for a pointer the class
  /// demonstrably carries. When this class generated no `copyWith` — a `$$`
  /// root never does — the write dispatches to the concrete subtypes that did.
  bool _emit(_PointerField field, bool hasWriter) {
    if (field.isVisibleHere) {
      return hasWriter || _writerArms(field).isNotEmpty;
    }
    return _writerArms(field).isNotEmpty;
  }

  /// [candidates] reduced to their outermost members: one that has an ancestor
  /// also present is dropped, because the ancestor's arm already matches every
  /// instance of it and keeping both emits an `unreachable_switch_case`.
  List<ClassElement> _outermost(List<ClassElement> candidates) => [
    for (final element in candidates)
      if (!candidates.any(
        (outer) =>
            outer != element &&
            element.allSupertypes.any((t) => t.element == outer),
      ))
        element,
  ];

  /// The classes the `get` dispatch names: every declarer of [field], pruned to
  /// the outermost ones.
  List<ClassElement> _readerArms(_PointerField field) =>
      _outermost(field.declaredOn);

  /// The declaring classes whose own generated `copyWith` accepts [field] —
  /// exactly the arms the `set` dispatch can name.
  ///
  /// Only a class that literally generated `copyWith` can be an arm: an
  /// intermediate or sealed node that merely inherits the field has no writer
  /// of its own, so naming it would emit `_node.copyWith(…)` against a member
  /// that does not exist. Such a node contributes exhaustiveness through its
  /// leaves, which DO declare the inherited field (see [_writableFieldsOf]) and
  /// therefore appear here in their own right.
  List<ClassElement> _writerArms(_PointerField field) => _outermost([
    for (final element in field.declaredOn)
      if (_subtypeHasWriter(element)) element,
  ]);

  /// Whether [element]'s generated class carries `copyWith`.
  ///
  /// The analyzer element reports the SOURCE class, not the generated one, so
  /// the answer comes from the same [ClassMetadata] the generators see: a
  /// sealed root with explicit subtypes is emitted with interface getters only
  /// (no constructor to rebuild through), which is why
  /// [CopyWithGenerator.shouldGenerate] declines it.
  bool _subtypeHasWriter(ClassElement element) {
    final cached = _writerCache[element];
    if (cached != null) return cached;
    final metadata = _metadataFor(element);
    if (metadata == null) return false;
    final answer = CopyWithGenerator().shouldGenerate(
      GenerationContext(metadata: metadata, config: _configFor(metadata)),
    );
    _writerCache[element] = answer;
    return answer;
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
  String _getter(_PointerField field, GenerationContext context) {
    if (field.isVisibleHere) {
      return '(root) => root.${field.name}';
    }
    final arms = <String>[];
    for (final element in _readerArms(field)) {
      final name = (element.name ?? element.displayName).replaceAll(r'$', '');
      arms.add('case $name _node:');
      arms.add('  return _node.${field.name};');
    }
    return '(root) {\n'
        'switch (root) {\n${arms.join('\n')}\n'
        '${_coversEverySubtype(field, context, writersOnly: false) ? '' : 'default:\n  return null;\n'}'
        '}\n'
        '}';
  }

  /// The `set` closure, routed through a writer that actually accepts the
  /// field: this class's own `copyWith` when it generated one, otherwise the
  /// declaring subtypes' — a sealed root has no constructor to rebuild through,
  /// so the write dispatches to the concrete subtypes instead.
  String _setter(
    _PointerField field,
    GenerationContext context,
    bool hasWriter, {
    bool typedValue = false,
  }) {
    if (field.isVisibleHere && hasWriter) {
      final value = typedValue ? 'value' : 'value as ${field.type}';
      return '(root, value) => root.copyWith(${field.name}: $value)';
    }
    final arms = <String>[];
    for (final element in _writerArms(field)) {
      final name = (element.name ?? element.displayName).replaceAll(r'$', '');
      final type = field.types[element] ?? field.type;
      arms.add('case $name _node:');
      arms.add('  return _node.copyWith(${field.name}: value as $type);');
    }
    return '(root, value) {\n'
        'switch (root) {\n${arms.join('\n')}\n'
        '${_coversEverySubtype(field, context, writersOnly: true) ? '' : 'default:\n  return root;\n'}'
        '}\n'
        '}';
  }

  /// Whether the arms emitted for [field] cover every subtype this switch can
  /// see, so omitting `default:` cannot leave it non-exhaustive.
  ///
  /// This is decided per FIELD, never for the hierarchy as a whole: a field
  /// declared by one subtype only covers that subtype, and reusing a
  /// hierarchy-wide answer dropped the `default:` that made the switch
  /// exhaustive — four `non_exhaustive_switch_statement` errors on the repo's
  /// own `$$Shape` fixture.
  ///
  /// [writersOnly] asks the same question for the `set` half, whose arms are
  /// the writable declarers rather than every declarer.
  ///
  /// Coverage is by ANCESTRY, not by name: an arm naming a parent matches every
  /// instance of its descendants, so `case LeafA` covers a `LeafB` that
  /// implements it — which is exactly why the arms are pruned to their
  /// outermost declarer and the pruning cannot leave the switch non-exhaustive.
  bool _coversEverySubtype(
    _PointerField field,
    GenerationContext context, {
    required bool writersOnly,
  }) {
    if (!context.metadata.isSealed) return false;
    final subtypes = _strictSubtypes(context);
    if (subtypes.isEmpty) return false;
    final arms = writersOnly ? _writerArms(field) : _readerArms(field);
    if (arms.isEmpty) return false;
    return subtypes.every(
      (s) => arms.any(
        (arm) => arm == s || s.allSupertypes.any((t) => t.element == arm),
      ),
    );
  }

  /// Whether this field's type is another annotated class of the same library,
  /// and that class actually emits a `resolvePath` to delegate to.
  ///
  /// Delegation is a static call, so a nested type whose own resolver was
  /// declined — a generic class, or one where no class in its hierarchy
  /// generated a `copyWith` — would make the emitted part reference a member
  /// that does not exist. Such a field keeps its direct lens and answers `null`
  /// for the deeper pointer instead.
  bool _isNested(_PointerField field) {
    if (field.nestedClass == null || field.type.endsWith('?')) return false;
    final target = _annotatedClasses[field.nestedClass!] ??
        _annotatedClasses['\$${field.nestedClass!}'];
    if (target == null) return false;
    final metadata = _metadataFor(target);
    if (metadata == null) return false;
    final context = GenerationContext(
      metadata: metadata,
      config: _configFor(metadata),
    );
    return _emitsResolver(context);
  }

  /// Whether the class described by [context] emits a `resolvePath` of its own.
  ///
  /// This mirrors [shouldGenerate] without populating the per-generation
  /// caches with another class's fields, which is why it is not a plain call.
  bool _emitsResolver(GenerationContext context) {
    if (context.metadata.generics.isNotEmpty) return false;
    final previousAnnotated = _annotatedClasses;
    final List<_PointerField> fields;
    try {
      fields = _coveredFields(context);
    } finally {
      _annotatedClasses = previousAnnotated;
    }
    if (fields.isEmpty) return false;
    if (_hasWriter(context)) return true;
    return fields.any((f) => _writerArms(f).isNotEmpty);
  }

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

/// A field as one generated `copyWith` accepts it: the name and the type that
/// parameter is declared with.
class _FieldShape {
  final String name;
  final String type;

  const _FieldShape(this.name, this.type);
}
