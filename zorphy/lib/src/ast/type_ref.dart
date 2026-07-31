/// Escape-free type-reference helpers for code_builder Specs.
///
/// These functions produce [TypeReference] objects suitable for use in
/// [Spec] instances, without relying on string escaping.
library;

import 'package:code_builder/code_builder.dart';

/// References an arbitrary Dart type by its fully-qualified or simple name.
///
/// Example:
/// ```dart
/// referType('String')       // => TypeReference((t) => t.symbol = 'String')
/// referType('List<int>')    // => TypeReference with types = [referType('int')]
/// ```
TypeReference referType(String type) {
  // Strip trailing ? for nullable handling - code_builder uses isNullable.
  final isNullable = type.endsWith('?');
  final cleanType = isNullable ? type.substring(0, type.length - 1) : type;

  // Handle generic types like Map<String, int>
  final ltIndex = cleanType.indexOf('<');
  if (ltIndex != -1) {
    final rtIndex = cleanType.lastIndexOf('>');
    final baseName = cleanType.substring(0, ltIndex);
    final typeArgsStr = cleanType.substring(ltIndex + 1, rtIndex);
    final typeArgs = _splitTypeArgs(typeArgsStr).map(referType).toList();
    return TypeReference((t) {
      t.symbol = baseName;
      t.types.addAll(typeArgs);
      t.isNullable = isNullable;
    });
  }

  return TypeReference((t) {
    t.symbol = cleanType;
    t.isNullable = isNullable;
  });
}

/// References a Zorphy-generated class by its clean (non-prefixed) name.
///
/// Zorphy-generated concrete classes use the clean name directly.
/// ```dart
/// referZorphyClass('User') // => TypeReference(symbol: 'User')
/// ```
TypeReference referZorphyClass(String name) {
  return referType(name);
}

/// References a Zorphy sealed class base (the `$$`-prefixed abstract class).
///
/// In Zorphy, sealed bases are emitted as `$$ClassName` in the
/// source, but by convention the **clean** name is used in the generated
/// output. Use [referZorphyClass] if you need the concrete form.
/// ```dart
/// referZorphySealedBase('Shape') // => TypeReference(symbol: '$$Shape')
/// ```
TypeReference referZorphySealedBase(String name) {
  return referType('\$\$$name');
}

/// References a class that lives in the same library (no import needed).
///
/// This is a thin wrapper over [referType] that makes intent explicit.
/// ```dart
/// referSibling('_$User') // => TypeReference(symbol: '_$User')
/// ```
TypeReference referSibling(String name) {
  return referType(name);
}

/// Wraps an existing [TypeReference] with a library import URI.
///
/// Returns a new [TypeReference] identical to [ref] but with [library]
/// set, so that `code_builder` emits the correct `import` statement.
/// ```dart
/// withLibrary(referType('DateTime'), 'dart:core')
/// ```
TypeReference withLibrary(TypeReference ref, String library) {
  return TypeReference((t) {
    t.symbol = ref.symbol;
    t.isNullable = ref.isNullable;
    t.types.addAll(ref.types);
    t.url = library;
  });
}

/// Splits a comma-separated type-argument string respecting angle brackets.
///
/// `'String, Map<String, int>'` => `['String', 'Map<String, int>']`
List<String> _splitTypeArgs(String args) {
  if (args.isEmpty) return [];
  final result = <String>[];
  var depth = 0;
  var current = StringBuffer();
  for (var i = 0; i < args.length; i++) {
    final ch = args[i];
    if (ch == '<') {
      depth++;
      current.write(ch);
    } else if (ch == '>') {
      depth--;
      current.write(ch);
    } else if (ch == ',' && depth == 0) {
      result.add(current.toString().trim());
      current = StringBuffer();
    } else {
      current.write(ch);
    }
  }
  final remaining = current.toString().trim();
  if (remaining.isNotEmpty) result.add(remaining);
  return result;
}
