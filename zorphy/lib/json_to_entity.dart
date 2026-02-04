/// JSON to Zorphy entity converter
/// Infers types from JSON and generates Zorphy entities

class JsonToEntity {
  final bool prefixNested;

  JsonToEntity({this.prefixNested = true});

  EntityResult parse(
    Map<String, dynamic> json,
    String name, {
    String? parentPrefix,
  }) {
    final fullName = prefixNested && parentPrefix != null
        ? '$parentPrefix$name'
        : name;
    final fields = <Field>[];
    final nested = <EntityResult>[];

    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;

      final isNullable = key.endsWith('?');
      final fieldName = isNullable ? key.substring(0, key.length - 1) : key;

      if (value is Map<String, dynamic>) {
        // Nested object
        final nestedName = _toPascal(fieldName);
        final nestedResult = parse(
          value,
          nestedName,
          parentPrefix: prefixNested ? fullName : null,
        );
        nested.add(nestedResult);
        fields.add(Field(fieldName, '\$${nestedResult.name}', isNullable));
      } else if (value is List && value.isNotEmpty && value.first is Map) {
        // List of objects
        final nestedName = _toPascal(_singularize(fieldName));
        final nestedResult = parse(
          value.first as Map<String, dynamic>,
          nestedName,
          parentPrefix: prefixNested ? fullName : null,
        );
        nested.add(nestedResult);
        fields.add(
          Field(fieldName, 'List<\$${nestedResult.name}>', isNullable),
        );
      } else {
        // Primitive
        final type = _inferType(value);
        fields.add(Field(fieldName, type, isNullable || value == null));
      }
    }

    return EntityResult(fullName, fields, nested);
  }

  String _inferType(dynamic value) {
    if (value == null) return 'dynamic';
    if (value is String) {
      if (DateTime.tryParse(value) != null) return 'DateTime';
      return 'String';
    }
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is bool) return 'bool';
    if (value is List) {
      if (value.isEmpty) return 'List<dynamic>';
      final first = value.first;
      return 'List<${_inferType(first)}>';
    }
    return 'dynamic';
  }

  String _toPascal(String s) {
    return s
        .split(RegExp(r'[_\s-]'))
        .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1))
        .join('');
  }

  String _singularize(String s) {
    if (s.endsWith('ies')) return s.substring(0, s.length - 3) + 'y';
    if (s.endsWith('es')) return s.substring(0, s.length - 2);
    if (s.endsWith('s')) return s.substring(0, s.length - 1);
    return s;
  }
}

class EntityResult {
  final String name;
  final List<Field> fields;
  final List<EntityResult> nested;

  EntityResult(this.name, this.fields, this.nested);
}

class Field {
  final String name;
  final String type;
  final bool nullable;

  Field(this.name, this.type, this.nullable);

  String get fullType => nullable && !type.endsWith('?') ? '$type?' : type;
}
