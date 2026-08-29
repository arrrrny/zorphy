/// GYM warmup rep #1 — resolve package dependencies (zorphy).
///
/// A warmup rep proves the operator can drive the package at all. This one
/// resolves the zorphy package's own dependencies via `dart pub get` and
/// asserts the produced `.dart_tool/package_config.json` is on disk and
/// references the zorphy root package (the monorepo path-override to
/// zorphy_annotation is part of the package's committed pubspec).
///
/// Run from the zorphy package root: `dart run .gym/warmup/01-deps.dart`
///
/// A mis-fire (unexpected outcome, not a clean failure) is a DROP CARD —
/// see github.com/arrrrny/drop-card.
library;

import 'dart:io';

/// Entry point for warmup rep #1.
Future<void> main() async {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln(
      'No pubspec.yaml in cwd=${Directory.current.path} — run this rep '
      'from the zorphy package root (zorphy/zorphy/).',
    );
    exit(1);
  }

  final result = await Process.run('dart', ['pub', 'get']);

  if (result.exitCode != 0) {
    stderr.writeln(
      'REP FAIL: 01-deps — `dart pub get` exited ${result.exitCode}',
    );
    stderr.writeln(result.stdout);
    stderr.writeln(result.stderr);
    exit(result.exitCode == 0 ? 1 : result.exitCode);
  }

  final pkgConfig = File('.dart_tool/package_config.json');
  if (!pkgConfig.existsSync()) {
    stderr.writeln(
      'REP FAIL: 01-deps — pub get exited 0 but '
      '.dart_tool/package_config.json is missing. Mis-fire — drop a card: '
      'github.com/arrrrny/drop-card',
    );
    exit(1);
  }

  final configText = pkgConfig.readAsStringSync();
  if (!configText.contains('"name":"zorphy"') &&
      !configText.contains('"name": "zorphy"')) {
    stderr.writeln(
      'REP FAIL: 01-deps — package_config.json does not reference the '
      '`zorphy` root package. Mis-fire — drop a card.',
    );
    exit(1);
  }

  stdout.writeln('REP OK: 01-deps — dependencies resolved.');
}
