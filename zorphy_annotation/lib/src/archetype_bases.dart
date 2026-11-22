/// Marker base for every v3 archetype that supports polymorphism.
///
/// An archetype that carries a `discriminator` and (optionally) an
/// `explicitSubTypes` list implements this interface, so a tool can ask
/// "is this annotation polymorphic?" without naming each archetype.
abstract class ZorphyPolymorphicBase {
  /// The JSON key the base's `fromJson` dispatches on.
  String get discriminator;

  /// The subtype set declared on the base, empty when the hierarchy is
  /// open-ended or resolved structurally.
  List<Type> get explicitSubTypes => const [];
}

/// Marker base for [`ZorphyEntity`] — an aggregate/event root with its own
/// identity.
///
/// [Id] is the type of the principal key: `Symbol?` on the annotation
/// itself, the key field's type on a model.
abstract class ZorphyEntityBase<Id> implements ZorphyPolymorphicBase {
  /// The principal key symbol, `null` on a subtype that inherits it.
  Id? get principalKey;
}

/// Marker base for [`ZorphyState`] — a state machine / view-model type.
abstract class ZorphyStateBase implements ZorphyPolymorphicBase {}

/// Marker base for [`ZorphyUnion`] — a closed set of variants with no
/// fields of its own.
///
/// A union declares its variant set as its `implements` clause, so it
/// carries the discriminator and no subtype list — only the FULL
/// polymorphic surface is its contract.
abstract class ZorphyUnionBase implements ZorphyPolymorphicBase {}

/// Marker base for [`ZorphyIntent`] — a command with replay semantics.
abstract class ZorphyIntentBase implements ZorphyPolymorphicBase {
  /// Whether replaying this intent is safe.
  bool get replaySafe;
}

/// Marker base for [`ZorphyValue`] — an immutable value with no identity.
abstract class ZorphyValueBase implements ZorphyPolymorphicBase {}
