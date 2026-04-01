/// Utility class for naming conventions
class NamingUtils {
  const NamingUtils._();

  /// Convert to PascalCase (ClassName)
  static String toPascalCase(String input) {
    var name = input.replaceAll('\$', '');
    final parts = name.split(RegExp(r'[_\s\-]+'));
    return parts
        .map((part) {
          if (part.isEmpty) return '';
          return part[0].toUpperCase() + part.substring(1);
        })
        .join('');
  }

  /// Convert to snake_case (file_name)
  static String toSnakeCase(String input) {
    final camel = toPascalCase(input);
    return camel.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
      final char = match.group(0)!;
      final index = match.start;
      return (index == 0) ? char.toLowerCase() : '_${char.toLowerCase()}';
    });
  }

  /// Convert to camelCase (variableName)
  static String toCamelCase(String input) {
    final pascal = toPascalCase(input);
    if (pascal.isEmpty) return pascal;
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  /// Singularize a word (basic implementation)
  static String singularize(String word) {
    if (word.endsWith('ies')) return '${word.substring(0, word.length - 3)}y';
    if (word.endsWith('es')) return word.substring(0, word.length - 2);
    if (word.endsWith('s')) return word.substring(0, word.length - 1);
    return word;
  }

  /// Check if a string is a primitive Dart type
  static bool isPrimitiveType(String type) {
    const primitives = {
      'String',
      'int',
      'double',
      'bool',
      'num',
      'DateTime',
      'List',
      'Set',
      'Map',
      'dynamic',
      'Object',
      'Iterable',
      'Future',
      'Stream',
      'void',
      'Null',
    };
    return primitives.contains(type);
  }

  /// Check if a type is a container type (List, Set, Map)
  static bool isContainerType(String type) {
    return type == 'List' || type == 'Set' || type == 'Map';
  }

  /// Extract type references from a type string (including generics)
  static Set<String> extractTypeReferences(String type) {
    final refs = <String>{};
    var cleanType = type.replaceAll('?', '');

    final pattern = RegExp(r'\$*[A-Z][a-zA-Z0-9]*');
    final matches = pattern.allMatches(cleanType);

    for (final match in matches) {
      refs.add(match.group(0)!);
    }

    return refs;
  }

  /// Split a string by comma, respecting nested brackets
  static List<String> smartSplit(String input) {
    final parts = <String>[];
    var depth = 0;
    var current = StringBuffer();

    for (var i = 0; i < input.length; i++) {
      final char = input[i];
      if (char == '<') {
        depth++;
        current.write(char);
      } else if (char == '>') {
        depth--;
        current.write(char);
      } else if (char == ',' && depth == 0) {
        final part = current.toString().trim();
        if (part.isNotEmpty) {
          parts.add(part);
        }
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    if (current.isNotEmpty) {
      final part = current.toString().trim();
      if (part.isNotEmpty) {
        parts.add(part);
      }
    }
    return parts;
  }
}
