import 'patch.dart';

abstract class PatchBase<TEntity, TEnum extends Enum>
    implements Patch<TEntity> {
  /// Creates a patch holding [patchMap], or a fresh mutable map when it is
  /// omitted.
  ///
  /// The no-argument form is what the fluent `with*` builders mutate, so it
  /// allocates per instance. A patch that is meant to be constant — the empty
  /// patch, which must be the O(1) neutral element of `compose` — is built
  /// through [PatchBase.empty] instead.
  PatchBase([Map<TEnum, dynamic>? patchMap])
    : patchMap = patchMap ?? <TEnum, dynamic>{};

  /// Creates a patch over a shared `const` empty map.
  ///
  /// Const-constructible and allocation-free: the map is the canonical empty
  /// one, so `isEmpty` is `true` for the whole life of the patch and no
  /// mutation is possible. Generated patches expose it as their `.empty`
  /// constructor.
  const PatchBase.empty() : patchMap = const <Never, Never>{};

  /// The field-keyed changes this patch carries.
  final Map<TEnum, dynamic> patchMap;

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
