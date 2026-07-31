// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'compare_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class Person {
  final String name;
  final int age;

  Person({required this.name, required this.age});

  Person copyWith({String? name, int? age}) {
    return Person(name: name ?? this.name, age: age ?? this.age);
  }

  Person copyWithPerson({String? name, int? age}) {
    return copyWith(name: name, age: age);
  }

  Person patchWithPerson({PersonPatch? patchInput}) {
    final _patcher = patchInput ?? PersonPatch();
    final _patchMap = _patcher.patchMap;
    return Person(
      name: _patchMap.containsKey(Person$.name)
          ? (_patchMap[Person$.name] is Function)
                ? _patchMap[Person$.name](this.name)
                : (_patchMap[Person$.name] is Patch)
                ? _patchMap[Person$.name].applyTo(this.name)
                : _patchMap[Person$.name]
          : this.name,
      age: _patchMap.containsKey(Person$.age)
          ? (_patchMap[Person$.age] is Function)
                ? _patchMap[Person$.age](this.age)
                : (_patchMap[Person$.age] is Patch)
                ? _patchMap[Person$.age].applyTo(this.age)
                : _patchMap[Person$.age]
          : this.age,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && name == other.name && age == other.age;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.age);
  }

  @override
  String toString() {
    return 'Person(' + 'name: ${name}' + ', ' + 'age: ${age})';
  }
}

extension PersonPropertyHelpers on Person {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

enum Person$ { name, age }

class PersonPatch extends PatchBase<Person, Person$> {
  Person applyTo(Person entity) {
    return entity.patchWithPerson(patchInput: this);
  }

  PersonPatch withName(String? value) {
    patchMap[Person$.name] = value;
    return this;
  }

  PersonPatch withAge(int? value) {
    patchMap[Person$.age] = value;
    return this;
  }
}

/// Field descriptors for [Person] query construction
abstract final class PersonFields {
  static String _$getname(Person e) => e.name;
  static const name = Field<Person, String>('name', _$getname);
  static int _$getage(Person e) => e.age;
  static const age = Field<Person, int>('age', _$getage);
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
    return diff;
  }
}
