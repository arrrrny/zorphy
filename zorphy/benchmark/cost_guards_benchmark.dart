// Standalone `dart run` entry for the Chord v2 in-memory cost guards
// (ISSUE-018, arrrrny/zorphy#193; reliability #237; real-generated-code #234).
//
// #234 requires the guards to measure the REAL `build_runner`-generated v3
// classes, with generation as a PREREQUISITE so a missing generated API
// (`<Entity>Patch.diff`, `changeTo*`, `resolvePath`, polymorphic `fromWire`)
// fails loudly at build time. This launcher is that prerequisite made explicit:
//
//   1. It runs the production generator scoped to the benchmark fixture
//      (`dart run build_runner build --build-filter 'benchmark/**'`), which
//      writes `_br_/benchmark/cost_guard_fixtures.part.dart`. If generation
//      fails, the launcher exits non-zero BEFORE any guard runs — the loud
//      failure the acceptance gate names.
//   2. It then spawns `benchmark/cost_guards_impl.dart`, which imports the
//      generated classes and measures them. Because that library only compiles
//      against real generated output, removing a surface from the generator
//      makes this step fail to compile — again loudly.
//
// The launcher itself imports NO generated code (only `dart:io`), so it always
// compiles; the compile-time dependency on generated output lives in the impl
// the launcher spawns. Both agree on three-valued semantics (#237):
//
//   * GREEN        — all four guards green; exit 0.
//   * RED          — a correctness failure or a stable timing regression; exit 1.
//   * INCONCLUSIVE — the host failed load admission (overloaded) or a timing
//     measurement was too noisy to call; exit 2. The release gate treats this
//     as NOT passing, so it can never close on an inconclusive result.
//
// Run: `dart run benchmark/cost_guards_benchmark.dart`

import 'dart:io';

/// The package root — the parent of this script's `benchmark/` directory —
/// resolved from the script URI so the launcher works regardless of the cwd it
/// is invoked from.
Uri get _packageRoot => Platform.script.resolve('../').normalizePath();

void main() async {
  final root = _packageRoot;
  final dart = Platform.resolvedExecutable;

  // Step 1 — generation is the prerequisite. A non-zero exit here is the loud
  // build-time failure #234's acceptance gate requires; nothing is measured on
  // a tree the generator could not produce.
  stdout.writeln(
    'Generating v3 fixtures (build_runner, scoped to benchmark/)…',
  );
  final gen = await _runInherit(dart, <String>[
    'run',
    'build_runner',
    'build',
    '--build-filter',
    'benchmark/**',
  ], root.toFilePath());
  if (gen != 0) {
    stderr.writeln(
      'FAILED: build_runner generation exited $gen — the cost guards measure '
      'generated code and cannot run without it (#234).',
    );
    exitCode = 1;
    return;
  }

  // Step 2 — run the generated-aware guards. The impl imports the generated
  // part, so a missing surface fails to compile here (loud), and its exit code
  // carries the green/red/inconclusive verdict.
  final impl = await _runInherit(dart, <String>[
    'run',
    'benchmark/cost_guards_impl.dart',
  ], root.toFilePath());
  exitCode = impl;
}

/// Runs [exe] with [args] in [cwd] with inherited stdio (so the child's output
/// reaches the caller's terminal directly) and returns its exit code.
Future<int> _runInherit(String exe, List<String> args, String cwd) async {
  final proc = await Process.start(
    exe,
    args,
    workingDirectory: cwd,
    mode: ProcessStartMode.inheritStdio,
  );
  return proc.exitCode;
}
