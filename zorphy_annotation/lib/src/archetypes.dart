/// Zero-toggle polymorphic archetype annotations for Zorphy v3.0.0.
///
/// v3 drops every preset (`ZorphyPreset`) and every `generate*` boolean toggle.
/// Instead a class is annotated with exactly ONE archetype that names what the
/// class IS, and polymorphism is expressed declaratively through
/// [discriminator] and [explicitSubTypes] — there are no feature flags to get
/// out of sync.
///
/// The five archetypes:
/// - [ZorphyEntity] — an aggregate/event root with its own identity
///   ([principalKey]); subtypes inherit the key.
/// - [ZorphyState] — a mutable/composed state node in a sealed hierarchy.
/// - [ZorphyUnion] — a closed discriminated union of sibling variants.
/// - [ZorphyIntent] — a replay-safe command/intent envelope.
/// - [ZorphyValue] — an immutable value object (no identity).
library;

/// An aggregate/event root with its own identity.
///
/// [principalKey] names the id-bearing field (a `Symbol` of the field name, as
/// `#id`). It is required on the ROOT of an entity hierarchy and inherited by
/// every subtype. [discriminator] is the wire field that distinguishes sibling
/// subtypes, and [explicitSubTypes] lists subtypes the generator cannot infer
/// from the same-library sealed declarations (e.g. subtypes in another library).
final class ZorphyEntity {
  /// The principal-key field of the root entity, as a field `Symbol` (`#id`).
  ///
  /// Required on the root; inherited by subtypes. `null` on a subtype means
  /// "inherit from the root".
  final Symbol? principalKey;

  /// The wire field carrying the subtype tag during polymorphic dispatch.
  final String discriminator;

  /// Subtypes the generator cannot infer from same-library declarations.
  final List<Type> explicitSubTypes;

  const ZorphyEntity({
    this.principalKey,
    this.discriminator = 'kind',
    this.explicitSubTypes = const [],
  });
}

/// A mutable/composed state node in a (possibly sealed) hierarchy.
final class ZorphyState {
  /// The wire field carrying the subtype tag during polymorphic dispatch.
  final String discriminator;

  /// Subtypes the generator cannot infer from same-library declarations.
  final List<Type> explicitSubTypes;

  const ZorphyState({
    this.discriminator = 'kind',
    this.explicitSubTypes = const [],
  });
}

/// A closed discriminated union of sibling variants.
final class ZorphyUnion {
  /// The wire field carrying the variant tag during polymorphic dispatch.
  final String discriminator;

  const ZorphyUnion({this.discriminator = 'kind'});
}

/// A command/intent envelope whose payloads are replayed across a boundary.
final class ZorphyIntent {
  /// Whether replaying this intent is side-effect-safe.
  ///
  /// REQUIRED — there is no default, so every intent must make the replay-safety
  /// decision explicit. Leaf subtypes may override it.
  final bool replaySafe;

  /// The wire field carrying the subtype tag during polymorphic dispatch.
  final String discriminator;

  /// Subtypes the generator cannot infer from same-library declarations.
  final List<Type> explicitSubTypes;

  const ZorphyIntent({
    required this.replaySafe,
    this.discriminator = 'kind',
    this.explicitSubTypes = const [],
  });
}

/// An immutable value object with no identity of its own.
final class ZorphyValue {
  /// The wire field carrying the subtype tag during polymorphic dispatch.
  final String discriminator;

  /// Subtypes the generator cannot infer from same-library declarations.
  final List<Type> explicitSubTypes;

  const ZorphyValue({
    this.discriminator = 'kind',
    this.explicitSubTypes = const [],
  });
}

/// Field-level mock-data seed hint for mock-first generation.
///
/// Unlike the five archetypes, [ZorphyMock] annotates a FIELD, not a class: it
/// tells the mock generator what trusted seed to synthesize for that field.
/// [preset] is one of `'email'`, `'uuid'`, `'price'`, `'url'` (other values are
/// passed through to the consumer's own seed registry); [example] is a literal
/// fallback used verbatim when no preset matches.
final class ZorphyMock {
  /// A named seed hint: `'email'`, `'uuid'`, `'price'`, or `'url'`.
  final String? preset;

  /// A literal example value used verbatim as the seed when no preset applies.
  final Object? example;

  const ZorphyMock({this.preset, this.example});
}
