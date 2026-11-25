// Chord v2 in-memory cost guards (ISSUE-018, arrrrny/zorphy#193).
//
// The guard logic behind both CI entry points:
//
//   * `dart run benchmark/cost_guards_benchmark.dart` — the standalone gate the
//     issue's acceptance criterion names; exits non-zero when any guard is red.
//   * `test/benchmark/cost_guards_test.dart` — rides the existing `dart test`
//     CI step, so a regression fails the build even though the dedicated
//     `cost_guards` workflow job could not be committed (the lane's GitHub
//     credential lacks the `workflow` scope `.github/workflows/*` requires).
//
// Each guard measures the real emitted API shape — the same shapes the
// generator produces and the runtime fixtures under `test/runtime/fixtures/`
// pin byte-for-byte. The fixture classes below mirror that output; they are
// hand-shaped here only so the guards are a self-contained, runnable program.
// The `test/golden/*` suites are what pin the emitter to these shapes.
//
// The four guards (Section 2 of the issue):
//
//   1. Zero-copy reference identity — `copyWith` / `changeTo*` reuse the
//      untouched references (no deep clone of `tags`, `createdAt`, …).
//   2. No-op patch identity — `Patch.diff(e, e).apply(e)` returns the SAME
//      instance and runs in < 50 ns/call.
//   3. Polymorphic JSON-Pointer lens lookup — `resolvePath('/…')` resolves in
//      < 200 ns/lookup across 100_000 iterations, dispatching on the runtime
//      subtype.
//   4. Boundary validation throughput — `Entity.fromWire(validMap)` validates
//      10_000 polymorphic entities in < 30 ms.

import 'dart:io';

import 'package:zorphy_annotation/zorphy.dart';

// ---------------------------------------------------------------------------
// Guard 1 fixtures — a concrete entity with a reference-typed collection field
// (`tags`) and a `DateTime` (`createdAt`), plus a `changeTo*` morph that must
// reuse both references.
// ---------------------------------------------------------------------------

/// Stands in for the generated `@ZorphyEntity Product`: `tags` is a
/// `List<String>` and `createdAt` a `DateTime`, both reference-typed so a
/// zero-copy `copyWith` / morph can be proven with `identical`.
class Product {
  const Product({
    required this.id,
    required this.price,
    required this.tags,
    required this.createdAt,
  });

  final String id;
  final double price;
  final List<String> tags;
  final DateTime createdAt;

  /// Generated `copyWith`: an omitted argument keeps the current reference.
  Product copyWith({String? id, double? price, List<String>? tags}) {
    return Product(
      id: id ?? this.id,
      price: price ?? this.price,
      tags: tags ?? this.tags,
      createdAt: createdAt,
    );
  }

  /// A generated `changeTo*` morph (the polymorphic-patch shape): the fields it
  /// does not touch are carried by reference, never cloned.
  OrderNotification changeToPriceDropNotification({required double newPrice}) {
    return OrderNotification(
      id: id,
      price: newPrice,
      tags: tags,
      createdAt: createdAt,
    );
  }

  @override
  String toString() => 'Product(id: $id, price: $price)';
}

/// The polymorphic sibling the morph produces; carries the SAME `tags` and
/// `createdAt` references it was handed.
class OrderNotification {
  const OrderNotification({
    required this.id,
    required this.price,
    required this.tags,
    required this.createdAt,
  });

  final String id;
  final double price;
  final List<String> tags;
  final DateTime createdAt;
}

// ---------------------------------------------------------------------------
// Guard 2 fixtures — a concrete entity + its generated patch algebra
// (`diff` / `apply`), byte-identical to `PatchEmitter`'s output.
// ---------------------------------------------------------------------------

enum Product$ { id, price, tags }

class ProductPatch extends PatchBase<Product, Product$> {
  const ProductPatch.empty() : super.empty();

  ProductPatch() : super();

  /// The canonical empty patch: no change, no allocation (the O(1) neutral
  /// element `diff` returns for an identical pair).
  static const ProductPatch emptyPatch = ProductPatch.empty();

  bool get isEmpty => patchMap.isEmpty;

  Product apply(Product target) {
    if (isEmpty) return target;
    return target.copyWith(
      id: patchMap[Product$.id] as String?,
      price: patchMap[Product$.price] as double?,
      tags: patchMap[Product$.tags] as List<String>?,
    );
  }

  @override
  Product applyTo(Product entity) => apply(entity);

  @override
  ProductPatch compose(covariant ProductPatch next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    return ProductPatch()..patchMap.addAll(next.patchMap);
  }

  @override
  ProductPatch invert(Product before) {
    final undo = ProductPatch();
    if (patchMap.containsKey(Product$.id)) {
      undo.patchMap[Product$.id] = before.id;
    }
    if (patchMap.containsKey(Product$.price)) {
      undo.patchMap[Product$.price] = before.price;
    }
    if (patchMap.containsKey(Product$.tags)) {
      undo.patchMap[Product$.tags] = before.tags;
    }
    return undo;
  }

  @override
  Map<String, Object?> toWire() {
    final wire = <String, Object?>{};
    if (patchMap.containsKey(Product$.id)) wire['id'] = patchMap[Product$.id];
    if (patchMap.containsKey(Product$.price)) {
      wire['price'] = patchMap[Product$.price];
    }
    if (patchMap.containsKey(Product$.tags)) {
      wire['tags'] = patchMap[Product$.tags];
    }
    return wire;
  }

  /// Generated `diff`: an identical pair yields the canonical empty patch, and
  /// `apply` of an empty patch returns the target by reference.
  static ProductPatch diff(Product previous, Product next) {
    if (identical(previous, next)) return const ProductPatch.empty();
    final changes = ProductPatch();
    if (previous.id != next.id) changes.patchMap[Product$.id] = next.id;
    if (previous.price != next.price) {
      changes.patchMap[Product$.price] = next.price;
    }
    if (!identical(previous.tags, next.tags)) {
      changes.patchMap[Product$.tags] = next.tags;
    }
    return changes;
  }
}

// ---------------------------------------------------------------------------
// Guard 3 fixtures — a polymorphic hierarchy with a static `resolvePath` lens
// table (the `JsonPointerGenerator` shape). `resolvePath` is a compile-time
// switch over the class's own JSON-Pointer segments and dispatches on the
// runtime subtype.
// ---------------------------------------------------------------------------

sealed class UiNode {
  const UiNode();

  /// Generated static lens table: one switch step per segment, no mirrors.
  static ZorphyLens<UiNode, Object?>? resolvePath(String pointer) {
    switch (pointer) {
      case '/label':
        return ZorphyLens<UiNode, Object?>(
          path: '/label',
          get: (node) => node is ZfaButtonNode ? node.label : null,
          set: (node, value) => node is ZfaButtonNode
              ? node.copyWith(label: value as String)
              : node,
        );
      case '/enabled':
        return ZorphyLens<UiNode, Object?>(
          path: '/enabled',
          get: (node) => node is InteractiveUiNode ? node.enabled : null,
          set: (node, value) => node is InteractiveUiNode
              ? node.copyWith(enabled: value as bool)
              : node,
        );
      default:
        return null;
    }
  }
}

class InteractiveUiNode extends UiNode {
  const InteractiveUiNode({required this.enabled});

  final bool enabled;

  InteractiveUiNode copyWith({bool? enabled}) =>
      InteractiveUiNode(enabled: enabled ?? this.enabled);
}

class ZfaButtonNode extends InteractiveUiNode {
  const ZfaButtonNode({required super.enabled, required this.label});

  final String label;

  @override
  ZfaButtonNode copyWith({bool? enabled, String? label}) => ZfaButtonNode(
    enabled: enabled ?? this.enabled,
    label: label ?? this.label,
  );
}

/// A nested-draft state with its own `resolvePath`, exercising the
/// `/editDraft/price` composed-pointer shape from the issue.
class ProductUiState {
  const ProductUiState({required this.editDraft});

  final EditDraft editDraft;

  static ZorphyLens<ProductUiState, Object?>? resolvePath(String pointer) {
    switch (pointer) {
      case '/editDraft/price':
        return ZorphyLens<ProductUiState, Object?>(
          path: '/editDraft/price',
          get: (state) => state.editDraft.price,
          set: (state, value) => state.copyWith(
            editDraft: state.editDraft.copyWith(price: value as double),
          ),
        );
      default:
        return null;
    }
  }

  ProductUiState copyWith({EditDraft? editDraft}) =>
      ProductUiState(editDraft: editDraft ?? this.editDraft);
}

class EditDraft {
  const EditDraft({required this.price});

  final double price;

  EditDraft copyWith({double? price}) => EditDraft(price: price ?? this.price);
}

// ---------------------------------------------------------------------------
// Guard 4 fixtures — a polymorphic entity with a generated `fromWire` boundary
// codec that validates through a trusted constructor and accumulates
// violations instead of throwing.
// ---------------------------------------------------------------------------

sealed class Entity {
  const Entity();

  /// Generated polymorphic `fromWire`: dispatches on the discriminator and
  /// validates every field through total helpers (no `as`-cast).
  static ZorphyBoundaryResult<Entity> fromWire(Map<String, Object?> raw) {
    final kind = raw['kind'];
    switch (kind) {
      case 'product':
        return _productFromWire(raw);
      case 'order':
        return _orderFromWire(raw);
      default:
        return BoundaryErr<Entity>(
          targetType: 'Entity',
          violations: <FieldViolation>[
            FieldViolation(
              path: '/kind',
              expected: 'one of: product, order',
              actual: ZorphyPatchWire.describe(kind),
            ),
          ],
        );
    }
  }
}

class ProductEntity extends Entity {
  const ProductEntity({required this.id, required this.price});

  final String id;
  final double price;
}

class OrderEntity extends Entity {
  const OrderEntity({required this.id, required this.itemCount});

  final String id;
  final int itemCount;
}

ZorphyBoundaryResult<Entity> _productFromWire(Map<String, Object?> raw) {
  final violations = <FieldViolation>[];
  final id = ZorphyPatchWire.as<String>(raw['id'], '/id', violations);
  final price = ZorphyPatchWire.asDouble(raw['price'], '/price', violations);
  if (violations.isNotEmpty) {
    return BoundaryErr<Entity>(
      targetType: 'ProductEntity',
      violations: violations,
    );
  }
  return BoundaryOk<Entity>(ProductEntity(id: id!, price: price!));
}

ZorphyBoundaryResult<Entity> _orderFromWire(Map<String, Object?> raw) {
  final violations = <FieldViolation>[];
  final id = ZorphyPatchWire.as<String>(raw['id'], '/id', violations);
  final itemCount = ZorphyPatchWire.as<int>(
    raw['itemCount'],
    '/itemCount',
    violations,
  );
  if (violations.isNotEmpty) {
    return BoundaryErr<Entity>(
      targetType: 'OrderEntity',
      violations: violations,
    );
  }
  return BoundaryOk<Entity>(OrderEntity(id: id!, itemCount: itemCount!));
}

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

double _maxLoadPerCoreFromEnv() {
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
int _meanNanos(int iterations, void Function(int) body) {
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
PerformanceVerdict _timedVerdict({
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
        if (i == 0)
          return SampleVerdict.inconclusive; // first sample already in
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

/// Runs all four Chord v2 cost guards and returns the suite (every guard report
/// plus the environment metadata). Pure of network I/O; reads only the local
/// load average and CPU count so both the `dart run` entry and the test can
/// consume it.
CostGuardSuite evaluateCostGuards() {
  final cpuCount = Platform.numberOfProcessors;
  final load1m = readLoadAverage1m();
  final maxPerCore = _maxLoadPerCoreFromEnv();
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
    _guard1ZeroCopy(),
    _guard2NoOpPatch(load.admitted),
    _guard3PolymorphicResolvePath(load.admitted),
    _guard4BoundaryThroughput(load.admitted),
  ];
  return CostGuardSuite(guards: guards, environment: environment);
}

// Guard 1 — zero-copy reference identity (correctness only, no timing budget).
CostGuardReport _guard1ZeroCopy() {
  final tags = <String>['a', 'b', 'c'];
  final createdAt = DateTime.utc(2026, 11, 24, 12);
  final entity = Product(
    id: 'p1',
    price: 9.99,
    tags: tags,
    createdAt: createdAt,
  );

  final copied = entity.copyWith(price: 10.0);
  final tagsReused = identical(entity.tags, copied.tags);

  final notif = entity.changeToPriceDropNotification(newPrice: 19.99);
  final createdAtReused = identical(entity.createdAt, notif.createdAt);

  final ok = tagsReused && createdAtReused;
  return CostGuardReport(
    name: 'Guard 1: zero-copy reference identity',
    correctnessOk: ok,
    correctnessDetail:
        'copyWith reuses tags=$tagsReused, morph reuses createdAt=$createdAtReused',
    timing: PerformanceVerdict.greenSample,
  );
}

// Guard 2 — no-op patch identity + latency.
CostGuardReport _guard2NoOpPatch(bool loadAdmitted) {
  final e = Product(
    id: 'p1',
    price: 9.99,
    tags: const <String>['a'],
    createdAt: DateTime.utc(2026, 11, 24),
  );

  final noop = ProductPatch.diff(e, e).apply(e);
  final identityOk = identical(noop, e);

  const budgetNs = 50; // nominal; CI headroom is the noise band, not a multiple
  final timing = _timedVerdict(
    budget: budgetNs,
    loadAdmitted: loadAdmitted,
    collect: () => List<int>.generate(
      sampleCount,
      (_) => _meanNanos(50_000, (_) {
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
CostGuardReport _guard3PolymorphicResolvePath(bool loadAdmitted) {
  final button = ZfaButtonNode(enabled: true, label: 'ok');
  final state = ProductUiState(editDraft: const EditDraft(price: 1.0));

  // Correctness first: the lens resolves and dispatches on the runtime subtype.
  final enabledLens = UiNode.resolvePath('/enabled');
  final enabledOk = enabledLens?.get(button) == true;
  final priceLens = ProductUiState.resolvePath('/editDraft/price');
  final priceOk = priceLens?.get(state) == 1.0;

  const budgetNs = 200;
  final timing = _timedVerdict(
    budget: budgetNs,
    loadAdmitted: loadAdmitted,
    collect: () => List<int>.generate(sampleCount, (_) {
      final nanosButton = _meanNanos(50_000, (_) {
        UiNode.resolvePath('/enabled');
      });
      final nanosState = _meanNanos(50_000, (_) {
        ProductUiState.resolvePath('/editDraft/price');
      });
      return nanosButton > nanosState ? nanosButton : nanosState;
    }),
  );

  return CostGuardReport(
    name: 'Guard 3: polymorphic resolvePath (<200ns/lookup)',
    correctnessOk: enabledOk && priceOk,
    correctnessDetail: 'enabled=$enabledOk price=$priceOk',
    timing: timing,
  );
}

// Guard 4 — boundary validation throughput.
CostGuardReport _guard4BoundaryThroughput(bool loadAdmitted) {
  const total = 10_000;
  // Warm up both discriminator branches so `fromWire` is JIT-tiered before we
  // time it.
  for (var i = 0; i < 1000; i++) {
    Entity.fromWire(
      i.isEven
          ? <String, Object?>{'kind': 'product', 'id': 'w$i', 'price': 9.99}
          : <String, Object?>{'kind': 'order', 'id': 'w$i', 'itemCount': i},
    );
  }

  // Correctness is MANDATORY and runs regardless of timing/load: every entity
  // must validate. This is never skipped under overload (#237).
  var ok = 0;
  for (var i = 0; i < total; i++) {
    final raw = i.isEven
        ? <String, Object?>{'kind': 'product', 'id': 'c$i', 'price': 9.99}
        : <String, Object?>{'kind': 'order', 'id': 'c$i', 'itemCount': i};
    if (Entity.fromWire(raw) is BoundaryOk<Entity>) ok++;
  }
  final correctnessOk = ok == total;

  const budgetMs = 30; // nominal; the noise band supplies the headroom
  // Each timed sample is one full 10k validation pass, in milliseconds.
  final timing = _timedVerdict(
    budget: budgetMs,
    loadAdmitted: loadAdmitted,
    collect: () => List<int>.generate(sampleCount, (_) {
      final sw = Stopwatch()..start();
      for (var i = 0; i < total; i++) {
        final raw = i.isEven
            ? <String, Object?>{'kind': 'product', 'id': 'p$i', 'price': 9.99}
            : <String, Object?>{'kind': 'order', 'id': 'o$i', 'itemCount': i};
        Entity.fromWire(raw);
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
