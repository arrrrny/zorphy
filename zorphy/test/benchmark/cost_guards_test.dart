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
  // A cwd that is neither the package root nor under it is a mis-invocation;
  // falling back to it hides the real problem behind a confusing `dart run`
  // "No such file" error. Fail here so the cause is self-explanatory.
  fail('could not locate zorphy package root from ${Directory.current}');
}

/// The captured result of [runWithDeadline].
final class _RunResult {
  const _RunResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}

/// Runs the benchmark launcher asynchronously, capturing both output streams,
/// and waits at most [deadline]. An asynchronous wait keeps the test isolate
/// responsive to its own timeout: `Process.runSync` would block that isolate
/// (and package:test's timer with it) until the subprocess exits. On expiry the
/// launcher AND the children it spawned (build_runner, the impl) are killed,
/// and a sentinel exit code of -1 is returned so the assertions below fail with
/// the captured output as their reason.
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
  // The launcher's children inherit its stdio, so a descendant that outlives
  // the launcher keeps these pipes open. Bound the wait and drop our
  // subscriptions on expiry: output capture must never hang cleanup on an
  // inherited pipe held by an orphan.
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

/// Terminates [rootPid] and every descendant. The launcher spawns build_runner
/// and the impl as independent processes with inherited stdio, so killing it
/// alone would leave them running — and holding the test's output pipes — after
/// a timeout.
Future<void> _killProcessTree(int rootPid) async {
  if (Platform.isWindows) {
    await Process.run('taskkill', <String>['/PID', '$rootPid', '/T', '/F']);
    return;
  }
  // Freeze the launcher BEFORE snapshotting: it promotes the impl to a direct
  // child the moment build_runner exits, and a stopped process cannot spawn
  // that child between our snapshot and the kill below.
  try {
    Process.killPid(rootPid, ProcessSignal.sigstop);
  } on Object {
    // Already exited; the bounded stream wait handles any orphan it left.
  }

  // Bounded `ps` snapshots (never a filesystem walk), repeated until the
  // descendant set stops growing, so a child spawned just before the freeze
  // cannot escape the sweep.
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

  // Kill descendants before the frozen launcher: killing the launcher first
  // would reparent its children and break the ppid links we just walked.
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

void main() {
  group('Chord v2 cost guards (ISSUE-018 / #234)', () {
    test(
      'the generated-code benchmark passes all four guards (exit 0, green)',
      () async {
        final root = _packageRoot();
        final dart = Platform.resolvedExecutable;
        // The internal deadline is shorter than the test's timeout so a stalled
        // generation is killed and reported here, rather than leaving package:test
        // to tear down an isolate whose child processes are still alive.
        final result = await runWithDeadline(
          dart,
          <String>['run', 'benchmark/cost_guards_benchmark.dart'],
          cwd: root.path,
          deadline: const Duration(minutes: 4),
        );

        final out = '${result.stdout}\n${result.stderr}';
        expect(
          result.exitCode,
          0,
          reason:
              'benchmark exited ${result.exitCode} (-1=TIMEOUT, 1=RED, '
              '2=INCONCLUSIVE; a compile failure here means a generated surface '
              'the guards name — diff / changeTo* / resolvePath / fromWire — is '
              'missing):\n$out',
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
