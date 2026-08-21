// Regression test for issue #119:
// "patch_generator emits `as $Type?` cast with leading $ for
//  explicit-subtype field types (compile error)"
//
// Root cause: when a field's type is an explicit-subtype class (declared with a
// leading `$`, e.g. `$Credentials`), the generated `patchWith` cast used the raw
// `$`-prefixed type name (`as $Credentials?`). The consuming file declares the
// field with the trimmed name (`Credentials?`), so the cast referenced an
// undefined identifier and the generated file failed to compile.
//
// Fix: the cast strips the leading `$` from the field type, keeping the
// trailing `?` nullable marker, so it matches how the field is declared.

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/patch_generator.dart';
import 'package:zorphy/src/models/class_metadata.dart';
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
    allAnnotatedClasses: const {},
  );
}

GenerationConfig _patchConfig() {
  return const GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.valueObject,
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
    nonSealed: false,
    factoryMethods: [],
    ownFields: {},
  );
}

String _emitMethod(Method spec) {
  final lib = Library((b) => b.body.add(spec));
  return lib.accept(DartEmitter(useNullSafetySyntax: true)).toString();
}

void main() {
  group('Issue #119 — patchWith cast strips leading \$ from subtype field types', () {
    final generator = PatchGenerator();

    test('main patchWith casts use the trimmed reference type', () {
      final meta = _concreteMeta(
        name: 'InitializationParams',
        fields: [
          NameTypeClassComment('credentials', r'$Credentials?', 'InitializationParams'),
          NameTypeClassComment('settings', r'$Settings?', 'InitializationParams'),
          NameTypeClassComment('label', 'String?', 'InitializationParams'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _patchConfig()),
      );
      final emitted = _emitMethod(specs.first as Method);

      // Casts must use the trimmed reference type, not the raw subtype name.
      expect(emitted, contains('as Credentials?'));
      expect(emitted, contains('as Settings?'));
      // The broken form (`as $Credentials?`) must never appear. A legit `$`
      // only shows up in the field-enum name (e.g. `InitializationParams$`),
      // never inside an `as` cast.
      expect(emitted, isNot(contains(RegExp(r'as \$\w+\?'))));
      // Non-subtype fields are unaffected.
      expect(emitted, contains('as String?'));
    });
  });
}
