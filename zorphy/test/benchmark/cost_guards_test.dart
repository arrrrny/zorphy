// CI enforcement for the Chord v2 in-memory cost guards (ISSUE-018,
// arrrrny/zorphy#193), with the reliability contract from arrrrny/zorphy#237.
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
// `evaluateCostGuards()` in `benchmark/cost_guards.dart` and agree on
// pass/fail/inconclusive semantics (#237):
//
//   * GREEN  — every guard green: correctness holds and timing is within budget.
//   * RED    — a correctness failure or a stable timing regression.
//   * INCONCLUSIVE — the host was overloaded (failed load admission) or a timing
//     measurement was too noisy to call. The release gate treats INCONCLUSIVE as
//     NOT passing, so it can never close on one (#237 acceptance gate).

import 'package:test/test.dart';

import '../../benchmark/cost_guards.dart';

void main() {
  group('Chord v2 cost guards (ISSUE-018)', () {
    test(
      'all four in-memory cost guards are green (not red, not inconclusive)',
      () {
        final suite = evaluateCostGuards();
        final notGreen = suite.guards
            .where((r) => r.outcome != GuardOutcome.green)
            .map((r) => r.toString())
            .toList();
        expect(
          notGreen,
          isEmpty,
          reason:
              'cost guard(s) not green (red or inconclusive):\n'
              '${notGreen.join('\n')}\n'
              'environment: ${suite.environment}',
        );
      },
    );
  });
}
