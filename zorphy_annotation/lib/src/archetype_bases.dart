/// Marker base interfaces for the v3.0.0 zero-toggle polymorphic archetypes.
///
/// These interfaces carry no behaviour — they exist so generated code and
/// consumer code can constrain a type parameter to "any subtype of a given
/// archetype family" at compile time (e.g. `T extends ZorphyEntityBase<Object>`).
///
/// They are the type-level half of the v3 polymorphism model; the annotation
/// classes that drive generation live in `archetypes.dart`.
library;

/// Base marker implemented by every polymorphic root/subtype in an
/// `@ZorphyEntity` hierarchy.
///
/// [Id] is the principal-key type: the type of the field named by
/// [ZorphyEntity.principalKey] on the root, inherited by every subtype.
abstract interface class ZorphyEntityBase<Id>
    implements ZorphyPolymorphicBase {}

/// Base marker implemented by every class in a `@ZorphyState` hierarchy.
abstract interface class ZorphyStateBase implements ZorphyPolymorphicBase {}

/// Base marker implemented by every member of a `@ZorphyUnion` hierarchy.
abstract interface class ZorphyUnionBase implements ZorphyPolymorphicBase {}

/// Base marker implemented by every class in a `@ZorphyIntent` hierarchy.
abstract interface class ZorphyIntentBase implements ZorphyPolymorphicBase {}

/// Base marker implemented by every class in a `@ZorphyValue` hierarchy.
abstract interface class ZorphyValueBase implements ZorphyPolymorphicBase {}

/// Common super-marker shared by all five archetype families.
///
/// A type parameter bounded by `ZorphyPolymorphicBase` accepts a subtype from
/// any archetype family, which is what generic patch/lens/codec helpers bound
/// themselves to.
abstract interface class ZorphyPolymorphicBase {}
