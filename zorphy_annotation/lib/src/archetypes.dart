import 'archetype_bases.dart';

/// A Zorphy archetype: an aggregate or event root with its own identity.
///
/// Zero codegen toggles — every member of the generated surface
/// (copyWith, equality, patch, filters, JSON) is unconditional. What
/// varies per archetype is the SEMANTICS, never the feature set.
///
/// `discriminator` and `explicitSubTypes` make the archetype polymorphic:
/// a base declaring subtypes emits the dispatching `fromJson`/`toJson` and
/// the `changeTo<Subtype>` conversions; the subtypes inherit the
/// discriminator from their base.
///
/// ```dart
/// @ZorphyEntity(principalKey: #id)
/// abstract class $User {
///   String get id;
///   String get name;
/// }
///
/// @ZorphyEntity(principalKey: #id, explicitSubTypes: [$Admin])
/// abstract class $$Account {
///   String get id;
/// }
///
/// @ZorphyEntity(principalKey: #id, discriminator: 'accountType')
/// abstract class $Admin implements $$Account {
///   String get id;
///   List<String> get scopes;
/// }
/// ```
final class ZorphyEntity implements ZorphyEntityBase<Symbol?> {
  /// The principal key of the root entity — the symbol of the identity
  /// field (`#id`, `#userId`, …). REQUIRED on a root entity and inherited
  /// by its subtypes, which never repeat it.
  final Symbol? principalKey;

  /// The JSON key the base's `fromJson` dispatches on. Subtypes inherit
  /// the base's value.
  @override
  final String discriminator;

  /// The subtype set of this base, as `$`-prefixed abstract classes.
  @override
  final List<Type> explicitSubTypes;

  /// Creates an entity archetype annotation.
  const ZorphyEntity({
    this.principalKey,
    this.discriminator = 'kind',
    this.explicitSubTypes = const [],
  });
}

/// A Zorphy archetype for state: a view-model / state-machine type.
///
/// Same unconditional generated surface as [ZorphyEntity], minus the
/// principal key — a state has no identity of its own.
final class ZorphyState implements ZorphyStateBase {
  /// The JSON key the base's `fromJson` dispatches on.
  @override
  final String discriminator;

  /// The subtype set of this base, as `$`-prefixed abstract classes.
  @override
  final List<Type> explicitSubTypes;

  /// Creates a state archetype annotation.
  const ZorphyState({
    this.discriminator = 'kind',
    this.explicitSubTypes = const [],
  });
}

/// A Zorphy archetype for unions: a closed set of variants.
///
/// The archetype of a `$$` base whose subtypes are its variants — it
/// carries the discriminator but no subtype list, because the variant set
/// IS the class's `implements` clause.
final class ZorphyUnion implements ZorphyUnionBase {
  /// The JSON key the base's `fromJson` dispatches on.
  @override
  final String discriminator;

  /// A union declares its variant set as its `implements` clause, so this
  /// is always empty.
  @override
  final List<Type> explicitSubTypes = const [];

  /// Creates a union archetype annotation.
  const ZorphyUnion({this.discriminator = 'kind'});
}

/// A Zorphy archetype for intents: commands, events, messages.
///
/// [replaySafe] is REQUIRED — there is no default, so every intent states
/// whether replaying it is safe. A leaf subtype that needs different
/// semantics overrides it on its own annotation.
final class ZorphyIntent implements ZorphyIntentBase {
  /// Whether replaying this intent is safe. No default by design: an
  /// intent's replay semantics is the one thing that must never be
  /// guessed for it.
  @override
  final bool replaySafe;

  /// The JSON key the base's `fromJson` dispatches on.
  @override
  final String discriminator;

  /// The subtype set of this base, as `$`-prefixed abstract classes.
  @override
  final List<Type> explicitSubTypes;

  /// Creates an intent archetype annotation.
  const ZorphyIntent({
    required this.replaySafe,
    this.discriminator = 'kind',
    this.explicitSubTypes = const [],
  });
}

/// A Zorphy archetype for values: immutable types with no identity.
final class ZorphyValue implements ZorphyValueBase {
  /// The JSON key the base's `fromJson` dispatches on.
  @override
  final String discriminator;

  /// The subtype set of this base, as `$`-prefixed abstract classes.
  @override
  final List<Type> explicitSubTypes;

  /// Creates a value archetype annotation.
  const ZorphyValue({
    this.discriminator = 'kind',
    this.explicitSubTypes = const [],
  });
}

/// Field-level seed hint for generated mock/sample data.
///
/// NOT a codegen toggle: it never changes what is generated, only the
/// values a mock factory seeds. [preset] names a well-known shape
/// (`'email'`, `'uuid'`, `'price'`, `'url'`); [example] carries a literal
/// value to use verbatim.
///
/// ```dart
/// @ZorphyValue
/// abstract class $Customer {
///   @ZorphyMock(preset: 'email')
///   String get email;
///
///   @ZorphyMock(example: 'EUR')
///   String get currency;
/// }
/// ```
final class ZorphyMock {
  /// The seed shape: `'email'`, `'uuid'`, `'price'`, `'url'`, … `null`
  /// when [example] carries the seed instead.
  final String? preset;

  /// A literal value the mock factory uses verbatim.
  final Object? example;

  /// Creates a field-level mock hint.
  const ZorphyMock({this.preset, this.example});
}

/// Annotation to declare a named constructor with a custom body on the
/// generated concrete class.
///
/// Place one or more `@ZorphyNamedConstructor` annotations on the
/// abstract class. The generated concrete class will have additional
/// named constructors with the same parameters as the default
/// constructor, plus the custom [body] code.
///
/// Example:
/// ```dart
/// @ZValueObject
/// @ZorphyNamedConstructor(name: 'world', body: r'assert(!name.startsWith("WINDOW-ID-"));')
/// abstract class $ContentWorld {
///   String get name;
/// }
/// ```
///
/// This generates:
/// ```dart
/// class ContentWorld {
///   final String name;
///   ContentWorld({required this.name});
///   ContentWorld.world({required this.name}) {
///     assert(!name.startsWith("WINDOW-ID-"));
///   }
/// }
/// ```
class ZorphyNamedConstructor {
  /// The constructor name (e.g. `world` produces `ContentWorld.world(...)`).
  ///
  /// Must be a valid Dart identifier and must not collide with a generated
  /// constructor name (`copyWith`, `_`, or the class name itself).
  final String name;

  /// Dart statements executed in the constructor body.
  ///
  /// Can contain `assert`, `precondition` checks, or any other logic.
  /// The body has access to all constructor parameters.
  ///
  /// When [factory] is `true`, [body] must construct and return an instance
  /// of the concrete class.
  final String body;

  /// When `true`, emit a `factory` constructor (see [body] for the contract).
  ///
  /// Defaults to `false`, which emits a normal (non-factory) constructor with
  /// field-formal parameters, an initializer list, and the [body].
  final bool factory;

  /// Creates a named constructor descriptor.
  const ZorphyNamedConstructor({
    required this.name,
    required this.body,
    this.factory = false,
  });
}
