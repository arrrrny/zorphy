class NameType {
  final String name;
  final String? type;

  NameType(this.name, this.type);

  @override
  String toString() => "$name: $type";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NameType &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type;

  @override
  int get hashCode => name.hashCode ^ (type.hashCode);
}

class NameTypeClassComment {
  final String name;
  final String? type;
  final String? className;
  final String? comment;
  final JsonKeyInfo? jsonKeyInfo;
  final bool isEnum;

  NameTypeClassComment(
    this.name,
    this.type,
    this.className, {
    this.comment,
    this.jsonKeyInfo,
    this.isEnum = false,
  });

  @override
  String toString() => "$name: $type ($className)";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NameTypeClassComment &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          type == other.type &&
          className == other.className;

  @override
  int get hashCode => name.hashCode ^ type.hashCode ^ className.hashCode;
}

class NameTypeClassCommentData<TMeta1> {
  final String name;
  final String? type;
  final String? className;
  final String? comment;
  final TMeta1? meta1;

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
  final String? toJson;
  final String? fromJson;

  const JsonKeyInfo({
    this.name,
    this.ignore,
    this.defaultValue,
    this.required,
    this.includeIfNull,
    this.includeFromJson,
    this.includeToJson,
    this.toJson,
    this.fromJson,
  });

  /// Generates the annotation string representation
  String toAnnotationString() {
    final params = <String>[];

    if (name != null) params.add("name: '$name'");
    if (ignore != null) params.add("ignore: $ignore");
    if (defaultValue != null) params.add("defaultValue: $defaultValue");
    if (required != null) params.add("required: $required");
    if (includeIfNull != null) params.add("includeIfNull: $includeIfNull");
    if (includeFromJson != null)
      params.add("includeFromJson: $includeFromJson");
    if (includeToJson != null) params.add("includeToJson: $includeToJson");
    if (toJson != null) params.add("toJson: $toJson");
    if (fromJson != null) params.add("fromJson: $fromJson");

    if (params.isEmpty) return "@JsonKey()";
    return "@JsonKey(${params.join(", ")})";
  }

  bool get hasAnnotations => params.isNotEmpty;

  List<String> get params {
    final result = <String>[];
    if (name != null) result.add("name");
    if (ignore != null) result.add("ignore");
    if (defaultValue != null) result.add("defaultValue");
    if (required != null) result.add("required");
    if (includeIfNull != null) result.add("includeIfNull");
    if (includeFromJson != null) result.add("includeFromJson");
    if (includeToJson != null) result.add("includeToJson");
    if (toJson != null) result.add("toJson");
    if (fromJson != null) result.add("fromJson");
    return result;
  }
}
