// Standalone `dart run` entry for the Chord v2 in-memory cost guards
// (ISSUE-018, arrrrny/zorphy#193).
//
// The guard logic lives in `benchmark/cost_guards.dart` so the same evaluation
// backs both this gate and `test/benchmark/cost_guards_test.dart` (which rides
// the existing `dart test` CI step). This program exits 0 only when all four
// guards are green; any red guard exits non-zero and fails the build.
//
// Run: `dart run benchmark/cost_guards_benchmark.dart`

import 'cost_guards.dart';

void main() {
  print('Chord v2 cost guards (ISSUE-018) — zorphy#193');
  print('');

  final results = evaluateCostGuards();
  for (final result in results) {
    print(
      '[${result.passed ? 'PASS' : 'FAIL'}] ${result.name} — ${result.detail}',
    );
  }

  final failures = results.where((r) => !r.passed).length;
  print('');
  if (failures == 0) {
    print('ALL ${results.length} COST GUARDS GREEN');
    return;
  }
  print('$failures COST GUARD(S) FAILED');
  // Non-zero exit fails the CI step that runs this benchmark.
  throw StateError('$failures cost guard(s) exceeded budget');
}
