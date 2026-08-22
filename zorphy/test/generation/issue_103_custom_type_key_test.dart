// Regression test for issue #103:
// "zorphy polymorphic JSON dispatch: __typename key + class-name values
//  are hardcoded — no way to preserve custom type-key wires"
//
// Verifies that:
//  1. `@Zorphy(typeKey: 'type')` on a polymorphic base renames the
//     discriminator key from `'__typename'` to `'type'` in BOTH
//     `fromJson` (dispatch) and `toJson` (emit).
//  2. `@Zorphy(subtypeWireValue: '...')` on each subtype overrides the
//     wire value the base matches/emits (default = clean class name).
//  3. The subtype's own `toJson()` (via _addToJsonWithDiscriminator)
//     emits the inherited typeKey + the subtype's subtypeWireValue.
//  4. The default behavior (no typeKey, no subtypeWireValue) is
//     unchanged: key is `'__typename'`, values are clean class names.

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy/src/ast/class_member_code.dart';
import 'package:zorphy/src/common/classes.dart';
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/json_generator.dart';
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

/// Builds a polymorphic-base [ClassMetadata] with [explicitSubtypes].
ClassMetadata _baseMeta({
  required String name,
  required List<Interface> subtypes,
  String? typeKey,
  bool nonSealed = true,
  bool isAbstract = false,
}) {
  return ClassMetadata(
    originalName: name,
    cleanName: name,
    isAbstract: isAbstract,
    isSealed: false,
    nonSealed: nonSealed,
    typeKey: typeKey,
    hasConstConstructor: false,
    docComment: '',
    generics: const [],
    interfaces: const [],
    allValueTInterfaces: const [],
    allFields: const [],
    ownFieldNames: const {},
    factoryMethods: const [],
    explicitSubtypes: subtypes,
    isInParentExplicitSubtypes: false,
    classElement: _StubClassElement(name),
    agentDirectiveInfo: const AgentDirectiveInfo(),
      allAnnotatedClasses: const {},
  );
}

/// Builds a subtype [ClassMetadata] (isInParentExplicitSubtypes: true).
ClassMetadata _subtypeMeta({
  required String name,
  String? typeKey,
  String? subtypeWireValue,
}) {
  return ClassMetadata(
    originalName: name,
    cleanName: name,
    isAbstract: false,
    isSealed: false,
    nonSealed: false,
    typeKey: typeKey,
    subtypeWireValue: subtypeWireValue,
    hasConstConstructor: false,
    docComment: '',
    generics: const [],
    interfaces: const [],
    allValueTInterfaces: const [],
    allFields: const [],
    ownFieldNames: const {},
    factoryMethods: const [],
    explicitSubtypes: const [],
    isInParentExplicitSubtypes: true,
    classElement: _StubClassElement(name),
    agentDirectiveInfo: const AgentDirectiveInfo(),
      allAnnotatedClasses: const {},
  );
}

Interface _subtype(String name, {String? wireValue}) {
  return Interface.fromGenerics(name, [], [], true, false, false, wireValue);
}

GenerationConfig _jsonConfig() {
  return const GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.entity,
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
    nonSealed: true,
    factoryMethods: [],
    ownFields: {},
  );
}

/// Emits a list of specs (ClassMemberCode + Method) into a single
/// source string by injecting them into a synthetic Class.
String _emitSpecs(List<Spec> specs) {
  final constructors = <Constructor>[];
  final methods = <Method>[];
  for (final spec in specs) {
    if (spec is ClassMemberCode) {
      if (spec.constructor != null) constructors.add(spec.constructor!);
      if (spec.method != null) methods.add(spec.method!);
    } else if (spec is Method) {
      methods.add(spec);
    }
  }
  final cls = Class((b) => b
    ..name = 'Synthetic'
    ..constructors.addAll(constructors)
    ..methods.addAll(methods));
  final lib = Library((b) => b.body.add(cls));
  return lib.accept(DartEmitter(useNullSafetySyntax: true)).toString();
}

void main() {
  final generator = JsonGenerator();

  group('issue #103 — custom typeKey + subtypeWireValue', () {
    test('base fromJson dispatches on custom typeKey with custom wire values', () {
      // Mirrors the zikzak_inappwebview TrustedWebActivityDisplayMode contract:
      //   {"type": "DEFAULT_MODE" | "IMMERSIVE_MODE"}
      final meta = _baseMeta(
        name: 'DisplayMode',
        typeKey: 'type',
        subtypes: [
          _subtype('DefaultMode', wireValue: 'DEFAULT_MODE'),
          _subtype('ImmersiveMode', wireValue: 'IMMERSIVE_MODE'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitSpecs(specs);

      // The discriminator key MUST be the custom `type`, NOT `__typename`.
      expect(emitted, contains("json['type']"));
      expect(emitted, isNot(contains('__typename')));

      // Each subtype's custom wire value must appear in the dispatch.
      expect(emitted, contains("'DEFAULT_MODE'"));
      expect(emitted, contains("'IMMERSIVE_MODE'"));

      // Clean class names must NOT appear as wire values (they're overridden).
      expect(emitted, isNot(contains("'DefaultMode'")));
      expect(emitted, isNot(contains("'ImmersiveMode'")));
    });

    test('base toJson emits custom typeKey + custom wire values', () {
      final meta = _baseMeta(
        name: 'DisplayMode',
        typeKey: 'type',
        subtypes: [
          _subtype('DefaultMode', wireValue: 'DEFAULT_MODE'),
          _subtype('ImmersiveMode', wireValue: 'IMMERSIVE_MODE'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitSpecs(specs);

      // The non-sealed polymorphic toJson must emit the custom key.
      expect(emitted, contains("json['type'] = 'DEFAULT_MODE'"));
      expect(emitted, contains("json['type'] = 'IMMERSIVE_MODE'"));
      // Self-case emits the base's clean name (no subtypeWireValue on base).
      expect(emitted, contains("json['type'] = 'DisplayMode'"));
    });

    test(
        'subtype own toJson (via _addToJsonWithDiscriminator) uses inherited '
        'typeKey + own subtypeWireValue', () {
      // The subtype inherits typeKey='type' from the base (resolved by
      // ClassAnalyzer._resolveInheritedTypeKey). In this unit test we
      // pass the resolved value directly.
      final meta = _subtypeMeta(
        name: 'DefaultMode',
        typeKey: 'type',
        subtypeWireValue: 'DEFAULT_MODE',
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitSpecs(specs);

      // Subtype's own toJson emits the inherited typeKey + own wire value.
      expect(emitted, contains("json['type'] = 'DEFAULT_MODE'"));
      expect(emitted, isNot(contains('__typename')));
      expect(emitted, isNot(contains("'DefaultMode'")));
    });

    test('default behavior unchanged when typeKey/subtypeWireValue are null', () {
      final meta = _baseMeta(
        name: 'PaymentMethod',
        subtypes: [
          _subtype('CreditCard'),
          _subtype('PayPal'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitSpecs(specs);

      // Default key is __typename.
      expect(emitted, contains("json['__typename']"));
      // Default wire values are clean class names.
      expect(emitted, contains("'CreditCard'"));
      expect(emitted, contains("'PayPal'"));
      expect(emitted, contains("'PaymentMethod'"));
    });

    test('_sanitizeJson strips the custom typeKey (not __typename)', () {
      final meta = _baseMeta(
        name: 'DisplayMode',
        typeKey: 'type',
        subtypes: [
          _subtype('DefaultMode', wireValue: 'DEFAULT_MODE'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitSpecs(specs);

      // _sanitizeJson must remove the custom key, not the default.
      expect(emitted, contains("json.remove('type');"));
      expect(emitted, isNot(contains("json.remove('__typename');")));
    });

    test('error message references the custom typeKey', () {
      final meta = _baseMeta(
        name: 'DisplayMode',
        typeKey: 'type',
        isAbstract: true,
        nonSealed: false,
        subtypes: [
          _subtype('DefaultMode', wireValue: 'DEFAULT_MODE'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _jsonConfig()),
      );
      final emitted = _emitSpecs(specs);

      // The UnsupportedError message must use the custom key name.
      expect(emitted, contains("The type '"));
      expect(emitted, isNot(contains('The __typename')));
    });
  });
}
