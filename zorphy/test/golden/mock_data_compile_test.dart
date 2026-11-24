// Compile-level tests for ISSUE-015 (arrrrny/zorphy#190): `<Name>MockData`.
//
// The golden layer pins the emitted SHAPE and the runtime layer proves the
// emitted BEHAVIOUR, but neither can prove the output COMPILES against the
// shapes this repo actually generates. That gap is what the review of #214
// found: a node carrying a nested `$Entity`, an enum, a `List<$X>` or a
// `Map<String, $X>` field was seeded as though every type were a `String`, and
// the emitted class only failed once somebody compiled it.
//
// Every case here splices the emitter's REAL output into a throwaway package
// that depends on the real `zorphy_annotation`, then runs `dart analyze` on it —
// the same probe `entity_and_value_golden_test.dart` uses, because a
// `contains(...)` assertion cannot see an `argument_type_not_assignable`.

@Timeout(Duration(minutes: 10))
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emitters/mock_fixture_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

ZorphyNodeIr _node({
  required String className,
  ArchetypeKind archetype = ArchetypeKind.entity,
  bool isSealedRoot = false,
  List<ZorphyNodeIr> children = const [],
  List<ZorphyNodeIr> superTypes = const [],
  String? principalKey,
  List<ZorphyFieldIr> fields = const [],
  List<String> typeParameters = const [],
}) => ZorphyNodeIr(
  className: className,
  cleanName: className.replaceAll(r'$', ''),
  archetype: archetype,
  isSealedRoot: isSealedRoot,
  isAbstractIntermediate: superTypes.isNotEmpty && children.isNotEmpty,
  isConcreteLeaf: children.isEmpty,
  superTypes: superTypes,
  directSubTypes: children,
  allConcreteLeaves: const [],
  discriminatorKey: 'kind',
  discriminatorValue: className.replaceAll(r'$', '').toLowerCase(),
  principalKey: principalKey,
  replaySafe: archetype == ArchetypeKind.intent ? false : null,
  isSyntheticLeaf: false,
  fields: fields,
  typeParameters: typeParameters,
);

/// Writes [emitted] into a throwaway package, resolves it, and analyzes it.
///
/// The probe package lives INSIDE this checkout so `dart pub get` resolves
/// against the local `zorphy_annotation` — a throwaway directory outside every
/// package would have to fetch a published version the emitter was not built
/// against.
({int exitCode, String output}) _analyzeEmitted(String emitted) {
  final annotationRoot = Directory.current.parent.uri
      .resolve('zorphy_annotation/')
      .toFilePath();
  final probeParent = Directory('test/.mock_compile_$pid')
    ..createSync(recursive: true);
  final probe = probeParent.createTempSync('issue_190_');
  addTearDown(() => probe.deleteSync(recursive: true));

  File('${probe.path}/pubspec.yaml').writeAsStringSync(
    'name: mock_compile_probe\n'
    'environment:\n'
    '  sdk: ">=3.11.0 <4.0.0"\n'
    'dependencies:\n'
    '  zorphy_annotation:\n'
    '    path: $annotationRoot\n',
  );
  Directory('${probe.path}/lib').createSync();
  File('${probe.path}/lib/emitted.dart').writeAsStringSync(
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n"
    '$_fixtures\n'
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

/// The hand-shaped classes the emitted `MockData` needs to construct: the
/// `fromTrusted` constructors and the patch fluent builders ISSUE-003 and
/// ISSUE-007 emit, plus the nested `$Address` / `$Item` / `$Tag` entities and
/// the `OrderStatus` enum the review's `$Order` example carries.
///
/// The patches are plain classes rather than `PatchBase` subclasses on
/// purpose: this probe is about the MOCK emitter's argument types, and a real
/// `PatchBase` would drag its abstract surface into the diagnostic noise.
const _fixtures = r'''
sealed class Address {
  const Address();
  String get id;
}

final class AddressNode extends Address {
  const AddressNode.fromTrusted({required this.id});
  @override
  final String id;
}

enum OrderStatus { pending, paid }

final class Order {
  const Order.fromTrusted({
    required this.id,
    this.address,
    required this.status,
    required this.items,
    required this.tags,
  });

  final String id;
  final Address? address;
  final OrderStatus status;
  final List<Address> items;
  final Map<String, Address> tags;
}

class OrderPatch {
  final Map<String, Object?> changes = <String, Object?>{};
  OrderPatch withId(String value) {
    changes['id'] = value;
    return this;
  }

  OrderPatch withStatus(OrderStatus value) {
    changes['status'] = value;
    return this;
  }
}

final class Cfg {
  const Cfg.fromTrusted({
    required this.id,
    this.address,
    required this.scores,
  });

  final String id;
  final Address? address;
  final Map<int, int> scores;
}

class CfgPatch {
  final Map<String, Object?> changes = <String, Object?>{};
  CfgPatch withId(String value) {
    changes['id'] = value;
    return this;
  }

  CfgPatch withScores(Map<int, int> value) {
    changes['scores'] = value;
    return this;
  }
}

final class Qty {
  const Qty.fromTrusted({required this.count});
  final int count;
}

class QtyPatch {
  final Map<String, Object?> changes = <String, Object?>{};
  QtyPatch withCount(int value) {
    changes['count'] = value;
    return this;
  }
}
''';

void main() {
  group('ISSUE-015 MockFixtureEmitter — emitted source compiles', () {
    test('a node whose required field is unseedable throws, and compiles', () {
      // `status` is an enum, `items`/`tags` are collections of a nested
      // Zorphy entity. None can be seeded, and all three are required, so
      // `single()` must refuse at RUNTIME rather than emit a String into a
      // parameter that cannot take one. `address` is nullable, so it is
      // simply omitted and the class still emits.
      final emitted = MockFixtureEmitter().emitForNode(
        _node(
          className: r'$Order',
          isSealedRoot: true,
          principalKey: 'id',
          fields: const [
            ZorphyFieldIr(name: 'id', type: 'String'),
            ZorphyFieldIr(name: 'address', type: r'$Address', isNullable: true),
            ZorphyFieldIr(name: 'status', type: 'OrderStatus'),
            ZorphyFieldIr(name: r'items', type: r'List<$Item>'),
            ZorphyFieldIr(name: 'tags', type: r'Map<String, $Tag>'),
          ],
        ),
      );

      expect(
        emitted,
        contains('UnsupportedError'),
        reason: 'a required unseedable field refuses instead of fabricating',
      );
      expect(
        emitted,
        isNot(contains("'status-\${seed}'")),
        reason: 'an enum field must never be seeded as a String',
      );

      final result = _analyzeEmitted(emitted);
      expect(result.exitCode, 0, reason: result.output);
    });

    test('a nullable unseedable field is omitted and the source compiles', () {
      final emitted = MockFixtureEmitter().emitForNode(
        _node(
          className: r'$Cfg',
          isSealedRoot: true,
          principalKey: 'id',
          fields: const [
            ZorphyFieldIr(name: 'id', type: 'String'),
            ZorphyFieldIr(name: 'address', type: r'$Address', isNullable: true),
            ZorphyFieldIr(name: 'scores', type: 'Map<int, int>'),
          ],
        ),
      );

      expect(emitted, contains('Cfg.fromTrusted('));
      expect(
        emitted,
        isNot(contains('address:')),
        reason: 'an optional parameter is left off when there is no seed',
      );
      expect(
        emitted,
        isNot(contains("'scores'")),
        reason: 'a Map<int, int> must not be seeded with a String key',
      );

      final result = _analyzeEmitted(emitted);
      expect(result.exitCode, 0, reason: result.output);
    });

    test('a preset that does not fit the field type is not used', () {
      // `price` renders a `num`; putting it in an `int` parameter is an
      // analyzer error, so the hint falls through to the type default.
      final emitted = MockFixtureEmitter().emitForNode(
        _node(
          className: r'$Qty',
          isSealedRoot: true,
          principalKey: 'count',
          fields: const [ZorphyFieldIr(name: 'count', type: 'int')],
        ),
        mockSeeds: const {'count': ZorphyMock(preset: ZorphyMockPresets.price)},
      );

      expect(
        emitted,
        isNot(contains('19.99')),
        reason: 'a price preset cannot seed an int field',
      );

      final result = _analyzeEmitted(emitted);
      expect(result.exitCode, 0, reason: result.output);
    });

    test('a generic node emits nothing rather than an invalid class', () {
      final emitted = MockFixtureEmitter().emitForNode(
        _node(
          className: r'$Box',
          isSealedRoot: true,
          typeParameters: const ['T extends num'],
          fields: const [ZorphyFieldIr(name: 'value', type: 'T')],
        ),
      );

      expect(
        emitted,
        isEmpty,
        reason:
            'class Box<T>MockData and Box<T>.fromTrusted are not legal Dart',
      );
    });
  });

  group('ISSUE-015 MockFixtureEmitter — uuidSeed shape', () {
    final canonical = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('every field name and seed renders a canonical uuid', () {
      for (final slug in ['id', 'date', 'email', 'name', 'created-at', 'uid']) {
        for (final seed in [0, 1, 7, -3]) {
          final value = uuidSeed(slug, seed);
          expect(
            value,
            matches(canonical),
            reason: 'uuidSeed($slug, $seed) = $value',
          );
        }
      }
    });

    test('the shape is stable for the same inputs', () {
      expect(uuidSeed('id', 0), uuidSeed('id', 0));
      expect(uuidSeed('id', 0), isNot(uuidSeed('id', 1)));
    });
  });
}
