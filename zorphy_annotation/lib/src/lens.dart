/// Typed, composable lenses over the generated Zorphy data classes.
///
/// A [ZorphyLens] is a first-class, JSON-Pointer-addressed accessor for one
/// field of an immutable Zorphy type: [get] reads the focused value out of a
/// root, and [set] returns a NEW root with just that value replaced. Generated
/// `<Name>Lenses` accessor classes expose one lens per field, so fine-grained
/// consumers — a store subscription, a `zuraffa_ui` rebuild scope — can name
/// exactly the slice they depend on instead of the whole object.
///
/// ```dart
/// final price = ProductUiState.lenses.editDraft.then(Draft.lenses.price);
/// final updated = price.set(state, 9.99); // only editDraft.price changed
/// ```
///
/// Lenses obey the standard lens laws, which the generator's emitted `set`
/// (and this class's [then]) preserve:
///
/// - **put-get** — `get(set(root, v)) == v`
/// - **get-put** — `set(root, get(root)) == root`
/// - **put-put** — `set(set(root, a), b) == set(root, b)`
///
/// [then] composes a lens with a lens focused on a value INSIDE it, giving a
/// lens from the outer root straight to the nested leaf. Paths concatenate, so
/// a composed lens still names its leaf as one JSON Pointer.
library;

/// A typed accessor for one value [V] inside a root [S].
///
/// Construct one directly only when hand-writing a lens for a type the
/// generator does not cover; generated code exposes them through each class's
/// `static const <Name>Lenses lenses` registry.
final class ZorphyLens<S, V> {
  /// The JSON-Pointer path of the focused value inside [S], e.g.
  /// `'/editDraft/price'`.
  ///
  /// A composed lens concatenates its parts, so the path always addresses the
  /// leaf relative to the root — the wire-level twin of the static type.
  final String path;

  /// Reads the focused value out of [root].
  final V Function(S root) get;

  /// Returns a copy of [root] with the focused value replaced by `value`.
  ///
  /// Implementations never mutate [root]; Zorphy types are immutable and the
  /// generated `set` routes through the type's own `copyWith`.
  final S Function(S root, V value) set;

  const ZorphyLens({required this.path, required this.get, required this.set});

  /// Composes this lens with a [child] lens focused inside its value.
  ///
  /// The result reads `root -> value -> child value` and writes the leaf back
  /// through both levels, preserving every sibling at each level:
  ///
  /// ```dart
  /// final price = ProductUiState.lenses.editDraft // ZorphyLens<State, Draft>
  ///     .then(Draft.lenses.price);                // ZorphyLens<State, double>
  /// ```
  ZorphyLens<S, Sub> then<Sub>(ZorphyLens<V, Sub> child) => ZorphyLens<S, Sub>(
    path: '$path${child.path}',
    get: (root) => child.get(get(root)),
    set: (root, subValue) => set(root, child.set(get(root), subValue)),
  );
}
