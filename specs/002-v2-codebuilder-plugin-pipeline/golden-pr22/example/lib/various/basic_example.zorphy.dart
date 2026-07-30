// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'basic_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class User {
  final String name;
  final int age;
  final String? email;

  User({required this.name, required this.age, this.email});

  User copyWith({String? name, int? age, String? email}) {
    return User(
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
    );
  }

  User copyWithUser({String? name, int? age, String? email}) {
    return copyWith(name: name, age: age, email: email);
  }

  User patchWithUser({UserPatch? patchInput}) {
    final _patcher = patchInput ?? UserPatch();
    final _patchMap = _patcher.patchMap;
    return User(
      name: _patchMap.containsKey(User$.name)
          ? (_patchMap[User$.name] is Function)
                ? _patchMap[User$.name](this.name)
                : (_patchMap[User$.name] is Patch)
                ? _patchMap[User$.name].applyTo(this.name)
                : _patchMap[User$.name]
          : this.name,
      age: _patchMap.containsKey(User$.age)
          ? (_patchMap[User$.age] is Function)
                ? _patchMap[User$.age](this.age)
                : (_patchMap[User$.age] is Patch)
                ? _patchMap[User$.age].applyTo(this.age)
                : _patchMap[User$.age]
          : this.age,
      email: _patchMap.containsKey(User$.email)
          ? (_patchMap[User$.email] is Function)
                ? _patchMap[User$.email](this.email)
                : (_patchMap[User$.email] is Patch)
                ? _patchMap[User$.email].applyTo(this.email)
                : _patchMap[User$.email]
          : this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
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
    return 'User(' +
        'name: ${name}' +
        ', ' +
        'age: ${age}' +
        ', ' +
        'email: ${email})';
  }
}

extension UserPropertyHelpers on User {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasEmail => email?.isNotEmpty == true;
  bool get noEmail => email?.isEmpty ?? true;
  String get emailRequired =>
      email ?? (throw StateError('email is required but was null'));
}

enum User$ { name, age, email }

class UserPatch extends PatchBase<User, User$> {
  User applyTo(User entity) {
    return entity.patchWithUser(patchInput: this);
  }

  UserPatch withName(String? value) {
    patchMap[User$.name] = value;
    return this;
  }

  UserPatch withAge(int? value) {
    patchMap[User$.age] = value;
    return this;
  }

  UserPatch withEmail(String? value) {
    patchMap[User$.email] = value;
    return this;
  }
}

extension UserCompareE on User {
  Map<String, dynamic> compareToUser(User other) {
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
