// Standalone `dart run` entry for the Chord v2 in-memory cost guards
// (ISSUE-018, arrrrny/zorphy#193), with the reliability contract from
// arrrrny/zorphy#237.
//
// The guard logic lives in `benchmark/cost_guards.dart` so the same evaluation
// backs both this gate and `test/benchmark/cost_guards_test.dart` (which rides
// the existing `dart test` CI step). Both agree on three-valued semantics:
//
//   * GREEN        — all four guards green; exit 0.
//   * RED          — a correctness failure or a stable timing regression; exit 1.
//   * INCONCLUSIVE — the host failed load admission (overloaded) or a timing
//     measurement was too noisy to call; exit 2. The release gate treats this as
//     NOT passing, so it can never close on an inconclusive result (#237).
//
// On an overloaded host this no longer reports a misleading red: it reports the
// documented INCONCLUSIVE outcome with the load metadata that caused it. A
// deliberate CPU-saturation probe therefore produces retry/inconclusive
// behaviour, never a false green or an unexplained red.
//
// Run: `dart run benchmark/cost_guards_benchmark.dart`

import 'dart:io';

import 'cost_guards.dart';

void main() {
  print('Chord v2 cost guards (ISSUE-018) — zorphy#193 / #237');
  print('');

  final suite = evaluateCostGuards();
  final env = suite.environment;
  print(
    'Environment: ${env.cpuCount} cores, '
    'loadavg(1m)=${env.loadAverage1m.toStringAsFixed(2)}, '
    'admission budget ${env.maxLoadPerCore.toStringAsFixed(2)}/core → '
    '${env.admitted ? 'ADMITTED' : 'INCONCLUSIVE (overloaded)'}',
  );
  print('');

  for (final result in suite.guards) {
    final tag = switch (result.outcome) {
      GuardOutcome.green => 'PASS',
      GuardOutcome.red => 'FAIL',
      GuardOutcome.inconclusive => 'INCONCLUSIVE',
    };
    print('[$tag] ${result.name} — ${result.detail}');
  }

  print('');
  switch (suite.aggregate) {
    case GuardOutcome.green:
      print('ALL ${suite.guards.length} COST GUARDS GREEN');
    case GuardOutcome.red:
      final failures = suite.guards
          .where((r) => r.outcome == GuardOutcome.red)
          .length;
      print('$failures COST GUARD(S) FAILED');
      // Non-zero exit fails the CI step that runs this benchmark. `exitCode`
      // (rather than a `throw`, which exits 255 with a stack trace) reads as a
      // deliberate CI-gate failure.
      exitCode = 1;
    case GuardOutcome.inconclusive:
      final count = suite.guards
          .where((r) => r.outcome == GuardOutcome.inconclusive)
          .length;
      print(
        '$count COST GUARD(S) INCONCLUSIVE — host overloaded or too noisy to '
        'measure; NOT a pass (release gate cannot close on inconclusive)',
      );
      // Distinct exit code (2) so a caller can tell "regression" from
      // "could not measure"; both are non-zero, so neither closes the gate.
      exitCode = 2;
  }
}
