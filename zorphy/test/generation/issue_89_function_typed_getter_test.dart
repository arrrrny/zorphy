// Regression test for issue #89:
// "generator: function-typed getters (callback fields) break the generated
//  source — build fails"
//
// Root cause: function-typed getters (e.g.
// `void Function(WebUri? url)? get onClick`) end up as concrete `final`
// fields on the `@JsonSerializable`-annotated class without an
// accompanying `@JsonKey(includeFromJson: false, includeToJson: false)`.
// `json_serializable` then tries to generate a serializer for the
// function type and bails out with:
//   "Could not generate `fromJson` code for `<field>`."
//
// Fix: `ClassDeclarationGenerator._addConcreteFields` now detects
// function-typed fields (via `_isFunctionType`) and auto-emits
// `@JsonKey(includeFromJson: false, includeToJson: false)` when the
// user has not already opted out. The user's own @JsonKey is honored:
// if they already set includeFromJson/includeToJson, we leave it alone;
// if they set other fields (name, defaultValue, …), we augment with
// includeFromJson/includeToJson=false.

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

class _StubClassElement implements ClassElement {
  @override
  final String name;
  _StubClassElement(this.name);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

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

GenerationConfig _jsonConfig() {
  return const GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.valueObject,
    autoId: false,
    generateJson: true,
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

String _emitClass(Class spec) {
  final lib = Library((b) => b.body.add(spec));
  return lib.accept(DartEmitter(useNullSafetySyntax: true)).toString();
}

void main() {
  group('Issue #89 — function-typed getters (callback fields)', () {
    final generator = ClassDeclarationGenerator();

    test(
      'function-typed getter emits @JsonKey(includeFromJson/includeToJson: false)',
      () {
        // The exact repro from the issue:
        //   @Zorphy(kind: ZorphyKind.valueObject, generateJson: true)
        //   abstract class $Foo {
        //     String get id;
        //     void Function(WebUri? url)? get onClick;
        //   }
        //
        // Before the fix: emitted `final void Function(WebUri? url)? onClick;`
        // with no @JsonKey, causing json_serializable to fail with
        // "Could not generate `fromJson` code for `onClick`."
        //
        // After the fix: emitted with @JsonKey(includeFromJson: false,
        // includeToJson: false) so json_serializable skips it.
        //
        // NOTE: isGetterOnly defaults to false here because the analyzer
        // sets isGetterOnly=false for abstract getters declared in `$Foo`
        // (verified end-to-end: `String get name;` in `$Person` becomes
        // `final String name;` in concrete `Person` — see compare_test).
        final meta = _concreteMeta(
          name: 'Foo',
          fields: [
            NameTypeClassComment('id', 'String', 'Foo'),
            NameTypeClassComment(
              'onClick',
              'void Function(WebUri? url)?',
              'Foo',
            ),
          ],
        );
        final specs = generator.generateSpec(
          GenerationContext(metadata: meta, config: _jsonConfig()),
        );
        expect(specs, hasLength(1));
        final emitted = _emitClass(specs.first as Class);

        // The function-typed field MUST carry the skip-serialization
        // JsonKey annotation.
        expect(
          emitted,
          contains('@JsonKey(includeFromJson: false, includeToJson: false)'),
        );
        // The field declaration itself is preserved (so the $Foo
        // interface contract is still satisfied).
        expect(emitted, contains('final void Function(WebUri? url)? onClick;'));
        // Non-function-typed fields are NOT annotated with the
        // skip-serialization JsonKey (no behavior change for them).
        expect(emitted, contains('final String id;'));
        // The id field should NOT have a JsonKey annotation at all
        // (since the user didn't provide one and it's not function-typed).
        final idJsonKeyPattern = RegExp(
          r'@JsonKey\([^)]*\)\s*\n\s*final String id;',
        );
        expect(idJsonKeyPattern.hasMatch(emitted), isFalse);
      },
    );

    test('multiple function-typed fields all get the annotation', () {
      // Mirrors the issue's "Impact" list: ChromeSafariBrowserActionButton
      // has multiple callback fields. Each must be annotated.
      final meta = _concreteMeta(
        name: 'ActionButton',
        fields: [
          NameTypeClassComment('id', 'int', 'ActionButton'),
          NameTypeClassComment(
            'onClick',
            'void Function(WebUri? url)?',
            'ActionButton',
          ),
          NameTypeClassComment(
            'onLongPress',
            'void Function()?',
            'ActionButton',
          ),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitClass(specs.first as Class);

      // Count occurrences of the skip-serialization JsonKey — must be
      // exactly 2 (one per function-typed field).
      final matches = RegExp(
        r'@JsonKey\(includeFromJson: false, includeToJson: false\)',
      ).allMatches(emitted);
      expect(matches, hasLength(2));
    });

    test(
      'user-provided @JsonKey without includeFromJson is augmented for function-typed fields',
      () {
        // If the user provides their own @JsonKey (e.g. with a custom
        // name) but doesn't set includeFromJson/includeToJson, we still
        // need to add those — otherwise json_serializable will still try
        // to generate a serializer for the function type.
        final meta = _concreteMeta(
          name: 'Foo',
          fields: [
            NameTypeClassComment(
              'onClick',
              'void Function(WebUri? url)?',
              'Foo',
              jsonKeyInfo: const JsonKeyInfo(name: 'on_click'),
            ),
          ],
        );
        final specs = generator.generateSpec(
          GenerationContext(metadata: meta, config: _jsonConfig()),
        );
        final emitted = _emitClass(specs.first as Class);

        // The emitted JsonKey must include BOTH the user-provided name
        // AND the auto-added includeFromJson/includeToJson: false.
        expect(
          emitted,
          contains(
            "@JsonKey(name: 'on_click', includeFromJson: false, includeToJson: false)",
          ),
        );
      },
    );

    test(
      'user-provided @JsonKey with includeFromJson: false is left alone',
      () {
        // If the user already opted out (set includeFromJson: false AND
        // includeToJson: false), we must not duplicate or override.
        final meta = _concreteMeta(
          name: 'Foo',
          fields: [
            NameTypeClassComment(
              'onClick',
              'void Function(WebUri? url)?',
              'Foo',
              jsonKeyInfo: const JsonKeyInfo(
                includeFromJson: false,
                includeToJson: false,
              ),
            ),
          ],
        );
        final specs = generator.generateSpec(
          GenerationContext(metadata: meta, config: _jsonConfig()),
        );
        final emitted = _emitClass(specs.first as Class);

        // Exactly one JsonKey annotation, matching the user's input.
        final matches = RegExp(r'@JsonKey\([^)]*\)').allMatches(emitted);
        expect(matches, hasLength(1));
        expect(
          emitted,
          contains('@JsonKey(includeFromJson: false, includeToJson: false)'),
        );
      },
    );

    test('non-function-typed fields are unaffected', () {
      // Regression guard: the fix must NOT add JsonKey annotations to
      // regular fields (String, int, List<X>, Map<K,V>, custom types).
      final meta = _concreteMeta(
        name: 'Foo',
        fields: [
          NameTypeClassComment('id', 'String', 'Foo'),
          NameTypeClassComment('count', 'int', 'Foo'),
          NameTypeClassComment('tags', 'List<String>', 'Foo'),
          NameTypeClassComment('meta', 'Map<String, dynamic>', 'Foo'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitClass(specs.first as Class);

      // No JsonKey annotations at all — none of these are function-typed
      // and the user didn't provide any.
      expect(emitted, isNot(contains('@JsonKey')));
    });

    test('various function-type shapes are all detected', () {
      // The _isFunctionType heuristic must catch all common forms:
      //   - void Function()?
      //   - void Function(WebUri? url)?
      //   - String Function(int)
      //   - bool Function(Object)?
      //   - T Function<U>(U)  (generic function type — rare but valid)
      //   - Function / Function?  (bare supertype — issue #105)
      //   - List<Function> / Map<String, Function?>  (issue #105)
      // And must NOT match:
      //   - A class named `MyFunction` (no `Function(` or `Function<`)
      //   - `Function` appearing in a doc comment (the type string is
      //     sourced from the analyzer, not the comment)
      final cases = <String, bool>{
        'void Function()?': true,
        'void Function(WebUri? url)?': true,
        'String Function(int)': true,
        'bool Function(Object)?': true,
        'T Function<U>(U)': true,
        'void Function(WebUri?, String)?': true,
        // Issue #105 — bare `Function` forms (produced by the CLI when
        // the user writes `--field "onLoad:!Function?"`):
        'Function': true,
        'Function?': true,
        'List<Function>': true,
        'Map<String, Function?>': true,
        // Negative cases — not function types:
        'String': false,
        'int?': false,
        'List<String>': false,
        'Map<String, dynamic>': false,
        'MyFunctionClass': false,
        'FunctionRef': false,
        'FunctionLikeBuilder': false,
      };
      // Access the private static method via reflection-ish trick:
      // invoke it through the public surface by emitting a class with
      // the given type and checking whether the JsonKey is added.
      for (final entry in cases.entries) {
        final meta = _concreteMeta(
          name: 'Probe',
          fields: [NameTypeClassComment('f', entry.key, 'Probe')],
        );
        final specs = generator.generateSpec(
          GenerationContext(metadata: meta, config: _jsonConfig()),
        );
        final emitted = _emitClass(specs.first as Class);
        final hasSkipKey = emitted.contains(
          '@JsonKey(includeFromJson: false, includeToJson: false)',
        );
        expect(
          hasSkipKey,
          equals(entry.value),
          reason:
              '_isFunctionType($entry.key) should return ${entry.value} '
              '(emitted JsonKey: $hasSkipKey)',
        );
      }
    });

    test(
      'isGetterOnly=true function-typed field is still skipped entirely',
      () {
        // Regression guard: the existing isGetterOnly skip path must
        // still work — when isGetterOnly=true AND no defaultValue, the
        // field is NOT added to the concrete class at all (so no JsonKey
        // is needed either). This is the original behavior; the fix must
        // not change it.
        final meta = _concreteMeta(
          name: 'Foo',
          fields: [
            NameTypeClassComment('id', 'String', 'Foo'),
            NameTypeClassComment(
              'onClick',
              'void Function(WebUri? url)?',
              'Foo',
              isGetterOnly: true,
            ),
          ],
        );
        final specs = generator.generateSpec(
          GenerationContext(metadata: meta, config: _jsonConfig()),
        );
        final emitted = _emitClass(specs.first as Class);

        // onClick must NOT appear in the concrete class — the isGetterOnly
        // skip path takes precedence (no field declaration, no JsonKey).
        expect(emitted, isNot(contains('onClick')));
        // id is still there (it's not getter-only in this test... well it
        // is by default false, so it's kept).
        expect(emitted, contains('final String id;'));
      },
    );
  });
}
