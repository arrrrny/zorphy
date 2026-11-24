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

  /// The legacy-annotation twin of [_zorphyChecker]. `ClassGraph` registers a
  /// class carrying EITHER annotation, so metadata lookups must too.
  static const _zorphy2Checker = TypeChecker.fromUrl(
    'package:zorphy_annotation/src/annotations.dart#Zorphy2',
  );

  /// Per-class writer answers, so the emission pass does not re-analyse the
  /// hierarchy it just walked.
  ///
  /// The generator instance is a process-wide singleton in
  /// `Orchestrator._generators`, so this map outlives one class's generation.
  /// A writer answer is derived purely from the element (its annotation and
  /// its own hierarchy), so it is order-independent by construction.
  final Map<ClassElement, bool> _writerCache = {};

  /// Metadata per class, analysed against THAT class's own library.
  ///
  /// The map is NOT keyed on the generating library because it must not be:
  /// analysing a target with the caller's map made its subtype set, and hence
  /// its eligibility, depend on which library happened to generate first —
  /// `Holder` (importing only `base.dart`) would see a shorter hierarchy than
  /// `$Base`'s own library and drop a delegation that the other order emits
  /// (CodeRabbit finding, #206). Every entry is therefore derived from the
  /// target's own library and is stable across generation order.
  final Map<ClassElement, ClassMetadata> _metadataCache = {};

  /// The annotated classes visible from each library, as a seed for analysis.
  final Map<LibraryElement, Map<String, ClassElement>> _libraryAnnotated = {};

  /// The annotated classes of the library currently being generated.
  Map<String, ClassElement> _annotatedClasses = const {};

  /// Per-class `{self} ∪ allSupertypes` clean names, used to tell a receiver's
  /// own arm (read-only, no `copyWith`) from a strict-subtype arm.
  final Map<String, Set<String>> _ancestorNames = {};

  @override
  bool shouldGenerate(GenerationContext context) {
    // A static member cannot reference the class's type parameters
    // (`type_parameter_referenced_by_static`), and a static cannot bind them
    // either, so a generic model gets no resolver at all — the same decline
    // [LensGenerator] makes for the lens registry.
    if (context.metadata.generics.isNotEmpty) return false;
    // A model may already declare `resolvePath` itself. Emitting the static
    // entry point then makes the part uncompilable (`conflicting_static_and_
    // instance` / duplicate member) even if nobody calls it, and every caller
    // that delegates to this class's resolver would reference it too — so the
    // surface is withheld here rather than emitted broken (CodeRabbit finding
    // on json_pointer_generator.dart:286).
    if (_declaresOwnResolver(context.metadata)) return false;
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

  /// Whether the model already declares a member named `resolvePath`.
  ///
  /// The generated entry point is a STATIC method, so a model member of the
  /// same name is a conflict the analyzer rejects outright. A model that owns
  /// the name keeps it; the resolver (and every static delegation to it) is
  /// skipped.
  static bool _declaresOwnResolver(ClassMetadata metadata) => metadata
      .classElement
      .children
      .any((member) => member.name == 'resolvePath');

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
      // `_annotatedElement` tries every spelling the graph may use, so a
      // `$$Root`-declared field (normalized to `Root` by the type helpers) is
      // recognised as nested — looking for only `Root`/`$Root` missed the
      // `$$Root` key and made `/root/id` answer null even when
      // `Root.resolvePath('/id')` existed (CodeRabbit finding on
      // json_pointer_generator.dart:136).
      return _annotatedElement(base) == null ? null : base;
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
        // A generic subtype's own type parameter cannot be named from a
        // STATIC member — `_node.copyWith(value: value as T)` is
        // `cast_to_non_type` — so a segment typed with it is not advertised
        // for that subtype. Dropping the arm keeps the table compilable; the
        // segment still resolves through any nongeneric declarer.
        if (_mentionsTypeParameter(element, field.type)) continue;
        add(
          field.name,
          helpers.replaceDollarTypesWithConcrete(field.type),
          element,
          false,
        );
      }
    }

    // A field's nested target is decided PER DECLARING CLASS, never from one
    // merged answer: two siblings may declare the same segment with different
    // types (`String payload` on one, `$Draft payload` on another), and a
    // single cached answer would take whichever sibling was visited first and
    // reject `/payload/title` for the other. Resolution dispatches on the
    // runtime subtype instead (see [_nestedTargets]).
    return _withNestedTargets(byName.values.toList(), nestedOf);
  }

  /// Fills in [byName]'s per-declarer nested targets.
  ///
  /// Returns the fields unchanged apart from [_PointerField.nestedTargets]:
  /// the annotated class each declaring class's own type names, when that
  /// class actually carries the field as a nested value.
  List<_PointerField> _withNestedTargets(
    List<_PointerField> fields,
    String? Function(String typeName) nestedOf,
  ) {
    for (final field in fields) {
      for (final entry in field.types.entries) {
        final target = nestedOf(entry.value);
        if (target != null) field.nestedTargets[entry.key] = target;
      }
    }
    return fields;
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
        if (!field.isGetterOnly)
          _FieldShape(field.name, field.type ?? 'dynamic'),
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

  /// The type parameters [element] declares, so a field type that names one is
  /// known to be inexpressible in a STATIC member of the generating class.
  static Set<String> _typeParametersOf(ClassElement element) =>
      {for (final parameter in element.typeParameters) parameter.name ?? ''}
        ..removeWhere((name) => name.isEmpty);

  /// Whether [type] names one of [element]'s own type parameters.
  ///
  /// A static member has no access to a type parameter (`T` there is
  /// `cast_to_non_type`), so a field a GENERIC subtype declares with its own
  /// `T` cannot be written from this table at all: the arm would emit
  /// `_node.copyWith(value: value as T)` in a static context.
  static bool _mentionsTypeParameter(ClassElement element, String type) {
    final parameters = _typeParametersOf(element);
    if (parameters.isEmpty) return false;
    final identifiers = RegExp(r'[A-Za-z_$][A-Za-z0-9_$]*')
        .allMatches(type)
        .map((match) => match.group(0)!);
    return identifiers.any(parameters.contains);
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
        lines.add(_nestedDispatch(className, field, context, hasWriter));
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

  /// The delegation block for one nested parent field.
  ///
  /// The target is resolved from the DECLARING class's own type — not from one
  /// merged answer — because two siblings may type the same segment
  /// differently (`String payload` vs `$Draft payload`). Whichever sibling the
  /// receiver turns out to be decides which `resolvePath` the remainder is
  /// handed to, so `/payload/title` resolves on the Draft-bearing sibling and
  /// answers `null` on the one carrying a plain `String`.
  ///
  /// A field visible on this class needs no dispatch: the receiver's own type
  /// carries the getter, so its single target composes through
  /// [ZorphyLens.then] directly.
  String _nestedDispatch(
    String className,
    _PointerField field,
    GenerationContext context,
    bool hasWriter,
  ) {
    if (field.isVisibleHere) {
      // The receiver's own type carries the getter, so the value is non-null
      // and [ZorphyLens.then] composes it directly — but only when a SINGLE
      // nested type names the target. A legal covariant redeclaration records
      // more than one, and the base-typed arm would shadow the narrowing
      // subtypes, so such a field cannot use a single static target — but it
      // must NOT lose its nested path either: `Node.resolvePath('/payload/title')`
      // answering null for a hierarchy that demonstrably carries it is the
      // gap reported on PR #201 (CodeRabbit finding on
      // json_pointer_generator.dart:827). It dispatches per runtime subtype
      // instead, most-derived arm first.
      final typeName = _fieldTypeName(field);
      if (typeName == null) return _covariantNestedDispatch(className, field);
      return 'final nested = $typeName.resolvePath(remainder);\n'
          'if (nested == null) return null;\n'
          'return ZorphyLens<$className, ${field.type}>('
          "path: '/${field.name}', "
          'get: ${_getter(field, context)}, '
          'set: ${_setter(field, context, hasWriter, typedValue: true)}, '
          ').then(nested);';
    }

    final targets = _delegableTargets(field);
    if (targets.isEmpty) return '';

    // The single-target composition is only sound when EVERY declarer names
    // that same nested type: a sibling carrying the segment as a plain
    // `String` would otherwise be handed to `Draft.resolvePath`, and the
    // merged getter's `Object` type would be rejected at the delegation.
    final arms = _readerArms(field);
    final resolved = {
      for (final element in arms) element: field.nestedTargets[element],
    };
    final distinct = resolved.values.whereType<String>().toSet();
    final everyArmDelegates =
        distinct.length == 1 &&
        resolved.values.every((target) => target == distinct.single);

    if (everyArmDelegates) {
      final target = distinct.single.replaceAll(r'$', '');
      return 'final nested = $target.resolvePath(remainder);\n'
          'if (nested != null) {\n'
          '${_indent(_guardedComposition(className, field, context, hasWriter))}\n'
          '}';
    }

    // Siblings disagree about the segment's type, so the target is only
    // knowable from the RUNTIME subtype — resolved inside each closure.
    return _multiTargetComposition(className, field, context, hasWriter);
  }

  /// The distinct delegation targets [field]'s declarers name, filtered to the
  /// ones that actually emit a `resolvePath`.
  List<String> _delegableTargets(_PointerField field) => {
    for (final element in _readerArms(field))
      if (field.nestedTargets[element] case final target?)
        if (_targetEmitsResolver(target)) target,
  }.toList();

  /// The nested delegation for a field VISIBLE on this class whose declarers
  /// name DIFFERENT nested types (a covariant redeclaration).
  ///
  /// A single static target would be wrong for one of the declarers — the
  /// base-typed arm shadows the narrowing subtype — so the target is chosen
  /// from the receiver's runtime subtype. Arms are ordered MOST-DERIVED first
  /// so `$Child`'s narrowed target wins over the base's, and the class's own
  /// type closes the switch.
  ///
  /// Without this the field resolved only as a plain segment, so
  /// `Node.resolvePath('/payload/title')` answered null even though every
  /// concrete node carries a `payload` whose own resolver handles `title`
  /// (CodeRabbit finding on json_pointer_generator.dart:827).
  String _covariantNestedDispatch(String className, _PointerField field) {
    final all = field.nestedTargets.entries
        .where((entry) => _targetEmitsResolver(entry.value))
        .toList();
    if (all.isEmpty) return '';

    // The generating class (and any ancestor of it) supplies the FALLBACK: a
    // sealed root carries no `copyWith`, so its arm can read through its own
    // target but never write. Only strict subtypes become `case` arms — naming
    // the receiver's own type there makes the switch cover every instance and
    // leaves `default:` unreachable (and `_node.copyWith` unresolvable).
    final own = all.where((e) => _isSelfOrAncestorOf(e.key, className));
    final derived = all.where((e) => !_isSelfOrAncestorOf(e.key, className));
    final fallback = own.isEmpty ? null : own.first;

    // Most-derived first, so a subtype is matched before its ancestor.
    final derivedSorted = derived.toList()
      ..sort((a, b) {
        final aIsSubOfB = a.key.allSupertypes.any((t) => t.element == b.key);
        final bIsSubOfA = b.key.allSupertypes.any((t) => t.element == a.key);
        if (aIsSubOfB) return -1;
        if (bIsSubOfA) return 1;
        return 0;
      });

    // `if` chains, not a `switch`: a sealed root whose declared subtypes are
    // ALL covered makes a switch exhaustive, and the `default:` that carries
    // the receiver's own arm then reports `unreachable_switch_default`.
    final readArms = <String>[];
    final writeArms = <String>[];
    for (final entry in derivedSorted) {
      final targetType = entry.value.replaceAll(r'$', '');
      final armType = helpers.replaceDollarTypesWithConcrete(
        field.types[entry.key] ?? field.type,
      );
      final cleanName = _cleanName(entry.key.name ?? entry.key.displayName);
      final nullable = armType.trim().endsWith('?');
      // `root is X` promotes `root`, so the arm reads and writes the real
      // subtype without an explicit cast local.
      readArms.add(
        '        if (root is $cleanName) {\n'
        '          final nested = $targetType.resolvePath(remainder);\n'
        '          if (nested == null) return null;\n'
        '${nullable ? '          final parent = root.${field.name};\n'
                  '          if (parent == null) return null;\n'
                  '          return nested.get(parent);' : '          return nested.get(root.${field.name});'}\n'
        '        }',
      );
      writeArms.add(
        '        if (root is $cleanName) {\n'
        '          final nested = $targetType.resolvePath(remainder);\n'
        '          if (nested == null) return root;\n'
        '${nullable ? '          final parent = root.${field.name};\n'
                  '          if (parent == null) return root;\n'
                  '          return root.copyWith('
                  '${field.name}: nested.set(parent, value));' : '          return root.copyWith('
                  '${field.name}: nested.set(root.${field.name}, value));'}\n'
        '        }',
      );
    }

    final fallbackTarget = fallback?.value.replaceAll(r'$', '');
    final fallbackType = fallback == null
        ? null
        : helpers.replaceDollarTypesWithConcrete(
            field.types[fallback.key] ?? field.type,
          );
    final fallbackNullable = (fallbackType ?? '').trim().endsWith('?');
    final fallbackRead = fallbackTarget == null
        ? 'return null;'
        : 'final nested = $fallbackTarget.resolvePath(remainder);\n'
              '        if (nested == null) return null;\n'
              '${fallbackNullable ? 'final parent = root.${field.name};\n'
                        '        if (parent == null) return null;\n'
                        '        return nested.get(parent);' : 'return nested.get(root.${field.name});'}';
    // The receiver is the sealed root or an ancestor: it has no writer, so a
    // write to its own arm answers the root unchanged rather than calling a
    // `copyWith` it does not carry.
    const fallbackWrite = 'return root;';

    return 'return ZorphyLens<$className, Object?>(\n'
        '      path: pointer,\n'
        '      get: (root) {\n'
        '${readArms.join('\n')}\n'
        '        $fallbackRead\n'
        '      },\n'
        '      set: (root, value) {\n'
        '${writeArms.join('\n')}\n'
        '        $fallbackWrite\n'
        '      },\n'
        '    );';
  }

  /// Whether [element] is the class named [className] or one of its ancestors.
  ///
  /// The set is computed once per generation from the generating class's own
  /// supertype chain, so an arm can be classified as "the receiver itself"
  /// (read-only: a sealed root has no `copyWith`) or "a strict subtype" (a real
  /// `case` arm).
  bool _isSelfOrAncestorOf(ClassElement element, String className) =>
      _selfOrAncestorNames(className)
          .contains(_cleanName(element.name ?? element.displayName));

  /// The clean names of [className] and every class it extends/implements.
  Set<String> _selfOrAncestorNames(String className) {
    final cached = _ancestorNames[className];
    if (cached != null) return cached;
    final element = _annotatedElement(className);
    final names = <String>{className};
    if (element != null) {
      for (final supertype in element.allSupertypes) {
        final name = supertype.element.name;
        if (name != null) names.add(_cleanName(name));
      }
    }
    _ancestorNames[className] = names;
    return names;
  }

  /// The composition for a subtype-only field whose declarers name DIFFERENT
  /// nested types.
  ///
  /// Neither the parent value nor the target exists until the receiver's
  /// runtime subtype is known, so both the read and the write dispatch on it.
  /// A declarer whose own type is not a nested class contributes no arm, and
  /// answers `null` (read) / the receiver (write) exactly as a subtype that
  /// does not carry the field would.
  String _multiTargetComposition(
    String className,
    _PointerField field,
    GenerationContext context,
    bool hasWriter,
  ) {
    String reads(String indent) {
      final arms = <String>[];
      for (final element in _readerArms(field)) {
        final target = field.nestedTargets[element];
        if (target == null || !_targetEmitsResolver(target)) continue;
        final name = (element.name ?? element.displayName).replaceAll(r'$', '');
        final targetType = helpers.replaceDollarTypesWithConcrete(
          field.types[element] ?? field.type,
        );
        // A declarer whose own type is nullable guards the read: `nested.get`
        // needs a non-null parent, and passing `DraftB?` to a lens typed
        // `DraftB` does not compile (CodeRabbit finding on lens.dart:821).
        final parent = '_node.${field.name}';
        final nullable = targetType.trim().endsWith('?');
        arms.add(
          'case $name _node:\n'
          '${indent}  final nested = ${target.replaceAll(r'$', '')}'
          '.resolvePath(remainder);\n'
          '${indent}  if (nested == null) return null;\n'
          '${nullable ? '${indent}  final parent = $parent;\n'
                    '${indent}  if (parent == null) return null;\n'
                    '${indent}  return nested.get(parent);' : '${indent}  return nested.get($parent);'}',
        );
      }
      arms.add('default:\n${indent}  return null;');
      return 'switch (root) {\n${arms.join('\n')}\n}';
    }

    String writes(String indent) {
      final arms = <String>[];
      // [_writerArms], not [_readerArms]: `_readerArms` prunes to the OUTERMOST
      // declarer, so a writable leaf under a writerless intermediate declarer
      // (`Mid` declares `Draft payload` with no `copyWith`, `Leaf` implements
      // it and is writable) was pruned away and every write on a `Leaf` root
      // fell to `default: return root;` — silently dropping the update while
      // `get` on the same pointer still answered through the `Mid` arm.
      for (final element in _writerArms(field)) {
        final target = field.nestedTargets[element];
        if (target == null || !_targetEmitsResolver(target)) continue;
        final name = (element.name ?? element.displayName).replaceAll(r'$', '');
        final targetType = helpers.replaceDollarTypesWithConcrete(
          field.types[element] ?? field.type,
        );
        final parent = '_node.${field.name}';
        final nullable = targetType.trim().endsWith('?');
        arms.add(
          'case $name _node:\n'
          '${indent}  final nested = ${target.replaceAll(r'$', '')}'
          '.resolvePath(remainder);\n'
          '${indent}  if (nested == null) return root;\n'
          '${nullable ? '${indent}  final parent = $parent;\n'
                    '${indent}  if (parent == null) return root;\n'
                    '${indent}  return _node.copyWith('
                    '${field.name}: nested.set(parent, value));' : '${indent}  return _node.copyWith('
                    '${field.name}: nested.set($parent, value));'}',
        );
      }
      arms.add('default:\n${indent}  return root;');
      return 'switch (root) {\n${arms.join('\n')}\n}';
    }

    const rootIndent = '    ';
    // An unknown remainder must answer `null`, exactly like a direct unknown
    // pointer does. Returning a lens whose `get` is always null and whose `set`
    // returns the root unchanged contradicts that — `/payload/notAField` is not
    // a path this hierarchy carries (CodeRabbit finding on
    // json_pointer_generator.dart:481). The probe asks each delegable target's
    // own resolver, so a path that resolves on at least one arm keeps its lens.
    final probes = <String>[
      for (final target in _delegableTargets(field))
        '${target.replaceAll(r'$', '')}.resolvePath(remainder) != null',
    ];
    final guard = probes.isEmpty
        ? ''
        : 'if (!(${probes.join(' || ')})) return null;\n';
    return '${guard}return ZorphyLens<$className, Object?>(\n'
        'path: pointer,\n'
        'get: (root) {\n'
        '${reads(rootIndent)}\n'
        '},\n'
        'set: (root, value) {\n'
        '${writes(rootIndent)}\n'
        '},\n'
        ');';
  }

  String _indent(String code) => code
      .split('\n')
      .map((line) => line.isEmpty ? line : '  $line')
      .join('\n');

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

  /// Whether [element]'s generated class carries the Patch surface.
  ///
  /// The null-write branch calls `patchWith<Writer>(<Writer>Patch()…)`, so it
  /// must be gated on the WRITER's own configuration — a root's
  /// `generatePatch` says nothing about a subtype that overrode the preset.
  bool _subtypeGeneratesPatch(ClassElement element) {
    final metadata = _metadataFor(element);
    if (metadata == null) return false;
    return _configFor(metadata).generatePatch;
  }

  /// Analyses [element] into the metadata the generator pipeline uses.
  ClassMetadata? _metadataFor(ClassElement element) {
    final cached = _metadataCache[element];
    if (cached != null) return cached;
    // The SAME lookup the class graph registers with: `ClassGraph` treats a
    // class as annotated when either `@Zorphy` or `@Zorphy2` is present, so a
    // `@Zorphy2` class reached `_targetEmitsResolver` with no metadata and was
    // reported as resolver-less — its nested pointer answered null even though
    // it emits a `resolvePath` (CodeRabbit finding on
    // json_pointer_generator.dart:602).
    final annotation =
        _zorphyChecker.firstAnnotationOf(element) ??
        _zorphy2Checker.firstAnnotationOf(element);
    if (annotation == null) return null;
    final reader = ConstantReader(annotation);
    final metadata = ClassAnalyzer.analyze(
      element,
      reader,
      // The target's OWN library, never the one being generated: the caller's
      // map merges only ITS direct imports, so it can omit a subtype the
      // target's library declares — which made eligibility depend on
      // generation order (CodeRabbit finding, #206).
      _annotatedMapForLibrary(element.library),
      const {},
    );
    _metadataCache[element] = metadata;
    return metadata;
  }

  /// The annotated classes visible from [library], built once per library.
  Map<String, ClassElement> _annotatedMapForLibrary(LibraryElement? library) {
    if (library == null) return _annotatedClasses;
    final cached = _libraryAnnotated[library];
    if (cached != null) return cached;
    final Map<String, ClassElement> annotated;
    try {
      annotated = ClassGraph.fromLibraryClasses(
        library.classes.toList(),
        library: library,
      ).annotated;
    } on Object {
      // An unreadable library falls back to the generating library's map: a
      // narrow map can only drop an arm, never emit a broken one.
      return _annotatedClasses;
    }
    _libraryAnnotated[library] = annotated;
    return annotated;
  }

  GenerationConfig _configFor(ClassMetadata metadata) =>
      GenerationConfig.fromAnnotationOptions(
        AnnotationParser.parse(
          ConstantReader(
            _zorphyChecker.firstAnnotationOf(metadata.classElement) ??
                _zorphy2Checker.firstAnnotationOf(metadata.classElement),
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
      final className = _cleanName(context.metadata.cleanName);
      // `copyWith` is `field: field ?? this.field`, so it cannot express an
      // explicit null; a nullable field routes the null write through the
      // generated Patch, whose `containsKey` gate can.
      final hasNullBranch =
          _isNullableType(field.type) && context.config.generatePatch;
      final value = typedValue
          ? 'value'
          // A composite list field casts element-wise through the repo's
          // checked conversion (issue #148): a hard `value as List<Map<…>>`
          // throws a TypeError on raw JSON payloads and fails the repo's
          // whole-document golden. With a null branch above, null is already
          // gone, so the non-nullable form is what promotes cleanly.
          : helpers.fieldCastExpression(
              'value',
              _nonNullableCastType(field.type, hasNullBranch),
            );
      final nullWrite = hasNullBranch
          ? 'if (value == null) {\n'
                'return root.patchWith$className('
                '${className}Patch()..with${_pascal(field.name)}(null));\n'
                '}\n'
          : '';
      return '(root, value) {\n'
          '$nullWrite'
          'return root.copyWith(${field.name}: $value);\n'
          '}';
    }
    final arms = <String>[];
    for (final element in _writerArms(field)) {
      final name = (element.name ?? element.displayName).replaceAll(r'$', '');
      final type = field.types[element] ?? field.type;
      final writer = _cleanName(element.name ?? element.displayName);
      // Patch availability is a property of the WRITER, not of the class whose
      // table this is: `$$Root` may use the standard preset while `Leaf` sets
      // `generatePatch: false`, and emitting `LeafPatch()`/`patchWithLeaf(…)`
      // there references members that do not exist. Asking the root's config
      // made both directions wrong (CodeRabbit finding on
      // json_pointer_generator.dart:722).
      final hasNullBranch =
          _isNullableType(type) && _subtypeGeneratesPatch(element);
      arms.add('case $name _node:');
      // A nullable field's write must be null-capable here too: the arm's own
      // `copyWith` has the same `??` ambiguity the direct setter had.
      if (hasNullBranch) {
        arms.add(
          '  if (value == null) {'
          ' return _node.patchWith$writer(${writer}Patch()'
          '..with${_pascal(field.name)}(null)); }',
        );
      }
      // The same element-wise conversion the direct setter uses: a hard
      // `value as List<Map<…>>` throws on raw JSON payloads (issue #148).
      // With a null branch above, null is gone and the non-nullable form is
      // what promotes cleanly.
      final castType = _nonNullableCastType(type, hasNullBranch);
      arms.add(
        '  return _node.copyWith('
        '${field.name}: ${helpers.fieldCastExpression('value', castType)});',
      );
    }
    return '(root, value) {\n'
        'switch (root) {\n${arms.join('\n')}\n'
        '${_coversEverySubtype(field, context, writersOnly: true) ? '' : 'default:\n  return root;\n'}'
        '}\n'
        '}';
  }

  /// Whether [type] admits an explicit null.
  static bool _isNullableType(String type) {
    final trimmed = type.trim();
    return trimmed.endsWith('?') ||
        trimmed == 'dynamic' ||
        trimmed.startsWith('dynamic<');
  }

  /// The type to hand [helpers.fieldCastExpression] for a write that already
  /// excluded null — the non-nullable spelling, so the helper emits plain
  /// `.` chains instead of `?.` ones the analyzer rejects as
  /// `invalid_null_aware_operator` (the receiver cannot be null after the
  /// branch above).
  static String _nonNullableCastType(String type, bool nullAlreadyHandled) {
    if (!nullAlreadyHandled) return type;
    final trimmed = type.trim();
    if (trimmed.endsWith('?')) {
      return trimmed.substring(0, trimmed.length - 1).trim();
    }
    return trimmed;
  }

  String _cleanName(String name) => name.replaceAll(r'$', '');

  String _pascal(String name) =>
      name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);

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

  /// Whether this field can be delegated at all: its type names another
  /// annotated class that actually emits a `resolvePath`, and the field is not
  /// a nullable reference (a `null` parent has nothing to delegate to).
  ///
  /// Delegation is a static call, so a nested type whose own resolver was
  /// declined — a generic class, or one where no class in its hierarchy
  /// generated a `copyWith` — would make the emitted part reference a member
  /// that does not exist. Each declarer's target is asked independently, so a
  /// sibling whose own type is a plain `String` contributes no arm rather than
  /// vetoing the delegation for a sibling that does name a class.
  bool _isNested(_PointerField field) {
    if (field.nestedTargets.isEmpty) return false;
    // Nullability is a per-DECLARER property, never a merged one: with
    // `DraftA payload` on one sibling and `DraftB? payload` on another, a
    // single `field.type` test admits both arms when the non-nullable one was
    // collected first — and the nullable arm then hands `DraftB?` to a lens
    // that requires `DraftB`. Each arm guards itself (see
    // [_multiTargetComposition]); only a field whose every declarer is
    // nullable is rejected outright, because then no arm could read it
    // unconditionally (CodeRabbit finding on lens.dart:821).
    final declarerTypes = field.types.values
        .map(helpers.replaceDollarTypesWithConcrete)
        .toList();
    final everyDeclarerNullable =
        declarerTypes.isNotEmpty &&
        declarerTypes.every((type) => type.trim().endsWith('?'));
    if (everyDeclarerNullable) return false;
    // A field VISIBLE on this class delegates through [ZorphyLens.then] with a
    // single static target. A legal covariant redeclaration records more than
    // one, and a single base-typed arm would shadow the narrowing subtypes — so
    // it dispatches per runtime subtype instead of taking the `then` path. It
    // must still be ADMITTED here, or the nested path disappears entirely
    // (`Node.resolvePath('/payload/title')` answering null for a hierarchy that
    // carries it: CodeRabbit finding on json_pointer_generator.dart:827).
    if (field.isVisibleHere && field.nestedClass == null) {
      return field.nestedTargets.entries.any(
        (entry) => _targetEmitsResolver(entry.value),
      );
    }
    return field.nestedTargets.entries.any(
      (entry) => _targetEmitsResolver(entry.value),
    );
  }

  /// The annotated class registered under any spelling [target] may take.
  ///
  /// The graph keys a class by its DECLARED name, so the same model can be
  /// `Root`, `$Root` or `$$Root` depending on how it was annotated; the type
  /// helpers normalize all three to `Root`. Every lookup goes through here so
  /// discovery (`nestedOf`) and eligibility ([_targetEmitsResolver]) agree —
  /// they used to try different spellings, which made a `$$Root`-typed field
  /// resolvable in one and not the other.
  ClassElement? _annotatedElement(String target) {
    for (final candidate in [target, '\$$target', '\$\$$target']) {
      final element = _annotatedClasses[candidate];
      if (element != null) return element;
    }
    return null;
  }

  /// Whether [target] actually emits a `resolvePath` of its own.
  bool _targetEmitsResolver(String target) {
    final element = _annotatedElement(target);
    if (element == null) return false;
    final metadata = _metadataFor(element);
    if (metadata == null) return false;
    return _emitsResolver(
      GenerationContext(metadata: metadata, config: _configFor(metadata)),
    );
  }

  /// Whether the class described by [context] emits a `resolvePath` of its own.
  ///
  /// This mirrors [shouldGenerate] without populating the per-generation
  /// caches with another class's fields, which is why it is not a plain call.
  bool _emitsResolver(GenerationContext context) {
    if (context.metadata.generics.isNotEmpty) return false;
    // Mirrors [shouldGenerate]'s own-resolver guard: a class that keeps its own
    // `resolvePath` member emits no static one, so delegating to it would
    // reference a member that does not exist.
    if (_declaresOwnResolver(context.metadata)) return false;
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

  /// The single delegation target when exactly one annotated type names it, or
  /// `null` when none do or several disagree.
  ///
  /// A field visible here normally has exactly one target; a legal covariant
  /// redeclaration can record more than one, and [`_PointerField.nestedClass`]
  /// already answers `null` for that — which routes the caller
  /// ([_nestedDispatch]) to the runtime-subtype composition rather than
  /// throwing `Bad state: Too many elements` on `.single`.
  String? _fieldTypeName(_PointerField field) {
    final target = field.nestedClass;
    return target?.replaceAll(r'$', '');
  }
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

  /// The annotated class each DECLARING class's own type names, when it is
  /// one — the delegation target for a nested pointer, resolved per subtype.
  final Map<ClassElement, String> nestedTargets = {};

  _PointerField({
    required this.name,
    required this.type,
    required this.types,
    required this.declaredOn,
    required this.isVisibleHere,
  });

  /// The single delegation target when one type names it, else null.
  String? get nestedClass {
    final targets = nestedTargets.values.toSet();
    return targets.length == 1 ? targets.single : null;
  }
}

/// A field as one generated `copyWith` accepts it: the name and the type that
/// parameter is declared with.
class _FieldShape {
  final String name;
  final String type;

  const _FieldShape(this.name, this.type);
}
