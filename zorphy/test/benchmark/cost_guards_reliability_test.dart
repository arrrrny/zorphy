// Reliability contract for the Chord v2 cost guards (arrrrny/zorphy#237).
//
// #193 wired the four in-memory cost guards into CI with a fixed 2x headroom
// and a single timed sample. On a shared, oversubscribed host that gate is
// unreliable in BOTH directions: a contended run can blow the wall-clock
// budgets and report a misleading RED, while a lucky quiet run reports GREEN
// with no evidence the host was fit to measure at all (#237's "misfire found
// during the #175 re-audit": 739/739 in-suite green, then two slower standalone
// failures at loadavg ~133 on 12 cores).
//
// These tests pin the RELIABILITY rules as pure functions, so they are
// deterministic and do not themselves flake on a loaded host:
//
//   * an overload admission check classifies a host too loaded to measure as
//     INCONCLUSIVE — never green, never an unexplained red;
//   * robust multi-sample statistics (median/MAD) replace the single sample,
//     so one noisy sample cannot flip the verdict;
//   * a retry budget re-runs an inconclusive/slow measurement before giving up
//     to a documented INCONCLUSIVE outcome;
//   * correctness/identity assertions stay mandatory and are never masked by a
//     timing verdict;
//   * the release gate (the `dart test` CI step) cannot close on INCONCLUSIVE.

import 'package:test/test.dart';

import '../../benchmark/cost_guards.dart';

void main() {
  group('overload admission (#237)', () {
    test('a host within the load budget is admitted', () {
      final verdict = classifyLoad(
        loadAverage1m: 4.0,
        cpuCount: 12,
        maxLoadPerCore: 1.0,
      );
      expect(verdict.admitted, isTrue);
      expect(verdict.inconclusive, isFalse);
    });

    test('a host past the load budget is inconclusive, not admitted', () {
      // The #237 misfire: loadavg 133 on a 12-core host.
      final verdict = classifyLoad(
        loadAverage1m: 133.72,
        cpuCount: 12,
        maxLoadPerCore: 1.0,
      );
      expect(verdict.admitted, isFalse);
      expect(verdict.inconclusive, isTrue);
      expect(verdict.detail, contains('loadavg'));
    });

    test('the load budget scales with cpu count', () {
      // 8 load on 8 cores is at the 1.0/core line — admitted.
      expect(
        classifyLoad(
          loadAverage1m: 8,
          cpuCount: 8,
          maxLoadPerCore: 1.0,
        ).admitted,
        isTrue,
      );
      // 8.5 on 8 cores is over the line — inconclusive.
      expect(
        classifyLoad(
          loadAverage1m: 8.5,
          cpuCount: 8,
          maxLoadPerCore: 1.0,
        ).inconclusive,
        isTrue,
      );
    });
  });

  group('robust sample statistics (#237)', () {
    test('median and MAD ignore a single noisy sample', () {
      final stats = summarizeSamples(<int>[10, 11, 9, 10, 5000]);
      expect(stats.median, 10);
      // median absolute deviation from the median (10): |10-10|,|11-10|,
      // |9-10|,|10-10|,|5000-10| -> [0,1,1,0,4990] -> median 1.
      expect(stats.mad, 1);
    });

    test('a tight cluster has a small MAD', () {
      final stats = summarizeSamples(<int>[20, 21, 20, 19, 20]);
      expect(stats.median, 20);
      expect(stats.mad, lessThanOrEqualTo(1));
    });
  });

  group('performance verdict decision (#237)', () {
    test('within budget is green', () {
      final verdict = decidePerformance(
        samples: <int>[18, 19, 20, 18, 19],
        budget: 30,
        maxMadsOverBudget: 3,
      );
      expect(verdict.outcome, PerformanceOutcome.green);
      expect(verdict.withinBudget, isTrue);
    });

    test('a stable regression past budget is red', () {
      final verdict = decidePerformance(
        samples: <int>[80, 81, 79, 80, 80],
        budget: 30,
        maxMadsOverBudget: 3,
      );
      expect(verdict.outcome, PerformanceOutcome.red);
      expect(verdict.withinBudget, isFalse);
    });

    test('a noisy sample straddling the budget is inconclusive, not red', () {
      // Median is under budget but the spread (MAD) reaches past it: the host
      // is too noisy to call a regression. Must be INCONCLUSIVE, never a
      // misleading red and never a green.
      final verdict = decidePerformance(
        samples: <int>[20, 25, 18, 40, 22],
        budget: 30,
        maxMadsOverBudget: 3,
      );
      expect(verdict.outcome, PerformanceOutcome.inconclusive);
    });

    test('a single slow sample cannot flip a tight cluster to red', () {
      final verdict = decidePerformance(
        samples: <int>[19, 20, 18, 19, 900],
        budget: 30,
        maxMadsOverBudget: 3,
      );
      expect(verdict.outcome, PerformanceOutcome.green);
    });
  });

  group('retry budget (#237)', () {
    test('a measurement that succeeds within the budget is returned', () {
      final outcome = withRetries(
        maxAttempts: 3,
        attempt: (attempt) =>
            attempt == 0 ? SampleVerdict.inconclusive : SampleVerdict.green,
      );
      expect(outcome, SampleVerdict.green);
    });

    test('an always-inconclusive measurement exhausts to inconclusive', () {
      final outcome = withRetries(
        maxAttempts: 3,
        attempt: (_) => SampleVerdict.inconclusive,
      );
      expect(outcome, SampleVerdict.inconclusive);
    });

    test('a hard red is returned immediately without burning retries', () {
      var calls = 0;
      final outcome = withRetries(
        maxAttempts: 3,
        attempt: (_) {
          calls++;
          return SampleVerdict.red;
        },
      );
      expect(outcome, SampleVerdict.red);
      expect(calls, 1);
    });
  });

  group('mandatory correctness is never masked by timing (#237)', () {
    test('a correctness failure is red even when timing is within budget', () {
      final report = CostGuardReport(
        name: 'Guard 2: no-op patch identity',
        correctnessOk: false,
        correctnessDetail: 'identical=false',
        timing: const PerformanceVerdict(
          outcome: PerformanceOutcome.green,
          median: 10,
          mad: 1,
          budget: 50,
          detail: 'median 10ns within 50ns',
        ),
      );
      expect(report.passed, isFalse);
      expect(report.inconclusive, isFalse);
      expect(report.outcome, GuardOutcome.red);
    });

    test('inconclusive timing yields an inconclusive guard, not green', () {
      final report = CostGuardReport(
        name: 'Guard 4: boundary validation throughput',
        correctnessOk: true,
        correctnessDetail: '10000/10000 validated',
        timing: const PerformanceVerdict(
          outcome: PerformanceOutcome.inconclusive,
          median: 30,
          mad: 12,
          budget: 30,
          detail: 'noisy: median 30ns, MAD 12ns straddles 30ns budget',
        ),
      );
      expect(report.passed, isFalse);
      expect(report.inconclusive, isTrue);
      expect(report.outcome, GuardOutcome.inconclusive);
    });

    test('correct + within budget is a passing green guard', () {
      final report = CostGuardReport(
        name: 'Guard 3: polymorphic resolvePath',
        correctnessOk: true,
        correctnessDetail: 'enabled=true price=true',
        timing: const PerformanceVerdict(
          outcome: PerformanceOutcome.green,
          median: 28,
          mad: 2,
          budget: 200,
          detail: 'median 28ns within 200ns',
        ),
      );
      expect(report.passed, isTrue);
      expect(report.inconclusive, isFalse);
      expect(report.outcome, GuardOutcome.green);
    });
  });

  group('the suite aggregate outcome (#237)', () {
    // NOTE (#234): the live `evaluateCostGuards()` assertion moved to
    // `cost_guards_test.dart`, which drives the generated-code benchmark as a
    // subprocess — `evaluateCostGuards` now lives in `cost_guards_impl.dart` and
    // needs the generated part, so it cannot be imported from this pure
    // reliability suite. The aggregate-outcome rules below stay here as pure
    // functions over hand-built reports.

    test(
      'aggregate outcome is inconclusive when any guard is inconclusive',
      () {
        const report = CostGuardSuite(
          guards: <CostGuardReport>[
            CostGuardReport(
              name: 'g1',
              correctnessOk: true,
              correctnessDetail: 'ok',
              timing: PerformanceVerdict.greenSample,
            ),
            CostGuardReport(
              name: 'g2',
              correctnessOk: true,
              correctnessDetail: 'ok',
              timing: PerformanceVerdict.inconclusiveSample,
            ),
          ],
          environment: LoadEnvironment.sample,
        );
        expect(report.aggregate, GuardOutcome.inconclusive);
        expect(report.allPassed, isFalse);
      },
    );

    test('aggregate is red when any guard is red', () {
      const report = CostGuardSuite(
        guards: <CostGuardReport>[
          CostGuardReport(
            name: 'g1',
            correctnessOk: false,
            correctnessDetail: 'bad',
            timing: PerformanceVerdict.greenSample,
          ),
        ],
        environment: LoadEnvironment.sample,
      );
      expect(report.aggregate, GuardOutcome.red);
    });

    test('aggregate is green only when every guard is green', () {
      const report = CostGuardSuite(
        guards: <CostGuardReport>[
          CostGuardReport(
            name: 'g1',
            correctnessOk: true,
            correctnessDetail: 'ok',
            timing: PerformanceVerdict.greenSample,
          ),
        ],
        environment: LoadEnvironment.sample,
      );
      expect(report.aggregate, GuardOutcome.green);
      expect(report.allPassed, isTrue);
    });
  });
}
