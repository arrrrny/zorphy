// Reliability primitives for the Chord v2 in-memory cost guards
// (ISSUE-018, arrrrny/zorphy#193; reliability contract arrrrny/zorphy#237;
// real-generated-code move arrrrny/zorphy#234).
//
// This file is DELIBERATELY generated-free: it holds only the pure reliability
// harness (overload admission, robust sample statistics, the performance
// verdict, the retry budget, the report types) plus the timing helpers. The
// four guards themselves — and the `evaluateCostGuards()` that runs them —
// live in `benchmark/cost_guards_impl.dart`, which imports the REAL
// `build_runner`-generated v3 classes from
// `benchmark/cost_guard_fixtures.dart` and measures THEM (#234).
//
// Keeping the harness here, free of any generated `part`, is what lets
// `test/benchmark/cost_guards_reliability_test.dart` pin the reliability rules
// as deterministic pure functions that compile and run without a generation
// step — while the generated-aware test and the standalone benchmark exercise
// the guards against real output.
//
// The release gate (the `dart test` CI step and the standalone `dart run`
// entry) treats INCONCLUSIVE as NOT passing, so it cannot close on one.
// ---------------------------------------------------------------------------

import 'dart:io';

// ---------------------------------------------------------------------------
// Reliability primitives (arrrrny/zorphy#237).
//
// The 2026-11-25 re-audit found the gate unreliable on a shared host: the
// in-suite run was green (739/739) while two standalone runs failed at
// loadavg ~133 on 12 cores. The cause was a single timed sample gated on a
// fixed 2x headroom, with no overload admission and no inconclusive state — so
// host contention produced a misleading RED and a quiet host a GREEN with no
// evidence the host was fit to measure.
//
// The fix is a reproducible performance-gate design, not a threshold bump:
//
//   * `classifyLoad` — an overload admission check. A host past its per-core
//     load budget is INCONCLUSIVE (not measured), never a misleading red.
//   * `summarizeSamples` — robust multi-sample statistics (median + MAD), so a
//     single noisy sample cannot flip the verdict.
//   * `decidePerformance` — classifies a measurement as green / red /
//     INCONCLUSIVE from the median and its noise band against the budget. A
//     band that straddles the budget is inconclusive, never a guess.
//   * `withRetries` — an explicit retry budget: an inconclusive/slow sample is
//     re-measured before the guard settles on a documented INCONCLUSIVE.
//   * `CostGuardReport` — keeps correctness/identity MANDATORY: a correctness
//     failure is red regardless of timing, and an inconclusive timing is an
//     inconclusive guard, never green.
//
// The release gate (the `dart test` CI step and the standalone `dart run`
// entry) treats INCONCLUSIVE as NOT passing, so it cannot close on one.
// ---------------------------------------------------------------------------

/// The three-valued outcome of a performance measurement. INCONCLUSIVE is a
/// first-class result — the documented outcome under host overload — distinct
/// from both a pass (green) and a regression (red).
enum PerformanceOutcome { green, red, inconclusive }

/// The three-valued outcome of a whole cost guard: correctness plus timing.
enum GuardOutcome { green, red, inconclusive }

/// The verdict of the overload admission check.
class LoadVerdict {
  const LoadVerdict({
    required this.admitted,
    required this.loadAverage1m,
    required this.cpuCount,
    required this.maxLoadPerCore,
  });

  /// Whether the host is fit to measure (load within the per-core budget).
  final bool admitted;

  /// True when the host is too loaded to measure — the inconclusive case.
  bool get inconclusive => !admitted;

  final double loadAverage1m;
  final int cpuCount;
  final double maxLoadPerCore;

  /// The per-core load budget the host was admitted against.
  double get budgetPerCore => maxLoadPerCore;

  String get detail =>
      'loadavg ${loadAverage1m.toStringAsFixed(2)} over '
      '${cpuCount} cores (budget ${maxLoadPerCore.toStringAsFixed(2)}/core) '
      '→ ${admitted ? 'admitted' : 'INCONCLUSIVE (overloaded)'}';

  @override
  String toString() => 'LoadVerdict($detail)';
}

/// Default per-core load budget for admission. The #237 misfire was ~11 load
/// per core; a normal `dart test -j 2` never approaches 2/core, so this catches
/// genuine overload without self-flaking the in-suite run. Override with
/// `COST_GUARD_MAX_LOAD_PER_CORE`.
const double defaultMaxLoadPerCore = 2.0;

/// Classifies a host's 1-minute load average against a per-core budget.
///
/// Pure so the reliability contract is testable without provoking real load.
LoadVerdict classifyLoad({
  required double loadAverage1m,
  required int cpuCount,
  required double maxLoadPerCore,
}) {
  final cores = cpuCount < 1 ? 1 : cpuCount;
  final admitted = loadAverage1m <= cores * maxLoadPerCore;
  return LoadVerdict(
    admitted: admitted,
    loadAverage1m: loadAverage1m,
    cpuCount: cores,
    maxLoadPerCore: maxLoadPerCore,
  );
}

/// Robust summary of a timing sample set: median and median absolute deviation.
/// The median/MAD pair ignores a single outlier (a pre-empted sample), which a
/// mean would let dominate the verdict.
class SampleStats {
  const SampleStats(this.median, this.mad);

  final int median;
  final int mad;

  @override
  String toString() => 'SampleStats(median=$median, mad=$mad)';
}

/// Median and median-absolute-deviation of [samples] (integer nanoseconds/ms).
SampleStats summarizeSamples(List<int> samples) {
  if (samples.isEmpty) return const SampleStats(0, 0);
  final sorted = List<int>.of(samples)..sort();
  final median = _intMedian(sorted);
  final deviations = sorted.map((v) => (v - median).abs()).toList()..sort();
  final mad = _intMedian(deviations);
  return SampleStats(median, mad);
}

int _intMedian(List<int> sorted) {
  final n = sorted.length;
  final lo = sorted[(n - 1) ~/ 2];
  final hi = sorted[n ~/ 2];
  return (lo + hi) ~/ 2;
}

/// The performance verdict for one guard: the outcome plus the numbers behind
/// it (median, MAD, budget) and a human-readable detail line.
class PerformanceVerdict {
  const PerformanceVerdict({
    required this.outcome,
    required this.median,
    required this.mad,
    required this.budget,
    required this.detail,
  });

  final PerformanceOutcome outcome;
  final int median;
  final int mad;
  final int budget;
  final String detail;

  bool get withinBudget => median <= budget;

  /// A ready-made green verdict for guards with no timing dimension (Guard 1).
  static const PerformanceVerdict greenSample = PerformanceVerdict(
    outcome: PerformanceOutcome.green,
    median: 0,
    mad: 0,
    budget: 1,
    detail: 'correctness-only guard (no timing budget)',
  );

  /// A ready-made inconclusive verdict (used in tests and the load gate).
  static const PerformanceVerdict inconclusiveSample = PerformanceVerdict(
    outcome: PerformanceOutcome.inconclusive,
    median: 0,
    mad: 0,
    budget: 1,
    detail: 'inconclusive (host overloaded or too noisy to measure)',
  );

  @override
  String toString() => '${outcome.name.toUpperCase()} timing — $detail';
}

/// Decides green / red / INCONCLUSIVE from [samples] against [budget].
///
/// * green — the whole noise band (median ± [maxMadsOverBudget]·MAD) is within
///   budget;
/// * red — the whole band is above budget (a stable regression);
/// * inconclusive — the band straddles the budget (too noisy to call), never a
///   misleading red and never a green.
PerformanceVerdict decidePerformance({
  required List<int> samples,
  required int budget,
  required int maxMadsOverBudget,
}) {
  final stats = summarizeSamples(samples);
  final upperBand = stats.median + maxMadsOverBudget * stats.mad;
  final lowerBand = stats.median - maxMadsOverBudget * stats.mad;

  final PerformanceOutcome outcome;
  if (upperBand <= budget) {
    outcome = PerformanceOutcome.green;
  } else if (lowerBand > budget) {
    outcome = PerformanceOutcome.red;
  } else {
    outcome = PerformanceOutcome.inconclusive;
  }

  final band =
      'median ${stats.median} (MAD ${stats.mad}, band '
      '${lowerBand}..${upperBand}) vs budget ${budget}';
  final detail = outcome == PerformanceOutcome.inconclusive
      ? 'noisy: $band — straddles budget, INCONCLUSIVE'
      : '$band';
  return PerformanceVerdict(
    outcome: outcome,
    median: stats.median,
    mad: stats.mad,
    budget: budget,
    detail: detail,
  );
}

/// The per-attempt verdict used by [withRetries].
enum SampleVerdict { green, red, inconclusive }

/// Runs [attempt] up to [maxAttempts] times, returning the first green/red, and
/// INCONCLUSIVE if every attempt is inconclusive. A hard red short-circuits
/// without burning the remaining budget.
SampleVerdict withRetries({
  required int maxAttempts,
  required SampleVerdict Function(int attempt) attempt,
}) {
  var last = SampleVerdict.inconclusive;
  final attempts = maxAttempts < 1 ? 1 : maxAttempts;
  for (var i = 0; i < attempts; i++) {
    last = attempt(i);
    if (last != SampleVerdict.inconclusive) return last;
  }
  return last;
}

SampleVerdict _outcomeToSample(PerformanceOutcome o) => switch (o) {
  PerformanceOutcome.green => SampleVerdict.green,
  PerformanceOutcome.red => SampleVerdict.red,
  PerformanceOutcome.inconclusive => SampleVerdict.inconclusive,
};

/// One guard's report: a MANDATORY correctness result plus a timing verdict.
class CostGuardReport {
  const CostGuardReport({
    required this.name,
    required this.correctnessOk,
    required this.correctnessDetail,
    required this.timing,
  });

  final String name;
  final bool correctnessOk;
  final String correctnessDetail;
  final PerformanceVerdict timing;

  /// The combined outcome. Correctness dominates: a correctness failure is red
  /// whatever the timing says; otherwise the timing outcome carries through.
  GuardOutcome get outcome {
    if (!correctnessOk) return GuardOutcome.red;
    return switch (timing.outcome) {
      PerformanceOutcome.green => GuardOutcome.green,
      PerformanceOutcome.red => GuardOutcome.red,
      PerformanceOutcome.inconclusive => GuardOutcome.inconclusive,
    };
  }

  bool get passed => outcome == GuardOutcome.green;
  bool get inconclusive => outcome == GuardOutcome.inconclusive;

  String get detail =>
      correctnessOk ? timing.detail : 'correctness FAILED: $correctnessDetail';

  @override
  String toString() => '${outcome.name.toUpperCase()} $name — $detail';
}

/// The host environment a guard run measured against.
class LoadEnvironment {
  const LoadEnvironment({
    required this.cpuCount,
    required this.loadAverage1m,
    required this.maxLoadPerCore,
    required this.admitted,
  });

  final int cpuCount;
  final double loadAverage1m;
  final double maxLoadPerCore;
  final bool admitted;

  static const LoadEnvironment sample = LoadEnvironment(
    cpuCount: 1,
    loadAverage1m: 0,
    maxLoadPerCore: defaultMaxLoadPerCore,
    admitted: true,
  );

  @override
  String toString() =>
      'LoadEnvironment(cores=$cpuCount, loadavg='
      '${loadAverage1m.toStringAsFixed(2)}, admitted=$admitted)';
}

/// The whole suite: every guard report plus the environment metadata, with an
/// aggregate outcome that is INCONCLUSIVE if any guard is inconclusive.
class CostGuardSuite {
  const CostGuardSuite({required this.guards, required this.environment});

  final List<CostGuardReport> guards;
  final LoadEnvironment environment;

  /// green only if every guard is green; red if any is red; else inconclusive.
  GuardOutcome get aggregate {
    var sawInconclusive = false;
    for (final g in guards) {
      if (g.outcome == GuardOutcome.red) return GuardOutcome.red;
      if (g.outcome == GuardOutcome.inconclusive) sawInconclusive = true;
    }
    return sawInconclusive ? GuardOutcome.inconclusive : GuardOutcome.green;
  }

  bool get allPassed => aggregate == GuardOutcome.green;
}

/// Reads the 1-minute load average, or 0 when the platform does not expose one.
double readLoadAverage1m() {
  // Linux: /proc/loadavg — first field is the 1-minute average.
  try {
    final f = File('/proc/loadavg');
    if (f.existsSync()) {
      final first = f.readAsStringSync().split(RegExp(r'\s+')).first;
      final v = double.tryParse(first);
      if (v != null) return v;
    }
  } catch (_) {
    // fall through to sysctl
  }
  // macOS / BSD: sysctl vm.loadavg → "{ 1.87 2.42 2.53 }".
  try {
    final r = Process.runSync('sysctl', <String>['-n', 'vm.loadavg']);
    if (r.exitCode == 0) {
      final m = RegExp(r'[0-9]+(?:\.[0-9]+)?').firstMatch(r.stdout as String);
      if (m != null) {
        final v = double.tryParse(m.group(0)!);
        if (v != null) return v;
      }
    }
  } catch (_) {
    // no load reading available — caller treats 0 as "cannot prove overload"
  }
  return 0;
}

/// The per-core load budget from `COST_GUARD_MAX_LOAD_PER_CORE`, or
/// [defaultMaxLoadPerCore] when unset/invalid.
double maxLoadPerCoreFromEnv() {
  final raw = Platform.environment['COST_GUARD_MAX_LOAD_PER_CORE'];
  final v = double.tryParse(raw ?? '');
  if (v == null || v <= 0) return defaultMaxLoadPerCore;
  return v;
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

/// Shared CI headroom factor retained for the detail lines' "CI budget"
/// wording; the verdict itself is now decided by [decidePerformance] against
/// the nominal budget with a noise band, not a fixed multiple.
const int ciHeadroomFactor = 2;

/// Number of timed samples per wall-clock guard (robust median/MAD input).
const int sampleCount = 7;

/// How many times an inconclusive/slow measurement is retried before the guard
/// settles on a documented INCONCLUSIVE.
const int retryBudget = 3;

/// Runs [body] [iterations] times and returns the mean wall-clock cost per call
/// in nanoseconds.
int meanNanos(int iterations, void Function(int) body) {
  // Warm up so the JIT has tiered the hot path before we measure.
  for (var i = 0; i < 1000; i++) {
    body(i);
  }
  final sw = Stopwatch()..start();
  for (var i = 0; i < iterations; i++) {
    body(i);
  }
  sw.stop();
  return sw.elapsedMicroseconds * 1000 ~/ iterations;
}

/// Measures [measure] [sampleCount] times and decides a verdict, retrying an
/// inconclusive result up to [retryBudget] times. [loadAdmitted] forces an
/// inconclusive verdict when the host failed admission (measurements under
/// overload are not trustworthy).
PerformanceVerdict timedVerdict({
  required int budget,
  required bool loadAdmitted,
  required List<int> Function() collect,
}) {
  if (!loadAdmitted) {
    return PerformanceVerdict(
      outcome: PerformanceOutcome.inconclusive,
      median: 0,
      mad: 0,
      budget: budget,
      detail: 'host not admitted (overloaded) — INCONCLUSIVE',
    );
  }
  var verdict = decidePerformance(
    samples: collect(),
    budget: budget,
    maxMadsOverBudget: 3,
  );
  if (verdict.outcome == PerformanceOutcome.inconclusive) {
    withRetries(
      // attempt(0) is the initial sample (already collected above); the
      // remaining retryBudget attempts are the actual re-samples.
      maxAttempts: retryBudget + 1,
      attempt: (i) {
        if (i == 0) {
          return SampleVerdict.inconclusive; // first sample already in
        }
        final retry = decidePerformance(
          samples: collect(),
          budget: budget,
          maxMadsOverBudget: 3,
        );
        verdict = retry;
        return _outcomeToSample(retry.outcome);
      },
    );
  }
  return verdict;
}
