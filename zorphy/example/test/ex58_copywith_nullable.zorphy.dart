// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex58_copywith_nullable.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class Pet extends $Pet {
  @override
  final String? type;
  @override
  final String name;

  Pet({
    this.type,
    required this.name,
  });

  Pet._copyWith({
    String?? type,
    String? name,
  }) : 
    type = type ?? throw ArgumentError("type is required"),
    name = name ?? throw ArgumentError("name is required");

  Pet copyWith({
    String? type,
    String? name,
  }) {
    return Pet(
      type: type ?? this.type,
      name: name ?? this.name,
    );
  }

  Pet copyWithPet({
    String? type,
    String? name,
  }) {
    return copyWith(
      type: type, name: name,
    );
  }

  Pet copyWithFn({
    String? Function(String?)? type,
    String? Function(String?)? name,
  }) {
    return Pet(
      type: type != null ? type(this.type) : this.type,
      name: name != null ? name(this.name) : this.name,
    );
  }

  Pet patchWithPet({
    PetPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PetPatch();
    final _patchMap = _patcher.toPatch();
    return Pet(
      type: _patchMap.containsKey(Pet$.type) ? (_patchMap[Pet$.type] is Function) ? _patchMap[Pet$.type](this.type) : _patchMap[Pet$.type] : this.type,
      name: _patchMap.containsKey(Pet$.name) ? (_patchMap[Pet$.name] is Function) ? _patchMap[Pet$.name](this.name) : _patchMap[Pet$.name] : this.name
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pet &&
        type == other.type &&
        name == other.name;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.type,
      this.name);
  }

  @override
  String toString() {
    return 'Pet(' +
        'type: ${type}' + ', ' +
        'name: ${name})';
  }

}
enum Pet$ {
type,name
}


class PetPatch implements Patch<Pet> {
  final Map<Pet$, dynamic> _patch = {};

  static PetPatch create([Map<String, dynamic>? diff]) {
    final patch = PetPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Pet$.values.firstWhere((e) => e.name == key);
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static PetPatch fromPatch(Map<Pet$, dynamic> patch) {
    final _patch = PetPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Pet$, dynamic> toPatch() => Map.from(_patch);

  Pet applyTo(Pet entity) {
    return entity.patchWithPet(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
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
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
        if (value?.toJsonLean != null) return value.toJsonLean();
      } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static PetPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  PetPatch withType(String? value) {
    _patch[Pet$.type] = value;
    return this;
  }

  PetPatch withName(String? value) {
    _patch[Pet$.name] = value;
    return this;
  }

}


extension PetCompareE on Pet {
  Map<String, dynamic> compareToPet(Pet other) {
    final Map<String, dynamic> diff = {};

    if (type != other.type) {
      diff['type'] = () => other.type;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    return diff;
  }
}
