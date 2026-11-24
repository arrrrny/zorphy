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

/// Field-level escape hatch from `ZORPHY_LINT_NO_BOOL_FLAGS` (ISSUE-005, #180).
///
/// A `bool` on a `@ZorphyState` / `@ZorphyIntent` / polymorphic variant is
/// reported by the generator when its NAME is a behavioral or lifecycle flag
/// (`isLoading`, `hasError`, `force*`, `skip*`, `silent`, ...): those exist to
/// model two commands or two states as one node, which is what polymorphic
/// subtypes and `AsyncSlice<T>` exist to replace.
///
/// It is a diagnostic on the resolved IR (`ZORPHY_LINT_NO_BOOL_FLAGS`), and
/// since #223 the production generator enforces it: `ZorphyGenerator` resolves
/// the library's `PolymorphicIr` and throws `InvalidGenerationSourceError` on
/// any diagnostic, so a flagged boolean fails the real `build_runner` run —
/// see `zorphy/lib/src/lints/no_bool_flags_lint.dart`.
///
/// A boolean that is genuinely part of the domain — `Product.inStock`,
/// `InteractiveUiNode.enabled` — is not a flag and must be able to say so.
/// The annotation works on both declaration forms the generator reads:
///
/// ```dart
/// @ZorphyState()
/// abstract class $UiNode {
///   @ZorphyDomainBool()
///   bool get isLoading; // an abstract getter — annotated on the getter
///
///   @ZorphyDomainBool()
///   final bool hasError; // a real field — annotated on the FIELD
/// }
/// ```
final class ZorphyDomainBool {
  /// Marks the annotated field/getter as a genuine domain boolean, exempting
  /// it from `ZORPHY_LINT_NO_BOOL_FLAGS`.
  const ZorphyDomainBool();
}

/// Field-level mock-data seed hint for mock-first generation.
///
/// Unlike the five archetypes, [ZorphyMock] annotates a FIELD, not a class: it
/// tells the mock generator what trusted seed to synthesize for that field.
/// [preset] is one of the constants in [ZorphyMockPresets] (other values are
/// passed through to the consumer's own seed registry); [example] is a literal
/// fallback used verbatim when no preset matches.
final class ZorphyMock {
  /// A named seed hint; see [ZorphyMockPresets] for the reserved names.
  ///
  /// The field stays a [String] rather than an enum so a consumer can register
  /// its own seeds. [ZorphyMockPresets.all] is the closed set the generator can
  /// warn on: a value outside it is a consumer-defined preset, not a typo it
  /// can reject on its own.
  final String? preset;

  /// A literal example value used verbatim as the seed when no preset applies.
  final Object? example;

  const ZorphyMock({this.preset, this.example});
}

/// The reserved [ZorphyMock.preset] names understood by the generator.
///
/// These are the presets every consumer gets without registering anything; any
/// other value is passed through to the consumer's own seed registry.
abstract final class ZorphyMockPresets {
  /// A syntactically valid email address.
  static const String email = 'email';

  /// A unique identifier string.
  static const String uuid = 'uuid';

  /// A monetary amount.
  static const String price = 'price';

  /// An absolute URL.
  static const String url = 'url';

  /// Every reserved preset name, for the generator's typo warning.
  static const List<String> all = <String>[email, uuid, price, url];
}
