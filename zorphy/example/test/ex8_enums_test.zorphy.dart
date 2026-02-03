// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex8_enums_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class Pet extends $Pet {
  @override
  final String type;
  @override
  final eBlim blim;

  Pet({
    required this.type,
    required this.blim,
  });

  Pet copyWith({
    String? type,
    eBlim? blim,
  }) {
    return Pet(
      type: type ?? this.type,
      blim: blim ?? this.blim,
    );
  }

  Pet copyWithPet({
    String? type,
    eBlim? blim,
  }) {
    return copyWith(
      type: type,
      blim: blim,
    );
  }

  Pet patchWithPet({
    PetPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PetPatch();
    final _patchMap = _patcher.toPatch();
    return Pet(
        type: _patchMap.containsKey(Pet$.type)
            ? (_patchMap[Pet$.type] is Function)
                ? _patchMap[Pet$.type](this.type)
                : _patchMap[Pet$.type]
            : this.type,
        blim: _patchMap.containsKey(Pet$.blim)
            ? (_patchMap[Pet$.blim] is Function)
                ? _patchMap[Pet$.blim](this.blim)
                : _patchMap[Pet$.blim]
            : this.blim);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pet && type == other.type && blim == other.blim;
  }

  @override
  int get hashCode {
    return Object.hash(this.type, this.blim);
  }

  @override
  String toString() {
    return 'Pet(' + 'type: ${type}' + ', ' + 'blim: ${blim})';
  }

  /// Creates a [Pet] instance from JSON
  factory Pet.fromJson(Map<String, dynamic> json) => _$PetFromJson(json);
}

enum Pet$ { type, blim }

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

  PetPatch withType(String? value) {
    _patch[Pet$.type] = value;
    return this;
  }

  PetPatch withBlim(eBlim? value) {
    _patch[Pet$.blim] = value;
    return this;
  }
}

extension PetSerialization on Pet {
  Map<String, dynamic> toJson() => _$PetToJson(this);
}

extension PetCompareE on Pet {
  Map<String, dynamic> compareToPet(Pet other) {
    final Map<String, dynamic> diff = {};

    if (type != other.type) {
      diff['type'] = () => other.type;
    }
    if (blim != other.blim) {
      diff['blim'] = () => other.blim;
    }
    return diff;
  }
}
