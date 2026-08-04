class NameType {
  final String name;
  final String? type;

  /// Creates a simple name/type pair.
  NameType(this.name, this.type);

  @override
  /// Returns a readable representation of the pair.
  String toString() => "$name: $type";

  @override
  /// Compares two NameType instances by value.
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NameType &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type;

  @override
  /// Returns a hash code derived from name and type.
  int get hashCode => name.hashCode ^ (type.hashCode);
}

class NameTypeClassComment {
  final String name;
  final String? type;
  final String? className;
  final String? comment;
  final JsonKeyInfo? jsonKeyInfo;
  final List<String> additionalAnnotations;
  final bool isEnum;
  final List<String> enumValues;
  final bool isGetterOnly;

  /// Creates a name/type pair with optional class and annotation metadata.
  NameTypeClassComment(
    this.name,
    this.type,
    this.className, {
    this.comment,
    this.jsonKeyInfo,
    this.additionalAnnotations = const [],
    this.isEnum = false,
    this.enumValues = const [],
    this.isGetterOnly = false,
  });

  @override
  /// Returns a readable representation with class context.
  String toString() => "$name: $type ($className)";

  @override
  /// Compares two NameTypeClassComment instances by value.
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NameTypeClassComment &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          className == other.className &&
          isGetterOnly == other.isGetterOnly;

  @override
  /// Returns a hash code derived from name, type, and className.
  int get hashCode =>
      name.hashCode ^
      type.hashCode ^
      className.hashCode ^
      isGetterOnly.hashCode;
}

class NameTypeClassCommentData<TMeta1> {
  final String name;
  final String? type;
  final String? className;
  final String? comment;
  final TMeta1? meta1;

  /// Creates a name/type pair with custom metadata.
  NameTypeClassCommentData(
    this.name,
    this.type,
    this.className, {
    this.comment,
    this.meta1,
  });
}

/// Stores information extracted from @JsonKey annotations
class JsonKeyInfo {
  final String? name;
  final bool? ignore;
  final dynamic defaultValue;
  final bool? required;
  final bool? includeIfNull;
  final bool? includeFromJson;
  final bool? includeToJson;
  final bool? disallowNullValue;
  final String? toJson;
  final String? fromJson;
  final String? converter;

  /// Creates a JsonKeyInfo record with optional parameters.
  const JsonKeyInfo({
    this.name,
    this.ignore,
    this.defaultValue,
    this.required,
    this.includeIfNull,
    this.includeFromJson,
    this.includeToJson,
    this.disallowNullValue,
    this.toJson,
    this.fromJson,
    this.converter,
  });

  /// Generates the annotation string representation.
  ///
  /// Returns the annotation **without** a leading `@` because
  /// code_builder's `DartEmitter` automatically prefixes annotations
  /// with `@` when emitting. Including `@` here would produce `@@`.
  String toAnnotationString({bool includeDefaultValue = true}) {
    final params = <String>[];

    if (name != null) params.add("name: '$name'");
    if (ignore != null) params.add("ignore: $ignore");
    if (includeDefaultValue && defaultValue != null)
      params.add("defaultValue: $defaultValue");
    if (required != null) params.add("required: $required");
    if (includeIfNull != null) params.add("includeIfNull: $includeIfNull");
    if (includeFromJson != null)
      params.add("includeFromJson: $includeFromJson");
    if (includeToJson != null) params.add("includeToJson: $includeToJson");
    if (disallowNullValue != null)
      params.add("disallowNullValue: $disallowNullValue");
    if (toJson != null) params.add("toJson: $toJson");
    if (fromJson != null) params.add("fromJson: $fromJson");
    if (converter != null) params.add("converter: $converter");

    if (params.isEmpty) return "JsonKey()";
    return "JsonKey(${params.join(", ")})";
  }

  /// Returns true when at least one annotation parameter is set.
  bool get hasAnnotations => params.isNotEmpty;

  /// Lists which JsonKey parameters are present.
  List<String> get params {
    final result = <String>[];
    if (name != null) result.add("name");
    if (ignore != null) result.add("ignore");
    if (defaultValue != null) result.add("defaultValue");
    if (required != null) result.add("required");
    if (includeIfNull != null) result.add("includeIfNull");
    if (includeFromJson != null) result.add("includeFromJson");
    if (includeToJson != null) result.add("includeToJson");
    if (disallowNullValue != null) result.add("disallowNullValue");
    if (toJson != null) result.add("toJson");
    if (fromJson != null) result.add("fromJson");
    if (converter != null) result.add("converter");
    return result;
  }
}
