/// GYM exercise — lift a legacy JSON payload into a typed Zorphy entity
/// (graded).
///
/// Brief (spec 022 / issue #397, US2-S2): a genuine dev task, not a
/// re-skinned unit test. A legacy catalog API returns the fixed payload at
/// .gym/fixtures/catalog-payload.json (name/price/stock/tags). The
/// exercise drives the zorphy toolchain the way an operator does:
///
///   1. Stage a throwaway target package (path deps into this monorepo).
///   2. `zorphy_cli from-json -n Product payload.json` — infer the entity
///      shape from the payload.
///   3. `zorphy build` — generate the entity code (.zorphy.dart/.g.dart)
///      and compile the target (build_runner + a probe run proves the
///      generated class is real).
///   4. Assert the state semantics on the generated class:
///      `Product.fromJson(payload)` -> field-by-field `toJson()` equality
///      with the original payload (the JSON round-trip), and `copyWith`
///      changing exactly the requested field while preserving the rest.
///
/// Grading (FR-007): exit 0 => pass; exit non-zero => fail. Mis-fires
/// (unexpected outcomes) write a structured DROP CARD
/// (Did/Expected/Happened/Where) under .gym/.drops/ (FR-006) — see
/// github.com/arrrrny/drop-card.
///
/// verifyCommand: `dart run .gym/exercise-lift-json-payload.dart`
/// evaluate: exit 0 => pass; exit !=0 => fail
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// The zorphy package root (this checkout).
final String _pkgRoot = _resolvePackageRoot();

String _resolvePackageRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i += 1) {
    if (File(p.join(dir.path, 'bin', 'zorphy_cli.dart')).existsSync() &&
        File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return Directory.current.path;
}

/// Outcome of one CLI invocation.
class _RunResult {
  _RunResult({required this.exitCode, required this.output});

  final int exitCode;
  final String output;
}

Future<_RunResult> _run(
  String workingDir,
  String executable,
  List<String> args, {
  bool shell = false,
}) async {
  final result = await Process.run(
    executable,
    args,
    workingDirectory: workingDir,
    runInShell: shell,
  );
  return _RunResult(
    exitCode: result.exitCode,
    output: '${result.stdout as String}${result.stderr as String}',
  );
}

/// Entry point for the graded exercise.
Future<void> main() async {
  // ── SETUP (sandbox lifecycle — fail fast before any work) ──────────
  final cli = p.join(_pkgRoot, 'bin', 'zorphy_cli.dart');
  if (!File(cli).existsSync()) {
    _fail(
      'zorphy CLI entry not found at $cli — run this exercise from the '
      'zorphy package root.',
    );
  }
  final payloadFixture = File(
    p.join(_pkgRoot, '.gym', 'fixtures', 'catalog-payload.json'),
  );
  if (!payloadFixture.existsSync()) {
    _fail('Payload fixture missing: ${payloadFixture.path}');
  }

  final sandbox = Directory(
    p.canonicalize(p.join(_pkgRoot, '.gym', '.sandbox', 'lift-json-payload')),
  );
  if (sandbox.existsSync()) {
    await sandbox.delete(recursive: true);
  }
  await sandbox.create(recursive: true);
  final target = sandbox.path;
  final annotationPath = p.normalize(
    p.join(_pkgRoot, '..', 'zorphy_annotation'),
  );

  await File(p.join(target, 'pubspec.yaml')).writeAsString('''
name: zorphy_gym_target
description: Sandbox target for the lift-json-payload GYM exercise.
version: 0.0.1
publish_to: none
environment:
  sdk: ^3.8.0
dependencies:
  json_annotation: ^4.8.0
  zorphy_annotation:
    path: ${annotationPath.replaceAll('\\', '/')}
dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.6.0
  zorphy:
    path: ${_pkgRoot.replaceAll('\\', '/')}
dependency_overrides:
  zorphy_annotation:
    path: ${annotationPath.replaceAll('\\', '/')}
''');
  await Directory(p.join(target, 'bin')).create(recursive: true);
  await payloadFixture.copy(p.join(target, 'payload.json'));

  final pubGet = await _run(target, 'dart', ['pub', 'get']);
  if (pubGet.exitCode != 0) {
    _fail(
      'SETUP ERROR: dart pub get failed in the sandbox target '
      '(exit ${pubGet.exitCode}) — environment/setup problem, not a '
      'graded failure.\n${pubGet.output}',
    );
  }

  // ── Step 1: lift the payload into an entity (zorphy_cli from-json) ──
  final fromJson = await _run(target, 'dart', [
    cli,
    'from-json',
    '-n',
    'Product',
    'payload.json',
  ]);
  if (fromJson.exitCode != 0) {
    _fail(
      '`zorphy_cli from-json -n Product payload.json` exited '
      '${fromJson.exitCode}.\n${fromJson.output}',
    );
  }
  final entityFile = File(
    p.join(
      target,
      'lib',
      'src',
      'domain',
      'entities',
      'product',
      'product.dart',
    ),
  );
  if (!entityFile.existsSync()) {
    await _dropCard(
      did: 'ran `zorphy_cli from-json -n Product payload.json` (exit 0)',
      expected: 'lib/src/domain/entities/product/product.dart on disk',
      happened: 'command reported success but the entity file is missing',
      where: 'lift-json-payload, step 1 (from-json)',
    );
    _fail(
      'Mis-fire: from-json exited 0 but the entity file is missing '
      '(${entityFile.path}). DROP CARD written.',
    );
  }

  // ── Step 2: generate + compile (zorphy build) ────────────────────────
  final build = await _run(target, 'dart', [cli, 'build']);
  if (build.exitCode != 0) {
    _fail('`zorphy build` exited ${build.exitCode}.\n${build.output}');
  }
  for (final part in <String>['product.zorphy.dart', 'product.g.dart']) {
    final partFile = File(
      p.join(target, 'lib', 'src', 'domain', 'entities', 'product', part),
    );
    if (!partFile.existsSync()) {
      await _dropCard(
        did: 'ran `zorphy build` after from-json (exit 0)',
        expected: 'generated part $part beside the entity',
        happened: 'build reported success but the part is missing',
        where: 'lift-json-payload, step 2 (build)',
      );
      _fail(
        'Mis-fire: build exited 0 but $part is missing. DROP CARD '
        'written.',
      );
    }
  }

  // ── Step 3: prove the generated class is real (probe) ───────────────
  await File(p.join(target, 'bin', 'probe.dart')).writeAsString('''
import 'package:zorphy_gym_target/src/domain/entities/product/product.dart';

void main() {
  const payload = <String, dynamic>{
    'name': 'Espresso',
    'price': 4.5,
    'stock': 12,
    'tags': ['hot', 'small'],
  };
  final product = Product.fromJson(payload);
  if (product.name != 'Espresso' ||
      product.price != 4.5 ||
      product.stock != 12 ||
      product.tags.length != 2 ||
      product.tags[0] != 'hot' ||
      product.tags[1] != 'small') {
    throw StateError('typed fields mismatch: \\\${product.toJson()}');
  }
  final out = product.toJson();
  for (final entry in payload.entries) {
    if (!_eq(out[entry.key], entry.value)) {
      throw StateError('round-trip mismatch at \\\${entry.key}: '
          '\\\${out[entry.key]} != \\\${entry.value}');
    }
  }
  final copied = product.copyWith(name: 'Latte');
  if (copied.name != 'Latte' ||
      copied.price != product.price ||
      copied.stock != product.stock ||
      copied.tags.length != product.tags.length) {
    throw StateError('copyWith did not preserve untouched fields');
  }
  print('JSON_LIFT_OK: Product round-trips the payload and copyWith is '
      'field-safe');
}

bool _eq(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_eq(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
''');

  final probe = await _run(target, 'dart', ['run', 'bin/probe.dart']);
  if (probe.exitCode != 0 || !probe.output.contains('JSON_LIFT_OK')) {
    await _dropCard(
      did: 'compiled the generated Product and ran the round-trip probe',
      expected:
          'JSON_LIFT_OK — typed fields, JSON round-trip equality, '
          'copyWith field-safety',
      happened: 'exit ${probe.exitCode}; output:\n${probe.output}',
      where: 'lift-json-payload, step 3 (probe)',
    );
    _fail(
      'The generated entity does not round-trip the payload.\n'
      '${probe.output}',
    );
  }

  stdout.writeln(
    'EXERCISE PASSED: lift-json-payload — legacy JSON payload '
    'lifted into a typed Zorphy entity; round-trip + copyWith proven.',
  );
  // Leave the sandbox in place for downstream inspection; wiped next run.
  exit(0);
}

/// Write a structured DROP CARD (Did/Expected/Happened/Where) for a
/// mis-fire — an unexpected outcome, as opposed to a clean failure.
Future<void> _dropCard({
  required String did,
  required String expected,
  required String happened,
  required String where,
}) async {
  final dropsDir = Directory(p.join(_pkgRoot, '.gym', '.drops'));
  await dropsDir.create(recursive: true);
  final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
  final card = File(p.join(dropsDir.path, 'DROP-lift-json-payload-$stamp.md'));
  await card.writeAsString('''
# DROP CARD: lift-json-payload

- **Did**: $did
- **Expected**: $expected
- **Happened**: $happened
- **Where**: $where

Recorded by `.gym/exercise-lift-json-payload.dart` (spec 022 / issue
#397). Mis-fire convention: github.com/arrrrny/drop-card
''');
  stderr.writeln('DROP CARD written: ${card.path}');
}

/// Print a structured failure message and exit non-zero.
void _fail(String message) {
  stderr.writeln('EXERCISE FAILED: lift-json-payload — $message');
  stderr.writeln('Mis-fire? Drop a card: github.com/arrrrny/drop-card');
  exit(1);
}
