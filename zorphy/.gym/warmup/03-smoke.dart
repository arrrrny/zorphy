/// GYM warmup rep #3 — codegen round-trip smoke call into the zorphy CLI.
///
/// The issue asks for "one authenticated smoke call" per package. zorphy
/// is a codegen package, not a service, so the equivalent of an
/// authenticated API call is driving the package's public CLI surface end
/// to end — the same adaptation zuraffa's .gym/warmup/03-smoke.dart made
/// for its codegen API. This rep scaffolds a throwaway target package,
/// creates an entity via `zorphy_cli create`, runs `zorphy build` over it,
/// and asserts the generated `.zorphy.dart` part landed with the public
/// capabilities an operator relies on (`fromJson`, `copyWith`).
///
/// Run from the zorphy package root: `dart run .gym/warmup/03-smoke.dart`
///
/// A mis-fire (unexpected outcome, not a clean failure) is a DROP CARD —
/// see github.com/arrrrny/drop-card.
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

/// Entry point for warmup rep #3.
Future<void> main() async {
  final sandbox = Directory(
    p.canonicalize(p.join(_pkgRoot, '.gym', '.sandbox', 'warmup-03-smoke')),
  );
  if (sandbox.existsSync()) {
    await sandbox.delete(recursive: true);
  }
  await sandbox.create(recursive: true);

  final annotationPath = p.normalize(
    p.join(_pkgRoot, '..', 'zorphy_annotation'),
  );

  // Throwaway target package: minimal consumer of the zorphy toolchain.
  await File(p.join(sandbox.path, 'pubspec.yaml')).writeAsString('''
name: zorphy_smoke_target
description: Throwaway target for the zorphy GYM smoke rep.
version: 0.0.1
publish_to: none
environment:
  sdk: ^3.8.0
dependencies:
  zorphy_annotation:
    path: ${annotationPath.replaceAll('\\', '/')}
dev_dependencies:
  build_runner: ^2.4.0
  zorphy:
    path: ${_pkgRoot.replaceAll('\\', '/')}
dependency_overrides:
  zorphy_annotation:
    path: ${annotationPath.replaceAll('\\', '/')}
''');

  final pubGet = await Process.run('dart', [
    'pub',
    'get',
  ], workingDirectory: sandbox.path);
  if (pubGet.exitCode != 0) {
    stderr.writeln(
      'REP FAIL: 03-smoke — dart pub get failed in the smoke '
      'target (setup error, not a grade).',
    );
    stderr.writeln(pubGet.stdout);
    stderr.writeln(pubGet.stderr);
    exit(1);
  }

  // The smoke call: create an entity through the public CLI.
  final create = await Process.run('dart', [
    p.join(_pkgRoot, 'bin', 'zorphy_cli.dart'),
    'create',
    '-n',
    'Order',
    '--field',
    'id:String',
    '--field',
    'label:String',
  ], workingDirectory: sandbox.path);
  if (create.exitCode != 0) {
    stderr.writeln(
      'REP FAIL: 03-smoke — `zorphy_cli create` exited '
      '${create.exitCode}',
    );
    stderr.writeln(create.stdout);
    stderr.writeln(create.stderr);
    exit(1);
  }

  final entityFile = File(
    p.join(
      sandbox.path,
      'lib',
      'src',
      'domain',
      'entities',
      'order',
      'order.dart',
    ),
  );
  if (!entityFile.existsSync()) {
    stderr.writeln(
      'REP FAIL: 03-smoke — create exited 0 but the entity file is missing '
      '(${entityFile.path}). Mis-fire — drop a card: '
      'github.com/arrrrny/drop-card',
    );
    exit(1);
  }

  // Round-trip: run the generator over the target.
  final build = await Process.run('dart', [
    p.join(_pkgRoot, 'bin', 'zorphy_cli.dart'),
    'build',
  ], workingDirectory: sandbox.path);
  if (build.exitCode != 0) {
    stderr.writeln(
      'REP FAIL: 03-smoke — `zorphy build` exited ${build.exitCode}',
    );
    stderr.writeln(build.stdout);
    stderr.writeln(build.stderr);
    exit(1);
  }

  final part = File(
    p.join(
      sandbox.path,
      'lib',
      'src',
      'domain',
      'entities',
      'order',
      'order.zorphy.dart',
    ),
  );
  if (!part.existsSync()) {
    stderr.writeln(
      'REP FAIL: 03-smoke — build exited 0 but the generated part is '
      'missing (${part.path}). Mis-fire — drop a card.',
    );
    exit(1);
  }
  final generated = part.readAsStringSync();
  for (final marker in <String>['fromJson', 'copyWith']) {
    if (!generated.contains(marker)) {
      stderr.writeln(
        'REP FAIL: 03-smoke — generated part is missing the "$marker" '
        'capability. Mis-fire — drop a card.',
      );
      exit(1);
    }
  }

  stdout.writeln('REP OK: 03-smoke — zorphy codegen round-trip OK.');
}
