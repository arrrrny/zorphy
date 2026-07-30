import 'package:collection/collection.dart';

/// Controls how much code zorphy generates for an annotated class.
///
/// - [lean]: only the essentials — class, constructor, `copyWith`,
///   `==`/`hashCode`, `toString`. No patch API, filter descriptors,
///   compareTo, property helpers, field enum, fields class, or changeTo.
/// - [standard]: the full v1.x default output — everything in [lean] plus
///   patch methods/patch class/field enum, filter descriptors, compareTo,
///   property helpers, and changeTo. This is the default and reproduces
///   zorphy 1.9.0 output byte-for-byte.
/// - [full]: everything in [standard] plus function-based copyWith
///   (`copyWithFn`).
///
/// `generateJson` is opt-in in every preset (it pulls in
/// `json_serializable`), enable it explicitly with `generateJson: true`.
///
/// Any explicit `bool` flag passed to the annotation overrides the preset
/// for that feature:
/// ```
/// @Zorphy(preset: ZorphyPreset.lean, generatePatch: true)
/// ```
enum ZorphyPreset { lean, standard, full }

/// {@macro ZorphyX}
const zorphy = Zorphy();

/// ### Deprecated alias of [zorphy].
///
/// Historically Zorphy2 was generated before Zorphy when the generator
/// needed a related class built first. Since zorphy 2.0 the generator is
/// single-pass and resolves ordering internally — `@zorphy2` behaves
/// exactly like `@zorphy` and is slated for removal in a later major.
/// ---
/// {@macro ZorphyX}
@Deprecated('Use @zorphy instead. Behaves identically since zorphy 2.0; '
    'will be removed in a later major release.')
const zorphy2 = Zorphy2();

class Zorphy implements ZorphyX {
  /// if we want a copyWith (cwX) method for a subtype in this same class
  final List<Type>? explicitSubTypes;

  /// How much code to generate. Defaults to [ZorphyPreset.standard],
  /// which reproduces zorphy 1.x output byte-for-byte.
  final ZorphyPreset preset;

  final bool generateJson;
  final bool explicitToJson;

  /// whether to generate compareTo extension methods
  /// (null = inherit from [preset])
  final bool? generateCompareTo;
  final bool hidePublicConstructor;

  ///if we specify the class as an abstract class we make it abstract and not sealed
  final bool nonSealed;

  ///if we want to generate function-based copyWith methods (copyWithFn)
  ///(null = inherit from [preset])
  final bool? generateCopyWithFn;

  ///if we want to generate patch methods and patch classes
  ///(null = inherit from [preset])
  final bool? generatePatch;

  /// if we want to generate filter field descriptors
  /// (null = inherit from [preset])
  final bool? generateFilter;

  /// whether to generate copyWith methods (null = inherit from [preset])
  final bool? generateCopyWith;

  /// whether to generate semantic property helpers
  /// (null = inherit from [preset])
  final bool? generatePropertyHelpers;

  /// whether to generate ==, hashCode and toString
  /// (null = inherit from [preset])
  final bool? generateEqualsToString;

  /// whether to generate changeTo conversion extensions for explicit
  /// subtypes (null = inherit from [preset])
  final bool? generateChangeTo;

  /// {@template ZorphyX}
  /// ### normal class; prepend class with a single dollar & make abstract
  /// ```
  /// abstract class $MyClass { ...
  /// ```
  /// ---
  /// ### define non final get properties only (no constructor)
  /// ```
  /// String get aValue;
  /// int? get nullableValue;
  /// ```
  /// ---
  /// ### to instantiate or use the class omit the dollar
  /// ```
  /// MyClass(aValue: "x");
  /// ```
  /// ---
  /// ### to implement an interface use [implements]
  /// ```
  /// @zorphy
  /// abstract class $B implements $$A<int, String> {
  ///  String get z;
  /// ```
  /// ---
  /// ### ensure the generic names are the same between inherited classes
  /// ```
  /// class $A<T1> { ...
  /// class $B<T1> extends $A<T1> { ...
  /// ```
  /// ---
  /// ### abstract classes; prepend class with two dollars
  /// ```
  /// class $$myAbstractClass { ...
  /// ```
  /// ---
  /// ### private constructor for custom constructors; postpend with underscore
  /// ```
  /// abstract class $A_ {
  /// ```
  ///
  /// this then allows default values by defining custom functions in the same file
  ///
  /// ```
  /// A_ AFactory() {
  ///    return A_._(a: "my default value");
  /// }
  /// ```
  ///
  /// it makes it explict that the default constructor cannot be used
  /// ---
  /// ### constant constructors
  /// ```
  /// abstract class $A {
  ///  int get a;
  ///  const $A();
  ///  }
  ///  ```
  ///
  ///  must add a ```const $A()``` constructor to abstract class
  /// {@endtemplate}
  ///
  /// ### generics / type parameters
  /// When defining new type parameters on sibling classes ensure that the
  /// type parameter names are different.
  ///
  /// This is ok
  /// `class $A<T> {`
  /// `class $B<T, TB1> implements $A {`
  /// `class $C<T, TC1> implements $A {`
  ///
  /// This will throw an error
  /// `class $A<T> {`
  /// `class $B<T, T1> implements $A {`
  /// `class $C<T, T1> implements $A {`
  /// Creates a Zorphy annotation with configurable generation options.
  const Zorphy({
    this.explicitSubTypes = null,
    this.preset = ZorphyPreset.standard,
    this.generateJson = false,
    this.explicitToJson = true,
    this.hidePublicConstructor = false,
    this.generateCompareTo = null,
    this.nonSealed = false,
    this.generateCopyWithFn = null,
    this.generatePatch = null,
    this.generateFilter = null,
    this.generateCopyWith = null,
    this.generatePropertyHelpers = null,
    this.generateEqualsToString = null,
    this.generateChangeTo = null,
  });
}

/// Deprecated alias of [Zorphy]. Behaves identically since zorphy 2.0;
/// will be removed in a later major release.
class Zorphy2 implements ZorphyX {
  final List<Type>? explicitSubTypes;

  /// How much code to generate. Defaults to [ZorphyPreset.standard].
  final ZorphyPreset preset;

  final bool generateJson;
  final bool explicitToJson;
  final bool hidePublicConstructor;
  final bool nonSealed;
  final bool? generateCompareTo;
  final bool? generateCopyWithFn;
  final bool? generatePatch;
  final bool? generateFilter;
  final bool? generateCopyWith;
  final bool? generatePropertyHelpers;
  final bool? generateEqualsToString;
  final bool? generateChangeTo;

  /// Creates a Zorphy2 annotation with configurable generation options.
  const Zorphy2({
    this.explicitSubTypes = null,
    this.preset = ZorphyPreset.standard,
    this.generateJson = false,
    this.explicitToJson = true,
    this.hidePublicConstructor = false,
    this.nonSealed = false,
    this.generateCompareTo = null,
    this.generateCopyWithFn = null,
    this.generatePatch = null,
    this.generateFilter = null,
    this.generateCopyWith = null,
    this.generatePropertyHelpers = null,
    this.generateEqualsToString = null,
    this.generateChangeTo = null,
  });
}

abstract class ZorphyX {
  /// Returns explicitly declared subtypes for polymorphic generation.
  List<Type>? get explicitSubTypes;

  /// Returns whether JSON serialization code should be generated.
  bool get generateJson;

  /// Returns whether to use explicitToJson in json_serializable.
  bool get explicitToJson;

  /// Returns whether filter descriptors should be generated
  /// (null = inherit from preset).
  bool? get generateFilter;
}

/// Resolves a generic toJson function for the provided [type].
Object? Function(Never) getGenericToJsonFn(
  Map<Type, Object? Function(Never)> fns,
  Type type,
) {
  var type1_fn = fns[type];

  if (type1_fn == null) //
    return (x) => x;

  return type1_fn;
}

/// Resolves the matching fromJson function for the provided generic type ids.
dynamic getFromJsonToGenericFn(
  Map<List<String>, dynamic Function(Map<String, dynamic>)> fns,
  Map<String, dynamic> json,
  List<String> genericType,
) {
  var types = genericType.map((e) => json[e]).toList();

  var fromJsonToGeneric_fn = fns.entries
      .firstWhereOrNull((entry) => ListEquality().equals(entry.key, types))
      ?.value;
  if (fromJsonToGeneric_fn == null) //
    throw Exception("From JSON function not found");
  return fromJsonToGeneric_fn;
}
