// Deterministic structural guards for the v3 generated surface
// (arrrrny/zorphy#252).
//
// The wall-clock cost guards (`benchmark/cost_guards*.dart`, #193/#237/#234)
// gate on host load: their latency budgets (50 ns / 200 ns / 30 ms) flake on a
// shared host and, after #237, report INCONCLUSIVE rather than red under load —
// so on a busy machine they prove nothing. #252 asks for the deterministic
// counterpart: structural assertions that hold regardless of host CPU load.
//
// This suite is that counterpart. It has two halves, both load-independent:
//
//   1. A static `dart:mirrors` import ban across the generator library
//      (`lib/`) — the v3 emission is reflection-free by construction (the
//      JSON-Pointer lens and the entity descriptor resolve fields without
//      mirrors, so the output is AOT-safe). This half needs no generation and
//      runs on a fresh checkout.
//
//   2. The generated-surface structural probe (`_structural_probe.dart`),
//      driven the same way `cost_guards_test.dart` drives the benchmark: the
//      test runs `build_runner` scoped to `benchmark/**` (a missing/broken
//      generator exits non-zero — the loud build-time failure #234 names),
//      then spawns the probe, which imports the REAL generated fixtures and
//      asserts ZorphyPatch op counts and O(1) switch-table resolvePath
//      coverage with zero timing. A removed surface fails to COMPILE there.
//
// The release gate treats a non-zero exit as NOT passing, so neither half can
// close on a skipped or inconclusive result.

import 'dart:async';
import 'dart:convert';
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
  fail('could not locate zorphy package root from ${Directory.current}');
}

/// The captured result of [runWithDeadline].
final class _RunResult {
  const _RunResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}

/// Runs [executable] with [args] asynchronously, capturing both output streams,
/// and waits at most [deadline]. On expiry the process AND the children it
/// spawned are killed and a sentinel exit code of -1 is returned so the
/// assertions fail with the captured output as their reason.
Future<_RunResult> runWithDeadline(
  String executable,
  List<String> args, {
  required String cwd,
  required Duration deadline,
}) async {
  final process = await Process.start(executable, args, workingDirectory: cwd);
  final stdout = StringBuffer();
  final stderr = StringBuffer();
  final stdoutSub = process.stdout.transform(utf8.decoder).listen(stdout.write);
  final stderrSub = process.stderr.transform(utf8.decoder).listen(stderr.write);
  final stdoutDone = stdoutSub.asFuture<void>();
  final stderrDone = stderrSub.asFuture<void>();

  final exitCode = await process.exitCode.timeout(
    deadline,
    onTimeout: () async {
      await _killProcessTree(process.pid);
      return -1;
    },
  );
  await Future.wait(<Future<void>>[stdoutDone, stderrDone]).timeout(
    const Duration(seconds: 10),
    onTimeout: () {
      stdoutSub.cancel();
      stderrSub.cancel();
      return <void>[];
    },
  );
  return _RunResult(exitCode, stdout.toString(), stderr.toString());
}

/// Terminates [rootPid] and every descendant (build_runner + the probe), so a
/// timeout cannot leave a child holding the test's output pipes open.
Future<void> _killProcessTree(int rootPid) async {
  if (Platform.isWindows) {
    await Process.run('taskkill', <String>['/PID', '$rootPid', '/T', '/F']);
    return;
  }
  try {
    Process.killPid(rootPid, ProcessSignal.sigstop);
  } on Object {
    // Already exited; the bounded stream wait handles any orphan it left.
  }

  final doomed = <int>{rootPid};
  for (var pass = 0; pass < 3; pass++) {
    final snapshot = await Process.run('ps', <String>[
      '-ax',
      '-o',
      'pid=,ppid=',
    ]);
    final children = <int, List<int>>{};
    for (final line in (snapshot.stdout as String).split('\n')) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final pid = int.tryParse(parts[0]);
      final ppid = int.tryParse(parts[1]);
      if (pid == null || ppid == null) continue;
      children.putIfAbsent(ppid, () => <int>[]).add(pid);
    }
    final before = doomed.length;
    final pending = doomed.toList();
    while (pending.isNotEmpty) {
      final pid = pending.removeLast();
      for (final child in children[pid] ?? const <int>[]) {
        if (doomed.add(child)) pending.add(child);
      }
    }
    if (doomed.length == before) break;
  }

  for (final pid in doomed) {
    if (pid == rootPid) continue;
    try {
      Process.killPid(pid, ProcessSignal.sigkill);
    } on Object {
      // Already exited.
    }
  }
  try {
    Process.killPid(rootPid, ProcessSignal.sigkill);
  } on Object {
    // Already exited.
  }
}

/// The major version of the `analyzer` package resolved in [root], or `null`
/// when it cannot be determined. build_runner 2.17.x needs analyzer 14, so the
/// generation-driven half is skipped on the analyzer-13 compat leg (which
/// exists to prove the library resolves/analyzes under 13, not to re-run
/// codegen).
Future<int?> _resolvedAnalyzerMajor(Directory root) async {
  final result = await Process.run(Platform.resolvedExecutable, <String>[
    'pub',
    'deps',
    '--style=compact',
  ], workingDirectory: root.path);
  if (result.exitCode != 0) return null;
  final match = RegExp(r'\banalyzer (\d+)\.').firstMatch('${result.stdout}');
  return match == null ? null : int.tryParse(match.group(1)!);
}

void main() {
  group('deterministic structural guards (#252)', () {
    test('the generator library carries no dart:mirrors import', () {
      final root = _packageRoot();
      final lib = Directory('${root.path}/lib');
      expect(
        lib.existsSync(),
        isTrue,
        reason: 'expected the generator library at ${lib.path}',
      );

      // A real `import 'dart:mirrors'` directive — not a doc comment that
      // merely mentions mirrors (the emitters reference it in prose to say the
      // output has none). Match the directive form only.
      final importRe = RegExp(
        r"""^\s*import\s+['"]dart:mirrors['"]""",
        multiLine: true,
      );
      final offenders = <String>[];
      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final src = entity.readAsStringSync();
        if (importRe.hasMatch(src)) {
          offenders.add(entity.path);
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'the v3 emission is reflection-free (AOT-safe); a dart:mirrors '
            'import in the generator breaks that invariant:\n'
            '${offenders.join('\n')}',
      );
    });

    test('the generated surface passes the structural probe (exit 0, green)', () async {
      final root = _packageRoot();
      final analyzerMajor = await _resolvedAnalyzerMajor(root);
      if (analyzerMajor != null && analyzerMajor < 14) {
        markTestSkipped(
          'build_runner 2.17.x requires analyzer 14+ (AnalysisOptionsBuilder); '
          'codegen cannot run under the analyzer-$analyzerMajor compat leg. '
          'The default test job and the analyzer-14 leg cover this probe.',
        );
        return;
      }
      final dart = Platform.resolvedExecutable;

      // Generation is the prerequisite: a non-zero exit here is the loud
      // build-time failure #234's acceptance gate requires.
      final gen = await runWithDeadline(
        dart,
        <String>[
          'run',
          'build_runner',
          'build',
          '--delete-conflicting-outputs',
          '--build-filter',
          'benchmark/**',
        ],
        cwd: root.path,
        deadline: const Duration(minutes: 4),
      );
      expect(
        gen.exitCode,
        0,
        reason:
            'build_runner generation failed (exit ${gen.exitCode}); the '
            'structural probe measures generated code and cannot run without '
            'it:\n${gen.stdout}\n${gen.stderr}',
      );

      final probe = await runWithDeadline(
        dart,
        <String>['run', 'test/audit/_structural_probe.dart'],
        cwd: root.path,
        deadline: const Duration(minutes: 2),
      );

      final out = '${probe.stdout}\n${probe.stderr}';
      expect(
        probe.exitCode,
        0,
        reason:
            'structural probe exited ${probe.exitCode} (-1=TIMEOUT, 1=FAILED; '
            'a compile failure here means a generated surface — diff / '
            'resolvePath / toWire — is missing):\n$out',
      );
      expect(
        probe.stdout,
        contains('ALL STRUCTURAL GUARDS GREEN'),
        reason:
            'the probe must exercise generated output and pass every '
            'structural guard:\n$out',
      );
    }, timeout: const Timeout(Duration(minutes: 6)));
  });
}
