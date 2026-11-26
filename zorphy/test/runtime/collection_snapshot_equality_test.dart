// Runtime proof for the #285 review fix: a snapshotted collection field gets a
// fresh instance on every value, so the generated `==`/`hashCode` must compare
// and hash CONTENTS. The golden layer only pins the emitted source; this test
// compiles and EXECUTES the emitter's real output so `value == value.copyWith()`
// and `cart != cart.copyWith(items: ['b'])` are proven, not asserted by shape.

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emission/polymorphic_class_emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

ZorphyNodeIr _node({
  required String className,
  bool isSealedRoot = false,
  List<ZorphyNodeIr> children = const [],
  required String? principalKey,
}) => ZorphyNodeIr(
  className: className,
  cleanName: className.replaceAll(r'$', ''),
  archetype: ArchetypeKind.entity,
  isSealedRoot: isSealedRoot,
  isAbstractIntermediate: false,
  isConcreteLeaf: children.isEmpty,
  superTypes: const [],
  directSubTypes: children,
  allConcreteLeaves: const [],
  discriminatorKey: 'kind',
  discriminatorValue: className.replaceAll(r'$', ''),
  principalKey: principalKey,
  fields: const [],
);

PolymorphicField _field(String name, String type) =>
    PolymorphicField(name: name, type: type);

void main() {
  test('snapshotted collections compare and hash by content', () {
    final leaf = _node(
      className: r'$OrderCart',
      principalKey: 'id',
    );
    final root = _node(
      className: r'$Cart',
      isSealedRoot: true,
      children: [leaf],
      principalKey: 'id',
    );
    final emitted = const PolymorphicClassEmitter().emit(
      root: root,
      fields: {
        r'$Cart': [_field('id', 'String')],
        r'$OrderCart': [
          _field('id', 'String'),
          _field('items', 'List<String>'),
          _field('scores', 'Map<String, int>'),
          _field('tags', 'Set<String>'),
        ],
      },
    );

    final program = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

$emitted

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  final items = <String>['a'];
  final scores = <String, int>{'x': 1};
  final tags = <String>{'t'};
  final cart = OrderCart.fromTrusted(
    id: 'c1', items: items, scores: scores, tags: tags,
  );

  // The snapshot itself still works: mutating the caller's collection cannot
  // change an already-built value.
  items.add('mutated');
  scores['y'] = 2;
  tags.add('mutated');
  check(cart.items.length == 1, 'list was not snapshotted');
  check(cart.scores.length == 1, 'map was not snapshotted');
  check(cart.tags.length == 1, 'set was not snapshotted');

  // An unchanged copy has different collection INSTANCES but must still be
  // equal and hash equal.
  final copy = cart.copyWith();
  check(cart == copy, 'unchanged copy must compare equal');
  check(cart.hashCode == copy.hashCode, 'equal values must hash equal');

  // Changed contents must compare unequal.
  check(cart != cart.copyWith(items: const ['b']), 'changed list must differ');
  check(cart != cart.copyWith(scores: const {'x': 2}), 'changed map must differ');
  check(cart != cart.copyWith(tags: const {'z'}), 'changed set must differ');

  print('ALL COLLECTION EQUALITY CHECKS PASSED');
}
''';

    // `dart run` resolves `package:` URIs from the nearest enclosing package
    // config, so the probe must live INSIDE the checkout's example package.
    final directory = Directory(
      'example/.dart_tool/zorphy_285_runtime',
    ).absolute..createSync(recursive: true);
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final file = File('${directory.path}/collection_equality_program.dart')
      ..writeAsStringSync(program);

    final result = Process.runSync(
      Platform.resolvedExecutable,
      ['run', file.path],
      workingDirectory: 'example',
      stdoutEncoding: const SystemEncoding(),
      stderrEncoding: const SystemEncoding(),
    );
    final output = '${result.stdout}\n${result.stderr}';
    expect(
      result.exitCode,
      0,
      reason: 'generated collection-equality program failed:\n$output\n'
          '---program---\n$program',
    );
    expect(output, contains('ALL COLLECTION EQUALITY CHECKS PASSED'));
  });
}
