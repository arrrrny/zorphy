// CI enforcement for the Chord v2 in-memory cost guards (ISSUE-018,
// arrrrny/zorphy#193).
//
// The issue asks for the guards to run in CI so a regression fails the build.
// The dedicated `cost_guards` workflow job could not be committed from the
// dispatch lane (its GitHub credential lacks the `workflow` scope that
// `.github/workflows/*` requires), so this suite rides the EXISTING `dart test`
// CI step instead: `dart test` discovers `test/**/*_test.dart`, and a red guard
// here fails the same build the workflow job would have.
//
// The authoritative standalone gate is still
// `dart run benchmark/cost_guards_benchmark.dart`; both consume the one
// `evaluateCostGuards()` in `benchmark/cost_guards.dart`.

import 'package:test/test.dart';

import '../../benchmark/cost_guards.dart';

void main() {
  group('Chord v2 cost guards (ISSUE-018)', () {
    test('all four in-memory cost guards stay within budget', () {
      final results = evaluateCostGuards();
      final failures = results
          .where((r) => !r.passed)
          .map((r) => r.toString())
          .toList();
      expect(
        failures,
        isEmpty,
        reason: 'cost guard(s) exceeded budget:\n${failures.join('\n')}',
      );
    });
  });
}
