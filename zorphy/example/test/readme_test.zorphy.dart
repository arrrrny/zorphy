// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'readme_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class Pet extends $Pet {
  @override
  final String name;
  @override
  final int age;

  Pet({
    required this.name,
    required this.age,
  });

  Pet._copyWith({
    String? name,
    int? age,
  }) : 
    name = name ?? (() { throw ArgumentError("name is required"); })(),
    age = age ?? (() { throw ArgumentError("age is required"); })();

  Pet copyWith({
    String? name,
    int? age,
  }) {
    return Pet(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }

  Pet copyWithPet({
    String? name,
    int? age,
  }) {
    return copyWith(
      name: name, age: age,
    );
  }

  Pet copyWithFn({
    String? Function(String?)? name,
    int? Function(int?)? age,
  }) {
    return Pet(
      name: name != null ? name(this.name) : this.name,
      age: age != null ? age(this.age) : this.age,
    );
  }

  Pet patchWithPet({
    PetPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PetPatch();
    final _patchMap = _patcher.toPatch();
    return Pet(
      name: _patchMap.containsKey(Pet$.name) ? (_patchMap[Pet$.name] is Function) ? _patchMap[Pet$.name](this.name) : _patchMap[Pet$.name] : this.name,
      age: _patchMap.containsKey(Pet$.age) ? (_patchMap[Pet$.age] is Function) ? _patchMap[Pet$.age](this.age) : _patchMap[Pet$.age] : this.age
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Pet &&
        name == other.name &&
        age == other.age;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.name,
      this.age);
  }

  @override
  String toString() {
    return 'Pet(' +
        'name: ${name}' + ', ' +
        'age: ${age})';
  }


  /// Creates a [Pet] instance from JSON
  factory Pet.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$PetFromJson(json);
    }
    if (json['_className_'] == "Cat") {
      return Cat.fromJson(json);
    } else if (json['_className_'] == "Pet") {
      return _$PetFromJson(json);
    }
    throw UnsupportedError("The _className_ '${json['_className_']}' is not supported by the Pet.fromJson constructor.");
  }
}
enum Pet$ {
name,age
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

  PetPatch withName(String? value) {
    _patch[Pet$.name] = value;
    return this;
  }

  PetPatch withAge(int? value) {
    _patch[Pet$.age] = value;
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

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    return diff;
  }
}


extension PetChangeToE on Pet {
  Cat changeToCat({required double whiskerLength}) {
    final _patcher = CatPatch();
    _patcher.withWhiskerLength(whiskerLength);
    final _patchMap = _patcher.toPatch();
    return Cat(
      whiskerLength: _patchMap[Cat$.whiskerLength],
      name: _patchMap.containsKey(Cat$.name)
          ? (_patchMap[Cat$.name] is Function)
                ? _patchMap[Cat$.name](name)
                : _patchMap[Cat$.name]
          : name,
      age: _patchMap.containsKey(Cat$.age)
          ? (_patchMap[Cat$.age] is Function)
                ? _patchMap[Cat$.age](age)
                : _patchMap[Cat$.age]
          : age
    );
  }

}




@JsonSerializable(explicitToJson: true)
class FrankensteinsDogCat extends $FrankensteinsDogCat implements Dog, Pet, Cat {
  @override
  final String woofSound;
  @override
  final String name;
  @override
  final int age;
  @override
  final double whiskerLength;
  @override
  final int? _ageInYears;

  FrankensteinsDogCat({
    required this.woofSound,
    required this.name,
    required this.age,
    required this.whiskerLength,
    this._ageInYears,
  });

  FrankensteinsDogCat._copyWith({
    String? woofSound,
    String? name,
    int? age,
    double? whiskerLength,
    int?? _ageInYears,
  }) : 
    woofSound = woofSound ?? (() { throw ArgumentError("woofSound is required"); })(),
    name = name ?? (() { throw ArgumentError("name is required"); })(),
    age = age ?? (() { throw ArgumentError("age is required"); })(),
    whiskerLength = whiskerLength ?? (() { throw ArgumentError("whiskerLength is required"); })(),
    _ageInYears = _ageInYears ?? (() { throw ArgumentError("_ageInYears is required"); })();

  FrankensteinsDogCat copyWith({
    String? woofSound,
    String? name,
    int? age,
    double? whiskerLength,
    int? _ageInYears,
  }) {
    return FrankensteinsDogCat(
      woofSound: woofSound ?? this.woofSound,
      name: name ?? this.name,
      age: age ?? this.age,
      whiskerLength: whiskerLength ?? this.whiskerLength,
      _ageInYears: _ageInYears ?? this._ageInYears,
    );
  }

  FrankensteinsDogCat copyWithFrankensteinsDogCat({
    String? woofSound,
    String? name,
    int? age,
    double? whiskerLength,
    int? _ageInYears,
  }) {
    return copyWith(
      woofSound: woofSound, name: name, age: age, whiskerLength: whiskerLength, _ageInYears: _ageInYears,
    );
  }

  FrankensteinsDogCat copyWithFn({
    String? Function(String?)? woofSound,
    String? Function(String?)? name,
    int? Function(int?)? age,
    double? Function(double?)? whiskerLength,
    int? Function(int?)? _ageInYears,
  }) {
    return FrankensteinsDogCat(
      woofSound: woofSound != null ? woofSound(this.woofSound) : this.woofSound,
      name: name != null ? name(this.name) : this.name,
      age: age != null ? age(this.age) : this.age,
      whiskerLength: whiskerLength != null ? whiskerLength(this.whiskerLength) : this.whiskerLength,
      _ageInYears: _ageInYears != null ? _ageInYears(this._ageInYears) : this._ageInYears,
    );
  }

  FrankensteinsDogCat patchWithFrankensteinsDogCat({
    FrankensteinsDogCatPatch? patchInput,
  }) {
    final _patcher = patchInput ?? FrankensteinsDogCatPatch();
    final _patchMap = _patcher.toPatch();
    return FrankensteinsDogCat(
      woofSound: _patchMap.containsKey(FrankensteinsDogCat$.woofSound) ? (_patchMap[FrankensteinsDogCat$.woofSound] is Function) ? _patchMap[FrankensteinsDogCat$.woofSound](this.woofSound) : _patchMap[FrankensteinsDogCat$.woofSound] : this.woofSound,
      name: _patchMap.containsKey(FrankensteinsDogCat$.name) ? (_patchMap[FrankensteinsDogCat$.name] is Function) ? _patchMap[FrankensteinsDogCat$.name](this.name) : _patchMap[FrankensteinsDogCat$.name] : this.name,
      age: _patchMap.containsKey(FrankensteinsDogCat$.age) ? (_patchMap[FrankensteinsDogCat$.age] is Function) ? _patchMap[FrankensteinsDogCat$.age](this.age) : _patchMap[FrankensteinsDogCat$.age] : this.age,
      whiskerLength: _patchMap.containsKey(FrankensteinsDogCat$.whiskerLength) ? (_patchMap[FrankensteinsDogCat$.whiskerLength] is Function) ? _patchMap[FrankensteinsDogCat$.whiskerLength](this.whiskerLength) : _patchMap[FrankensteinsDogCat$.whiskerLength] : this.whiskerLength,
      _ageInYears: _patchMap.containsKey(FrankensteinsDogCat$._ageInYears) ? (_patchMap[FrankensteinsDogCat$._ageInYears] is Function) ? _patchMap[FrankensteinsDogCat$._ageInYears](this._ageInYears) : _patchMap[FrankensteinsDogCat$._ageInYears] : this._ageInYears
    );
  }


  FrankensteinsDogCat copyWithDog({
    String? woofSound,
  }) {
    return copyWith(
      woofSound: woofSound,
    );
  }

  FrankensteinsDogCat copyWithPet({
    String? name,
    int? age,
  }) {
    return copyWith(
      name: name, age: age,
    );
  }

  FrankensteinsDogCat copyWithCat({
    double? whiskerLength,
  }) {
    return copyWith(
      whiskerLength: whiskerLength,
    );
  }


  FrankensteinsDogCat patchWithDog({
    DogPatch? patchInput,
  }) {
    final _patcher = patchInput ?? DogPatch();
    final _patchMap = _patcher.toPatch();
    return FrankensteinsDogCat(
      woofSound: _patchMap.containsKey(Dog$.woofSound) ? (_patchMap[Dog$.woofSound] is Function) ? _patchMap[Dog$.woofSound](this.woofSound) : _patchMap[Dog$.woofSound] : this.woofSound,
      name: this.name,
      age: this.age,
      whiskerLength: this.whiskerLength,
      _ageInYears: this._ageInYears,
    );
  }

  FrankensteinsDogCat patchWithPet({
    PetPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PetPatch();
    final _patchMap = _patcher.toPatch();
    return FrankensteinsDogCat(
      woofSound: this.woofSound,
      name: _patchMap.containsKey(Pet$.name) ? (_patchMap[Pet$.name] is Function) ? _patchMap[Pet$.name](this.name) : _patchMap[Pet$.name] : this.name,
      age: _patchMap.containsKey(Pet$.age) ? (_patchMap[Pet$.age] is Function) ? _patchMap[Pet$.age](this.age) : _patchMap[Pet$.age] : this.age,
      whiskerLength: this.whiskerLength,
      _ageInYears: this._ageInYears,
    );
  }

  FrankensteinsDogCat patchWithCat({
    CatPatch? patchInput,
  }) {
    final _patcher = patchInput ?? CatPatch();
    final _patchMap = _patcher.toPatch();
    return FrankensteinsDogCat(
      woofSound: this.woofSound,
      name: this.name,
      age: this.age,
      whiskerLength: _patchMap.containsKey(Cat$.whiskerLength) ? (_patchMap[Cat$.whiskerLength] is Function) ? _patchMap[Cat$.whiskerLength](this.whiskerLength) : _patchMap[Cat$.whiskerLength] : this.whiskerLength,
      _ageInYears: this._ageInYears,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FrankensteinsDogCat &&
        woofSound == other.woofSound &&
        name == other.name &&
        age == other.age &&
        whiskerLength == other.whiskerLength &&
        _ageInYears == other._ageInYears;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.woofSound,
      this.name,
      this.age,
      this.whiskerLength,
      this._ageInYears);
  }

  @override
  String toString() {
    return 'FrankensteinsDogCat(' +
        'woofSound: ${woofSound}' + ', ' +
        'name: ${name}' + ', ' +
        'age: ${age}' + ', ' +
        'whiskerLength: ${whiskerLength}' + ', ' +
        '_ageInYears: ${_ageInYears})';
  }


  /// Creates a [FrankensteinsDogCat] instance from JSON
  factory FrankensteinsDogCat.fromJson(Map<String, dynamic> json) => _$FrankensteinsDogCatFromJson(json);
}
enum FrankensteinsDogCat$ {
woofSound,name,age,whiskerLength,ageInYears
}


class FrankensteinsDogCatPatch implements Patch<FrankensteinsDogCat> {
  final Map<FrankensteinsDogCat$, dynamic> _patch = {};

  static FrankensteinsDogCatPatch create([Map<String, dynamic>? diff]) {
    final patch = FrankensteinsDogCatPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = FrankensteinsDogCat$.values.firstWhere((e) => e.name == key);
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

  static FrankensteinsDogCatPatch fromPatch(Map<FrankensteinsDogCat$, dynamic> patch) {
    final _patch = FrankensteinsDogCatPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<FrankensteinsDogCat$, dynamic> toPatch() => Map.from(_patch);

  FrankensteinsDogCat applyTo(FrankensteinsDogCat entity) {
    return entity.patchWithFrankensteinsDogCat(patchInput: this);
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

  static FrankensteinsDogCatPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  FrankensteinsDogCatPatch withWoofSound(String? value) {
    _patch[FrankensteinsDogCat$.woofSound] = value;
    return this;
  }

  FrankensteinsDogCatPatch withName(String? value) {
    _patch[FrankensteinsDogCat$.name] = value;
    return this;
  }

  FrankensteinsDogCatPatch withAge(int? value) {
    _patch[FrankensteinsDogCat$.age] = value;
    return this;
  }

  FrankensteinsDogCatPatch withWhiskerLength(double? value) {
    _patch[FrankensteinsDogCat$.whiskerLength] = value;
    return this;
  }

  FrankensteinsDogCatPatch withAgeInYears(int? value) {
    _patch[FrankensteinsDogCat$.ageInYears] = value;
    return this;
  }

}


extension FrankensteinsDogCatSerialization on FrankensteinsDogCat {
  Map<String, dynamic> toJson() => _$FrankensteinsDogCatToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$FrankensteinsDogCatToJson(this);
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

extension FrankensteinsDogCatCompareE on FrankensteinsDogCat {
  Map<String, dynamic> compareToFrankensteinsDogCat(FrankensteinsDogCat other) {
    final Map<String, dynamic> diff = {};

    if (woofSound != other.woofSound) {
      diff['woofSound'] = () => other.woofSound;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (whiskerLength != other.whiskerLength) {
      diff['whiskerLength'] = () => other.whiskerLength;
    }
    if (_ageInYears != other._ageInYears) {
      diff['_ageInYears'] = () => other._ageInYears;
    }
    return diff;
  }
}




@JsonSerializable(explicitToJson: true)
class Cat extends $Cat implements Pet {
  @override
  final String name;
  @override
  final int age;
  @override
  final double whiskerLength;

  Cat({
    required this.name,
    required this.age,
    required this.whiskerLength,
  });

  Cat._copyWith({
    String? name,
    int? age,
    double? whiskerLength,
  }) : 
    name = name ?? (() { throw ArgumentError("name is required"); })(),
    age = age ?? (() { throw ArgumentError("age is required"); })(),
    whiskerLength = whiskerLength ?? (() { throw ArgumentError("whiskerLength is required"); })();

  Cat copyWith({
    String? name,
    int? age,
    double? whiskerLength,
  }) {
    return Cat(
      name: name ?? this.name,
      age: age ?? this.age,
      whiskerLength: whiskerLength ?? this.whiskerLength,
    );
  }

  Cat copyWithCat({
    String? name,
    int? age,
    double? whiskerLength,
  }) {
    return copyWith(
      name: name, age: age, whiskerLength: whiskerLength,
    );
  }

  Cat copyWithFn({
    String? Function(String?)? name,
    int? Function(int?)? age,
    double? Function(double?)? whiskerLength,
  }) {
    return Cat(
      name: name != null ? name(this.name) : this.name,
      age: age != null ? age(this.age) : this.age,
      whiskerLength: whiskerLength != null ? whiskerLength(this.whiskerLength) : this.whiskerLength,
    );
  }

  Cat patchWithCat({
    CatPatch? patchInput,
  }) {
    final _patcher = patchInput ?? CatPatch();
    final _patchMap = _patcher.toPatch();
    return Cat(
      name: _patchMap.containsKey(Cat$.name) ? (_patchMap[Cat$.name] is Function) ? _patchMap[Cat$.name](this.name) : _patchMap[Cat$.name] : this.name,
      age: _patchMap.containsKey(Cat$.age) ? (_patchMap[Cat$.age] is Function) ? _patchMap[Cat$.age](this.age) : _patchMap[Cat$.age] : this.age,
      whiskerLength: _patchMap.containsKey(Cat$.whiskerLength) ? (_patchMap[Cat$.whiskerLength] is Function) ? _patchMap[Cat$.whiskerLength](this.whiskerLength) : _patchMap[Cat$.whiskerLength] : this.whiskerLength
    );
  }


  Cat copyWithPet({
    String? name,
    int? age,
  }) {
    return copyWith(
      name: name, age: age,
    );
  }


  Cat patchWithPet({
    PetPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PetPatch();
    final _patchMap = _patcher.toPatch();
    return Cat(
      name: _patchMap.containsKey(Pet$.name) ? (_patchMap[Pet$.name] is Function) ? _patchMap[Pet$.name](this.name) : _patchMap[Pet$.name] : this.name,
      age: _patchMap.containsKey(Pet$.age) ? (_patchMap[Pet$.age] is Function) ? _patchMap[Pet$.age](this.age) : _patchMap[Pet$.age] : this.age,
      whiskerLength: this.whiskerLength,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cat &&
        name == other.name &&
        age == other.age &&
        whiskerLength == other.whiskerLength;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.name,
      this.age,
      this.whiskerLength);
  }

  @override
  String toString() {
    return 'Cat(' +
        'name: ${name}' + ', ' +
        'age: ${age}' + ', ' +
        'whiskerLength: ${whiskerLength})';
  }


  /// Creates a [Cat] instance from JSON
  factory Cat.fromJson(Map<String, dynamic> json) => _$CatFromJson(json);
}
enum Cat$ {
name,age,whiskerLength
}


class CatPatch implements Patch<Cat> {
  final Map<Cat$, dynamic> _patch = {};

  static CatPatch create([Map<String, dynamic>? diff]) {
    final patch = CatPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Cat$.values.firstWhere((e) => e.name == key);
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

  static CatPatch fromPatch(Map<Cat$, dynamic> patch) {
    final _patch = CatPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Cat$, dynamic> toPatch() => Map.from(_patch);

  Cat applyTo(Cat entity) {
    return entity.patchWithCat(patchInput: this);
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

  static CatPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  CatPatch withName(String? value) {
    _patch[Cat$.name] = value;
    return this;
  }

  CatPatch withAge(int? value) {
    _patch[Cat$.age] = value;
    return this;
  }

  CatPatch withWhiskerLength(double? value) {
    _patch[Cat$.whiskerLength] = value;
    return this;
  }

}


extension CatSerialization on Cat {
  Map<String, dynamic> toJson() => _$CatToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CatToJson(this);
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

extension CatCompareE on Cat {
  Map<String, dynamic> compareToCat(Cat other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (whiskerLength != other.whiskerLength) {
      diff['whiskerLength'] = () => other.whiskerLength;
    }
    return diff;
  }
}




@JsonSerializable(explicitToJson: true)
class Dog extends $Dog implements Pet {
  @override
  final String name;
  @override
  final int age;
  @override
  final String woofSound;

  Dog({
    required this.name,
    required this.age,
    required this.woofSound,
  });

  Dog._copyWith({
    String? name,
    int? age,
    String? woofSound,
  }) : 
    name = name ?? (() { throw ArgumentError("name is required"); })(),
    age = age ?? (() { throw ArgumentError("age is required"); })(),
    woofSound = woofSound ?? (() { throw ArgumentError("woofSound is required"); })();

  Dog copyWith({
    String? name,
    int? age,
    String? woofSound,
  }) {
    return Dog(
      name: name ?? this.name,
      age: age ?? this.age,
      woofSound: woofSound ?? this.woofSound,
    );
  }

  Dog copyWithDog({
    String? name,
    int? age,
    String? woofSound,
  }) {
    return copyWith(
      name: name, age: age, woofSound: woofSound,
    );
  }

  Dog copyWithFn({
    String? Function(String?)? name,
    int? Function(int?)? age,
    String? Function(String?)? woofSound,
  }) {
    return Dog(
      name: name != null ? name(this.name) : this.name,
      age: age != null ? age(this.age) : this.age,
      woofSound: woofSound != null ? woofSound(this.woofSound) : this.woofSound,
    );
  }

  Dog patchWithDog({
    DogPatch? patchInput,
  }) {
    final _patcher = patchInput ?? DogPatch();
    final _patchMap = _patcher.toPatch();
    return Dog(
      name: _patchMap.containsKey(Dog$.name) ? (_patchMap[Dog$.name] is Function) ? _patchMap[Dog$.name](this.name) : _patchMap[Dog$.name] : this.name,
      age: _patchMap.containsKey(Dog$.age) ? (_patchMap[Dog$.age] is Function) ? _patchMap[Dog$.age](this.age) : _patchMap[Dog$.age] : this.age,
      woofSound: _patchMap.containsKey(Dog$.woofSound) ? (_patchMap[Dog$.woofSound] is Function) ? _patchMap[Dog$.woofSound](this.woofSound) : _patchMap[Dog$.woofSound] : this.woofSound
    );
  }


  Dog copyWithPet({
    String? name,
    int? age,
  }) {
    return copyWith(
      name: name, age: age,
    );
  }


  Dog patchWithPet({
    PetPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PetPatch();
    final _patchMap = _patcher.toPatch();
    return Dog(
      name: _patchMap.containsKey(Pet$.name) ? (_patchMap[Pet$.name] is Function) ? _patchMap[Pet$.name](this.name) : _patchMap[Pet$.name] : this.name,
      age: _patchMap.containsKey(Pet$.age) ? (_patchMap[Pet$.age] is Function) ? _patchMap[Pet$.age](this.age) : _patchMap[Pet$.age] : this.age,
      woofSound: this.woofSound,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Dog &&
        name == other.name &&
        age == other.age &&
        woofSound == other.woofSound;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.name,
      this.age,
      this.woofSound);
  }

  @override
  String toString() {
    return 'Dog(' +
        'name: ${name}' + ', ' +
        'age: ${age}' + ', ' +
        'woofSound: ${woofSound})';
  }


  /// Creates a [Dog] instance from JSON
  factory Dog.fromJson(Map<String, dynamic> json) => _$DogFromJson(json);
}
enum Dog$ {
name,age,woofSound
}


class DogPatch implements Patch<Dog> {
  final Map<Dog$, dynamic> _patch = {};

  static DogPatch create([Map<String, dynamic>? diff]) {
    final patch = DogPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Dog$.values.firstWhere((e) => e.name == key);
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

  static DogPatch fromPatch(Map<Dog$, dynamic> patch) {
    final _patch = DogPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Dog$, dynamic> toPatch() => Map.from(_patch);

  Dog applyTo(Dog entity) {
    return entity.patchWithDog(patchInput: this);
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

  static DogPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  DogPatch withName(String? value) {
    _patch[Dog$.name] = value;
    return this;
  }

  DogPatch withAge(int? value) {
    _patch[Dog$.age] = value;
    return this;
  }

  DogPatch withWoofSound(String? value) {
    _patch[Dog$.woofSound] = value;
    return this;
  }

}


extension DogSerialization on Dog {
  Map<String, dynamic> toJson() => _$DogToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$DogToJson(this);
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

extension DogCompareE on Dog {
  Map<String, dynamic> compareToDog(Dog other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (woofSound != other.woofSound) {
      diff['woofSound'] = () => other.woofSound;
    }
    return diff;
  }
}




@JsonSerializable(explicitToJson: true)
class Fish extends $Fish implements Pet {
  @override
  final String name;
  @override
  final int age;
  @override
  final eFishColour fishColour;

  Fish({
    required this.name,
    required this.age,
    required this.fishColour,
  });

  Fish._copyWith({
    String? name,
    int? age,
    eFishColour? fishColour,
  }) : 
    name = name ?? (() { throw ArgumentError("name is required"); })(),
    age = age ?? (() { throw ArgumentError("age is required"); })(),
    fishColour = fishColour ?? (() { throw ArgumentError("fishColour is required"); })();

  Fish copyWith({
    String? name,
    int? age,
    eFishColour? fishColour,
  }) {
    return Fish(
      name: name ?? this.name,
      age: age ?? this.age,
      fishColour: fishColour ?? this.fishColour,
    );
  }

  Fish copyWithFish({
    String? name,
    int? age,
    eFishColour? fishColour,
  }) {
    return copyWith(
      name: name, age: age, fishColour: fishColour,
    );
  }

  Fish copyWithFn({
    String? Function(String?)? name,
    int? Function(int?)? age,
    eFishColour? Function(eFishColour?)? fishColour,
  }) {
    return Fish(
      name: name != null ? name(this.name) : this.name,
      age: age != null ? age(this.age) : this.age,
      fishColour: fishColour != null ? fishColour(this.fishColour) : this.fishColour,
    );
  }

  Fish patchWithFish({
    FishPatch? patchInput,
  }) {
    final _patcher = patchInput ?? FishPatch();
    final _patchMap = _patcher.toPatch();
    return Fish(
      name: _patchMap.containsKey(Fish$.name) ? (_patchMap[Fish$.name] is Function) ? _patchMap[Fish$.name](this.name) : _patchMap[Fish$.name] : this.name,
      age: _patchMap.containsKey(Fish$.age) ? (_patchMap[Fish$.age] is Function) ? _patchMap[Fish$.age](this.age) : _patchMap[Fish$.age] : this.age,
      fishColour: _patchMap.containsKey(Fish$.fishColour) ? (_patchMap[Fish$.fishColour] is Function) ? _patchMap[Fish$.fishColour](this.fishColour) : _patchMap[Fish$.fishColour] : this.fishColour
    );
  }


  Fish copyWithPet({
    String? name,
    int? age,
  }) {
    return copyWith(
      name: name, age: age,
    );
  }


  Fish patchWithPet({
    PetPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PetPatch();
    final _patchMap = _patcher.toPatch();
    return Fish(
      name: _patchMap.containsKey(Pet$.name) ? (_patchMap[Pet$.name] is Function) ? _patchMap[Pet$.name](this.name) : _patchMap[Pet$.name] : this.name,
      age: _patchMap.containsKey(Pet$.age) ? (_patchMap[Pet$.age] is Function) ? _patchMap[Pet$.age](this.age) : _patchMap[Pet$.age] : this.age,
      fishColour: this.fishColour,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fish &&
        name == other.name &&
        age == other.age &&
        fishColour == other.fishColour;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.name,
      this.age,
      this.fishColour);
  }

  @override
  String toString() {
    return 'Fish(' +
        'name: ${name}' + ', ' +
        'age: ${age}' + ', ' +
        'fishColour: ${fishColour})';
  }


  /// Creates a [Fish] instance from JSON
  factory Fish.fromJson(Map<String, dynamic> json) => _$FishFromJson(json);
}
enum Fish$ {
name,age,fishColour
}


class FishPatch implements Patch<Fish> {
  final Map<Fish$, dynamic> _patch = {};

  static FishPatch create([Map<String, dynamic>? diff]) {
    final patch = FishPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Fish$.values.firstWhere((e) => e.name == key);
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

  static FishPatch fromPatch(Map<Fish$, dynamic> patch) {
    final _patch = FishPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Fish$, dynamic> toPatch() => Map.from(_patch);

  Fish applyTo(Fish entity) {
    return entity.patchWithFish(patchInput: this);
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

  static FishPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  FishPatch withName(String? value) {
    _patch[Fish$.name] = value;
    return this;
  }

  FishPatch withAge(int? value) {
    _patch[Fish$.age] = value;
    return this;
  }

  FishPatch withFishColour(eFishColour? value) {
    _patch[Fish$.fishColour] = value;
    return this;
  }

}


extension FishSerialization on Fish {
  Map<String, dynamic> toJson() => _$FishToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$FishToJson(this);
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

extension FishCompareE on Fish {
  Map<String, dynamic> compareToFish(Fish other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (fishColour != other.fishColour) {
      diff['fishColour'] = () => other.fishColour;
    }
    return diff;
  }
}




class PetOwner<TPet extends $Pet> extends $PetOwner {
  @override
  final String ownerName;
  @override
  final TPet pet;

  PetOwner({
    required this.ownerName,
    required this.pet,
  });

  PetOwner copyWith({
    String? ownerName,
    TPet? pet,
  }) {
    return PetOwner(
      ownerName: ownerName ?? this.ownerName,
      pet: pet ?? this.pet,
    );
  }

  PetOwner copyWithPetOwner({
    String? ownerName,
    TPet? pet,
  }) {
    return copyWith(
      ownerName: ownerName, pet: pet,
    );
  }

  PetOwner patchWithPetOwner({
    PetOwnerPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PetOwnerPatch();
    final _patchMap = _patcher.toPatch();
    return PetOwner(
      ownerName: _patchMap.containsKey(PetOwner$.ownerName) ? (_patchMap[PetOwner$.ownerName] is Function) ? _patchMap[PetOwner$.ownerName](this.ownerName) : _patchMap[PetOwner$.ownerName] : this.ownerName,
      pet: _patchMap.containsKey(PetOwner$.pet) ? (_patchMap[PetOwner$.pet] is Function) ? _patchMap[PetOwner$.pet](this.pet) : _patchMap[PetOwner$.pet] : this.pet
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PetOwner &&
        ownerName == other.ownerName &&
        pet == other.pet;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.ownerName,
      this.pet);
  }

  @override
  String toString() {
    return 'PetOwner(' +
        'ownerName: ${ownerName}' + ', ' +
        'pet: ${pet})';
  }

}
enum PetOwner$ {
ownerName,pet
}


class PetOwnerPatch implements Patch<PetOwner> {
  final Map<PetOwner$, dynamic> _patch = {};

  static PetOwnerPatch create([Map<String, dynamic>? diff]) {
    final patch = PetOwnerPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = PetOwner$.values.firstWhere((e) => e.name == key);
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

  static PetOwnerPatch fromPatch(Map<PetOwner$, dynamic> patch) {
    final _patch = PetOwnerPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<PetOwner$, dynamic> toPatch() => Map.from(_patch);

  PetOwner applyTo(PetOwner entity) {
    return entity.patchWithPetOwner(patchInput: this);
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

  static PetOwnerPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  PetOwnerPatch withOwnerName(String? value) {
    _patch[PetOwner$.ownerName] = value;
    return this;
  }

  PetOwnerPatch withPet(dynamic value) {
    _patch[PetOwner$.pet] = value;
    return this;
  }

}


extension PetOwnerCompareE on PetOwner {
  Map<String, dynamic> compareToPetOwner(PetOwner other) {
    final Map<String, dynamic> diff = {};

    if (ownerName != other.ownerName) {
      diff['ownerName'] = () => other.ownerName;
    }
    if (pet != other.pet) {
      diff['pet'] = () => other.pet;
    }
    return diff;
  }
}




class A extends $A {
  @override
  final String val;
  @override
  final DateTime timestamp;

  A copyWith({
    String? val,
    DateTime? timestamp,
  }) {
    return A(
      val: val ?? this.val,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  A copyWithA({
    String? val,
    DateTime? timestamp,
  }) {
    return copyWith(
      val: val, timestamp: timestamp,
    );
  }

  A patchWithA({
    APatch? patchInput,
  }) {
    final _patcher = patchInput ?? APatch();
    final _patchMap = _patcher.toPatch();
    return A(
      val: _patchMap.containsKey(A$.val) ? (_patchMap[A$.val] is Function) ? _patchMap[A$.val](this.val) : _patchMap[A$.val] : this.val,
      timestamp: _patchMap.containsKey(A$.timestamp) ? (_patchMap[A$.timestamp] is Function) ? _patchMap[A$.timestamp](this.timestamp) : _patchMap[A$.timestamp] : this.timestamp
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A &&
        val == other.val &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.val,
      this.timestamp);
  }

  @override
  String toString() {
    return 'A(' +
        'val: ${val}' + ', ' +
        'timestamp: ${timestamp})';
  }

}
enum A$ {
val,timestamp
}


class APatch implements Patch<A> {
  final Map<A$, dynamic> _patch = {};

  static APatch create([Map<String, dynamic>? diff]) {
    final patch = APatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = A$.values.firstWhere((e) => e.name == key);
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

  static APatch fromPatch(Map<A$, dynamic> patch) {
    final _patch = APatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<A$, dynamic> toPatch() => Map.from(_patch);

  A applyTo(A entity) {
    return entity.patchWithA(patchInput: this);
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

  static APatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  APatch withVal(String? value) {
    _patch[A$.val] = value;
    return this;
  }

  APatch withTimestamp(DateTime? value) {
    _patch[A$.timestamp] = value;
    return this;
  }

}


extension ACompareE on A {
  Map<String, dynamic> compareToA(A other) {
    final Map<String, dynamic> diff = {};

    if (val != other.val) {
      diff['val'] = () => other.val;
    }
    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }
    return diff;
  }
}




const class B extends $B {
  @override
  final String val;
  @override
  final String? optional;

  B({
    required this.val,
    this.optional,
  });

  B copyWith({
    String? val,
    String? optional,
  }) {
    return B(
      val: val ?? this.val,
      optional: optional ?? this.optional,
    );
  }

  B copyWithB({
    String? val,
    String? optional,
  }) {
    return copyWith(
      val: val, optional: optional,
    );
  }

  B patchWithB({
    BPatch? patchInput,
  }) {
    final _patcher = patchInput ?? BPatch();
    final _patchMap = _patcher.toPatch();
    return B(
      val: _patchMap.containsKey(B$.val) ? (_patchMap[B$.val] is Function) ? _patchMap[B$.val](this.val) : _patchMap[B$.val] : this.val,
      optional: _patchMap.containsKey(B$.optional) ? (_patchMap[B$.optional] is Function) ? _patchMap[B$.optional](this.optional) : _patchMap[B$.optional] : this.optional
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is B &&
        val == other.val &&
        optional == other.optional;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.val,
      this.optional);
  }

  @override
  String toString() {
    return 'B(' +
        'val: ${val}' + ', ' +
        'optional: ${optional})';
  }

}
enum B$ {
val,optional
}


class BPatch implements Patch<B> {
  final Map<B$, dynamic> _patch = {};

  static BPatch create([Map<String, dynamic>? diff]) {
    final patch = BPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = B$.values.firstWhere((e) => e.name == key);
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

  static BPatch fromPatch(Map<B$, dynamic> patch) {
    final _patch = BPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<B$, dynamic> toPatch() => Map.from(_patch);

  B applyTo(B entity) {
    return entity.patchWithB(patchInput: this);
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

  static BPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  BPatch withVal(String? value) {
    _patch[B$.val] = value;
    return this;
  }

  BPatch withOptional(String? value) {
    _patch[B$.optional] = value;
    return this;
  }

}


extension BCompareE on B {
  Map<String, dynamic> compareToB(B other) {
    final Map<String, dynamic> diff = {};

    if (val != other.val) {
      diff['val'] = () => other.val;
    }
    if (optional != other.optional) {
      diff['optional'] = () => other.optional;
    }
    return diff;
  }
}




@JsonSerializable(explicitToJson: true)
class X extends $X {
  @override
  final String val;

  X({
    required this.val,
  });

  X copyWith({
    String? val,
  }) {
    return X(
      val: val ?? this.val,
    );
  }

  X copyWithX({
    String? val,
  }) {
    return copyWith(
      val: val,
    );
  }

  X patchWithX({
    XPatch? patchInput,
  }) {
    final _patcher = patchInput ?? XPatch();
    final _patchMap = _patcher.toPatch();
    return X(
      val: _patchMap.containsKey(X$.val) ? (_patchMap[X$.val] is Function) ? _patchMap[X$.val](this.val) : _patchMap[X$.val] : this.val
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is X &&
        val == other.val;
  }

  @override
  int get hashCode {
    return Object.hash(val, 0);
  }

  @override
  String toString() {
    return 'X(' +
        'val: ${val})';
  }


  /// Creates a [X] instance from JSON
  factory X.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$XFromJson(json);
    }
    if (json['_className_'] == "Z") {
      return Z.fromJson(json);
    } else if (json['_className_'] == "Y") {
      return Y.fromJson(json);
    } else if (json['_className_'] == "X") {
      return _$XFromJson(json);
    }
    throw UnsupportedError("The _className_ '${json['_className_']}' is not supported by the X.fromJson constructor.");
  }
}
enum X$ {
val
}


class XPatch implements Patch<X> {
  final Map<X$, dynamic> _patch = {};

  static XPatch create([Map<String, dynamic>? diff]) {
    final patch = XPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = X$.values.firstWhere((e) => e.name == key);
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

  static XPatch fromPatch(Map<X$, dynamic> patch) {
    final _patch = XPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<X$, dynamic> toPatch() => Map.from(_patch);

  X applyTo(X entity) {
    return entity.patchWithX(patchInput: this);
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

  static XPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  XPatch withVal(String? value) {
    _patch[X$.val] = value;
    return this;
  }

}


extension XSerialization on X {
  Map<String, dynamic> toJson() => _$XToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$XToJson(this);
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

extension XCompareE on X {
  Map<String, dynamic> compareToX(X other) {
    final Map<String, dynamic> diff = {};

    if (val != other.val) {
      diff['val'] = () => other.val;
    }
    return diff;
  }
}


extension XChangeToE on X {
  Z changeToZ({required double valZ, required int valY, required String a}) {
    final _patcher = ZPatch();
    _patcher.withValZ(valZ);
    _patcher.withValY(valY);
    _patcher.withA(a);
    final _patchMap = _patcher.toPatch();
    return Z(
      valZ: _patchMap[Z$.valZ],
      valY: _patchMap[Z$.valY],
      val: _patchMap.containsKey(Z$.val)
          ? (_patchMap[Z$.val] is Function)
                ? _patchMap[Z$.val](val)
                : _patchMap[Z$.val]
          : val,
      a: _patchMap[Z$.a]
    );
  }

  Y changeToY({required int valY}) {
    final _patcher = YPatch();
    _patcher.withValY(valY);
    final _patchMap = _patcher.toPatch();
    return Y(
      valY: _patchMap[Y$.valY],
      val: _patchMap.containsKey(Y$.val)
          ? (_patchMap[Y$.val] is Function)
                ? _patchMap[Y$.val](val)
                : _patchMap[Y$.val]
          : val
    );
  }

}




@JsonSerializable(explicitToJson: true)
class Y extends $Y implements X {
  @override
  final String val;
  @override
  final int valY;

  Y({
    required this.val,
    required this.valY,
  });

  Y copyWith({
    String? val,
    int? valY,
  }) {
    return Y(
      val: val ?? this.val,
      valY: valY ?? this.valY,
    );
  }

  Y copyWithY({
    String? val,
    int? valY,
  }) {
    return copyWith(
      val: val, valY: valY,
    );
  }

  Y patchWithY({
    YPatch? patchInput,
  }) {
    final _patcher = patchInput ?? YPatch();
    final _patchMap = _patcher.toPatch();
    return Y(
      val: _patchMap.containsKey(Y$.val) ? (_patchMap[Y$.val] is Function) ? _patchMap[Y$.val](this.val) : _patchMap[Y$.val] : this.val,
      valY: _patchMap.containsKey(Y$.valY) ? (_patchMap[Y$.valY] is Function) ? _patchMap[Y$.valY](this.valY) : _patchMap[Y$.valY] : this.valY
    );
  }


  Y copyWithX({
    String? val,
  }) {
    return copyWith(
      val: val,
    );
  }


  Y patchWithX({
    XPatch? patchInput,
  }) {
    final _patcher = patchInput ?? XPatch();
    final _patchMap = _patcher.toPatch();
    return Y(
      val: _patchMap.containsKey(X$.val) ? (_patchMap[X$.val] is Function) ? _patchMap[X$.val](this.val) : _patchMap[X$.val] : this.val,
      valY: this.valY,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Y &&
        val == other.val &&
        valY == other.valY;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.val,
      this.valY);
  }

  @override
  String toString() {
    return 'Y(' +
        'val: ${val}' + ', ' +
        'valY: ${valY})';
  }


  /// Creates a [Y] instance from JSON
  factory Y.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$YFromJson(json);
    }
    if (json['_className_'] == "Z") {
      return Z.fromJson(json);
    } else if (json['_className_'] == "Y") {
      return _$YFromJson(json);
    }
    throw UnsupportedError("The _className_ '${json['_className_']}' is not supported by the Y.fromJson constructor.");
  }
}
enum Y$ {
val,valY
}


class YPatch implements Patch<Y> {
  final Map<Y$, dynamic> _patch = {};

  static YPatch create([Map<String, dynamic>? diff]) {
    final patch = YPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Y$.values.firstWhere((e) => e.name == key);
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

  static YPatch fromPatch(Map<Y$, dynamic> patch) {
    final _patch = YPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Y$, dynamic> toPatch() => Map.from(_patch);

  Y applyTo(Y entity) {
    return entity.patchWithY(patchInput: this);
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

  static YPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  YPatch withVal(String? value) {
    _patch[Y$.val] = value;
    return this;
  }

  YPatch withValY(int? value) {
    _patch[Y$.valY] = value;
    return this;
  }

}


extension YSerialization on Y {
  Map<String, dynamic> toJson() => _$YToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$YToJson(this);
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

extension YCompareE on Y {
  Map<String, dynamic> compareToY(Y other) {
    final Map<String, dynamic> diff = {};

    if (val != other.val) {
      diff['val'] = () => other.val;
    }
    if (valY != other.valY) {
      diff['valY'] = () => other.valY;
    }
    return diff;
  }
}


extension YChangeToE on Y {
  Z changeToZ({required double valZ}) {
    final _patcher = ZPatch();
    _patcher.withValZ(valZ);
    final _patchMap = _patcher.toPatch();
    return Z(
      valZ: _patchMap[Z$.valZ],
      valY: _patchMap.containsKey(Z$.valY)
          ? (_patchMap[Z$.valY] is Function)
                ? _patchMap[Z$.valY](valY)
                : _patchMap[Z$.valY]
          : valY,
      val: _patchMap.containsKey(Z$.val)
          ? (_patchMap[Z$.val] is Function)
                ? _patchMap[Z$.val](val)
                : _patchMap[Z$.val]
          : val
    );
  }

}




@JsonSerializable(explicitToJson: true)
class Z extends $Z implements Y, X {
  @override
  final int valY;
  @override
  final String val;
  @override
  final double valZ;

  Z({
    required this.valY,
    required this.val,
    required this.valZ,
  });

  Z._copyWith({
    int? valY,
    String? val,
    double? valZ,
  }) : 
    valY = valY ?? (() { throw ArgumentError("valY is required"); })(),
    val = val ?? (() { throw ArgumentError("val is required"); })(),
    valZ = valZ ?? (() { throw ArgumentError("valZ is required"); })();

  Z copyWith({
    int? valY,
    String? val,
    double? valZ,
  }) {
    return Z(
      valY: valY ?? this.valY,
      val: val ?? this.val,
      valZ: valZ ?? this.valZ,
    );
  }

  Z copyWithZ({
    int? valY,
    String? val,
    double? valZ,
  }) {
    return copyWith(
      valY: valY, val: val, valZ: valZ,
    );
  }

  Z copyWithFn({
    int? Function(int?)? valY,
    String? Function(String?)? val,
    double? Function(double?)? valZ,
  }) {
    return Z(
      valY: valY != null ? valY(this.valY) : this.valY,
      val: val != null ? val(this.val) : this.val,
      valZ: valZ != null ? valZ(this.valZ) : this.valZ,
    );
  }

  Z patchWithZ({
    ZPatch? patchInput,
  }) {
    final _patcher = patchInput ?? ZPatch();
    final _patchMap = _patcher.toPatch();
    return Z(
      valY: _patchMap.containsKey(Z$.valY) ? (_patchMap[Z$.valY] is Function) ? _patchMap[Z$.valY](this.valY) : _patchMap[Z$.valY] : this.valY,
      val: _patchMap.containsKey(Z$.val) ? (_patchMap[Z$.val] is Function) ? _patchMap[Z$.val](this.val) : _patchMap[Z$.val] : this.val,
      valZ: _patchMap.containsKey(Z$.valZ) ? (_patchMap[Z$.valZ] is Function) ? _patchMap[Z$.valZ](this.valZ) : _patchMap[Z$.valZ] : this.valZ
    );
  }


  Z copyWithY({
    int? valY,
  }) {
    return copyWith(
      valY: valY,
    );
  }

  Z copyWithX({
    String? val,
  }) {
    return copyWith(
      val: val,
    );
  }


  Z patchWithY({
    YPatch? patchInput,
  }) {
    final _patcher = patchInput ?? YPatch();
    final _patchMap = _patcher.toPatch();
    return Z(
      valY: _patchMap.containsKey(Y$.valY) ? (_patchMap[Y$.valY] is Function) ? _patchMap[Y$.valY](this.valY) : _patchMap[Y$.valY] : this.valY,
      val: this.val,
      valZ: this.valZ,
    );
  }

  Z patchWithX({
    XPatch? patchInput,
  }) {
    final _patcher = patchInput ?? XPatch();
    final _patchMap = _patcher.toPatch();
    return Z(
      valY: this.valY,
      val: _patchMap.containsKey(X$.val) ? (_patchMap[X$.val] is Function) ? _patchMap[X$.val](this.val) : _patchMap[X$.val] : this.val,
      valZ: this.valZ,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Z &&
        valY == other.valY &&
        val == other.val &&
        valZ == other.valZ;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.valY,
      this.val,
      this.valZ);
  }

  @override
  String toString() {
    return 'Z(' +
        'valY: ${valY}' + ', ' +
        'val: ${val}' + ', ' +
        'valZ: ${valZ})';
  }


  /// Creates a [Z] instance from JSON
  factory Z.fromJson(Map<String, dynamic> json) => _$ZFromJson(json);
}
enum Z$ {
valY,val,valZ
}


class ZPatch implements Patch<Z> {
  final Map<Z$, dynamic> _patch = {};

  static ZPatch create([Map<String, dynamic>? diff]) {
    final patch = ZPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Z$.values.firstWhere((e) => e.name == key);
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

  static ZPatch fromPatch(Map<Z$, dynamic> patch) {
    final _patch = ZPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Z$, dynamic> toPatch() => Map.from(_patch);

  Z applyTo(Z entity) {
    return entity.patchWithZ(patchInput: this);
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

  static ZPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ZPatch withValY(int? value) {
    _patch[Z$.valY] = value;
    return this;
  }

  ZPatch withVal(String? value) {
    _patch[Z$.val] = value;
    return this;
  }

  ZPatch withValZ(double? value) {
    _patch[Z$.valZ] = value;
    return this;
  }

}


extension ZSerialization on Z {
  Map<String, dynamic> toJson() => _$ZToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ZToJson(this);
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

extension ZCompareE on Z {
  Map<String, dynamic> compareToZ(Z other) {
    final Map<String, dynamic> diff = {};

    if (valY != other.valY) {
      diff['valY'] = () => other.valY;
    }
    if (val != other.val) {
      diff['val'] = () => other.val;
    }
    if (valZ != other.valZ) {
      diff['valZ'] = () => other.valZ;
    }
    return diff;
  }
}
