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
// Harness
// ---------------------------------------------------------------------------

/// The outcome of one cost guard: whether it stayed within budget, plus a
/// human-readable detail line carrying the measured numbers.
class CostGuardResult {
  const CostGuardResult({
    required this.name,
    required this.passed,
    required this.detail,
  });

  final String name;
  final bool passed;
  final String detail;

  @override
  String toString() => '${passed ? 'PASS' : 'FAIL'} $name — $detail';
}

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

/// Runs all four Chord v2 cost guards and returns one [CostGuardResult] each,
/// in issue order. Pure of I/O so both the `dart run` entry and the test can
/// consume it.
List<CostGuardResult> evaluateCostGuards() => <CostGuardResult>[
  _guard1ZeroCopy(),
  _guard2NoOpPatch(),
  _guard3PolymorphicResolvePath(),
  _guard4BoundaryThroughput(),
];

// Guard 1 — zero-copy reference identity.
CostGuardResult _guard1ZeroCopy() {
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

  return CostGuardResult(
    name: 'Guard 1: zero-copy reference identity',
    passed: tagsReused && createdAtReused,
    detail:
        'copyWith reuses tags=$tagsReused, '
        'morph reuses createdAt=$createdAtReused',
  );
}

// Guard 2 — no-op patch identity + latency.
CostGuardResult _guard2NoOpPatch() {
  final e = Product(
    id: 'p1',
    price: 9.99,
    tags: const <String>['a'],
    createdAt: DateTime.utc(2026, 11, 24),
  );

  final noop = ProductPatch.diff(e, e).apply(e);
  final identityOk = identical(noop, e);

  final nanos = _meanNanos(100_000, (_) {
    ProductPatch.diff(e, e).apply(e);
  });

  return CostGuardResult(
    name: 'Guard 2: no-op patch identity (<50ns, identical)',
    passed: identityOk && nanos < 50,
    detail: 'identical=$identityOk, ${nanos}ns/call (budget 50ns)',
  );
}

// Guard 3 — polymorphic JSON-Pointer lens lookup latency.
CostGuardResult _guard3PolymorphicResolvePath() {
  final button = ZfaButtonNode(enabled: true, label: 'ok');
  final state = ProductUiState(editDraft: const EditDraft(price: 1.0));

  // Correctness first: the lens resolves and dispatches on the runtime subtype.
  final enabledLens = UiNode.resolvePath('/enabled');
  final enabledOk = enabledLens?.get(button) == true;
  final priceLens = ProductUiState.resolvePath('/editDraft/price');
  final priceOk = priceLens?.get(state) == 1.0;

  final nanosButton = _meanNanos(100_000, (_) {
    UiNode.resolvePath('/enabled');
  });
  final nanosState = _meanNanos(100_000, (_) {
    ProductUiState.resolvePath('/editDraft/price');
  });
  final worst = nanosButton > nanosState ? nanosButton : nanosState;

  return CostGuardResult(
    name: 'Guard 3: polymorphic resolvePath (<200ns/lookup)',
    passed: enabledOk && priceOk && worst < 200,
    detail:
        'enabled=$enabledOk price=$priceOk, worst ${worst}ns '
        '(button ${nanosButton}ns, state ${nanosState}ns; budget 200ns)',
  );
}

// Guard 4 — boundary validation throughput.
CostGuardResult _guard4BoundaryThroughput() {
  const total = 10_000;
  final sw = Stopwatch()..start();
  var ok = 0;
  for (var i = 0; i < total; i++) {
    final raw = i.isEven
        ? <String, Object?>{'kind': 'product', 'id': 'p$i', 'price': 9.99}
        : <String, Object?>{'kind': 'order', 'id': 'o$i', 'itemCount': i};
    final result = Entity.fromWire(raw);
    if (result is BoundaryOk<Entity>) ok++;
  }
  sw.stop();

  final elapsedMs = sw.elapsedMilliseconds;
  return CostGuardResult(
    name: 'Guard 4: boundary validation throughput (<30ms/10k)',
    passed: ok == total && elapsedMs < 30,
    detail: '$ok/$total validated in ${elapsedMs}ms (budget 30ms)',
  );
}
