// Regression test for issue #47:
// "[Bug] Spec-pipeline constructor missing this. prefix on all fields
//  without defaults"
//
// Before fix 9b14f97, the concrete-constructor parameters for normal
// (non-default) fields never set Parameter.toThis, so code_builder
// emitted a plain named param (`User({required String name, ...})`)
// instead of a field-initializing formal (`User({required this.name})`).
// Result: final fields were left uninitialized, producing
// "All final variables must be initialized" analyze errors.
//
// This test pins the contract: every own (non-parent) field WITHOUT a
// JsonKey defaultValue MUST be emitted as a `this.<field>` formal in
// the generated concrete constructor. Fields WITH a defaultValue keep
// the explicit initializer form
// (`this.<field> = <field> ?? <default>`).

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/class_declaration_generator.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/agent_directive_info.dart';
import 'package:zorphy/src/models/generation_config.dart';

// ────────────────────────────────────────────────────────────────────
// Minimal ClassElement stub for unit testing (same pattern as
// spec_mapper_test.dart).
// ────────────────────────────────────────────────────────────────────
class _StubClassElement implements ClassElement {
  @override
  final String name;

  _StubClassElement(this.name);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────

/// Builds a minimal concrete [ClassMetadata] for a class with the given
/// fields. The class is concrete (no `$` prefix), has no interfaces,
/// no generics, no factory methods.
ClassMetadata _concreteMeta({
  required String name,
  required List<NameTypeClassComment> fields,
}) {
  final ownFieldNames = fields.map((f) => f.name).toSet();
  return ClassMetadata(
    originalName: name,
    cleanName: name,
    isAbstract: false,
    isSealed: false,
    nonSealed: false,
    hasConstConstructor: false,
    docComment: '',
    generics: const [],
    interfaces: const [],
    allValueTInterfaces: const [],
    allFields: fields,
    ownFieldNames: ownFieldNames,
    factoryMethods: const [],
    explicitSubtypes: const [],
    isInParentExplicitSubtypes: false,
    classElement: _StubClassElement(name),
    agentDirectiveInfo: const AgentDirectiveInfo(),
    namedConstructors: const [],
      allAnnotatedClasses: const {},
  );
}

/// Builds a [GenerationConfig] with all features off except the bare
/// minimum needed to produce a concrete class declaration (no JSON,
/// no copyWith, no patch, etc.). This isolates the constructor
/// generation path under test.
GenerationConfig _bareConfig() {
  return const GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.entity,
    autoId: false,
    generateJson: false,
    explicitToJson: true,
    generateCopyWith: false,
    generateCopyWithFn: false,
    generateCompareTo: false,
    generatePatch: false,
    hidePublicConstructor: false,
    generateFilter: false,
    generatePropertyHelpers: false,
    generateEqualsToString: false,
    generateChangeTo: false,
    nonSealed: false,
    factoryMethods: [],
    ownFields: {},
  );
}

/// Emits a [Class] spec to a Dart source string for assertion.
String _emitClass(Class spec) {
  final lib = Library((b) => b.body.add(spec));
  return lib.accept(DartEmitter(useNullSafetySyntax: true)).toString();
}

/// Extracts the primary constructor signature from emitted class
/// source. Returns the substring inside `ClassName(...)`.
String _extractConstructor(String emitted, String className) {
  final ctorPattern = RegExp(
    RegExp.escape(className) + r'\(([^)]*(?:\([^)]*\))*[^)]*)\)',
  );
  final match = ctorPattern.firstMatch(emitted);
  return match?.group(1) ?? '';
}

// ────────────────────────────────────────────────────────────────────
// Tests
// ────────────────────────────────────────────────────────────────────

void main() {
  group('Issue #47 — spec-pipeline constructor this. prefix', () {
    final generator = ClassDeclarationGenerator();

    test('own field without default uses field-initializing formal', () {
      // A required, non-nullable String field "name" with no default
      // value MUST be emitted as `required this.name`.
      final meta = _concreteMeta(
        name: 'User',
        fields: [
          NameTypeClassComment('name', 'String', 'User'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _bareConfig()),
      );
      expect(specs, hasLength(1));
      final emitted = _emitClass(specs.first as Class);
      final ctor = _extractConstructor(emitted, 'User');

      // The constructor must use the `this.name` field-initializing
      // formal — NOT a plain `String name` parameter.
      expect(ctor, contains('this.name'));
      expect(ctor, contains('required'));
      // Negative assertion: must NOT contain a plain named parameter
      // (i.e. `String name` without `this.`).
      expect(
        ctor,
        isNot(contains(RegExp(r'String\s+name(?!\s*=\s*name)'))),
      );
    });

    test(
      'nullable own field without default uses field-initializing formal',
      () {
        // A nullable field "email" with no default value MUST be emitted
        // as `this.email` (no `required`, but still `this.`-prefixed).
        final meta = _concreteMeta(
          name: 'Account',
          fields: [
            NameTypeClassComment('email', 'String?', 'Account'),
          ],
        );
        final specs = generator.generateSpec(
          GenerationContext(metadata: meta, config: _bareConfig()),
        );
        final emitted = _emitClass(specs.first as Class);
        final ctor = _extractConstructor(emitted, 'Account');

        expect(ctor, contains('this.email'));
        // Nullable fields are NOT required.
        expect(ctor, isNot(contains('required')));
      },
    );

    test('multiple own fields without defaults all use this. prefix', () {
      // The bug title says "all fields without defaults" — verify that
      // EVERY own field without a default gets `this.`, not just the
      // first one.
      final meta = _concreteMeta(
        name: 'Person',
        fields: [
          NameTypeClassComment('firstName', 'String', 'Person'),
          NameTypeClassComment('lastName', 'String', 'Person'),
          NameTypeClassComment('age', 'int', 'Person'),
          NameTypeClassComment('nickname', 'String?', 'Person'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _bareConfig()),
      );
      final emitted = _emitClass(specs.first as Class);
      final ctor = _extractConstructor(emitted, 'Person');

      // Every non-default field must be a `this.`-prefixed formal.
      expect(ctor, contains('this.firstName'));
      expect(ctor, contains('this.lastName'));
      expect(ctor, contains('this.age'));
      expect(ctor, contains('this.nickname'));
    });

    test(
      'field WITH default value keeps explicit initializer form',
      () {
        // A field with a JsonKey defaultValue keeps the
        // `this.<field> = <field> ?? <default>` initializer form
        // (Parameter.toThis cannot carry a default initializer).
        final meta = _concreteMeta(
          name: 'Config',
          fields: [
            NameTypeClassComment(
              'retries',
              'int',
              'Config',
              jsonKeyInfo: const JsonKeyInfo(defaultValue: 3),
            ),
          ],
        );
        final specs = generator.generateSpec(
          GenerationContext(metadata: meta, config: _bareConfig()),
        );
        final emitted = _emitClass(specs.first as Class);
        final ctor = _extractConstructor(emitted, 'Config');

        // Default-value branch: parameter is named `retries`, and the
        // initializer list contains `this.retries = retries ?? 3`.
        expect(ctor, contains('retries'));
        expect(emitted, contains('this.retries = retries ?? 3'));
      },
    );

    test('mixed default + non-default fields', () {
      // Combine both branches to ensure they coexist correctly:
      //  - `name` (no default) → `required this.name`
      //  - `retries` (default 3) → `int? retries` + `this.retries = retries ?? 3`
      final meta = _concreteMeta(
        name: 'Service',
        fields: [
          NameTypeClassComment('name', 'String', 'Service'),
          NameTypeClassComment(
            'retries',
            'int',
            'Service',
            jsonKeyInfo: const JsonKeyInfo(defaultValue: 3),
          ),
          NameTypeClassComment('timeout', 'int?', 'Service'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _bareConfig()),
      );
      final emitted = _emitClass(specs.first as Class);
      final ctor = _extractConstructor(emitted, 'Service');

      // Non-default, non-nullable → `required this.name`.
      expect(ctor, contains('this.name'));
      // Non-default, nullable → `this.timeout` (no required).
      expect(ctor, contains('this.timeout'));
      // Default-value field keeps initializer form in the body.
      expect(emitted, contains('this.retries = retries ?? 3'));
    });

    test('generated constructor compiles (final fields initialized)', () {
      // The user-visible symptom of the bug was "All final variables
      // must be initialized" analyze errors. Verify that the emitted
      // class declaration has every final field initialized via the
      // `this.<field>` form, so no analyzer error would be raised.
      final meta = _concreteMeta(
        name: 'Point',
        fields: [
          NameTypeClassComment('x', 'int', 'Point'),
          NameTypeClassComment('y', 'int', 'Point'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _bareConfig()),
      );
      final emitted = _emitClass(specs.first as Class);

      // Both final fields must appear with `this.` prefix in the
      // constructor signature (which is what initializes them).
      final ctor = _extractConstructor(emitted, 'Point');
      expect(ctor, contains('this.x'));
      expect(ctor, contains('this.y'));

      // Sanity check: the emitted class declares the fields as final.
      expect(emitted, contains('final int x;'));
      expect(emitted, contains('final int y;'));
    });
  });
}
