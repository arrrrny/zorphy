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
//   - defensive snapshot of collection fields in `fromTrusted` (#284);
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

/// Writes [emitted] into a throwaway package that depends on the real
/// `zorphy_annotation`, then runs `dart analyze` on it.
///
/// A `contains(...)` assertion cannot prove the output BUILDS — the emitter's
/// real defects (an undefined `_sentinel`, a one-argument `Object.hash`) were
/// all invisible to text checks. This is the probe that catches them.
({int exitCode, String output}) _analyzeEmitted(String emitted) {
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
      // that every `contains(...)` above happily passed. `_analyzeEmitted`
      // writes the library into a throwaway package that depends on the real
      // `zorphy_annotation`, then analyzes it.
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

      final result = _analyzeEmitted(emitted);
      expect(
        result.exitCode,
        0,
        reason: 'emitted source does not analyze:\n${result.output}',
      );
    });
  });

  group('defensive cloning of collection fields', () {
    test('fromTrusted snapshots collection fields (#284)', () {
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

      // A collection field is copied at construction so a caller that mutates
      // the list it passed cannot change an already-built value (#284). The
      // copy is a `List.of`, and the constructor is no longer const.
      expect(source, contains('List<String>.of(items)'));
      expect(source, isNot(contains('const OrderCart.fromTrusted')));
    });
  });

  group('@ZorphyEntity — standalone root (sealed + concrete leaf)', () {
    test('a root that is also a concrete leaf still emits the principalKey '
        'getter', () {
      // A hierarchy with a single, instantiable root: the node is BOTH the
      // sealed root and a concrete leaf, so it takes the leaf branch. The
      // principalKey getter must still be emitted for every sealed entity
      // root, not only the non-leaf branch.
      final root = _node(
        className: r'$Counter',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Counter': [_field('id', 'int'), _field('value', 'int')],
        },
      );

      expect(source, contains('int get principalKey => id;'));
      expect('principalKey'.allMatches(source), hasLength(1));
    });
  });

  group('non-entity archetypes implement their own base', () {
    test('@ZorphyState implements ZorphyStateBase, not ZorphyValueBase', () {
      final leaf = _node(className: r'$Idle', archetype: ArchetypeKind.state);
      final root = _node(
        className: r'$UiState',
        archetype: ArchetypeKind.state,
        isSealedRoot: true,
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$UiState': [_field('status', 'String')],
          r'$Idle': [_field('status', 'String')],
        },
      );

      expect(
        source,
        contains('sealed class UiState implements ZorphyStateBase'),
      );
      expect(source, contains('implements ZorphyStateBase'));
      expect(source, isNot(contains('ZorphyValueBase')));
    });

    test('@ZorphyIntent implements ZorphyIntentBase', () {
      final leaf = _node(className: r'$Save', archetype: ArchetypeKind.intent);
      final root = _node(
        className: r'$Command',
        archetype: ArchetypeKind.intent,
        isSealedRoot: true,
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Command': [_field('at', 'DateTime')],
          r'$Save': [_field('at', 'DateTime')],
        },
      );

      expect(source, contains('ZorphyIntentBase'));
      expect(source, isNot(contains('ZorphyValueBase')));
    });
  });

  group('principal key type through the full ancestor chain', () {
    test('a leaf two levels down inherits the ROOT key type, not String', () {
      // Root declares `id: int`; the intermediate and leaf declare OTHER
      // fields and no `id` of their own. The resolver stamps each node's
      // `root` with its IMMEDIATE parent, so the leaf must resolve `int`
      // through `superTypes` — a `node.root`-only lookup reaches the
      // intermediate (no `id`) and falls back to String.
      final leaf = _node(
        className: r'$Order',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final middle = _node(
        className: r'$Base',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
        children: [leaf],
      );
      final root = _node(
        className: r'$Record',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [middle],
      );

      final irLeaf = leaf.copyWith(superTypes: [middle, root], root: middle);
      final irMiddle = middle.copyWith(superTypes: [root], root: root);
      final tree = root.copyWith(
        directSubTypes: [
          irMiddle.copyWith(directSubTypes: [irLeaf]),
        ],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: tree,
        fields: {
          r'$Record': [_field('id', 'int')],
          r'$Base': [_field('to', 'String')],
          r'$Order': [_field('subject', 'String')],
        },
      );

      expect(source, isNot(contains('ZorphyEntityBase<String>')));
      expect('ZorphyEntityBase<int>'.allMatches(source), hasLength(3));
    });
  });

  group('field-count-independent hashing', () {
    test(
      'a single-field leaf uses Object.hashAll, not the two-arg Object.hash',
      () {
        final leaf = _node(className: r'$Dot', archetype: ArchetypeKind.value);
        final root = _node(
          className: r'$Shape',
          archetype: ArchetypeKind.value,
          isSealedRoot: true,
          children: [leaf],
        );

        final source = const PolymorphicClassEmitter().emit(
          root: root,
          fields: {
            // The root is a marker (no fields), so the leaf's payload is the
            // single field `radius` — the shape that broke `Object.hash`.
            r'$Shape': <PolymorphicField>[],
            r'$Dot': [_field('radius', 'double')],
          },
        );

        expect(source, contains('Object.hashAll([radius])'));
        expect(source, isNot(contains('Object.hash(')));
      },
    );
  });

  group('emitNode is self-contained', () {
    test('its output declares the sentinel and compiles on its own', () {
      // `emitNode` advertises itself for a caller that owns the traversal, so
      // its output must compile in isolation — a nullable field references
      // `_sentinel`, which the fragment now declares alongside its private
      // type.
      final node = _node(
        className: r'$Profile',
        archetype: ArchetypeKind.value,
      );
      final source = const PolymorphicClassEmitter().emitNode(
        node: node,
        fields: [_field('nickname', 'String', nullable: true)],
      );

      expect(source, contains('_ZorphyCopyWithSentinel'));
      expect(source, contains('identical(nickname, _sentinel)'));

      final result = _analyzeEmitted(source);
      expect(
        result.exitCode,
        0,
        reason: 'emitNode output does not analyze:\n${result.output}',
      );
    });
  });

  group('copyWith — nullable cast lowering', () {
    test(r'a nullable $-prefixed field casts to the lowered type', () {
      // The field is declared `$Address?` but the generated constructor
      // parameter and field are `Address?`; the copyWith replacement cast must
      // be lowered too, or the emitted method does not compile.
      final leaf = _node(
        className: r'$Order',
        archetype: ArchetypeKind.entity,
        principalKey: 'id',
      );
      final root = _node(
        className: r'$Receipt',
        archetype: ArchetypeKind.entity,
        isSealedRoot: true,
        principalKey: 'id',
        children: [leaf],
      );

      final source = const PolymorphicClassEmitter().emit(
        root: root,
        fields: {
          r'$Receipt': [_field('id', 'String')],
          r'$Order': [
            _field('id', 'String'),
            _field('address', r'$Address', nullable: true),
          ],
        },
      );

      expect(source, contains('address as Address?'));
      expect(source, isNot(contains(r'as $Address')));
    });
  });
}
