// E2E for issue #251 (ZRP-003): the v3 production builder must emit a
// reflection-free `ZorphyEntityDescriptor<T>` (`<Entity>.descriptor`) for every
// emittable `@ZorphyEntity`, and a generic algorithm operating SOLELY on the
// descriptor must round-trip an entity it never names concretely — under AOT,
// with zero reflection.
//
// Before #251 `ArchetypeComposer` composed class shapes, codecs, patches, lenses
// and pointers only, so a generic container (`ZfaStore`, `ZfaDocument<T>`) had
// no seam to reach an entity's principal key, fields, diff, patch or wire codec
// without a `runtimeType` switch — impossible under AOT, which has no
// `dart:mirrors`.
//
// The source under test is the REAL build_runner output: `dart run build_runner
// build` inside example/ (CI runs it before this test, exactly as the #230 e2e
// does) writes the shared part this file reads. The part is a `part of`
// fragment, so the `part of` directive is stripped and the annotation import
// prepended to make a standalone library.
//
// Execution runs under `dart compile exe` (AOT), so the descriptor is exercised
// as a compiled program — the issue's reflection-free / AOT acceptance.

@Timeout(Duration(minutes: 8))
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final v3Part = File('example/lib/_br_/v3_archetypes/v3_archetypes.part.dart');

  late String body;

  setUpAll(() {
    if (!v3Part.existsSync()) {
      fail(
        'Missing generated file: ${v3Part.path}\n'
        'Run: cd example && dart run build_runner build',
      );
    }
    body = v3Part
        .readAsStringSync()
        .split('\n')
        .where((line) => !line.startsWith('part of'))
        .join('\n');
  });

  test('every emittable entity root carries a descriptor registry field', () {
    // A standalone entity (Product) and sealed hierarchy roots (Notification,
    // Event, Task) each expose the static `descriptor`. A hierarchy LEAF does
    // not — its patch is typed to the root, so only the root is the generic
    // seam — and neither does an abstract intermediate (SystemEvent), whose
    // patch is a typedef with no reachable static `diff`.
    for (final className in const [
      'Product',
      'Notification',
      'Event',
      'Task',
    ]) {
      expect(
        body,
        contains('static const ZorphyEntityDescriptor<$className> descriptor'),
        reason: '$className must expose a descriptor registry field',
      );
    }
    for (final className in const [
      'OrderNotification',
      'DeployEvent',
      'OpenTask',
      'DoneTask',
      'SystemEvent',
    ]) {
      expect(
        body,
        isNot(
          contains(
            'static const ZorphyEntityDescriptor<$className> descriptor',
          ),
        ),
        reason: '$className is a leaf/intermediate, not a generic seam root',
      );
    }
  });

  test(
    'a generic algorithm over ZorphyEntityDescriptor<T> round-trips under AOT',
    () {
      final probeParent = Directory('test/.issue_251_$pid')
        ..createSync(recursive: true);
      final probe = probeParent.createTempSync('issue_251_').absolute;
      addTearDown(() => probe.deleteSync(recursive: true));

      final annotationRoot = Directory.current.parent.uri
          .resolve('zorphy_annotation/')
          .toFilePath();

      File('${probe.path}/pubspec.yaml').writeAsStringSync(
        'name: issue_251_probe\n'
        'environment:\n'
        '  sdk: ">=3.11.0 <4.0.0"\n'
        'dependencies:\n'
        '  zorphy_annotation:\n'
        '    path: $annotationRoot\n',
      );
      Directory('${probe.path}/lib').createSync();
      Directory('${probe.path}/bin').createSync();
      File('${probe.path}/lib/generated.dart').writeAsStringSync(
        "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n$body",
      );
      File('${probe.path}/bin/main.dart').writeAsStringSync(_mainSource);

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
        'lib/generated.dart',
      ], workingDirectory: probe.path);
      expect(
        analyze.exitCode,
        0,
        reason:
            'generated part does not compile:\n'
            '${analyze.stdout}\n${analyze.stderr}',
      );

      final compiled = Process.runSync('dart', [
        'compile',
        'exe',
        'bin/main.dart',
        '-o',
        'main',
      ], workingDirectory: probe.path);
      expect(
        compiled.exitCode,
        0,
        reason:
            'dart compile exe failed:\n'
            '${compiled.stdout}\n${compiled.stderr}',
      );

      final run = Process.runSync(
        '${probe.path}/main',
        const [],
        workingDirectory: probe.path,
      );
      expect(
        run.exitCode,
        0,
        reason:
            'generated descriptor failed at runtime:\n'
            '${run.stdout}\n${run.stderr}',
      );
      expect(run.stdout.toString(), contains('ALL CHECKS PASSED'));
    },
  );
}

/// The executed program: a single generic helper that operates ONLY on
/// `ZorphyEntityDescriptor<T>` and verifies `principalKeyOf`, `diff`,
/// `applyPatch`, `conflictingPaths`, `composePatches`, `fieldByPath`, `toWire`
/// and `fromWire` — over two different entity types, with no `runtimeType`
/// switch and no reflective access.
const _mainSource = r'''
import 'dart:io';

import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:issue_251_probe/generated.dart';

void _check(bool condition, String label) {
  if (!condition) throw StateError('FAILED: $label');
}

/// The issue's mandated generic helper — reflection-free, AOT-safe, names no
/// concrete entity type. It exercises every descriptor member for any entity.
void roundTripGeneric<T extends ZorphyEntityBase>(
  ZorphyEntityDescriptor<T> desc,
  T a,
  T b,
) {
  final label = desc.typeName;

  // typeName is the entity's clean name.
  _check(desc.typeName.isNotEmpty, '$label typeName non-empty');

  // principalKeyOf agrees with the principal-key field's own extractor.
  final pkField = desc.principalKeyField;
  _check(
    desc.principalKeyOf(a) == pkField.getValue!(a),
    '$label principalKeyOf matches principalKeyField',
  );

  // fields lists the principal key, and fieldByPath resolves it by pointer and
  // by bare name, and misses cleanly.
  _check(
    desc.fields.any((f) => f.name == pkField.name),
    '$label fields carries the principal key',
  );
  _check(
    desc.fieldByPath('/${pkField.name}')?.name == pkField.name,
    '$label fieldByPath /pointer',
  );
  _check(
    desc.fieldByPath(pkField.name)?.name == pkField.name,
    '$label fieldByPath bare name',
  );
  _check(desc.fieldByPath('/__nope__') == null, '$label fieldByPath miss');

  // diff + applyPatch: applying diff(a, b) to a reproduces b.
  final patch = desc.diff(a, b);
  _check(desc.applyPatch(a, patch) == b, '$label applyPatch(diff(a,b), a)==b');

  // toWire + fromWire round-trip b through the trust boundary.
  final wire = desc.toWire(b);
  final decoded = desc.fromWire(wire);
  _check(decoded.isOk, '$label fromWire(toWire(b)) is Ok');
  _check(decoded.valueOrNull == b, '$label fromWire(toWire(b))==b');

  // conflictingPaths: a patch conflicts with itself on every path it changes.
  final conflicts = desc.conflictingPaths(patch, patch);
  _check(conflicts.isNotEmpty, '$label conflictingPaths self non-empty');
  _check(
    conflicts.every((p) => p.startsWith('/')),
    '$label conflictingPaths are JSON pointers',
  );

  // composePatches: composing with an empty (no-op) patch behaves like the
  // original — the identity law the three-way name relies on.
  final empty = desc.diff(b, b);
  final composed = desc.composePatches(patch, empty);
  _check(
    desc.applyPatch(a, composed) == b,
    '$label composePatches(patch, empty)==patch',
  );
}

void main() {
  // Two distinct root shapes: a flat standalone entity and a sealed hierarchy
  // root — so the generic helper is proved over more than one payload shape. A
  // hierarchy is stored by its ROOT type, so the Notification descriptor is
  // exercised with OrderNotification leaves (which ARE Notifications). The
  // changed field is a SHARED root field (title): the generated root patch
  // diffs the shared payload, which is the root descriptor's contract. Scalar
  // fields keep the round-trip `==` honest (the generated `==` compares
  // collection fields by identity, orthogonal to the descriptor).
  roundTripGeneric<Product>(
    Product.descriptor,
    const Product.fromTrusted(id: 'p1', name: 'Widget'),
    const Product.fromTrusted(id: 'p1', name: 'Gadget'),
  );

  roundTripGeneric<Notification>(
    Notification.descriptor,
    const OrderNotification.fromTrusted(
      id: 'n1',
      title: 'Hello',
      orderId: 'o1',
    ),
    const OrderNotification.fromTrusted(
      id: 'n1',
      title: 'Hi',
      orderId: 'o1',
    ),
  );

  print('ALL CHECKS PASSED');
}
''';
