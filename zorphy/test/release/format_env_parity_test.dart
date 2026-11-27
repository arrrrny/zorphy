import 'dart:io';

import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

/// Regression gate for issue #327: the CI `format` job and the release gate's
/// format step must format against the SAME language version.
///
/// `dart format` chooses the tall vs. short style from the language version in
/// the resolved package config (the pubspec's SDK lower bound, `>=3.11.0`).
/// The release gate runs `dart pub get` before it formats (`pre_publish_gate`
/// in `scripts/publish.sh`), so it resolves language 3.11 and formats tall —
/// matching the tall-style tree committed in `style: reformat zorphy/`. The CI
/// `format` job used to run `dart format` with no `dart pub get`, so it had no
/// package config, fell back to the short style, and disagreed with the gate on
/// 30 files. These tests pin that BOTH environments resolve dependencies before
/// formatting, so they can never drift apart again.

/// The repository root: this test runs with the `zorphy` package as cwd (the
/// documented `dart test` invocation) and the package sits directly under it.
final String _repoRoot = Directory(
  '${Directory.current.path}/..',
).resolveSymbolicLinksSync();

String _read(String relative) =>
    File('$_repoRoot/$relative').readAsStringSync();

/// Extracts a bash function body: from the `<name>() {` line to the next line
/// that is a lone `}` at column 0 (the closing brace of a top-level function in
/// `publish.sh`). Returns null when the function is not defined.
String? _functionBody(String script, String name) {
  final lines = script.split('\n');
  final start = lines.indexWhere(
    (l) => RegExp('^\\s*${RegExp.escape(name)}\\s*\\(\\)\\s*\\{').hasMatch(l),
  );
  if (start < 0) return null;
  final body = <String>[];
  for (var i = start; i < lines.length; i++) {
    if (i > start && lines[i] == '}') break;
    body.add(lines[i]);
  }
  return body.join('\n');
}

/// The `run:` bodies of a job's steps, in order (skipping `uses:` steps).
List<String> _runSteps(YamlMap job) {
  final steps = job['steps'];
  expect(steps, isA<YamlList>(), reason: 'the job must declare steps');
  final runs = <String>[];
  for (final step in (steps as YamlList)) {
    if (step is! YamlMap) continue;
    final run = step['run'];
    if (run is String && run.trim().isNotEmpty) runs.add(run);
  }
  return runs;
}

void main() {
  group('format environment parity (issue #327)', () {
    test('CI format job resolves dependencies before formatting', () {
      final ci = loadYaml(_read('.github/workflows/ci.yaml')) as YamlMap;
      final formatJob = (ci['jobs'] as YamlMap)['format'] as YamlMap;
      final runs = _runSteps(formatJob);

      final pubGetAt = runs.indexWhere((c) => c.contains('dart pub get'));
      final formatAt = runs.indexWhere((c) => c.contains('dart format'));

      expect(
        formatAt,
        isNonNegative,
        reason: 'the format job must run `dart format`',
      );
      expect(
        pubGetAt,
        isNonNegative,
        reason:
            'the CI format job must run `dart pub get` so the formatter sees '
            'a package config pinning the declared language version — without '
            'it the job formats short-style while the release gate formats '
            'tall-style, and the two disagree (issue #327)',
      );
      expect(
        pubGetAt < formatAt,
        isTrue,
        reason:
            '`dart pub get` must run BEFORE `dart format` in the format job',
      );
    });

    test('release gate resolves dependencies before formatting', () {
      final script = _read('scripts/publish.sh');
      final gate = _functionBody(script, 'pre_publish_gate');

      expect(
        gate,
        isNotNull,
        reason: 'publish.sh must define pre_publish_gate',
      );
      final pubGetAt = gate!.indexOf('dart pub get');
      final formatAt = gate.indexOf('dart format');

      expect(
        pubGetAt,
        isNonNegative,
        reason: 'the release gate must run `dart pub get`',
      );
      expect(
        formatAt,
        isNonNegative,
        reason: 'the release gate must run `dart format`',
      );
      expect(
        pubGetAt < formatAt,
        isTrue,
        reason:
            'the release gate must resolve BEFORE it formats, so its language '
            'version matches the CI format job (issue #327)',
      );
    });
  });
}
