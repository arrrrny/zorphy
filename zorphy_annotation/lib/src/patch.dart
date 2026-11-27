import 'equality.dart';

/// Deep structural equality for lists of patch items, used by
/// [ListReplaceAll.operator ==].
final _listEquality = const ListEquality<Object?>();

/// Deep structural equality for maps of patch entries, used by
/// [MapReplaceAll.operator ==].
final _mapEquality = const MapEquality<Object?, Object?>();

/// Patch interface for Zorphy code generation
///
/// This is used by generated Patch classes to provide a common interface
/// for partial updates to objects.
abstract class Patch<T> {
  /// Applies this patch to the given entity
  T applyTo(T entity);

  /// Creates a patch from a JSON map
  static Patch<T> fromJson<T>(Map<String, dynamic> json) {
    throw UnimplementedError(
      'fromJson must be implemented by generated Patch classes',
    );
  }
}

/// A partial update of a value of type [T] — the v3 patch contract.
///
/// A patch is a *value*: it holds the field changes to apply, knows whether it
/// carries any change at all, can be chained with another patch of the same
/// [T], can be turned back into the patch that undoes it, and can be rendered
/// as a wire map. Generated `<Name>Patch` classes implement this interface
/// (ISSUE-007); the sealed field-level shapes it composes with — [PatchValue],
/// [PatchNested], [ListPatchOp], [MapPatchOp] — live in this same library.
///
/// ## Algebraic laws
///
/// An implementation is expected to satisfy the following laws. They are the
/// contract consumers (draft coalescing, undo, transport) rely on, and they are
/// stated extensionally — two patches are the same when they agree on every
/// input, not when their fields match.
///
/// - **Identity.** There is an empty patch (`isEmpty == true`) that is the
///   neutral element of [compose]: `empty.compose(p)` and `p.compose(empty)`
///   both behave like `p`.
/// - **Associativity of [compose].** For patches `a`, `b`, `c` of the same
///   [T]: `(a.compose(b)).compose(c)` and `a.compose(b.compose(c))` behave
///   alike.
/// - **Composition order.** [compose] threads left to right:
///   `(a.compose(b)).apply(x) == b.apply(a.apply(x))`.
/// - **Invert round-trip.** [invert] captures what it needs from the value it
///   is handed: `p.invert(x).apply(p.apply(x)) == x`.
/// - **Empty is a zero-copy no-op.** When [isEmpty] is true, [apply] returns
///   the target itself (`identical`), so a caller can skip the update.
///
/// [compose] takes its argument covariantly so an implementation may narrow it
/// to its own patch type — a generated `ProductPatch` composes
/// `ProductPatch`s and keeps its static type through the chain.
abstract interface class ZorphyPatch<T> {
  /// Whether this patch carries no change at all.
  ///
  /// An empty patch must be a zero-copy no-op: [apply] returns the target
  /// itself.
  bool get isEmpty;

  /// Whether this patch carries at least one change.
  bool get isNotEmpty => !isEmpty;

  /// Returns [target] with this patch applied.
  ///
  /// The target is never mutated.
  T apply(T target);

  /// Returns the patch that applies this patch first and then [next].
  ///
  /// The result satisfies the composition law
  /// `apply(x) == next.apply(apply(x))`.
  ZorphyPatch<T> compose(covariant ZorphyPatch<T> next);

  /// Returns the patch that undoes this one for a value that was [before].
  ///
  /// Implementations capture whatever prior state they need from [before], so
  /// the round-trip `invert(x).apply(p.apply(x)) == x` holds.
  ZorphyPatch<T> invert(T before);

  /// The wire form of this patch: the field changes it carries, keyed by the
  /// field name they belong to.
  Map<String, Object?> toWire();
}

extension ZorphyPatchAlgebra<T> on ZorphyPatch<T> {
  /// Top-level JSON pointers changed by this patch.
  Set<String> get changedPaths => toWire().keys.map((key) => '/$key').toSet();

  /// The exact intersection of this patch's and [other]'s changed paths.
  Set<String> conflictingPaths(ZorphyPatch<T> other) =>
      changedPaths.intersection(other.changedPaths);

  /// Three-way name for [compose], with the same left-to-right semantics.
  ZorphyPatch<T> composePatches(ZorphyPatch<T> next) => compose(next);
}

/// A single field's contribution to a patch: either "leave it alone" or
/// "set it to this value".
///
/// Sealed, so a `switch` over it is exhaustive — the shape a generated patch
/// emits per field. `unchanged` is the default for a field a patch does not
/// touch, which is what keeps an untouched field out of [ZorphyPatch.toWire].
///
/// ```dart
/// switch (patch.name) {
///   case PatchUnchanged<String>():
///     break; // keep the target's value
///   case PatchSet<String>(:final value):
///     target = target.copyWith(name: value);
/// }
/// ```
sealed class PatchValue<V> {
  const PatchValue();

  /// The field is not part of this patch.
  const factory PatchValue.unchanged() = PatchUnchanged<V>;

  /// The field is set to [value] by this patch.
  const factory PatchValue.set(V value) = PatchSet<V>;

  /// Whether this value leaves the field alone.
  bool get isUnchanged => this is PatchUnchanged<V>;

  /// Whether this value sets the field.
  bool get isSet => this is PatchSet<V>;

  /// The value this patch sets, or `null` when [isUnchanged].
  ///
  /// A set value is allowed to be `null` itself — [isSet] is what tells the
  /// two cases apart.
  V? get valueOrNull => switch (this) {
    PatchUnchanged<V>() => null,
    PatchSet<V>(:final value) => value,
  };

  /// Bridges both shapes to a result of type [R]: [onUnchanged] for
  /// [PatchUnchanged], [onSet] with the value for [PatchSet].
  R fold<R>(R Function() onUnchanged, R Function(V value) onSet) =>
      switch (this) {
        PatchUnchanged<V>() => onUnchanged(),
        PatchSet<V>(:final value) => onSet(value),
      };
}

/// The `unchanged` [PatchValue]: the field is left as it is.
final class PatchUnchanged<V> extends PatchValue<V> {
  const PatchUnchanged();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchUnchanged<V> && runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'PatchValue<$V>.unchanged()';
}

/// The `set` [PatchValue]: the field takes [value].
final class PatchSet<V> extends PatchValue<V> {
  const PatchSet(this.value);

  /// The value this patch sets. It may be `null` for a nullable field.
  final V value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchSet<V> &&
          runtimeType == other.runtimeType &&
          other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PatchValue<$V>.set($value)';
}

/// A patch for one nested field of a parent patch: it carries the patch that
/// applies to the nested value instead of the nested value itself.
///
/// [Sub] is the nested value's type and [SubPatch] the patch type applied to
/// it; the bound `SubPatch extends ZorphyPatch<Sub>` is what lets a parent
/// patch declare a precise nested patch type and still treat the field as an
/// ordinary [ZorphyPatch] of the nested value. Every member delegates to
/// [patch], so a nested patch composes, inverts and renders exactly like the
/// patch it wraps.
///
/// It also implements the legacy [Patch] surface, because that is the arm a
/// generated `patchWith` resolves a carried field through: the parent patch
/// puts one of these in its field map and the entity applies it to its own
/// sub-value (ISSUE-008).
final class PatchNested<Sub, SubPatch extends ZorphyPatch<Sub>>
    implements ZorphyPatch<Sub>, Patch<Sub> {
  const PatchNested(this.patch);

  /// The patch applied to the nested value.
  final SubPatch patch;

  @override
  bool get isEmpty => patch.isEmpty;

  @override
  bool get isNotEmpty => patch.isNotEmpty;

  @override
  Sub apply(Sub target) => patch.apply(target);

  /// The legacy [Patch] entry point: same behaviour as [apply].
  @override
  Sub applyTo(Sub entity) => apply(entity);

  /// Composes exactly like the wrapped patch: a [next] that is itself a
  /// [PatchNested] of the same [Sub] is unwrapped first, so a delegate
  /// narrowing [compose]'s parameter to its own patch type still receives a
  /// patch of that type instead of the wrapper.
  @override
  ZorphyPatch<Sub> compose(ZorphyPatch<Sub> next) => patch.compose(
    next is PatchNested<Sub, ZorphyPatch<Sub>> ? next.patch : next,
  );

  /// Composes another carry of the same nested field, keeping THIS wrapper's
  /// static type parameters.
  ///
  /// A generated patch's `compose` narrows its result to the concrete nested
  /// patch, so the cast is safe for generated carries; preserving the type
  /// matters because generated `invert` narrows the carry back to
  /// `PatchNested<Sub, SubPatch>`.
  PatchNested<Sub, SubPatch> composeNested(
    covariant PatchNested<Sub, SubPatch> next,
  ) => PatchNested<Sub, SubPatch>(patch.compose(next.patch) as SubPatch);

  @override
  ZorphyPatch<Sub> invert(Sub before) => patch.invert(before);

  /// The inverse as a nested patch of the same shape.
  ///
  /// The inner patch narrows its own `invert` covariantly (a generated
  /// `<Sub>Patch` returns a `<Sub>Patch`), but [PatchNested] cannot require
  /// that of an arbitrary [SubPatch], so the inverse is carried as a
  /// [ZorphyPatch] of [Sub]. It stays a [PatchNested] — and therefore still
  /// resolves through the legacy [Patch] arm — whatever the inner patch
  /// returns.
  PatchNested<Sub, ZorphyPatch<Sub>> invertNested(Sub before) =>
      PatchNested<Sub, ZorphyPatch<Sub>>(patch.invert(before));

  @override
  Map<String, Object?> toWire() => patch.toWire();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatchNested<Sub, SubPatch> &&
          runtimeType == other.runtimeType &&
          other.patch == patch;

  @override
  int get hashCode => patch.hashCode;

  @override
  String toString() => 'PatchNested<$Sub, $SubPatch>($patch)';
}

/// One operation on a list field of a patch.
///
/// Sealed, so a `switch` over it is exhaustive. A list is edited
/// operationally rather than by whole-value assignment so a burst of small
/// edits stays cheap and readable on the wire.
///
/// Every variant returns a fresh list; [apply] never mutates its target.
sealed class ListPatchOp<E> {
  const ListPatchOp();

  /// Replaces the whole list with [items].
  const factory ListPatchOp.replaceAll(List<E> items) = ListReplaceAll<E>;

  /// Appends [item] at the end.
  const factory ListPatchOp.append(E item) = ListAppend<E>;

  /// Removes the item at [index], as a [RangeError] when it is out of range.
  const factory ListPatchOp.removeAt(int index) = ListRemoveAt<E>;

  /// Replaces the item at [index], as a [RangeError] when it is out of range.
  const factory ListPatchOp.updateAt(int index, E item) = ListUpdateAt<E>;

  /// Applies this operation to [target] and returns the resulting list.
  ///
  /// [target] is never mutated.
  List<E> apply(List<E> target);
}

/// Replaces the whole list. [items] is held as given — a `const` op cannot copy
/// it — so a caller that keeps mutating the list it passed in would see the
/// change.
final class ListReplaceAll<E> extends ListPatchOp<E> {
  const ListReplaceAll(this.items);

  final List<E> items;

  @override
  List<E> apply(List<E> _) => List<E>.of(items);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListReplaceAll<E> &&
          runtimeType == other.runtimeType &&
          _listEquality.equals(other.items, items);

  @override
  int get hashCode => Object.hashAll(items);

  @override
  String toString() => 'ListPatchOp<$E>.replaceAll($items)';
}

/// Appends one item.
final class ListAppend<E> extends ListPatchOp<E> {
  const ListAppend(this.item);

  final E item;

  @override
  List<E> apply(List<E> target) => <E>[...target, item];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListAppend<E> &&
          runtimeType == other.runtimeType &&
          other.item == item;

  @override
  int get hashCode => item.hashCode;

  @override
  String toString() => 'ListPatchOp<$E>.append($item)';
}

/// Removes the item at [index].
final class ListRemoveAt<E> extends ListPatchOp<E> {
  const ListRemoveAt(this.index);

  final int index;

  @override
  List<E> apply(List<E> target) => List<E>.of(target)..removeAt(index);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListRemoveAt<E> &&
          runtimeType == other.runtimeType &&
          other.index == index;

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'ListPatchOp<$E>.removeAt($index)';
}

/// Replaces the item at [index].
final class ListUpdateAt<E> extends ListPatchOp<E> {
  const ListUpdateAt(this.index, this.item);

  final int index;
  final E item;

  @override
  List<E> apply(List<E> target) => List<E>.of(target)..[index] = item;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListUpdateAt<E> &&
          runtimeType == other.runtimeType &&
          other.index == index &&
          other.item == item;

  @override
  int get hashCode => Object.hash(index, item);

  @override
  String toString() => 'ListPatchOp<$E>.updateAt($index, $item)';
}

/// One operation on a map field of a patch — the key-keyed counterpart of
/// [ListPatchOp].
///
/// Sealed, so a `switch` over it is exhaustive. A map is edited by key rather
/// than by whole-value assignment for the same reason a list is edited
/// operationally: a burst of small edits stays cheap and readable on the wire.
///
/// [MapPut] is also the update: setting a key that already exists overwrites
/// it, so no separate update variant is needed.
///
/// Every variant returns a fresh map; [apply] never mutates its target.
sealed class MapPatchOp<K, V> {
  const MapPatchOp();

  /// Replaces the whole map with [entries].
  const factory MapPatchOp.replaceAll(Map<K, V> entries) = MapReplaceAll<K, V>;

  /// Sets [key] to [value], inserting it when absent and overwriting it when
  /// present.
  const factory MapPatchOp.put(K key, V value) = MapPut<K, V>;

  /// Removes [key], and is a no-op when the key is absent.
  const factory MapPatchOp.remove(K key) = MapRemove<K, V>;

  /// Applies this operation to [target] and returns the resulting map.
  ///
  /// [target] is never mutated.
  Map<K, V> apply(Map<K, V> target);
}

/// Replaces the whole map. [entries] is held as given — a `const` op cannot
/// copy it — so a caller that keeps mutating the map it passed in would see the
/// change.
final class MapReplaceAll<K, V> extends MapPatchOp<K, V> {
  const MapReplaceAll(this.entries);

  final Map<K, V> entries;

  @override
  Map<K, V> apply(Map<K, V> _) => Map<K, V>.of(entries);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapReplaceAll<K, V> &&
          runtimeType == other.runtimeType &&
          _mapEquality.equals(other.entries, entries);

  @override
  int get hashCode => _mapEquality.hash(entries);

  @override
  String toString() => 'MapPatchOp<$K, $V>.replaceAll($entries)';
}

/// Sets one key.
final class MapPut<K, V> extends MapPatchOp<K, V> {
  const MapPut(this.key, this.value);

  final K key;
  final V value;

  @override
  Map<K, V> apply(Map<K, V> target) => Map<K, V>.of(target)..[key] = value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPut<K, V> &&
          runtimeType == other.runtimeType &&
          other.key == key &&
          other.value == value;

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() => 'MapPatchOp<$K, $V>.put($key, $value)';
}

/// Removes one key.
final class MapRemove<K, V> extends MapPatchOp<K, V> {
  const MapRemove(this.key);

  final K key;

  @override
  Map<K, V> apply(Map<K, V> target) => Map<K, V>.of(target)..remove(key);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapRemove<K, V> &&
          runtimeType == other.runtimeType &&
          other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'MapPatchOp<$K, $V>.remove($key)';
}

/// An ordered sequence of [ListPatchOp] steps — the collection-delta half of
/// the patch algebra (ISSUE-008).
///
/// A list field is patched operationally rather than by whole-value
/// assignment, so a burst of small edits stays cheap and readable on the wire.
/// The delta implements the same algebra the generated `<Name>Patch` classes
/// do, which makes it composable with them and — through the legacy [Patch]
/// surface — applicable by a generated `patchWith` exactly like a patch.
///
/// ## Laws
///
/// - **Minimal diff.** [diff] carries no op for two content-equal lists, and an
///   append tail, a removal tail and an in-place edit each become the single
///   [ListPatchOp] that expresses them.
/// - **No mutation.** [apply] folds the ops in order and returns a fresh list.
/// - **Composition.** [compose] concatenates, so
///   `(a.compose(b)).apply(x) == b.apply(a.apply(x))`.
/// - **Invert round-trip.** `d.invert(x).apply(d.apply(x)) == x`.
final class ListPatchDelta<E> implements ZorphyPatch<List<E>>, Patch<List<E>> {
  /// Creates a delta over [ops], applied in order.
  const ListPatchDelta(this.ops);

  /// The empty delta: no operation, no change.
  ///
  /// Not `const`: a type variable may not appear in a const expression, and
  /// the canonical empty ops list is what makes this allocation-free anyway.
  ListPatchDelta.empty() : ops = const <ListPatchOp<Never>>[];

  /// The steps this delta applies, in order.
  final List<ListPatchOp<E>> ops;

  /// The smallest delta that turns [previous] into [next].
  ///
  /// Identical and content-equal lists carry no op. A changed tail is an
  /// append (per added item) or a removal (per removed item, from the end);
  /// a same-length list with changed positions is one updateAt per position.
  /// A structural change between unchanged neighbours falls back to a single
  /// replaceAll — the op vocabulary has no insertion, so nothing finer is
  /// expressible.
  ///
  /// A static member cannot see the class's type variables, so `diff` declares
  /// its own — the caller supplies them from the two lists it passes in. This
  /// matches the generic `<Name>Patch.diff` shape (ISSUE-007).
  static ListPatchDelta<E> diff<E>(List<E> previous, List<E> next) {
    // Type variables are never const-eligible, so the empty delta is built
    // rather than `const`; its `ops` list is the canonical const one.
    final empty = ListPatchDelta<E>.empty();
    if (identical(previous, next)) return empty;
    if (previous.length == next.length &&
        _listEquality.equals(previous, next)) {
      return empty;
    }

    final shortest = previous.length < next.length
        ? previous.length
        : next.length;
    var prefix = 0;
    while (prefix < shortest && previous[prefix] == next[prefix]) {
      prefix++;
    }

    // Pure append: every previous item survives at the same position.
    if (prefix == previous.length && next.length > previous.length) {
      return ListPatchDelta<E>(<ListPatchOp<E>>[
        for (var i = prefix; i < next.length; i++)
          ListPatchOp<E>.append(next[i]),
      ]);
    }

    // Pure removal of the tail: drop from the end so every index stays valid.
    if (prefix == next.length && previous.length > next.length) {
      return ListPatchDelta<E>(<ListPatchOp<E>>[
        for (var i = previous.length - 1; i >= next.length; i--)
          ListPatchOp<E>.removeAt(i),
      ]);
    }

    // Same shape: a positional edit per changed position.
    if (previous.length == next.length) {
      final ops = <ListPatchOp<E>>[];
      for (var i = 0; i < next.length; i++) {
        if (previous[i] != next[i])
          ops.add(ListPatchOp<E>.updateAt(i, next[i]));
      }
      return ops.isEmpty ? empty : ListPatchDelta<E>(ops);
    }

    return ListPatchDelta<E>(<ListPatchOp<E>>[
      ListPatchOp<E>.replaceAll(List<E>.of(next)),
    ]);
  }

  @override
  bool get isEmpty => ops.isEmpty;

  @override
  bool get isNotEmpty => ops.isNotEmpty;

  @override
  List<E> apply(List<E> target) {
    if (isEmpty) return target;
    var result = target;
    for (final op in ops) {
      result = op.apply(result);
    }
    return result;
  }

  /// The legacy [Patch] entry point: same behaviour as [apply].
  @override
  List<E> applyTo(List<E> entity) => apply(entity);

  @override
  ListPatchDelta<E> compose(covariant ListPatchDelta<E> next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    return ListPatchDelta<E>(<ListPatchOp<E>>[...ops, ...next.ops]);
  }

  /// The delta that restores [before].
  ///
  /// The ops are positional, so a positional inverse would have to replay
  /// intermediate list states this delta does not carry. Restoring the prior
  /// list wholesale is the one shape that is correct for every composition,
  /// which is why the inverse is a single replaceAll rather than the mirror of
  /// each step.
  @override
  ListPatchDelta<E> invert(List<E> before) {
    if (isEmpty) return ListPatchDelta<E>.empty();
    return ListPatchDelta<E>(<ListPatchOp<E>>[
      ListPatchOp<E>.replaceAll(List<E>.of(before)),
    ]);
  }

  @override
  Map<String, Object?> toWire() => <String, Object?>{
    'ops': <Object?>[
      for (final op in ops)
        switch (op) {
          ListReplaceAll<E>(:final items) => <String, Object?>{
            'op': 'replaceAll',
            'items': items,
          },
          ListAppend<E>(:final item) => <String, Object?>{
            'op': 'append',
            'item': item,
          },
          ListRemoveAt<E>(:final index) => <String, Object?>{
            'op': 'removeAt',
            'index': index,
          },
          ListUpdateAt<E>(:final index, :final item) => <String, Object?>{
            'op': 'updateAt',
            'index': index,
            'item': item,
          },
        },
    ],
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListPatchDelta<E> && _listEquality.equals(other.ops, ops);

  @override
  int get hashCode => Object.hashAll(ops);

  @override
  String toString() => 'ListPatchDelta<$E>($ops)';
}

/// An ordered sequence of [MapPatchOp] steps — the key-keyed counterpart of
/// [ListPatchDelta].
///
/// Same algebra and the same laws: [diff] is minimal (one put per added or
/// changed key, one remove per dropped key, none for an unchanged map),
/// [apply] never mutates, [compose] concatenates and [invert] round-trips.
final class MapPatchDelta<K, V>
    implements ZorphyPatch<Map<K, V>>, Patch<Map<K, V>> {
  /// Creates a delta over [ops], applied in order.
  const MapPatchDelta(this.ops);

  /// The empty delta: no operation, no change.
  ///
  /// Not `const`, for the same reason as [ListPatchDelta.empty].
  MapPatchDelta.empty() : ops = const <MapPatchOp<Never, Never>>[];

  /// The steps this delta applies, in order.
  final List<MapPatchOp<K, V>> ops;

  /// The smallest delta that turns [previous] into [next].
  ///
  /// Puts are emitted in [next]'s key order and removals in [previous]'s, so
  /// the same pair always yields the same delta.
  /// As in [ListPatchDelta.diff], the static declares its own type parameters.
  static MapPatchDelta<K, V> diff<K, V>(Map<K, V> previous, Map<K, V> next) {
    final empty = MapPatchDelta<K, V>.empty();
    if (identical(previous, next)) return empty;
    final ops = <MapPatchOp<K, V>>[];
    for (final entry in next.entries) {
      if (!previous.containsKey(entry.key) ||
          previous[entry.key] != entry.value) {
        ops.add(MapPatchOp<K, V>.put(entry.key, entry.value));
      }
    }
    for (final key in previous.keys) {
      if (!next.containsKey(key)) ops.add(MapPatchOp<K, V>.remove(key));
    }
    return ops.isEmpty ? empty : MapPatchDelta<K, V>(ops);
  }

  @override
  bool get isEmpty => ops.isEmpty;

  @override
  bool get isNotEmpty => ops.isNotEmpty;

  @override
  Map<K, V> apply(Map<K, V> target) {
    if (isEmpty) return target;
    var result = target;
    for (final op in ops) {
      result = op.apply(result);
    }
    return result;
  }

  /// The legacy [Patch] entry point: same behaviour as [apply].
  @override
  Map<K, V> applyTo(Map<K, V> entity) => apply(entity);

  @override
  MapPatchDelta<K, V> compose(covariant MapPatchDelta<K, V> next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    return MapPatchDelta<K, V>(<MapPatchOp<K, V>>[...ops, ...next.ops]);
  }

  /// The delta that restores [before] — a single replaceAll, for the same
  /// reason [ListPatchDelta.invert] is: positional history is not carried.
  @override
  MapPatchDelta<K, V> invert(Map<K, V> before) {
    if (isEmpty) return MapPatchDelta<K, V>.empty();
    return MapPatchDelta<K, V>(<MapPatchOp<K, V>>[
      MapPatchOp<K, V>.replaceAll(Map<K, V>.of(before)),
    ]);
  }

  @override
  Map<String, Object?> toWire() => <String, Object?>{
    'ops': <Object?>[
      for (final op in ops)
        switch (op) {
          MapReplaceAll<K, V>(:final entries) => <String, Object?>{
            'op': 'replaceAll',
            'entries': entries,
          },
          MapPut<K, V>(:final key, :final value) => <String, Object?>{
            'op': 'put',
            'key': key,
            'value': value,
          },
          MapRemove<K, V>(:final key) => <String, Object?>{
            'op': 'remove',
            'key': key,
          },
        },
    ],
  };

  /// The field-level wire form: a bare list of steps, not `{'ops': [...]}`.
  ///
  /// A replacement map may legitimately contain a literal `ops` key, so a
  /// wrapper keyed `ops` would make the two shapes ambiguous (#215). A map
  /// field therefore carries the bare list; `ZorphyPatchWire.mapDelta` reads a
  /// list as steps and a map as a replacement.
  List<Object?> toWireSteps() => <Object?>[
    for (final op in ops)
      switch (op) {
        MapReplaceAll<K, V>(:final entries) => <String, Object?>{
          'op': 'replaceAll',
          'entries': entries,
        },
        MapPut<K, V>(:final key, :final value) => <String, Object?>{
          'op': 'put',
          'key': key,
          'value': value,
        },
        MapRemove<K, V>(:final key) => <String, Object?>{
          'op': 'remove',
          'key': key,
        },
      },
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapPatchDelta<K, V> && _listEquality.equals(other.ops, ops);

  @override
  int get hashCode => Object.hashAll(ops);

  @override
  String toString() => 'MapPatchDelta<$K, $V>($ops)';
}
