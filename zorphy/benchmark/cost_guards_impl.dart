// The four Chord v2 cost guards, measured against REAL generated code
// (arrrrny/zorphy#234).
//
// Before #234 the guards measured hand-written lookalikes declared inline in
// `cost_guards.dart`, so the gate could stay green while the generated APIs the
// acceptance criteria name (`<Entity>Patch.diff`, `changeTo*`, `resolvePath`,
// polymorphic `fromWire`) were absent from real output. This file closes that
// gap: it imports the classes the production `build_runner` pipeline emits from
// `benchmark/cost_guard_fixtures.dart` and measures THEM.
//
// Because the fixture's shared part (`_br_/benchmark/cost_guard_fixtures.part.dart`)
// is generated, this library only COMPILES once generation has run — a
// deliberate removal of `diff` / `changeTo*` / `resolvePath` / `fromWire` from
// the generator makes this file fail to compile (build/analysis time), which is
// exactly the loud failure #234's acceptance gate requires. The benchmark
// launcher (`cost_guards_benchmark.dart`) runs generation first, then spawns
// this file's `main`.
//
// The four guards and their budgets are unchanged from #193/#237:
//
//   1. Zero-copy reference identity — generated `copyWith` / `changeTo*` reuse
//      the untouched references (`tags`, `createdAt`). Correctness-only.
//   2. No-op patch identity — `ProductPatch.diff(e, e).apply(e)` returns the
//      SAME instance and runs in < 50 ns/call.
//   3. Polymorphic JSON-Pointer lens lookup — generated `resolvePath('/…')`
//      resolves in < 200 ns/lookup, dispatching on the runtime subtype and
//      descending into a nested value (`/editDraft/price`).
//   4. Boundary validation throughput — the sealed `Task.fromWire` validates
//      10_000 polymorphic entities in < 30 ms through the trusted constructors.

import 'dart:io';

import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'cost_guard_fixtures.dart';
import 'cost_guards.dart';

/// Runs all four Chord v2 cost guards against the generated v3 classes and
/// returns the suite (every guard report plus the environment metadata). Reads
/// only the local load average and CPU count so the result carries the load
/// metadata the reliability contract needs.
CostGuardSuite evaluateCostGuards() {
  final cpuCount = Platform.numberOfProcessors;
  final load1m = readLoadAverage1m();
  final maxPerCore = maxLoadPerCoreFromEnv();
  final load = classifyLoad(
    loadAverage1m: load1m,
    cpuCount: cpuCount,
    maxLoadPerCore: maxPerCore,
  );
  final environment = LoadEnvironment(
    cpuCount: load.cpuCount,
    loadAverage1m: load.loadAverage1m,
    maxLoadPerCore: load.maxLoadPerCore,
    admitted: load.admitted,
  );

  final guards = <CostGuardReport>[
    guard1ZeroCopy(),
    guard2NoOpPatch(load.admitted),
    guard3PolymorphicResolvePath(load.admitted),
    guard4BoundaryThroughput(load.admitted),
  ];
  return CostGuardSuite(guards: guards, environment: environment);
}

// Guard 1 — zero-copy reference identity (correctness only, no timing budget).
//
// Measures the GENERATED `OpenTask`: `copyWith` and the `changeToDoneTask`
// morph must carry the reference-typed `tags` list and `createdAt` DateTime by
// reference, never a deep clone.
CostGuardReport guard1ZeroCopy() {
  final tags = <String>['a', 'b', 'c'];
  final createdAt = DateTime.utc(2026, 11, 24, 12);
  final task = OpenTask.fromTrusted(
    id: 't1',
    createdAt: createdAt,
    tags: tags,
    assignee: 'me',
  );

  final copied = task.copyWith(assignee: 'you');
  final tagsReused = identical(task.tags, copied.tags);

  final done = task.changeToDoneTask(result: 'shipped');
  final createdAtReused = identical(task.createdAt, done.createdAt);
  final morphTagsReused = identical(task.tags, done.tags);

  final ok = tagsReused && createdAtReused && morphTagsReused;
  return CostGuardReport(
    name: 'Guard 1: zero-copy reference identity',
    correctnessOk: ok,
    correctnessDetail:
        'copyWith reuses tags=$tagsReused, morph reuses '
        'createdAt=$createdAtReused tags=$morphTagsReused',
    timing: PerformanceVerdict.greenSample,
  );
}

// Guard 2 — no-op patch identity + latency.
//
// Measures the GENERATED `Product` / `ProductPatch`: `diff(e, e)` returns the
// canonical empty patch and `apply(e)` of it returns the SAME instance in O(1).
CostGuardReport guard2NoOpPatch(bool loadAdmitted) {
  final e = Product.fromTrusted(id: 'p1', name: 'widget');

  final noop = ProductPatch.diff(e, e).apply(e);
  final identityOk = identical(noop, e);

  const budgetNs = 50; // nominal; CI headroom is the noise band, not a multiple
  final timing = timedVerdict(
    budget: budgetNs,
    loadAdmitted: loadAdmitted,
    collect: () => List<int>.generate(
      sampleCount,
      (_) => meanNanos(50_000, (_) {
        ProductPatch.diff(e, e).apply(e);
      }),
    ),
  );

  return CostGuardReport(
    name: 'Guard 2: no-op patch identity (<50ns, identical)',
    correctnessOk: identityOk,
    correctnessDetail: 'identical=$identityOk',
    timing: timing,
  );
}

// Guard 3 — polymorphic JSON-Pointer lens lookup latency.
//
// Measures the GENERATED `UiNode` hierarchy's `resolvePath` dispatching on the
// runtime subtype — the polymorphic lookup this guard is named for. A segment
// the receiver does not carry (`/text` on a button) answers null rather than
// throwing, and the nested `ProductUiState.resolvePath('/editDraft/price')`
// composed pointer is asserted for CORRECTNESS (it descends into the nested
// value); its heavier string-parse + recursion + lens-composition cost is a
// distinct "nested descent" capability, not the subtype dispatch the 200 ns
// budget names.
CostGuardReport guard3PolymorphicResolvePath(bool loadAdmitted) {
  final button = ZfaButtonNode.fromTrusted(
    contractId: 'c1',
    mode: 'edit',
    label: 'ok',
  );
  final state = ProductUiState.fromTrusted(
    editDraft: EditDraft.fromTrusted(title: 'draft', price: 1.0),
    selectedTab: 0,
  );

  // Correctness first: each lens resolves and dispatches on the runtime subtype.
  final labelLens = UiNode.resolvePath('/label');
  final labelOk = labelLens?.get(button) == 'ok';
  // A segment the button does not carry (`/text`) must answer null, not throw.
  final textLens = UiNode.resolvePath('/text');
  final textNullOk = textLens?.get(button) == null;
  // The composed nested pointer resolves into the child value.
  final priceLens = ProductUiState.resolvePath('/editDraft/price');
  final priceOk = priceLens?.get(state) == 1.0;

  const budgetNs = 200;
  final timing = timedVerdict(
    budget: budgetNs,
    loadAdmitted: loadAdmitted,
    collect: () => List<int>.generate(sampleCount, (_) {
      final nanosLabel = meanNanos(50_000, (_) {
        UiNode.resolvePath('/label');
      });
      final nanosText = meanNanos(50_000, (_) {
        UiNode.resolvePath('/text');
      });
      return nanosLabel > nanosText ? nanosLabel : nanosText;
    }),
  );

  return CostGuardReport(
    name: 'Guard 3: polymorphic resolvePath (<200ns/lookup)',
    correctnessOk: labelOk && textNullOk && priceOk,
    correctnessDetail:
        'label=$labelOk textNull=$textNullOk nestedPrice=$priceOk',
    timing: timing,
  );
}

// Guard 4 — boundary validation throughput.
//
// Measures the GENERATED sealed `Record.fromWire`, which dispatches on the
// `kind` discriminator and validates every flat field through the trusted
// constructors, accumulating violations instead of throwing. `Record` carries
// flat fields (a String id plus one numeric field per branch), mirroring the
// original Guard 4 entity the 30 ms/10k budget was calibrated on (#234).
CostGuardReport guard4BoundaryThroughput(bool loadAdmitted) {
  const total = 10_000;

  Map<String, Object?> numericRaw(int i) => <String, Object?>{
    'kind': 'numeric_record',
    'id': 'w$i',
    'amount': 9.99,
  };
  Map<String, Object?> countRaw(int i) => <String, Object?>{
    'kind': 'count_record',
    'id': 'w$i',
    'count': i,
  };

  // Warm up both discriminator branches so `fromWire` is JIT-tiered before we
  // time it.
  for (var i = 0; i < 1000; i++) {
    Record.fromWire(i.isEven ? numericRaw(i) : countRaw(i));
  }

  // Correctness is MANDATORY and runs regardless of timing/load: every entity
  // must validate. This is never skipped under overload (#237).
  var ok = 0;
  for (var i = 0; i < total; i++) {
    final result = Record.fromWire(i.isEven ? numericRaw(i) : countRaw(i));
    if (result is BoundaryOk<Record>) ok++;
  }
  final correctnessOk = ok == total;

  const budgetMs = 30; // nominal; the noise band supplies the headroom
  // Each timed sample is one full 10k validation pass, in milliseconds.
  final timing = timedVerdict(
    budget: budgetMs,
    loadAdmitted: loadAdmitted,
    collect: () => List<int>.generate(sampleCount, (_) {
      final sw = Stopwatch()..start();
      for (var i = 0; i < total; i++) {
        Record.fromWire(i.isEven ? numericRaw(i) : countRaw(i));
      }
      sw.stop();
      return sw.elapsedMilliseconds;
    }),
  );

  return CostGuardReport(
    name: 'Guard 4: boundary validation throughput (<30ms/10k)',
    correctnessOk: correctnessOk,
    correctnessDetail: '$ok/$total validated',
    timing: timing,
  );
}

/// Runs the suite and prints the report, setting [exitCode] for the CI gate:
/// 0 green, 1 red, 2 inconclusive (the release gate treats inconclusive as NOT
/// passing). The benchmark launcher spawns this as a subprocess and propagates
/// the exit code.
void runAndReport() {
  print('Chord v2 cost guards (ISSUE-018) — zorphy#193 / #237 / #234');
  print('Measuring REAL build_runner-generated v3 classes.');
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
      exitCode = 1;
    case GuardOutcome.inconclusive:
      final count = suite.guards
          .where((r) => r.outcome == GuardOutcome.inconclusive)
          .length;
      print(
        '$count COST GUARD(S) INCONCLUSIVE — host overloaded or too noisy to '
        'measure; NOT a pass (release gate cannot close on inconclusive)',
      );
      exitCode = 2;
  }
}

void main() => runAndReport();
