// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex59_json_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class Person extends $Person {
  @override
  final int age;

  Person({
    required this.age,
  });

  Person copyWith({
    int? age,
  }) {
    return Person(
      age: age ?? this.age,
    );
  }

  Person copyWithPerson({
    int? age,
  }) {
    return copyWith(
      age: age,
    );
  }

  Person patchWithPerson({
    PersonPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PersonPatch();
    final _patchMap = _patcher.toPatch();
    return Person(
        age: _patchMap.containsKey(Person$.age)
            ? (_patchMap[Person$.age] is Function)
                ? _patchMap[Person$.age](this.age)
                : _patchMap[Person$.age]
            : this.age);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && age == other.age;
  }

  @override
  int get hashCode {
    return Object.hash(age, 0);
  }

  @override
  String toString() {
    return 'Person(' + 'age: ${age})';
  }

  /// Creates a [Person] instance from JSON
  factory Person.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$PersonFromJson(json);
    }
    if (json['_className_'] == "Athlete") {
      return Athlete.fromJson(json);
    } else if (json['_className_'] == "BaseballPlayer") {
      return BaseballPlayer.fromJson(json);
    } else if (json['_className_'] == "Person") {
      return _$PersonFromJson(json);
    }
    throw UnsupportedError(
        "The _className_ '${json['_className_']}' is not supported by the Person.fromJson constructor.");
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PersonToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum Person$ { age }

class PersonPatch implements Patch<Person> {
  final Map<Person$, dynamic> _patch = {};

  static PersonPatch create([Map<String, dynamic>? diff]) {
    final patch = PersonPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Person$.values.firstWhere((e) => e.name == key);
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

  static PersonPatch fromPatch(Map<Person$, dynamic> patch) {
    final _patch = PersonPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Person$, dynamic> toPatch() => Map.from(_patch);

  Person applyTo(Person entity) {
    return entity.patchWithPerson(patchInput: this);
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

  static PersonPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  PersonPatch withAge(int? value) {
    _patch[Person$.age] = value;
    return this;
  }
}

extension PersonSerialization on Person {
  Map<String, dynamic> toJson() => _$PersonToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PersonToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension PersonCompareE on Person {
  Map<String, dynamic> compareToPerson(Person other) {
    final Map<String, dynamic> diff = {};

    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    return diff;
  }
}

extension PersonChangeToE on Person {
  Athlete changeToAthlete({required int speed}) {
    final _patcher = AthletePatch();
    _patcher.withSpeed(speed);
    final _patchMap = _patcher.toPatch();
    return Athlete(
        speed: _patchMap[Athlete$.speed],
        age: _patchMap.containsKey(Athlete$.age)
            ? (_patchMap[Athlete$.age] is Function)
                ? _patchMap[Athlete$.age](age)
                : _patchMap[Athlete$.age]
            : age);
  }

  BaseballPlayer changeToBaseballPlayer(
      {required int height, required int speed}) {
    final _patcher = BaseballPlayerPatch();
    _patcher.withHeight(height);
    _patcher.withSpeed(speed);
    final _patchMap = _patcher.toPatch();
    return BaseballPlayer(
        height: _patchMap[BaseballPlayer$.height],
        speed: _patchMap[BaseballPlayer$.speed],
        age: _patchMap.containsKey(BaseballPlayer$.age)
            ? (_patchMap[BaseballPlayer$.age] is Function)
                ? _patchMap[BaseballPlayer$.age](age)
                : _patchMap[BaseballPlayer$.age]
            : age);
  }
}

@JsonSerializable(explicitToJson: true)
class Athlete extends $Athlete implements Person {
  @override
  final int age;
  @override
  final int speed;

  Athlete({
    required this.age,
    required this.speed,
  });

  Athlete copyWith({
    int? age,
    int? speed,
  }) {
    return Athlete(
      age: age ?? this.age,
      speed: speed ?? this.speed,
    );
  }

  Athlete copyWithAthlete({
    int? age,
    int? speed,
  }) {
    return copyWith(
      age: age,
      speed: speed,
    );
  }

  Athlete patchWithAthlete({
    AthletePatch? patchInput,
  }) {
    final _patcher = patchInput ?? AthletePatch();
    final _patchMap = _patcher.toPatch();
    return Athlete(
        age: _patchMap.containsKey(Athlete$.age)
            ? (_patchMap[Athlete$.age] is Function)
                ? _patchMap[Athlete$.age](this.age)
                : _patchMap[Athlete$.age]
            : this.age,
        speed: _patchMap.containsKey(Athlete$.speed)
            ? (_patchMap[Athlete$.speed] is Function)
                ? _patchMap[Athlete$.speed](this.speed)
                : _patchMap[Athlete$.speed]
            : this.speed);
  }

  Athlete copyWithPerson({
    int? age,
  }) {
    return copyWith(
      age: age,
    );
  }

  Athlete patchWithPerson({
    PersonPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PersonPatch();
    final _patchMap = _patcher.toPatch();
    return Athlete(
      age: _patchMap.containsKey(Person$.age)
          ? (_patchMap[Person$.age] is Function)
              ? _patchMap[Person$.age](this.age)
              : _patchMap[Person$.age]
          : this.age,
      speed: this.speed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Athlete && age == other.age && speed == other.speed;
  }

  @override
  int get hashCode {
    return Object.hash(this.age, this.speed);
  }

  @override
  String toString() {
    return 'Athlete(' + 'age: ${age}' + ', ' + 'speed: ${speed})';
  }

  /// Creates a [Athlete] instance from JSON
  factory Athlete.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$AthleteFromJson(json);
    }
    if (json['_className_'] == "BaseballPlayer") {
      return BaseballPlayer.fromJson(json);
    } else if (json['_className_'] == "Athlete") {
      return _$AthleteFromJson(json);
    }
    throw UnsupportedError(
        "The _className_ '${json['_className_']}' is not supported by the Athlete.fromJson constructor.");
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AthleteToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum Athlete$ { age, speed }

class AthletePatch implements Patch<Athlete> {
  final Map<Athlete$, dynamic> _patch = {};

  static AthletePatch create([Map<String, dynamic>? diff]) {
    final patch = AthletePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Athlete$.values.firstWhere((e) => e.name == key);
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

  static AthletePatch fromPatch(Map<Athlete$, dynamic> patch) {
    final _patch = AthletePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Athlete$, dynamic> toPatch() => Map.from(_patch);

  Athlete applyTo(Athlete entity) {
    return entity.patchWithAthlete(patchInput: this);
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

  static AthletePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  AthletePatch withAge(int? value) {
    _patch[Athlete$.age] = value;
    return this;
  }

  AthletePatch withSpeed(int? value) {
    _patch[Athlete$.speed] = value;
    return this;
  }
}

extension AthleteSerialization on Athlete {
  Map<String, dynamic> toJson() => _$AthleteToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AthleteToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension AthleteCompareE on Athlete {
  Map<String, dynamic> compareToAthlete(Athlete other) {
    final Map<String, dynamic> diff = {};

    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (speed != other.speed) {
      diff['speed'] = () => other.speed;
    }
    return diff;
  }
}

extension AthleteChangeToE on Athlete {
  BaseballPlayer changeToBaseballPlayer({required int height}) {
    final _patcher = BaseballPlayerPatch();
    _patcher.withHeight(height);
    final _patchMap = _patcher.toPatch();
    return BaseballPlayer(
        height: _patchMap[BaseballPlayer$.height],
        speed: _patchMap.containsKey(BaseballPlayer$.speed)
            ? (_patchMap[BaseballPlayer$.speed] is Function)
                ? _patchMap[BaseballPlayer$.speed](speed)
                : _patchMap[BaseballPlayer$.speed]
            : speed,
        age: _patchMap.containsKey(BaseballPlayer$.age)
            ? (_patchMap[BaseballPlayer$.age] is Function)
                ? _patchMap[BaseballPlayer$.age](age)
                : _patchMap[BaseballPlayer$.age]
            : age);
  }
}

@JsonSerializable(explicitToJson: true)
class BaseballPlayer extends $BaseballPlayer implements Athlete, Person {
  @override
  final int speed;
  @override
  final int age;
  @override
  final int height;

  BaseballPlayer({
    required this.speed,
    required this.age,
    required this.height,
  });

  BaseballPlayer copyWith({
    int? speed,
    int? age,
    int? height,
  }) {
    return BaseballPlayer(
      speed: speed ?? this.speed,
      age: age ?? this.age,
      height: height ?? this.height,
    );
  }

  BaseballPlayer copyWithBaseballPlayer({
    int? speed,
    int? age,
    int? height,
  }) {
    return copyWith(
      speed: speed,
      age: age,
      height: height,
    );
  }

  BaseballPlayer patchWithBaseballPlayer({
    BaseballPlayerPatch? patchInput,
  }) {
    final _patcher = patchInput ?? BaseballPlayerPatch();
    final _patchMap = _patcher.toPatch();
    return BaseballPlayer(
        speed: _patchMap.containsKey(BaseballPlayer$.speed)
            ? (_patchMap[BaseballPlayer$.speed] is Function)
                ? _patchMap[BaseballPlayer$.speed](this.speed)
                : _patchMap[BaseballPlayer$.speed]
            : this.speed,
        age: _patchMap.containsKey(BaseballPlayer$.age)
            ? (_patchMap[BaseballPlayer$.age] is Function)
                ? _patchMap[BaseballPlayer$.age](this.age)
                : _patchMap[BaseballPlayer$.age]
            : this.age,
        height: _patchMap.containsKey(BaseballPlayer$.height)
            ? (_patchMap[BaseballPlayer$.height] is Function)
                ? _patchMap[BaseballPlayer$.height](this.height)
                : _patchMap[BaseballPlayer$.height]
            : this.height);
  }

  BaseballPlayer copyWithAthlete({
    int? speed,
  }) {
    return copyWith(
      speed: speed,
    );
  }

  BaseballPlayer copyWithPerson({
    int? age,
  }) {
    return copyWith(
      age: age,
    );
  }

  BaseballPlayer patchWithAthlete({
    AthletePatch? patchInput,
  }) {
    final _patcher = patchInput ?? AthletePatch();
    final _patchMap = _patcher.toPatch();
    return BaseballPlayer(
      speed: _patchMap.containsKey(Athlete$.speed)
          ? (_patchMap[Athlete$.speed] is Function)
              ? _patchMap[Athlete$.speed](this.speed)
              : _patchMap[Athlete$.speed]
          : this.speed,
      age: this.age,
      height: this.height,
    );
  }

  BaseballPlayer patchWithPerson({
    PersonPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PersonPatch();
    final _patchMap = _patcher.toPatch();
    return BaseballPlayer(
      speed: this.speed,
      age: _patchMap.containsKey(Person$.age)
          ? (_patchMap[Person$.age] is Function)
              ? _patchMap[Person$.age](this.age)
              : _patchMap[Person$.age]
          : this.age,
      height: this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseballPlayer &&
        speed == other.speed &&
        age == other.age &&
        height == other.height;
  }

  @override
  int get hashCode {
    return Object.hash(this.speed, this.age, this.height);
  }

  @override
  String toString() {
    return 'BaseballPlayer(' +
        'speed: ${speed}' +
        ', ' +
        'age: ${age}' +
        ', ' +
        'height: ${height})';
  }

  /// Creates a [BaseballPlayer] instance from JSON
  factory BaseballPlayer.fromJson(Map<String, dynamic> json) =>
      _$BaseballPlayerFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BaseballPlayerToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum BaseballPlayer$ { speed, age, height }

class BaseballPlayerPatch implements Patch<BaseballPlayer> {
  final Map<BaseballPlayer$, dynamic> _patch = {};

  static BaseballPlayerPatch create([Map<String, dynamic>? diff]) {
    final patch = BaseballPlayerPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue =
              BaseballPlayer$.values.firstWhere((e) => e.name == key);
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

  static BaseballPlayerPatch fromPatch(Map<BaseballPlayer$, dynamic> patch) {
    final _patch = BaseballPlayerPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<BaseballPlayer$, dynamic> toPatch() => Map.from(_patch);

  BaseballPlayer applyTo(BaseballPlayer entity) {
    return entity.patchWithBaseballPlayer(patchInput: this);
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

  static BaseballPlayerPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  BaseballPlayerPatch withSpeed(int? value) {
    _patch[BaseballPlayer$.speed] = value;
    return this;
  }

  BaseballPlayerPatch withAge(int? value) {
    _patch[BaseballPlayer$.age] = value;
    return this;
  }

  BaseballPlayerPatch withHeight(int? value) {
    _patch[BaseballPlayer$.height] = value;
    return this;
  }
}

extension BaseballPlayerSerialization on BaseballPlayer {
  Map<String, dynamic> toJson() => _$BaseballPlayerToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BaseballPlayerToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension BaseballPlayerCompareE on BaseballPlayer {
  Map<String, dynamic> compareToBaseballPlayer(BaseballPlayer other) {
    final Map<String, dynamic> diff = {};

    if (speed != other.speed) {
      diff['speed'] = () => other.speed;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (height != other.height) {
      diff['height'] = () => other.height;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Building extends $Building {
  @override
  final List<Person> people;

  Building({
    required this.people,
  });

  Building copyWith({
    List<Person>? people,
  }) {
    return Building(
      people: people ?? this.people,
    );
  }

  Building copyWithBuilding({
    List<Person>? people,
  }) {
    return copyWith(
      people: people,
    );
  }

  Building patchWithBuilding({
    BuildingPatch? patchInput,
  }) {
    final _patcher = patchInput ?? BuildingPatch();
    final _patchMap = _patcher.toPatch();
    return Building(
        people: _patchMap.containsKey(Building$.people)
            ? (_patchMap[Building$.people] is Function)
                ? _patchMap[Building$.people](this.people)
                : _patchMap[Building$.people]
            : this.people);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Building && people == other.people;
  }

  @override
  int get hashCode {
    return Object.hash(people, 0);
  }

  @override
  String toString() {
    return 'Building(' + 'people: ${people})';
  }

  /// Creates a [Building] instance from JSON
  factory Building.fromJson(Map<String, dynamic> json) =>
      _$BuildingFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BuildingToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum Building$ { people }

class BuildingPatch implements Patch<Building> {
  final Map<Building$, dynamic> _patch = {};

  static BuildingPatch create([Map<String, dynamic>? diff]) {
    final patch = BuildingPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Building$.values.firstWhere((e) => e.name == key);
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

  static BuildingPatch fromPatch(Map<Building$, dynamic> patch) {
    final _patch = BuildingPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Building$, dynamic> toPatch() => Map.from(_patch);

  Building applyTo(Building entity) {
    return entity.patchWithBuilding(patchInput: this);
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

  static BuildingPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  BuildingPatch withPeople(List<Person>? value) {
    _patch[Building$.people] = value;
    return this;
  }

  BuildingPatch updatePeopleAt(
      int index, PersonPatch Function(PersonPatch) patch) {
    _patch[Building$.people] = (List<dynamic> list) {
      var updatedList = List.from(list);
      if (index >= 0 && index < updatedList.length) {
        updatedList[index] = patch(updatedList[index] as PersonPatch);
      }
      return updatedList;
    };
    return this;
  }
}

extension BuildingSerialization on Building {
  Map<String, dynamic> toJson() => _$BuildingToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BuildingToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json
        ..forEach((key, value) {
          json[key] = _sanitizeJson(value);
        });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension BuildingCompareE on Building {
  Map<String, dynamic> compareToBuilding(Building other) {
    final Map<String, dynamic> diff = {};

    if (people != other.people) {
      diff['people'] = () => other.people;
    }
    return diff;
  }
}
