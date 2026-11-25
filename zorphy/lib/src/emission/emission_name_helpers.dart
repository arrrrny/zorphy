/// Small name-normalization helpers shared by the IR-native emitters.
///
/// Both the lens surface and the JSON-Pointer resolver strip the synthesized
/// v3 `$` prefix from types and PascalCase field names. Keeping the helpers in
/// one internal library means the two copies cannot drift (review finding on
/// #239).
library;

/// Strips the v3 synthesized `$` prefix from a type or class name.
String concreteTypeName(String type) => type.replaceAll(r'$', '');

/// Upper-cases the first character of [name] (a PascalCase helper).
String pascalCase(String name) =>
    name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
