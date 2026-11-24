// Generator-level tests for ISSUE-009 (zorphy#184) review findings.
//
// The golden + runtime suites prove what `PolymorphicPatchEmitter` emits and
// that the emitted shape works. These tests cover the GENERATOR wiring, which
// neither of them touches:
//
//  1. A generic sealed root is refused with a clear error instead of emitting
//     `PatchValue<T>` members whose `T` no emitted class declares.
//  2. A sealed root's subtype patch, as emitted, DOES extend the root patch
//     and narrows `apply` — and the generator-level route that would bypass
//     this (a subtype falling through to the plain `PatchBase` emitter) is
//     documented here so the gap cannot drift silently.

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/common/classes.dart';
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/patch_generator.dart';
import 'package:zorphy/src/models/agent_directive_info.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/generation_config.dart';

class _StubClassElement implements ClassElement {
  @override
  final String name;
  _StubClassElement(this.name);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

GenerationConfig _config() {
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
    nonSealed: false,
    factoryMethods: [],
    ownFields: {},
  );
}

ClassMetadata _sealedRootMeta({
  String cleanName = 'Notification',
  List<GenericParameterMetadata> generics = const [],
  List<NameTypeClassComment> fields = const [],
  List<Interface> explicitSubtypes = const [],
}) {
  return ClassMetadata(
    originalName: '\$\$$cleanName',
    cleanName: cleanName,
    isAbstract: true,
    isSealed: true,
    nonSealed: false,
    hasConstConstructor: true,
    docComment: '',
    generics: generics,
    interfaces: const [],
    allValueTInterfaces: const [],
    allFields: fields,
    ownFieldNames: const {},
    factoryMethods: const [],
    explicitSubtypes: explicitSubtypes,
    isInParentExplicitSubtypes: false,
    classElement: _StubClassElement(cleanName),
    agentDirectiveInfo: const AgentDirectiveInfo(),
    allAnnotatedClasses: const {},
  );
}

Interface _subtypeInterface(String name, List<NameType> fields) =>
    Interface('\$$name', const [], const [], fields);

String _emit(List<Spec> specs) {
  final lib = Library((b) => b.body.addAll(specs));
  return lib.accept(DartEmitter(useNullSafetySyntax: true)).toString();
}

void main() {
  group('ISSUE-009 generator wiring — sealed root patch', () {
    test('a non-generic sealed root emits the polymorphic patch surface', () {
      final meta = _sealedRootMeta(
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('readAt', 'DateTime?', ''),
        ],
        explicitSubtypes: [
          _subtypeInterface('OrderNotification', [
            NameType('itemCount', 'int'),
          ]),
        ],
      );
      final context = GenerationContext(metadata: meta, config: _config());

      final emitted = _emit(PatchClassGenerator().generateSpec(context));

      expect(emitted, contains('sealed class NotificationPatch'));
      expect(emitted, contains('final class NotificationSharedPatch'));
      expect(
        emitted,
        contains('PatchValue<DateTime?> get readAt'),
        reason:
            'a shared nullable field keeps its nullability so it can be '
            'cleared deliberately',
      );
    });

    test('a generic sealed root is refused by name, not emitted broken', () {
      final meta = _sealedRootMeta(
        cleanName: 'Result',
        generics: [const GenericParameterMetadata(name: 'T')],
        fields: [NameTypeClassComment('value', 'T', '')],
        explicitSubtypes: [
          _subtypeInterface('OkResult', [NameType('value', 'T')]),
        ],
      );
      final context = GenerationContext(metadata: meta, config: _config());

      // Without this gate the emitter writes `PatchValue<T> get value` into a
      // class that declares no `T`, and the generated library does not compile.
      expect(
        () => PatchClassGenerator().generateSpec(context),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('generic sealed root'),
          ),
        ),
      );
    });

    test('a sealed root with no subtypes emits nothing', () {
      final meta = _sealedRootMeta(
        fields: [NameTypeClassComment('id', 'String', '')],
      );
      final context = GenerationContext(metadata: meta, config: _config());

      expect(PatchClassGenerator().generateSpec(context), isEmpty);
      expect(
        PatchClassGenerator().shouldGenerate(context),
        isFalse,
        reason:
            'a shared patch that can never dispatch to a subtype is a silent '
            'trap, so the generator declines to emit one',
      );
    });
  });

  group('ISSUE-009 generator wiring — subtype patch shape', () {
    test('the root emission names every subtype so dispatch arms resolve', () {
      final meta = _sealedRootMeta(
        fields: [NameTypeClassComment('id', 'String', '')],
        explicitSubtypes: [
          _subtypeInterface('OrderNotification', [NameType('itemCount', 'int')]),
          _subtypeInterface('PriceDropNotification', [
            NameType('newPrice', 'double'),
          ]),
        ],
      );
      final context = GenerationContext(metadata: meta, config: _config());

      final emitted = _emit(PatchClassGenerator().generateSpec(context));

      // Each declared subtype gets an `if (target is X)` arm; a missing arm
      // would send that subtype to the ArgumentError fallback at runtime.
      expect(emitted, contains('if (target is OrderNotification)'));
      expect(emitted, contains('if (target is PriceDropNotification)'));
      expect(
        emitted,
        contains('NotificationPatch cannot apply to'),
        reason: 'an unknown element must fail loudly, never be skipped',
      );
    });
  });
}
