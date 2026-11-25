// CI enforcement for the Chord v2 in-memory cost guards (ISSUE-018,
// arrrrny/zorphy#193; reliability #237; real-generated-code #234).
//
// #234 requires the guards to measure the REAL `build_runner`-generated v3
// classes, with generation as a prerequisite so a missing generated API fails
// loudly. This suite therefore does NOT import generated code itself (a fresh
// CI checkout has no generated `_br_` part until the build runs); instead it
// drives the standalone benchmark as a subprocess:
//
//   * the benchmark launcher runs generation first (a missing/broken generator
//     exits non-zero — the loud build-time failure #234's acceptance names),
//   * then it spawns the generated-aware impl, which only COMPILES against real
//     generated output, so removing `diff` / `changeTo*` / `resolvePath` from
//     the generator makes the impl fail to compile (again loudly).
//
// The test asserts the whole chain exits 0 and prints the all-green banner, so
// a regression in any guard — or a missing generated surface — fails this
// build. It rides the existing `dart test` CI step; the dedicated `cost_guards`
// workflow job still cannot be committed (the lane credential lacks the
// `workflow` scope `.github/workflows/*` requires).
//
// Three-valued semantics (#237): the benchmark exits 1 on RED and 2 on
// INCONCLUSIVE (host overloaded / too noisy); the release gate treats anything
// but exit 0 as NOT passing, so it can never close on an inconclusive result.

import 'dart:io';

import 'package:test/test.dart';

/// The package root: the nearest ancestor of the current working directory (or
/// the test script's directory) that holds both a `pubspec.yaml` and the
/// `benchmark/` directory. `dart test` runs from the package root, but
/// `Platform.script` under the test runner does not point at this file, so the
/// root is discovered by walking up rather than assumed.
Directory _packageRoot() {
  final seeds = <Directory>[
    Directory.current,
    File.fromUri(Platform.script).parent,
  ];
  for (final seed in seeds) {
    var dir = seed;
    while (true) {
      final hasPubspec = File('${dir.path}/pubspec.yaml').existsSync();
      final hasBench = Directory('${dir.path}/benchmark').existsSync();
      if (hasPubspec && hasBench) return dir;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  }
  // Fall back to the cwd; the assertion below will surface a clear error if it
  // is wrong.
  return Directory.current;
}

void main() {
  group('Chord v2 cost guards (ISSUE-018 / #234)', () {
    test(
      'the generated-code benchmark passes all four guards (exit 0, green)',
      () {
        final root = _packageRoot();
        final dart = Platform.resolvedExecutable;
        final result = Process.runSync(dart, <String>[
          'run',
          'benchmark/cost_guards_benchmark.dart',
        ], workingDirectory: root.path);

        final out = '${result.stdout}\n${result.stderr}';
        expect(
          result.exitCode,
          0,
          reason:
              'benchmark exited ${result.exitCode} (1=RED, 2=INCONCLUSIVE; a '
              'compile failure here means a generated surface the guards name '
              '— diff / changeTo* / resolvePath / fromWire — is missing):\n'
              '$out',
        );
        expect(
          result.stdout,
          contains('ALL 4 COST GUARDS GREEN'),
          reason:
              'the benchmark must exercise generated output and pass all '
              'four guards:\n$out',
        );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
