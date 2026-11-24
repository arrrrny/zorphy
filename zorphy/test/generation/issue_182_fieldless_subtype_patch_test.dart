// Regression test: a fieldless CONCRETE explicit subtype must get the
// placeholder field enum its Patch references.
//
// `PatchClassGenerator` emits a `<Name>Patch` for every class with
// `allFields.isNotEmpty || isInParentExplicitSubtypes`. For a fieldless
// concrete subtype of a union (e.g. `PaymentMethod.cash() = CashPayment;`)
// the patch is `class CashPaymentPatch
// extends PatchBase<CashPayment, CashPayment$>` — which references
// `CashPayment$`. `getEnumPropertyList` returns '' for empty fields, so
// `FieldEnumGenerator` used to emit nothing for that class, leaving the
// generated Dart referencing an undefined `CashPayment$` type
// (`non_type_as_type_argument`). The migrator smoke fixture (an 11-class
// freezed project with a union) failed `dart analyze` on exactly this.
//
// The abstract-nonSealed stub path (issue #111) already handled its fieldless
// placeholder; this covers the concrete path the same way.

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/patch_generator.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/agent_directive_info.dart';
import 'package:zorphy/src/models/generation_config.dart';
import 'package:zorphy/src/models/interface_metadata.dart';

class _StubClassElement implements ClassElement {
  @override
  final String name;
  _StubClassElement(this.name);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ClassMetadata _meta({
  required String originalName,
  required String cleanName,
  bool isAbstract = false,
  bool nonSealed = false,
  bool isInParentExplicitSubtypes = false,
  List<NameTypeClassComment> fields = const [],
}) {
  return ClassMetadata(
    originalName: originalName,
    cleanName: cleanName,
    isAbstract: isAbstract,
    isSealed: isAbstract && !nonSealed,
    nonSealed: nonSealed,
    hasConstConstructor: false,
    docComment: '',
    generics: const [],
    interfaces: const <InterfaceMetadata>[],
    allValueTInterfaces: const [],
    allFields: fields,
    ownFieldNames: const {},
    factoryMethods: const [],
    explicitSubtypes: const [],
    isInParentExplicitSubtypes: isInParentExplicitSubtypes,
    classElement: _StubClassElement(cleanName),
    agentDirectiveInfo: const AgentDirectiveInfo(),
    allAnnotatedClasses: const {},
  );
}

GenerationConfig _patchConfig() {
  return const GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.entity,
    autoId: false,
    generateJson: false,
    explicitToJson: false,
    generateCopyWith: false,
    generateCopyWithFn: false,
    generateCompareTo: false,
    generatePatch: true,
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

String _emit(List<Spec> specs) {
  final lib = Library((b) => b.body.addAll(specs));
  return lib.accept(DartEmitter(useNullSafetySyntax: true)).toString();
}

void main() {
  group('fieldless concrete explicit subtype — placeholder field enum', () {
    test(r'FieldEnumGenerator emits `enum <Name>$ { none }` for it', () {
      final meta = _meta(
        originalName: r'$CashPayment',
        cleanName: 'CashPayment',
        isInParentExplicitSubtypes: true,
      );
      final context = GenerationContext(metadata: meta, config: _patchConfig());

      expect(FieldEnumGenerator().shouldGenerate(context), isTrue);
      final emitted = _emit(FieldEnumGenerator().generateSpec(context));
      expect(emitted, contains('enum CashPayment\$ { none }'));
    });

    test(r'the Patch references the same `CashPayment$` the enum defines', () {
      final meta = _meta(
        originalName: r'$CashPayment',
        cleanName: 'CashPayment',
        isInParentExplicitSubtypes: true,
      );
      final context = GenerationContext(metadata: meta, config: _patchConfig());

      final patch = _emit(PatchClassGenerator().generateSpec(context));
      final enumSrc = _emit(FieldEnumGenerator().generateSpec(context));
      expect(patch, contains('PatchBase<CashPayment, CashPayment\$>'));
      // The exact type the patch names must be the type the enum declares.
      expect(enumSrc, contains('enum CashPayment\$'));
    });

    test('a fieldless class NOT in explicit subtypes gets no enum', () {
      final meta = _meta(originalName: r'$Marker', cleanName: 'Marker');
      final context = GenerationContext(metadata: meta, config: _patchConfig());

      expect(FieldEnumGenerator().shouldGenerate(context), isFalse);
    });

    test('a fielded concrete class still emits its real field enum', () {
      final meta = _meta(
        originalName: r'$CardPayment',
        cleanName: 'CardPayment',
        isInParentExplicitSubtypes: true,
        fields: [
          NameTypeClassComment('last4', 'String', ''),
          NameTypeClassComment('brand', 'String', ''),
        ],
      );
      final context = GenerationContext(metadata: meta, config: _patchConfig());

      final emitted = _emit(FieldEnumGenerator().generateSpec(context));
      expect(emitted, contains('enum CardPayment\$'));
      expect(emitted, contains('last4'));
      expect(emitted, contains('brand'));
      expect(emitted, isNot(contains('{ none }')));
    });

    test('abstract nonSealed fieldless enum is NOT double-emitted here', () {
      // PatchClassGenerator's abstract stub path owns that placeholder; the
      // FieldEnumGenerator must defer to it (only the fielded case is its own).
      final meta = _meta(
        originalName: r'$$Base',
        cleanName: 'Base',
        isAbstract: true,
        nonSealed: true,
        isInParentExplicitSubtypes: true,
      );
      final context = GenerationContext(metadata: meta, config: _patchConfig());

      expect(FieldEnumGenerator().shouldGenerate(context), isFalse);
    });
  });
}
