// Golden tests for ISSUE-009 (zorphy#184) — polymorphic patch emission.
//
// A polymorphic root (`abstract class $$Notification`) currently emits NO
// patch at all: `PatchClassGenerator` returns early for every sealed root, so a
// caller holding a heterogeneous `List<Notification>` cannot apply a shared
// field update (`markAllRead`) without downcasting.
//
// `PolymorphicPatchEmitter` closes that gap: `emitRoot` produces the sealed
// `<Root>Patch`, and `emitSubtypePatch` produces the concrete `<Subtype>Patch`
// that implements it while narrowing `apply` to its own entity.
//
// These tests lock the emitted surface.

import 'package:test/test.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';

import 'dart:io';

/// The `Notification` root's shared fields — the ones a polymorphic patch
/// mutates across every subtype.
List<NameTypeClassComment> rootFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('readAt', 'DateTime?', ''),
];

List<String> subtypes() => ['OrderNotification', 'PriceDropNotification'];

List<NameTypeClassComment> orderFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('readAt', 'DateTime?', ''),
  NameTypeClassComment('itemCount', 'int', ''),
];

List<NameTypeClassComment> priceDropFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('readAt', 'DateTime?', ''),
  NameTypeClassComment('newPrice', 'double', ''),
];

const _fixturePath = 'test/runtime/fixtures/notification.dart';

/// The fixture region between [start] and [end] markers, trimmed.
String _fixtureRegion(String start, String end) {
  final source = File(_fixturePath).readAsStringSync();
  final from = source.indexOf(start);
  final to = source.indexOf(end);
  expect(from, isNot(-1), reason: 'fixture must carry $start');
  expect(to, isNot(-1), reason: 'fixture must carry $end');
  return source.substring(from + start.length, to).trim();
}

void main() {
  group('ISSUE-009 PolymorphicPatchEmitter — sealed root patch', () {
    test('emits a sealed root patch class', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        contains('sealed class NotificationPatch'),
        reason: 'a polymorphic root must expose a sealed root patch',
      );
    });

    test('the root patch declares shared fields as PatchValue getters', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        contains('PatchValue<DateTime?> get readAt'),
        reason:
            'a shared nullable DateTime must keep its nullability in the '
            'PatchValue type, so null can be set deliberately',
      );
      expect(
        emitted,
        contains('PatchValue<String> get id'),
        reason: 'a shared non-nullable String must be a PatchValue getter',
      );
    });

    test('the root apply is covariant so subtypes may narrow it', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        contains('Notification apply(covariant Notification target)'),
        reason:
            'without covariant, a subtype patch cannot legally narrow apply '
            '(parameter types are contravariant in Dart)',
      );
    });

    test('the root patch is const-constructible', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        contains('const NotificationPatch()'),
        reason:
            'a const root is what the .shared(...) factory redirects to and '
            'what subtype patches extend',
      );
    });

    test('a root with no shared fields still emits a usable patch', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: const [],
        subtypeNames: subtypes(),
      );

      expect(emitted, contains('sealed class NotificationPatch'));
      expect(
        emitted,
        contains('return true;'),
        reason: 'a fieldless root patch is always empty',
      );
    });

    test('a root with no concrete subtypes is refused, not silently empty', () {
      expect(
        () => PolymorphicPatchEmitter().emitRoot(
          rootName: 'Lonely',
          fields: rootFields(),
          subtypeNames: const [],
        ),
        throwsA(isA<ArgumentError>()),
        reason:
            'a sealed root with no subtypes has nothing to dispatch to; '
            'emitting a patch that can never apply is a silent trap',
      );
    });

    test('the root emission matches the runtime fixture byte for byte', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );
      expect(
        emitted.trim(),
        _fixtureRegion('// GOLDEN-POLY-ROOT-START', '// GOLDEN-POLY-ROOT-END'),
        reason:
            'the runtime suite must exercise the real emitted root patch — '
            'regenerate $_fixturePath if the emission changed on purpose',
      );
    });
  });

  group('ISSUE-009 PolymorphicPatchEmitter — subtype narrowing', () {
    test('a concrete subtype patch extends the root patch interface', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );

      expect(
        emitted,
        contains('OrderNotificationPatch extends NotificationPatch'),
        reason:
            'OrderNotificationPatch must be assignable to NotificationPatch so '
            'a heterogeneous collection can be patched uniformly. It EXTENDS '
            'rather than implements: ZorphyPatch uses its type parameter in '
            'both parameter and return position, so ZorphyPatch<Order> and '
            'ZorphyPatch<Notification> cannot be implemented by one class',
      );
    });

    test('the subtype patch narrows apply to its own entity', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );

      expect(
        emitted,
        contains('OrderNotification apply(covariant OrderNotification target)'),
        reason:
            'subtype narrowing is the point: applying an OrderNotification '
            'patch must yield an OrderNotification, not a Notification',
      );
    });

    test('the subtype patch overrides the shared field getters', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );

      final overrides = 'override'.allMatches(emitted).length;
      expect(
        overrides,
        greaterThanOrEqualTo(3),
        reason:
            'isEmpty + apply + the two shared getters must each be an override',
      );
    });

    test('subtype fields never reach the root patch', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        isNot(contains('itemCount')),
        reason:
            'a subtype-only field has no meaning on the root; leaking it there '
            'would make the root patch unapplicable to sibling subtypes',
      );
    });

    test('the OrderNotification emission matches the runtime fixture', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );
      expect(
        emitted.trim(),
        _fixtureRegion(
          '// GOLDEN-POLY-ORDER-START',
          '// GOLDEN-POLY-ORDER-END',
        ),
        reason: 'regenerate $_fixturePath if the emission changed on purpose',
      );
    });

    test('the PriceDropNotification emission matches the runtime fixture', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'PriceDropNotification',
        rootName: 'Notification',
        fields: priceDropFields(),
        sharedFields: const ['id', 'readAt'],
      );
      expect(
        emitted.trim(),
        _fixtureRegion(
          '// GOLDEN-POLY-PRICE-START',
          '// GOLDEN-POLY-PRICE-END',
        ),
        reason: 'regenerate $_fixturePath if the emission changed on purpose',
      );
    });

    test('subtype patches carry the fluent builders samplePatch builds', () {
      // ISSUE-0223: MockFixtureEmitter.samplePatch() builds through
      // `with<Name>` builders, so every concrete patch carries them.
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );

      expect(emitted, contains('OrderNotificationPatch withId(String value)'));
      expect(
        emitted,
        contains('OrderNotificationPatch withItemCount(int value)'),
      );
      expect(
        emitted,
        contains('OrderNotificationPatch withReadAt(DateTime? value)'),
      );
      expect(
        emitted,
        contains('itemCount: PatchValue.set(value)'),
        reason: 'the builder sets its own field and carries the rest over',
      );
    });
  });

  group('ISSUE-0223 PolymorphicPatchEmitter — standalone entity patch', () {
    test('emits one concrete ZorphyPatch-implementing class', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Product',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('name', 'String', ''),
        ],
      );

      expect(
        emitted,
        contains('final class ProductPatch implements ZorphyPatch<Product>'),
      );
      expect(
        emitted,
        isNot(contains('extends')),
        reason: 'a standalone entity has no root patch to extend',
      );
      expect(emitted, contains('ProductPatch withName(String value)'));
      expect(emitted, contains('Product apply(covariant Product target)'));
      expect(
        emitted,
        contains('ProductPatch compose(ZorphyPatch<Product> next)'),
        reason:
            'the parameter stays the interface type so the kind guard is not '
            'dead code',
      );
    });

    test('the standalone emission compiles against the annotation library', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Product',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('name', 'String', ''),
        ],
      );
      final result = _analyzeEmitted(emitted, _standaloneFixture);
      expect(result.exitCode, 0, reason: result.output);
    });

    test('a field named value does not shadow the carried field', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Box',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('value', 'String', ''),
        ],
      );

      // `withId(String value)` must carry `value: this.value` — an
      // unqualified `value: value` picks up the builder's parameter instead
      // of the existing patch field and fails to compile.
      expect(emitted, contains('value: this.value'));
      expect(emitted, contains('id: this.id'));

      final result = _analyzeEmitted(emitted, _standaloneValueFixture);
      expect(result.exitCode, 0, reason: result.output);
    });
  });
}

/// The minimal entity surface a standalone patch applies to.
const _standaloneFixture = r'''
final class Product {
  const Product({required this.id, required this.name});

  final String id;
  final String name;

  Product copyWith({String? id, String? name}) {
    return Product(id: id ?? this.id, name: name ?? this.name);
  }
}
''';

/// Standalone entity carrying a field literally named `value` — the name
/// collides with the `with*` builders' own parameter.
const _standaloneValueFixture = r'''
final class Box {
  const Box({required this.id, required this.value});

  final String id;
  final String value;

  Box copyWith({String? id, String? value}) {
    return Box(id: id ?? this.id, value: value ?? this.value);
  }
}
''';

/// Analyzes [emitted] spliced after [fixture] in a throwaway package that
/// depends on the real `zorphy_annotation` — the same probe the mock-data
/// compile suite uses, because a `contains(...)` assertion cannot see a type
/// error inside the generated code.
({int exitCode, String output}) _analyzeEmitted(
  String emitted,
  String fixture,
) {
  final annotationRoot = Directory.current.parent.uri
      .resolve('zorphy_annotation/')
      .toFilePath();
  final probeParent = Directory('test/.poly_patch_compile_$pid')
    ..createSync(recursive: true);
  final probe = probeParent.createTempSync('issue_223_');
  addTearDown(() => probe.deleteSync(recursive: true));

  File('${probe.path}/pubspec.yaml').writeAsStringSync(
    'name: poly_patch_probe\n'
    'environment:\n'
    '  sdk: ">=3.11.0 <4.0.0"\n'
    'dependencies:\n'
    '  zorphy_annotation:\n'
    '    path: $annotationRoot\n',
  );
  Directory('${probe.path}/lib').createSync();
  File('${probe.path}/lib/emitted.dart').writeAsStringSync(
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n"
    '$fixture\n'
    '$emitted',
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
