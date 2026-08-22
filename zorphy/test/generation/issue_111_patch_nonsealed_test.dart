// Regression test for issue #111 review findings on PR #112:
// "nonSealed abstract bases: Patch + FieldEnum generation"
//
// Verifies that:
//  1. The abstract Patch stub preserves the entity's generic parameters
//     (including bounds) and parameterizes the PatchBase entity type, while
//     the field enum stays unparameterized.
//  2. Fieldless abstract nonSealed subtypes still get a placeholder field
//     enum — the stub references `X$` but getEnumPropertyList returns ''
//     for empty fields.
//  3. PatchGenerator emits no patchWith methods (main or interface) for
//     abstract nonSealed bases — an abstract class cannot be constructed.

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
  required bool isAbstract,
  required bool nonSealed,
  bool isInParentExplicitSubtypes = false,
  List<GenericParameterMetadata> generics = const [],
  List<InterfaceMetadata> interfaces = const [],
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
    generics: generics,
    interfaces: interfaces,
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
  group('issue #111 — nonSealed abstract Patch stub', () {
    test('golden: bounded generic parameters are preserved on the stub', () {
      final meta = _meta(
        originalName: '\$\$Base',
        cleanName: 'Base',
        isAbstract: true,
        nonSealed: true,
        generics: [
          GenericParameterMetadata(name: 'T'),
          GenericParameterMetadata(name: 'U', bound: 'num'),
        ],
      );
      final context = GenerationContext(metadata: meta, config: _patchConfig());
      final specs = PatchClassGenerator().generateSpec(context);
      final emitted = _emit(specs);

      // Golden: declaration carries the bounded params, PatchBase gets the
      // parameterized entity type, and the field enum stays unparameterized.
      expect(
        emitted,
        contains('abstract class BasePatch<T, U extends num> '
            'extends PatchBase<Base<T, U>, Base\$> {}'),
      );
      expect(emitted, isNot(contains('Base\$<')));
      expect(emitted, isNot(contains('PatchBase<Base, Base\$>')));
    });

    test('non-generic stub stays unchanged', () {
      final meta = _meta(
        originalName: '\$\$Base',
        cleanName: 'Base',
        isAbstract: true,
        nonSealed: true,
      );
      final context = GenerationContext(metadata: meta, config: _patchConfig());
      final emitted = _emit(PatchClassGenerator().generateSpec(context));

      expect(
        emitted,
        contains('abstract class BasePatch extends PatchBase<Base, Base\$> {}'),
      );
    });

    test('fieldless explicit subtype gets a placeholder field enum', () {
      final meta = _meta(
        originalName: '\$Marker',
        cleanName: 'Marker',
        isAbstract: true,
        nonSealed: true,
        isInParentExplicitSubtypes: true,
      );
      final context = GenerationContext(metadata: meta, config: _patchConfig());
      final emitted = _emit(PatchClassGenerator().generateSpec(context));

      // The stub references Marker$, so a placeholder enum must exist for the
      // generated Dart to compile (getEnumPropertyList returns '' when there
      // are no fields).
      expect(emitted, contains('PatchBase<Marker, Marker\$>'));
      expect(emitted, contains('enum Marker\$ { none }'));
    });

    test('PatchGenerator emits no methods for abstract nonSealed bases', () {
      final iface = InterfaceMetadata(
        '\$Named',
        [],
        [],
        [NameType('name', 'String')],
        element: _StubClassElement('Named'),
      );
      final meta = _meta(
        originalName: '\$\$Base',
        cleanName: 'Base',
        isAbstract: true,
        nonSealed: true,
        interfaces: [iface],
        fields: [NameTypeClassComment('name', 'String', '')],
      );
      final context = GenerationContext(metadata: meta, config: _patchConfig());

      // shouldGenerate gates this on (abstract + nonSealed), but generateSpec
      // must not emit interface patchWith methods that would construct the
      // abstract class.
      expect(PatchGenerator().shouldGenerate(context), isTrue);
      expect(PatchGenerator().generateSpec(context), isEmpty);
    });
  });
}
