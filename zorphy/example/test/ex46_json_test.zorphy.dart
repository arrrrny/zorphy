// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex46_json_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class Pet extends $Pet {
  @override
  final String kind;

  Pet({required this.kind});

  Pet copyWith({String? kind}) {
    return Pet(kind: kind ?? this.kind);
  }

  Pet copyWithPet({String? kind}) {
    return copyWith(kind: kind);
  }

  Pet patchWithPet({PetPatch? patchInput}) {
    final _patcher = patchInput ?? PetPatch();
    final _patchMap = _patcher.toPatch();
    return Pet(
      kind: _patchMap.containsKey(Pet$.kind)
          ? (_patchMap[Pet$.kind] is Function)
                ? _patchMap[Pet$.kind](this.kind)
                : _patchMap[Pet$.kind]
          : this.kind,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pet && kind == other.kind;
  }

  @override
  int get hashCode {
    return Object.hash(kind, 0);
  }

  @override
  String toString() {
    return 'Pet(' + 'kind: ${kind})';
  }

  /// Creates a [Pet] instance from JSON
  factory Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PetToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum Pet$ { kind }

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
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
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

  PetPatch withKind(String? value) {
    _patch[Pet$.kind] = value;
    return this;
  }
}

extension PetSerialization on Pet {
  Map<String, dynamic> toJson() => _$PetToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PetToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension PetCompareE on Pet {
  Map<String, dynamic> compareToPet(Pet other) {
    final Map<String, dynamic> diff = {};

    if (kind != other.kind) {
      diff['kind'] = () => other.kind;
    }
    return diff;
  }
}
