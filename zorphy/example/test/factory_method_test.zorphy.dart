// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'factory_method_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class Person implements $Person {
  final String? firstName;
  final String? lastName;
  final int? age;

  Person({
    this.firstName,
    this.lastName,
    this.age,
  });

  Person._copyWith({
    String?? firstName,
    String?? lastName,
    int?? age,
  }) : 
    firstName = firstName ?? (() { throw ArgumentError("firstName is required"); })(),
    lastName = lastName ?? (() { throw ArgumentError("lastName is required"); })(),
    age = age ?? (() { throw ArgumentError("age is required"); })();

  Person copyWith({
    String? firstName,
    String? lastName,
    int? age,
  }) {
    return Person(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
    );
  }

  Person copyWithPerson({
    String? firstName,
    String? lastName,
    int? age,
  }) {
    return copyWith(
      firstName: firstName, lastName: lastName, age: age,
    );
  }

  Person copyWithFn({
    String? Function(String?)? firstName,
    String? Function(String?)? lastName,
    int? Function(int?)? age,
  }) {
    return Person(
      firstName: firstName != null ? firstName(this.firstName) : this.firstName,
      lastName: lastName != null ? lastName(this.lastName) : this.lastName,
      age: age != null ? age(this.age) : this.age,
    );
  }

  factory Person.fromNames({required String firstName, required String lastName}) => Person.fromNames(firstName: firstName, lastName: lastName);


  factory Person.withAge(String firstName, String lastName, int age) => Person.withAge(firstName, lastName, age);


  factory Person.empty() => Person.empty();


  Person patchWithPerson({
    PersonPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PersonPatch();
    final _patchMap = _patcher.toPatch();
    return Person(
      firstName: _patchMap.containsKey(Person$.firstName) ? (_patchMap[Person$.firstName] is Function) ? _patchMap[Person$.firstName](this.firstName) : _patchMap[Person$.firstName] : this.firstName,
      lastName: _patchMap.containsKey(Person$.lastName) ? (_patchMap[Person$.lastName] is Function) ? _patchMap[Person$.lastName](this.lastName) : _patchMap[Person$.lastName] : this.lastName,
      age: _patchMap.containsKey(Person$.age) ? (_patchMap[Person$.age] is Function) ? _patchMap[Person$.age](this.age) : _patchMap[Person$.age] : this.age
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person &&
        firstName == other.firstName &&
        lastName == other.lastName &&
        age == other.age;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.firstName,
      this.lastName,
      this.age);
  }

  @override
  String toString() {
    return 'Person(' +
        'firstName: ${firstName}' + ', ' +
        'lastName: ${lastName}' + ', ' +
        'age: ${age})';
  }

}
enum Person$ {
firstName,lastName,age
}


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
    if (value is Map) return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
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

  PersonPatch withFirstName(String? value) {
    _patch[Person$.firstName] = value;
    return this;
  }

  PersonPatch withLastName(String? value) {
    _patch[Person$.lastName] = value;
    return this;
  }

  PersonPatch withAge(int? value) {
    _patch[Person$.age] = value;
    return this;
  }

}


extension PersonCompareE on Person {
  Map<String, dynamic> compareToPerson(Person other) {
    final Map<String, dynamic> diff = {};

    if (firstName != other.firstName) {
      diff['firstName'] = () => other.firstName;
    }
    if (lastName != other.lastName) {
      diff['lastName'] = () => other.lastName;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    return diff;
  }
}




class Actor extends $Actor {
  @override
  final String? stageName;
  @override
  final int? yearsActive;

  Actor({
    this.stageName,
    this.yearsActive,
  });

  Actor._copyWith({
    String?? stageName,
    int?? yearsActive,
  }) : 
    stageName = stageName ?? (() { throw ArgumentError("stageName is required"); })(),
    yearsActive = yearsActive ?? (() { throw ArgumentError("yearsActive is required"); })();

  Actor copyWith({
    String? stageName,
    int? yearsActive,
  }) {
    return Actor(
      stageName: stageName ?? this.stageName,
      yearsActive: yearsActive ?? this.yearsActive,
    );
  }

  Actor copyWithActor({
    String? stageName,
    int? yearsActive,
  }) {
    return copyWith(
      stageName: stageName, yearsActive: yearsActive,
    );
  }

  Actor copyWithFn({
    String? Function(String?)? stageName,
    int? Function(int?)? yearsActive,
  }) {
    return Actor(
      stageName: stageName != null ? stageName(this.stageName) : this.stageName,
      yearsActive: yearsActive != null ? yearsActive(this.yearsActive) : this.yearsActive,
    );
  }

  Actor patchWithActor({
    ActorPatch? patchInput,
  }) {
    final _patcher = patchInput ?? ActorPatch();
    final _patchMap = _patcher.toPatch();
    return Actor(
      stageName: _patchMap.containsKey(Actor$.stageName) ? (_patchMap[Actor$.stageName] is Function) ? _patchMap[Actor$.stageName](this.stageName) : _patchMap[Actor$.stageName] : this.stageName,
      yearsActive: _patchMap.containsKey(Actor$.yearsActive) ? (_patchMap[Actor$.yearsActive] is Function) ? _patchMap[Actor$.yearsActive](this.yearsActive) : _patchMap[Actor$.yearsActive] : this.yearsActive
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Actor &&
        stageName == other.stageName &&
        yearsActive == other.yearsActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.stageName,
      this.yearsActive);
  }

  @override
  String toString() {
    return 'Actor(' +
        'stageName: ${stageName}' + ', ' +
        'yearsActive: ${yearsActive})';
  }

}
enum Actor$ {
stageName,yearsActive
}


class ActorPatch implements Patch<Actor> {
  final Map<Actor$, dynamic> _patch = {};

  static ActorPatch create([Map<String, dynamic>? diff]) {
    final patch = ActorPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Actor$.values.firstWhere((e) => e.name == key);
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

  static ActorPatch fromPatch(Map<Actor$, dynamic> patch) {
    final _patch = ActorPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Actor$, dynamic> toPatch() => Map.from(_patch);

  Actor applyTo(Actor entity) {
    return entity.patchWithActor(patchInput: this);
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

  static ActorPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ActorPatch withStageName(String? value) {
    _patch[Actor$.stageName] = value;
    return this;
  }

  ActorPatch withYearsActive(int? value) {
    _patch[Actor$.yearsActive] = value;
    return this;
  }

}


extension ActorCompareE on Actor {
  Map<String, dynamic> compareToActor(Actor other) {
    final Map<String, dynamic> diff = {};

    if (stageName != other.stageName) {
      diff['stageName'] = () => other.stageName;
    }
    if (yearsActive != other.yearsActive) {
      diff['yearsActive'] = () => other.yearsActive;
    }
    return diff;
  }
}




class Employee implements $Employee, Person {
  final String? firstName;
  final String? lastName;
  final int? age;
  final String? department;
  final double? salary;

  Employee({
    this.firstName,
    this.lastName,
    this.age,
    this.department,
    this.salary,
  });

  Employee._copyWith({
    String?? firstName,
    String?? lastName,
    int?? age,
    String?? department,
    double?? salary,
  }) : 
    firstName = firstName ?? (() { throw ArgumentError("firstName is required"); })(),
    lastName = lastName ?? (() { throw ArgumentError("lastName is required"); })(),
    age = age ?? (() { throw ArgumentError("age is required"); })(),
    department = department ?? (() { throw ArgumentError("department is required"); })(),
    salary = salary ?? (() { throw ArgumentError("salary is required"); })();

  Employee copyWith({
    String? firstName,
    String? lastName,
    int? age,
    String? department,
    double? salary,
  }) {
    return Employee(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      department: department ?? this.department,
      salary: salary ?? this.salary,
    );
  }

  Employee copyWithEmployee({
    String? firstName,
    String? lastName,
    int? age,
    String? department,
    double? salary,
  }) {
    return copyWith(
      firstName: firstName, lastName: lastName, age: age, department: department, salary: salary,
    );
  }

  Employee copyWithFn({
    String? Function(String?)? firstName,
    String? Function(String?)? lastName,
    int? Function(int?)? age,
    String? Function(String?)? department,
    double? Function(double?)? salary,
  }) {
    return Employee(
      firstName: firstName != null ? firstName(this.firstName) : this.firstName,
      lastName: lastName != null ? lastName(this.lastName) : this.lastName,
      age: age != null ? age(this.age) : this.age,
      department: department != null ? department(this.department) : this.department,
      salary: salary != null ? salary(this.salary) : this.salary,
    );
  }

  factory Employee.newHire({required String firstName, required String lastName, required String department}) => Employee.newHire(firstName: firstName, lastName: lastName, department: department);


  Employee patchWithEmployee({
    EmployeePatch? patchInput,
  }) {
    final _patcher = patchInput ?? EmployeePatch();
    final _patchMap = _patcher.toPatch();
    return Employee(
      firstName: _patchMap.containsKey(Employee$.firstName) ? (_patchMap[Employee$.firstName] is Function) ? _patchMap[Employee$.firstName](this.firstName) : _patchMap[Employee$.firstName] : this.firstName,
      lastName: _patchMap.containsKey(Employee$.lastName) ? (_patchMap[Employee$.lastName] is Function) ? _patchMap[Employee$.lastName](this.lastName) : _patchMap[Employee$.lastName] : this.lastName,
      age: _patchMap.containsKey(Employee$.age) ? (_patchMap[Employee$.age] is Function) ? _patchMap[Employee$.age](this.age) : _patchMap[Employee$.age] : this.age,
      department: _patchMap.containsKey(Employee$.department) ? (_patchMap[Employee$.department] is Function) ? _patchMap[Employee$.department](this.department) : _patchMap[Employee$.department] : this.department,
      salary: _patchMap.containsKey(Employee$.salary) ? (_patchMap[Employee$.salary] is Function) ? _patchMap[Employee$.salary](this.salary) : _patchMap[Employee$.salary] : this.salary
    );
  }


  Employee copyWithPerson({
    String? firstName,
    String? lastName,
    int? age,
  }) {
    return copyWith(
      firstName: firstName, lastName: lastName, age: age,
    );
  }


  Employee patchWithPerson({
    PersonPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PersonPatch();
    final _patchMap = _patcher.toPatch();
    return Employee(
      firstName: _patchMap.containsKey(Person$.firstName) ? (_patchMap[Person$.firstName] is Function) ? _patchMap[Person$.firstName](this.firstName) : _patchMap[Person$.firstName] : this.firstName,
      lastName: _patchMap.containsKey(Person$.lastName) ? (_patchMap[Person$.lastName] is Function) ? _patchMap[Person$.lastName](this.lastName) : _patchMap[Person$.lastName] : this.lastName,
      age: _patchMap.containsKey(Person$.age) ? (_patchMap[Person$.age] is Function) ? _patchMap[Person$.age](this.age) : _patchMap[Person$.age] : this.age,
      department: this.department,
      salary: this.salary,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee &&
        firstName == other.firstName &&
        lastName == other.lastName &&
        age == other.age &&
        department == other.department &&
        salary == other.salary;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.firstName,
      this.lastName,
      this.age,
      this.department,
      this.salary);
  }

  @override
  String toString() {
    return 'Employee(' +
        'firstName: ${firstName}' + ', ' +
        'lastName: ${lastName}' + ', ' +
        'age: ${age}' + ', ' +
        'department: ${department}' + ', ' +
        'salary: ${salary})';
  }

}
enum Employee$ {
firstName,lastName,age,department,salary
}


class EmployeePatch implements Patch<Employee> {
  final Map<Employee$, dynamic> _patch = {};

  static EmployeePatch create([Map<String, dynamic>? diff]) {
    final patch = EmployeePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Employee$.values.firstWhere((e) => e.name == key);
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

  static EmployeePatch fromPatch(Map<Employee$, dynamic> patch) {
    final _patch = EmployeePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Employee$, dynamic> toPatch() => Map.from(_patch);

  Employee applyTo(Employee entity) {
    return entity.patchWithEmployee(patchInput: this);
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

  static EmployeePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  EmployeePatch withFirstName(String? value) {
    _patch[Employee$.firstName] = value;
    return this;
  }

  EmployeePatch withLastName(String? value) {
    _patch[Employee$.lastName] = value;
    return this;
  }

  EmployeePatch withAge(int? value) {
    _patch[Employee$.age] = value;
    return this;
  }

  EmployeePatch withDepartment(String? value) {
    _patch[Employee$.department] = value;
    return this;
  }

  EmployeePatch withSalary(double? value) {
    _patch[Employee$.salary] = value;
    return this;
  }

}


extension EmployeeCompareE on Employee {
  Map<String, dynamic> compareToEmployee(Employee other) {
    final Map<String, dynamic> diff = {};

    if (firstName != other.firstName) {
      diff['firstName'] = () => other.firstName;
    }
    if (lastName != other.lastName) {
      diff['lastName'] = () => other.lastName;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (department != other.department) {
      diff['department'] = () => other.department;
    }
    if (salary != other.salary) {
      diff['salary'] = () => other.salary;
    }
    return diff;
  }
}
