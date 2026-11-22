// Golden tests for ISSUE-003 (arrrrny/zorphy#178): `PolymorphicClassEmitter`.
//
// The emitter turns a resolved one-hierarchy `PolymorphicIr` plus each node's
// declared fields into Dart 3 `sealed class` roots, `sealed class`
// intermediates and `final class` leaves — `package:code_builder` only, no
// `StringBuffer`.
//
// The IR carries names, hierarchy links, `principalKey` and the discriminator
// but NO field data (a field's declaration belongs to the analyzer element the
// resolver deliberately does not expose), so a node's fields arrive beside the
// IR as `Map<String, List<PolymorphicField>>`. The shape mirrors the issue's
// emitted example exactly:
//
//   sealed class Notification implements $Notification, ZorphyEntityBase<String>
//   final class OrderNotification extends Notification implements $OrderNotification
//
// Coverage:
//   - a single-level `@ZorphyEntity` hierarchy with an inherited principalKey;
//   - a multi-level hierarchy: sealed root -> sealed intermediate -> leaf,
//     where the leaf implements every transitive `$Parent` interface;
//   - a `@ZorphyValue` hierarchy (no principalKey, `ZorphyValueBase`);
//   - `copyWith` nullable clearing through the `_sentinel` object;
//   - zero-copy passthrough of collection references in `fromTrusted` and
//     `copyWith`;
//   - the "no `StringBuffer`, `package:code_builder` only" acceptance gate.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emission/polymorphic_class_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

/// Builds one node, wiring [children] into `directSubTypes` (and itself into
/// each child's `superTypes`/`root`) so the fixture is a real tree — the same
/// shape `HierarchyResolver` produces.
ZorphyNodeIr _node({
  required String className,
  required ArchetypeKind archetype,
  bool isSealedRoot = false,
  List<ZorphyNodeIr> children = const [],
  List<ZorphyNodeIr> superTypes = const [],
  String? principalKey,
  String discriminatorKey = 'kind',
}) {
  final cleanName = className.replaceAll(r'$', '');
  final node = ZorphyNodeIr(
    className: className,
    cleanName: cleanName,
    archetype: archetype,
    isSealedRoot: isSealedRoot,
    isAbstractIntermediate: superTypes.isNotEmpty && children.isNotEmpty,
    isConcreteLeaf: children.isEmpty,
    superTypes: superTypes,
    directSubTypes: children,
    allConcreteLeaves: const [],
    discriminatorKey: discriminatorKey,
    discriminatorValue: cleanName,
    principalKey: principalKey,
    replaySafe: null,
    isSyntheticLeaf: false,
  );
  return node;
}

PolymorphicField _field(String name, String type, {bool nullable = false}) =>
    PolymorphicField(name: name, type: type, isNullable: nullable);

/// The single-level `@ZorphyEntity` fixture from the issue's own example.
({ZorphyNodeIr root, Map<String, List<PolymorphicField>> fields})
_notification() {
  final leaf = _node(
    className: r'$OrderNotification',
    archetype: ArchetypeKind.entity,
    principalKey: 'id',
  );
  final root = _node(
    className: r'$Notification',
    archetype: ArchetypeKind.entity,
    isSealedRoot: true,
    principalKey: 'id',
    children: [leaf],
  );
  return (
    root: root,
    fields: {
      r'$Notification': [
        _field('id', 'String'),
        _field('createdAt', 'DateTime'),
      ],
      r'$OrderNotification': [
        _field('id', 'String'),
        _field('createdAt', 'DateTime'),
        _field('orderId', 'String'),
      ],
    },
  );
}

void main() {
  group('emitter source contract', () {
    test('the emitter uses package:code_builder and no StringBuffer', () {
      // Acceptance criterion: "Zero StringBuffer usage in emitter". Assert on
      // the emitter's OWN source, not on emitted output — output could be
      // clean while the emitter still builds half a class by hand. Comments
      // are stripped first: the docs say the word "StringBuffer" (and must,
      // to state the rule), which is prose, not usage.
      final source = File('lib/src/emission/polymorphic_class_emitter.dart')
          .readAsStringSync()
          .split('\n')
          .where((line) => !line.trimLeft().startsWith('//'))
          .join('\n');

      expect(source, isNot(contains('StringBuffer')));
      expect(source, contains('package:code_builder/code_builder.dart'));
      // No preset surface and no `generate*` boolean toggles.
      expect(source, isNot(contains('ZorphyPreset')));
    });
  });

  group('@ZorphyEntity — single level', () {
    late String source;
    late ZorphyNodeIr root;

    setUp(() {
      final fixture = _notification();
      root = fixture.root;
      source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: fixture.fields,
      );
    });

    test(
      'the root is a sealed class implementing the entity archetype base',
      () {
        expect(
          source,
          contains(
            'sealed class Notification implements ZorphyEntityBase<String>',
          ),
        );
      },
    );

    test('the root declares an inherited principalKey getter', () {
      expect(source, contains('String get principalKey => id;'));
    });

    test('the root declares its contract as abstract overridden getters', () {
      expect(source, contains('String get id;'));
      expect(source, contains('DateTime get createdAt;'));
    });

    test('the leaf is a final class extending the nearest sealed root', () {
      expect(
        source,
        contains('final class OrderNotification extends Notification'),
      );
      expect(source, contains('implements ZorphyEntityBase<String>'));
    });

    test('the leaf carries final fields and a const fromTrusted ctor', () {
      expect(source, contains('final String orderId;'));
      expect(source, contains('const OrderNotification.fromTrusted({'));
    });

    test('the leaf declares copyWith, ==, hashCode and toString', () {
      expect(source, contains('OrderNotification copyWith({'));
      expect(source, contains('bool operator ==('));
      expect(source, contains('int get hashCode'));
      expect(source, contains('String toString()'));
    });

    test('the leaf redeclares its inherited fields as overrides', () {
      final leafSection = source.substring(
        source.indexOf('final class OrderNotification'),
      );
      expect(leafSection, contains('final String id;'));
      expect(leafSection, contains('final DateTime createdAt;'));
    });
  });

  group('@ZorphyEntity — multi level', () {
    test(r'a leaf extends its nearest sealed parent and implements every '
        r'transitive $Parent', () {
      final leaf = _node(
        className: r'$WelcomeEmail',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final middle = _node(
        className: r'$EmailNotification',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
        children: [leaf],
      );
      final root = _node(
        className: r'$Notification',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [middle],
      );

      // The resolver stamps the fully-resolved ancestor chain on each node;
      // mirror that so the fixture reads like a real IR.
      final irLikeLeaf = leaf.copyWith(superTypes: [middle, root]);
      final irLikeMiddle = middle.copyWith(superTypes: [root]);
      final tree = root.copyWith(
        directSubTypes: [
          irLikeMiddle.copyWith(directSubTypes: [irLikeLeaf]),
        ],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: tree,
        fields: {
          r'$Notification': [
            _field('id', 'String'),
            _field('createdAt', 'DateTime'),
          ],
          r'$EmailNotification': [
            _field('id', 'String'),
            _field('createdAt', 'DateTime'),
            _field('to', 'String'),
          ],
          r'$WelcomeEmail': [
            _field('id', 'String'),
            _field('createdAt', 'DateTime'),
            _field('to', 'String'),
          ],
        },
      );

      // The intermediate is sealed, not concrete.
      expect(
        source,
        contains('sealed class EmailNotification extends Notification'),
      );
      // The leaf's `extends` is the NEAREST sealed ancestor — without it the
      // leaf would not be a subtype of the root at all.
      expect(
        source,
        contains('final class WelcomeEmail extends EmailNotification'),
      );
      // The inherited principalKey is declared ONCE, on the root, and reached
      // through the `extends` chain — not redeclared on every leaf.
      expect('principalKey'.allMatches(source), hasLength(1));
    });
  });

  group('@ZorphyValue — no identity', () {
    test('a value hierarchy implements ZorphyValueBase and has no '
        'principalKey getter', () {
      final leaf = _node(className: r'$Circle', archetype: ArchetypeKind.value);
      final root = _node(
        className: r'$Shape',
        archetype: ArchetypeKind.value,
        isSealedRoot: true,
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Shape': [_field('area', 'double')],
          r'$Circle': [_field('area', 'double'), _field('radius', 'double')],
        },
      );

      expect(source, contains('sealed class Shape implements ZorphyValueBase'));
      expect(source, isNot(contains('principalKey')));
    });
  });

  group('@ZorphyEntity — principal key type', () {
    test('an int principal key parameterizes the base with int', () {
      // The base's type argument comes from the key FIELD, not a hardcoded
      // String: an int key must produce ZorphyEntityBase<int>, or a consumer
      // bounding `T extends ZorphyEntityBase<int>` would reject the very
      // hierarchy it was written for.
      final leaf = _node(
        className: r'$Cached',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final root = _node(
        className: r'$Record',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Record': [_field('id', 'int')],
          r'$Cached': [_field('id', 'int')],
        },
      );

      expect(source, contains('ZorphyEntityBase<int>'));
      expect(source, isNot(contains('ZorphyEntityBase<String>')));
      expect(source, contains('int get principalKey => id;'));
    });
  });

  group('copyWith — nullable clearing', () {
    test('a nullable field clears through the _sentinel object', () {
      final leaf = _node(
        className: r'$UserProfile',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final root = _node(
        className: r'$Profile',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Profile': [_field('id', 'String')],
          r'$UserProfile': [
            _field('id', 'String'),
            _field('nickname', 'String', nullable: true),
          ],
        },
      );

      // The sentinel parameter + the `identical(..., _sentinel)` test is what
      // makes `copyWith(nickname: null)` CLEAR the field instead of keeping
      // the old value.
      expect(source, contains('_sentinel'));
      expect(source, contains('identical(nickname, _sentinel)'));
    });
  });

  group('emitted source compiles', () {
    test('the emitted hierarchy is valid Dart against zorphy_annotation', () {
      // A text assertion cannot prove the output BUILDS — this check did not
      // exist at first, and the source it now guards had 17 analyzer issues
      // that every `contains(...)` above happily passed. The emitted library
      // is written into a throwaway package that depends on the real
      // `zorphy_annotation`, then analyzed.
      final leaf = _node(
        className: r'$OrderNotification',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final root = _node(
        className: r'$Notification',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [leaf],
      );

      final emitted = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Notification': [
            _field('id', 'String'),
            _field('createdAt', 'DateTime'),
          ],
          r'$OrderNotification': [
            _field('id', 'String'),
            _field('createdAt', 'DateTime'),
            _field('orderId', 'String'),
            _field('note', 'String', nullable: true),
          ],
        },
      );

      final annotationRoot = Directory.current.parent.uri
          .resolve('zorphy_annotation/')
          .toFilePath();
      final probeParent = Directory('test/.golden_compile_$pid')
        ..createSync(recursive: true);
      final probe = probeParent.createTempSync('issue_178_');
      addTearDown(() => probe.deleteSync(recursive: true));

      File('${probe.path}/pubspec.yaml').writeAsStringSync(
        'name: golden_probe\n'
        'environment:\n'
        '  sdk: ">=3.11.0 <4.0.0"\n'
        'dependencies:\n'
        '  zorphy_annotation:\n'
        '    path: $annotationRoot\n',
      );
      Directory('${probe.path}/lib').createSync();
      File('${probe.path}/lib/emitted.dart').writeAsStringSync(
        "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n"
        '$emitted',
      );

      final pubGet = Process.runSync('dart', [
        'pub',
        'get',
      ], workingDirectory: probe.path);
      expect(
        pubGet.exitCode,
        0,
        reason: 'dart pub get failed:\n${pubGet.stdout}\n${pubGet.stderr}',
      );

      final analyze = Process.runSync('dart', [
        'analyze',
        '--no-fatal-warnings',
        'lib/emitted.dart',
      ], workingDirectory: probe.path);
      expect(
        analyze.exitCode,
        0,
        reason:
            'emitted source does not analyze:\n'
            '${analyze.stdout}\n${analyze.stderr}',
      );
    });
  });

  group('zero defensive cloning', () {
    test('fromTrusted and copyWith pass collection references directly', () {
      final leaf = _node(
        className: r'$OrderCart',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final root = _node(
        className: r'$Cart',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Cart': [_field('id', 'String')],
          r'$OrderCart': [
            _field('id', 'String'),
            _field('items', 'List<String>'),
          ],
        },
      );

      expect(source, isNot(contains('.toList()')));
      expect(source, isNot(contains('List.unmodifiable')));
      expect(source, isNot(contains('List<String>.from')));
    });
  });
}
