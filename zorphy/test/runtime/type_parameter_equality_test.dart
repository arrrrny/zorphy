// Runtime proof for #294: a field typed by a bare type parameter is opaque to
// the emitter's collection detection, so it used to fall through to a plain
// `==` — comparing a `Map`/`List`/`Set` payload by IDENTITY. Two values with
// equal payloads were therefore never `==`. The golden layer only pins the
// emitted source; this test compiles and EXECUTES the emitter's real output so
// `Box<Map>` equality/hashing is proven by content while a scalar `Box<int>`
// still compares by value.

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
  List<String> typeParameters = const [],
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
  typeParameters: typeParameters,
  fields: const [],
);

PolymorphicField _field(String name, String type) =>
    PolymorphicField(name: name, type: type);

void main() {
  test('a type-parameter field compares and hashes by content', () {
    // A plain `@ZorphyValue()` is a single concrete class: one node, no
    // sealed-root/child split (which would declare `Box` twice).
    final box = _node(
      className: r'$Box',
      typeParameters: const ['T'],
      principalKey: 'id',
    );
    final emitted = const PolymorphicClassEmitter().emit(
      root: box,
      fields: {
        r'$Box': [_field('payload', 'T'), _field('id', 'String')],
      },
    );

    final program =
        '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

$emitted

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void main() {
  // A Map payload: two separately-constructed but equal maps must compare
  // equal and hash equal, even though the Map instances are distinct.
  final a = Box<Map<String, dynamic>>.fromTrusted(
    payload: <String, dynamic>{'k': 1},
    id: 'x',
  );
  final b = Box<Map<String, dynamic>>.fromTrusted(
    payload: <String, dynamic>{'k': 1},
    id: 'x',
  );
  check(a == b, 'equal Map payloads must compare equal');
  check(a.hashCode == b.hashCode, 'equal Map payloads must hash equal');

  // A changed payload must compare unequal.
  final c = Box<Map<String, dynamic>>.fromTrusted(
    payload: <String, dynamic>{'k': 2},
    id: 'x',
  );
  check(a != c, 'different Map payloads must differ');

  // A scalar type-parameter payload still compares by value.
  final n1 = Box<int>.fromTrusted(payload: 7, id: 'y');
  final n2 = Box<int>.fromTrusted(payload: 7, id: 'y');
  final n3 = Box<int>.fromTrusted(payload: 8, id: 'y');
  check(n1 == n2, 'equal int payloads must compare equal');
  check(n1.hashCode == n2.hashCode, 'equal int payloads must hash equal');
  check(n1 != n3, 'different int payloads must differ');

  print('ALL TYPE-PARAMETER EQUALITY CHECKS PASSED');
}
''';

    // `dart run` resolves `package:` URIs from the nearest enclosing package
    // config, so the probe must live INSIDE the checkout's example package.
    final directory = Directory(
      'example/.dart_tool/zorphy_294_runtime',
    ).absolute..createSync(recursive: true);
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final file = File('${directory.path}/type_parameter_equality_program.dart')
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
      reason:
          'generated type-parameter-equality program failed:\n$output\n'
          '---program---\n$program',
    );
    expect(output, contains('ALL TYPE-PARAMETER EQUALITY CHECKS PASSED'));
  });
}
