/// Escape-free type-reference helpers for code_builder Specs.
///
/// These functions produce [TypeReference] objects suitable for use in
/// [Spec] instances, without relying on string escaping.
library;

import 'package:code_builder/code_builder.dart';

/// References an arbitrary Dart type by its fully-qualified or simple name.
TypeReference referType(String type) {
  final isNullable = type.endsWith('?');
  final cleanType = isNullable ? type.substring(0, type.length - 1) : type;
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

TypeReference referZorphyClass(String name) => referType(name);

TypeReference referZorphySealedBase(String name) =>
    referType('\$' + name);

TypeReference referSibling(String name) => referType(name);

TypeReference withLibrary(TypeReference ref, String library) {
  return TypeReference((t) {
    t.symbol = ref.symbol;
    t.isNullable = ref.isNullable;
    t.types.addAll(ref.types);
    t.url = library;
  });
}

TypeReference referConcreteType(String type) {
  // Remove dollar signs from type names but preserve import prefixes like api$
  final processed = type.replaceAllMapped(
    RegExp(r'(\w+\$\.)?(\$+)?(\w+)(<[^>]+>)?(\?)?'),
    (m) {
      final prefix = m.group(1) ?? ''; // e.g., "api$."
      final dollarPrefix = m.group(2) ?? ''; // e.g., "$$" or "$"
      final typeName = m.group(3) ?? ''; // e.g., "Order"
      final typeArgs = m.group(4) ?? ''; // e.g., "<String>"
      final nullable = m.group(5) ?? ''; // e.g., "?"

      // Recursively clean type arguments
      final cleanTypeArgs = typeArgs.isEmpty
          ? ''
          : '<${typeArgs.substring(1, typeArgs.length - 1).split(',').map((arg) => referConcreteType(arg.trim()).symbol).join(', ')}>';

      return '$prefix$typeName$cleanTypeArgs$nullable';
    },
  );
  return referType(processed);
}

List<String> _splitTypeArgs(String args) {
  if (args.isEmpty) return [];
  final result = <String>[];
  var depth = 0;
  var current = StringBuffer();
  for (var i = 0; i < args.length; i++) {
    final ch = args[i];
    if (ch == '<') { depth++; current.write(ch); }
    else if (ch == '>') { depth--; current.write(ch); }
    else if (ch == ',' && depth == 0) {
      result.add(current.toString().trim()); current = StringBuffer(); }
    else { current.write(ch); }
  }
  final remaining = current.toString().trim();
  if (remaining.isNotEmpty) result.add(remaining);
  return result;
}
