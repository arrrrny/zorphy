import 'patch.dart';

abstract class PatchBase<TEntity, TEnum extends Enum>
    implements Patch<TEntity> {
  final Map<TEnum, dynamic> patchMap = {};

  Map<TEnum, dynamic> toPatch() => Map.from(patchMap);

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    patchMap.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.name;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if ((value as dynamic).toJsonLean != null)
        return (value as dynamic).toJsonLean();
    } catch (_) {}
    try {
      if ((value as dynamic).toJson != null) return (value as dynamic).toJson();
    } catch (_) {}
    return value.toString();
  }
}
