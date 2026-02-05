import 'package:dartx/dartx.dart';
import 'package:collection/collection.dart';

/// Utility functions for generic type serialization
///
/// These functions help with polymorphic JSON serialization when dealing
/// with generic types. They allow for registering and retrieving type-specific
/// serialization functions for generic containers.
///
/// ## Usage
///
/// ### Registering Type Functions
/// ```dart
/// final toJsonFns = <Type, Object? Function(Never)>{
///   Product: (product) => product.toJson(),
///   User: (user) => user.toJson(),
/// };
///
/// final json = getGenericToJsonFn(toJsonFns, productType)(product);
/// ```
///
/// ### From JSON with Generics
/// ```dart
/// final fromJsonFns = <List<String>, dynamic Function(Map<String, dynamic>)>{
///   [String, int]: (json) => Container.fromJson(json),
///   [String, bool]: (json) => OtherContainer.fromJson(json),
/// };
///
/// final container = getFromJsonToGenericFn(
///   fromJsonFns,
///   json,
///   [String, int],
/// );
/// ```
///
/// ## See Also
///
/// - [Zorphy] - Main annotation that uses these utilities
/// - [Zorphy2] - Two-pass annotation for circular dependencies

/// Gets a type-specific toJson function for generic serialization
///
/// This function looks up a serialization function for [type] in the
/// provided [fns] map. Returns an identity function if no specific
/// function is registered.
///
/// ## Parameters
/// - [fns] - Map of Type to serialization functions
/// - [type] - The type to look up
///
/// ## Returns
/// A function that serializes objects of [type], or an identity function
/// if no specific serializer is registered.
///
/// ## Example
/// ```dart
/// final serializers = <Type, Object? Function(Never)>{
///   MyType: (obj) => (obj as MyType).toJson(),
/// };
///
/// final fn = getGenericToJsonFn(serializers, MyType);
/// final json = fn(myInstance);
/// ```
Object? Function(Never) getGenericToJsonFn(
  Map<Type, Object? Function(Never)> fns,
  Type type,
) {
  var type1_fn = fns[type];

  if (type1_fn == null) {
    // Return identity function if no specific serializer
    return (x) => x;
  }

  return type1_fn;
}

/// Gets a fromJson function for generic type deserialization
///
/// This function looks up a deserialization function based on the
/// generic type signature in [genericType]. It uses [ListEquality]
/// to match generic type parameters.
///
/// ## Parameters
/// - [fns] - Map of generic type signatures to fromJson functions
/// - [json] - JSON map containing type information
/// - [genericType] - List of generic type names (e.g., [String, int])
///
/// ## Returns
/// A function that can deserialize JSON into the appropriate generic type
///
/// ## Throws
/// - [Exception] if no matching fromJson function is found
///
/// ## Example
/// ```dart
/// final factories = <List<String>, dynamic Function(Map<String, dynamic>)>{
///   ['T1', 'T2']: (json) => Container<T1, T2>.fromJson(json),
/// };
///
/// final json = {
///   'T1': 'String',
///   'T2': 'int',
///   'value': 42,
/// };
///
/// final factory = getFromJsonToGenericFn(factories, json, ['T1', 'T2']);
/// final container = factory(json);
/// ```
dynamic getFromJsonToGenericFn(
  Map<List<String>, dynamic Function(Map<String, dynamic>)> fns,
  Map<String, dynamic> json,
  List<String> genericType,
) {
  // Extract the actual type values from JSON
  var types = genericType.map((e) => json[e]).toList();

  // Find matching function using ListEquality for proper type comparison
  var fromJsonToGeneric_fn = fns.entries
      .firstWhereOrNull((entry) => const ListEquality().equals(entry.key, types))
      ?.value;

  if (fromJsonToGeneric_fn == null) {
    throw Exception("From JSON function not found for type: $types");
  }

  return fromJsonToGeneric_fn;
}
