// E2E smoke for issue #223: the v3 archetype surface must come out of the
// REAL build_runner pipeline, not only out of emitter-level tests.
//
// Before #223 the production builder registered only the legacy
// `@Zorphy`/`@Zorphy2` type checkers, so a consumer's `@ZorphyEntity` /
// `@ZorphyState` / `@ZorphyUnion` / `@ZorphyIntent` / `@ZorphyValue` class
// produced NO generated output — the issue's reproduction. This test pins the
// closed behavior: the shared part of a v3 library carries every archetype's
// surface, the legacy path still generates beside it, and the emitted source
// compiles.
//
// Follows the issue_109 / decorator_preservation e2e pattern: the part files
// are produced by `dart run build_runner build` inside example/ (CI runs it
// before this test) and asserted here.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final v3Part = File('example/lib/_br_/v3_archetypes/v3_archetypes.part.dart');
  final legacyPart = File(
    'example/lib/_br_/v3_archetypes/legacy_control.part.dart',
  );

  late String v3;
  late String legacy;

  setUpAll(() {
    for (final file in [v3Part, legacyPart]) {
      if (!file.existsSync()) {
        fail(
          'Missing generated file: ${file.path}\n'
          'Run: cd example && dart run build_runner build '
          '--delete-conflicting-outputs',
        );
      }
    }
    v3 = v3Part.readAsStringSync();
    legacy = legacyPart.readAsStringSync();
  });

  group('#223 v3 archetypes — e2e build_runner smoke', () {
    test(
      '@ZorphyEntity: sealed root + final leaf + inherited principalKey',
      () {
        expect(
          v3,
          contains(
            'sealed class Notification implements ZorphyEntityBase<String>',
          ),
        );
        expect(
          v3,
          contains('final class OrderNotification extends Notification'),
        );
        expect(v3, contains('String get principalKey => id;'));
        expect(v3, contains('const OrderNotification.fromTrusted({'));
      },
    );

    test('@ZorphyState: sealed state root + final leaf', () {
      expect(v3, contains('sealed class UiState implements ZorphyStateBase'));
      expect(v3, contains('final class ReadyState extends UiState'));
    });

    test('@ZorphyUnion: union root + synthetic variant leaves', () {
      expect(
        v3,
        contains('sealed class AsyncStatus implements ZorphyValueBase'),
      );
      expect(v3, contains('final class Loading extends AsyncStatus'));
      expect(v3, contains('final class Ready extends AsyncStatus'));
    });

    test('@ZorphyIntent: intent envelope with digest and replaySafe', () {
      expect(
        v3,
        contains('class InspectProductIntent implements ZorphyIntentBase'),
      );
      expect(v3, contains('String get intentName'));
      expect(v3, contains('bool get replaySafe => true;'));
      expect(v3, contains('String intentDigest()'));
    });

    test('@ZorphyIntent: validated fromWire + mock/wire fixtures (#232)', () {
      // Every intent class — the standalone leaf and every node of the
      // polymorphic hierarchy — carries the validated decoder.
      expect(
        v3,
        contains('static ZorphyBoundaryResult<InspectProductIntent> fromWire('),
      );
      expect(v3, contains('static ZorphyBoundaryResult<CartIntent> fromWire('));
      expect(
        v3,
        contains('static ZorphyBoundaryResult<AddToCartIntent> fromWire('),
      );
      // The polymorphic root dispatches on the discriminator.
      expect(v3, contains("case 'add_to_cart_intent':"));
      expect(
        v3,
        contains(
          "'String (one of: add_to_cart_intent, "
          "remove_from_cart_intent)'",
        ),
      );
      // Mock-first fixtures per intent root, seeded across every leaf.
      expect(v3, contains('class CartIntentMockData'));
      expect(v3, contains('class CartIntentWireFixtures'));
      expect(v3, contains('class AddToCartIntentMockData'));
      expect(v3, contains('class RemoveFromCartIntentWireFixtures'));
      // An intent-valued field on an entity decodes through the intent's
      // own boundary instead of travelling as a raw wire value.
      expect(v3, contains('CartIntent.fromWire('));
    });

    test("@ZorphyValue: the issue's \$Greeting repro generates", () {
      expect(v3, contains('final class Greeting implements ZorphyValueBase'));
      expect(v3, contains('const Greeting.fromTrusted({'));
      expect(v3, contains('Greeting copyWith({'));
    });

    test('boundary codec: fromWire/toWire on every non-intent hierarchy', () {
      expect(
        v3,
        contains('static ZorphyBoundaryResult<Notification> fromWire('),
      );
      expect(v3, contains('static ZorphyBoundaryResult<UiState> fromWire('));
      expect(
        v3,
        contains('static ZorphyBoundaryResult<AsyncStatus> fromWire('),
      );
      expect(v3, contains('static ZorphyBoundaryResult<Greeting> fromWire('));
      expect(v3, contains('Map<String, Object?> toWire()'));
    });

    test('mock fixtures: <Name>MockData per non-intent hierarchy', () {
      expect(v3, contains('class NotificationMockData'));
      expect(v3, contains('class UiStateMockData'));
      expect(v3, contains('class AsyncStatusMockData'));
      expect(v3, contains('class GreetingMockData'));
    });

    test('entity patches: root + shared + leaf surface samplePatch builds', () {
      // samplePatch() builds through <Name>Patch fluent builders, so the
      // composed library must carry the polymorphic patch surface.
      expect(v3, contains('sealed class NotificationPatch'));
      expect(
        v3,
        contains(
          'final class NotificationSharedPatch extends NotificationPatch',
        ),
      );
      expect(
        v3,
        contains(
          'final class OrderNotificationPatch extends NotificationPatch',
        ),
      );
      expect(v3, contains('OrderNotificationPatch withOrderId(String value)'));
      expect(v3, contains('OrderNotificationPatch withId(String value)'));
    });

    test(
      'a standalone entity gets a single ZorphyPatch-implementing patch',
      () {
        expect(
          v3,
          contains('final class Product implements ZorphyEntityBase<String>'),
        );
        expect(v3, contains('class ProductMockData'));
        expect(
          v3,
          contains('final class ProductPatch implements ZorphyPatch<Product>'),
        );
        expect(v3, contains('ProductPatch withName(String value)'));
        expect(v3, isNot(contains('ProductPatch extends')));
      },
    );

    test('a three-level hierarchy aliases the intermediate patch', () {
      expect(v3, contains('sealed class EventPatch'));
      expect(v3, contains('typedef SystemEventPatch = EventPatch;'));
      expect(v3, contains('final class DeployEventPatch extends EventPatch'));
    });

    test('legacy @Zorphy control still generates beside the v3 surface', () {
      expect(legacy, contains('class LegacyGreeting'));
    });

    test('the generated v3 part compiles standalone', () {
      final result = _analyzeEmitted(v3);
      expect(
        result.exitCode,
        0,
        reason: 'generated v3 part does not compile:\n${result.output}',
      );
    });
  });
}

/// Writes [emitted] into a throwaway package that depends on the real
/// `zorphy_annotation` and runs `dart analyze` on it — the same probe the
/// golden tests use, because a `contains(...)` assertion cannot see a type
/// error inside the generated code.
({int exitCode, String output}) _analyzeEmitted(String emitted) {
  // The shared part is a `part of` fragment; standalone analysis needs the
  // directive stripped and the annotation import the owning library provides.
  final body = emitted
      .split('\n')
      .where((line) => !line.startsWith('part of'))
      .join('\n');
  final annotationRoot = Directory.current.parent.uri
      .resolve('zorphy_annotation/')
      .toFilePath();
  final probeParent = Directory('test/.issue_223_compile_$pid')
    ..createSync(recursive: true);
  final probe = probeParent.createTempSync('issue_223_');
  addTearDown(() => probe.deleteSync(recursive: true));

  File('${probe.path}/pubspec.yaml').writeAsStringSync(
    'name: issue_223_probe\n'
    'environment:\n'
    '  sdk: ">=3.11.0 <4.0.0"\n'
    'dependencies:\n'
    '  zorphy_annotation:\n'
    '    path: $annotationRoot\n',
  );
  Directory('${probe.path}/lib').createSync();
  File('${probe.path}/lib/emitted.dart').writeAsStringSync(
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n$body",
  );

  final pubGet = Process.runSync('dart', [
    'pub',
    'get',
  ], workingDirectory: probe.path);
  if (pubGet.exitCode != 0) {
    return (
      exitCode: pubGet.exitCode,
      output: 'dart pub get failed:\n${pubGet.stdout}\n${pubGet.stderr}',
    );
  }
  final analyze = Process.runSync('dart', [
    'analyze',
    '--no-fatal-warnings',
    'lib/emitted.dart',
  ], workingDirectory: probe.path);
  return (
    exitCode: analyze.exitCode,
    output: '${analyze.stdout}\n${analyze.stderr}',
  );
}
