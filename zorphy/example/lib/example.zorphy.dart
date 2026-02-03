// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class Person extends $Person {
  @override
  final String name;
  @override
  final int age;
  @override
  final String? email;

  Person({required this.name, required this.age, this.email});

  Person copyWith({String? name, int? age, String? email}) {
    return Person(
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
    );
  }

  Person copyWithPerson({String? name, int? age, String? email}) {
    return copyWith(name: name, age: age, email: email);
  }

  Person patchWithPerson({PersonPatch? patchInput}) {
    final _patcher = patchInput ?? PersonPatch();
    final _patchMap = _patcher.toPatch();
    return Person(
      name: _patchMap.containsKey(Person$.name)
          ? (_patchMap[Person$.name] is Function)
                ? _patchMap[Person$.name](this.name)
                : _patchMap[Person$.name]
          : this.name,
      age: _patchMap.containsKey(Person$.age)
          ? (_patchMap[Person$.age] is Function)
                ? _patchMap[Person$.age](this.age)
                : _patchMap[Person$.age]
          : this.age,
      email: _patchMap.containsKey(Person$.email)
          ? (_patchMap[Person$.email] is Function)
                ? _patchMap[Person$.email](this.email)
                : _patchMap[Person$.email]
          : this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person &&
        name == other.name &&
        age == other.age &&
        email == other.email;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.age, this.email);
  }

  @override
  String toString() {
    return 'Person(' +
        'name: ${name}' +
        ', ' +
        'age: ${age}' +
        ', ' +
        'email: ${email})';
  }

  /// Creates a [Person] instance from JSON
  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
}

enum Person$ { name, age, email }

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

  PersonPatch withName(String? value) {
    _patch[Person$.name] = value;
    return this;
  }

  PersonPatch withAge(int? value) {
    _patch[Person$.age] = value;
    return this;
  }

  PersonPatch withEmail(String? value) {
    _patch[Person$.email] = value;
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
      return json..forEach((key, value) {
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

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    return diff;
  }
}
