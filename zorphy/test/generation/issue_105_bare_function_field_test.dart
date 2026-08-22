// Regression test for issue #105:
// "generator: value-object entities with callback fields (!Function?) emit
//  @JsonSerializable with Function fields — json_serializable errors,
//  .g.dart never generated (uncompilable output)"
//
// Root cause: the #89 fix in `ClassDeclarationGenerator._isFunctionType`
// only matched `Function(` and `Function<`. The BARE `Function` /
// `Function?` forms — produced by the CLI when the user writes a callback
// field without pinning down a signature (e.g.
// `zfa entity create -n X --field "onLoad:!Function?"`) — slipped through.
// The generator emitted `final Function? onLoad;` on the
// `@JsonSerializable`-annotated concrete class with no `@JsonKey` opt-out,
// `json_serializable` then errored with
//   "Could not generate `fromJson` code for `onLoad`."
// and the `.g.dart` was never written, breaking the whole package.
//
// Fix: `_isFunctionType` now also matches the bare `Function` token
// (with word boundaries so it does not false-positive on class names like
// `MyFunction` / `FunctionRef`). The existing `_effectiveJsonKeyForField`
// pipeline then emits the synthetic
// `@JsonKey(includeFromJson: false, includeToJson: false)` annotation
// automatically, exactly as it does for `void Function(...)?` getters.

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
  group('Issue #105 — bare Function/Function? callback fields on value-object', () {
    final generator = ClassDeclarationGenerator();

    test(
      'exact issue repro: ScriptHtmlTagAttributes with onLoad/onError as Function?',
      () {
        // Mirrors the CLI invocation from the issue:
        //   zfa entity create -n ScriptHtmlTagAttributes \
        //     --kind=value_object \
        //     --field "type:String"  --field "id:String?" \
        //     --field "onLoad:!Function?"  --field "onError:!Function?"
        //
        // The CLI writes `Function? get onLoad;` / `Function? get onError;`
        // to the entity file; the analyzer resolves both field types to
        // the bare `Function?` type. Before the fix: emitted as
        //   final Function? onLoad;
        //   final Function? onError;
        // with NO @JsonKey, causing json_serializable to fail with
        // "Could not generate `fromJson` code for `onLoad`."
        //
        // After the fix: each Function? field carries
        //   @JsonKey(includeFromJson: false, includeToJson: false)
        // so json_serializable skips them and the .g.dart is written.
        final meta = _concreteMeta(
          name: 'ScriptHtmlTagAttributes',
          fields: [
            NameTypeClassComment('type', 'String', 'ScriptHtmlTagAttributes'),
            NameTypeClassComment('id', 'String?', 'ScriptHtmlTagAttributes'),
            NameTypeClassComment(
              'onLoad',
              'Function?',
              'ScriptHtmlTagAttributes',
            ),
            NameTypeClassComment(
              'onError',
              'Function?',
              'ScriptHtmlTagAttributes',
            ),
          ],
        );
        final specs = generator.generateSpec(
          GenerationContext(metadata: meta, config: _jsonConfig()),
        );
        expect(specs, hasLength(1));
        final emitted = _emitClass(specs.first as Class);

        // Both callback fields MUST carry the skip-serialization JsonKey.
        final skipKeyMatches = RegExp(
          r'@JsonKey\(includeFromJson: false, includeToJson: false\)',
        ).allMatches(emitted);
        expect(skipKeyMatches, hasLength(2));

        // The field declarations themselves are preserved so the
        // abstract `$ScriptHtmlTagAttributes` interface contract is
        // still satisfied (callbacks remain accessible at runtime).
        expect(emitted, contains('final Function? onLoad;'));
        expect(emitted, contains('final Function? onError;'));

        // Non-callback fields are unaffected — no JsonKey on them.
        expect(emitted, contains('final String type;'));
        expect(emitted, contains('final String? id;'));
        final typeJsonKeyPattern = RegExp(
          r'@JsonKey\([^)]*\)\s*\n\s*final String type;',
        );
        expect(typeJsonKeyPattern.hasMatch(emitted), isFalse);
        final idJsonKeyPattern = RegExp(
          r'@JsonKey\([^)]*\)\s*\n\s*final String\? id;',
        );
        expect(idJsonKeyPattern.hasMatch(emitted), isFalse);
      },
    );

    test('bare non-nullable `Function` is also detected', () {
      // Some callers want a non-nullable callback slot:
      //   --field "onReady:!Function"
      // The CLI writes `Function get onReady;` and the analyzer resolves
      // the type to `Function` (no `?`). This must also be detected —
      // json_serializable cannot serialize a non-nullable `Function`
      // field any more than a nullable one.
      final meta = _concreteMeta(
        name: 'Foo',
        fields: [
          NameTypeClassComment('id', 'String', 'Foo'),
          NameTypeClassComment('onReady', 'Function', 'Foo'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitClass(specs.first as Class);

      expect(
        emitted,
        contains(
          '@JsonKey(includeFromJson: false, includeToJson: false)',
        ),
      );
      expect(emitted, contains('final Function onReady;'));
    });

    test('bare `Function` nested in generics is detected', () {
      // Edge case: `List<Function>` and `Map<String, Function?>` should
      // also be treated as function-typed for the purposes of JSON
      // serialization — json_serializable cannot synthesize a serializer
      // for them either (the inner Function type is what breaks it).
      final meta = _concreteMeta(
        name: 'Foo',
        fields: [
          NameTypeClassComment('id', 'String', 'Foo'),
          NameTypeClassComment('callbacks', 'List<Function>', 'Foo'),
          NameTypeClassComment(
            'namedCallbacks',
            'Map<String, Function?>',
            'Foo',
          ),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitClass(specs.first as Class);

      final skipKeyMatches = RegExp(
        r'@JsonKey\(includeFromJson: false, includeToJson: false\)',
      ).allMatches(emitted);
      expect(skipKeyMatches, hasLength(2));
    });

    test('class names containing `Function` substring are NOT detected', () {
      // Regression guard: the word-boundary regex must NOT match class
      // names like `MyFunction`, `FunctionRef`, `FunctionLikeBuilder`,
      // etc. These are plain reference types and json_serializable
      // handles them normally (or fails for other reasons, but not with
      // the skip-JsonKey path).
      final meta = _concreteMeta(
        name: 'Foo',
        fields: [
          NameTypeClassComment('id', 'String', 'Foo'),
          NameTypeClassComment('handler', 'MyFunction', 'Foo'),
          NameTypeClassComment('ref', 'FunctionRef', 'Foo'),
          NameTypeClassComment('builder', 'FunctionLikeBuilder', 'Foo'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitClass(specs.first as Class);

      // No skip-serialization JsonKey should be emitted for any of
      // these — they are plain (non-function) types.
      expect(
        emitted,
        isNot(
          contains(
            '@JsonKey(includeFromJson: false, includeToJson: false)',
          ),
        ),
      );
    });

    test('mixed callback + data fields: only callbacks get the JsonKey', () {
      // Realistic value-object with both data fields and callback
      // fields. The generator must annotate ONLY the callback fields.
      final meta = _concreteMeta(
        name: 'BrowserMenuItem',
        fields: [
          NameTypeClassComment('id', 'String', 'BrowserMenuItem'),
          NameTypeClassComment('label', 'String', 'BrowserMenuItem'),
          NameTypeClassComment('icon', 'String?', 'BrowserMenuItem'),
          NameTypeClassComment('onTap', 'Function?', 'BrowserMenuItem'),
          NameTypeClassComment(
            'onLongPress',
            'void Function()?',
            'BrowserMenuItem',
          ),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitClass(specs.first as Class);

      // Exactly two skip-JsonKey annotations — one per callback field
      // (the bare `Function?` and the fully-typed `void Function()?`).
      final skipKeyMatches = RegExp(
        r'@JsonKey\(includeFromJson: false, includeToJson: false\)',
      ).allMatches(emitted);
      expect(skipKeyMatches, hasLength(2));

      // Data fields are emitted without the skip-JsonKey.
      expect(emitted, contains('final String id;'));
      expect(emitted, contains('final String label;'));
      expect(emitted, contains('final String? icon;'));
    });

    test(
      'user-provided @JsonKey on bare Function field is augmented',
      () {
        // If the user provides their own @JsonKey (e.g. with a custom
        // wire name) on a bare `Function?` field but doesn't set
        // includeFromJson/includeToJson, we must still add those —
        // otherwise json_serializable will still try to generate a
        // serializer for the bare Function type and fail.
        final meta = _concreteMeta(
          name: 'Foo',
          fields: [
            NameTypeClassComment(
              'onLoad',
              'Function?',
              'Foo',
              jsonKeyInfo: const JsonKeyInfo(name: 'on_load'),
            ),
          ],
        );
        final specs = generator.generateSpec(
          GenerationContext(metadata: meta, config: _jsonConfig()),
        );
        final emitted = _emitClass(specs.first as Class);

        expect(
          emitted,
          contains(
            "@JsonKey(name: 'on_load', includeFromJson: false, includeToJson: false)",
          ),
        );
      },
    );
  });
}
