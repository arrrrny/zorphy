// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'withPatch_morphy_types_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class Profile extends $Profile {
  @override
  final String name;
  @override
  final int age;

  Profile({
    required this.name,
    required this.age,
  });

  Profile copyWith({
    String? name,
    int? age,
  }) {
    return Profile(
      name: name ?? this.name,
      age: age ?? this.age,
    );
  }

  Profile copyWithProfile({
    String? name,
    int? age,
  }) {
    return copyWith(
      name: name,
      age: age,
    );
  }

  Profile patchWithProfile({
    ProfilePatch? patchInput,
  }) {
    final _patcher = patchInput ?? ProfilePatch();
    final _patchMap = _patcher.toPatch();
    return Profile(
        name: _patchMap.containsKey(Profile$.name)
            ? (_patchMap[Profile$.name] is Function)
                ? _patchMap[Profile$.name](this.name)
                : _patchMap[Profile$.name]
            : this.name,
        age: _patchMap.containsKey(Profile$.age)
            ? (_patchMap[Profile$.age] is Function)
                ? _patchMap[Profile$.age](this.age)
                : _patchMap[Profile$.age]
            : this.age);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile && name == other.name && age == other.age;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.age);
  }

  @override
  String toString() {
    return 'Profile(' + 'name: ${name}' + ', ' + 'age: ${age})';
  }

  /// Creates a [Profile] instance from JSON
  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ProfileToJson(this);
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

enum Profile$ { name, age }

class ProfilePatch implements Patch<Profile> {
  final Map<Profile$, dynamic> _patch = {};

  static ProfilePatch create([Map<String, dynamic>? diff]) {
    final patch = ProfilePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Profile$.values.firstWhere((e) => e.name == key);
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

  static ProfilePatch fromPatch(Map<Profile$, dynamic> patch) {
    final _patch = ProfilePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Profile$, dynamic> toPatch() => Map.from(_patch);

  Profile applyTo(Profile entity) {
    return entity.patchWithProfile(patchInput: this);
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

  static ProfilePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ProfilePatch withName(String? value) {
    _patch[Profile$.name] = value;
    return this;
  }

  ProfilePatch withAge(int? value) {
    _patch[Profile$.age] = value;
    return this;
  }
}

extension ProfileSerialization on Profile {
  Map<String, dynamic> toJson() => _$ProfileToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ProfileToJson(this);
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

extension ProfileCompareE on Profile {
  Map<String, dynamic> compareToProfile(Profile other) {
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

@JsonSerializable(explicitToJson: true)
class User extends $User {
  @override
  final String email;
  @override
  final Profile profile;

  User({
    required this.email,
    required this.profile,
  });

  User copyWith({
    String? email,
    Profile? profile,
  }) {
    return User(
      email: email ?? this.email,
      profile: profile ?? this.profile,
    );
  }

  User copyWithUser({
    String? email,
    Profile? profile,
  }) {
    return copyWith(
      email: email,
      profile: profile,
    );
  }

  User patchWithUser({
    UserPatch? patchInput,
  }) {
    final _patcher = patchInput ?? UserPatch();
    final _patchMap = _patcher.toPatch();
    return User(
        email: _patchMap.containsKey(User$.email)
            ? (_patchMap[User$.email] is Function)
                ? _patchMap[User$.email](this.email)
                : _patchMap[User$.email]
            : this.email,
        profile: _patchMap.containsKey(User$.profile)
            ? (_patchMap[User$.profile] is Function)
                ? _patchMap[User$.profile](this.profile)
                : _patchMap[User$.profile]
            : this.profile);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && email == other.email && profile == other.profile;
  }

  @override
  int get hashCode {
    return Object.hash(this.email, this.profile);
  }

  @override
  String toString() {
    return 'User(' + 'email: ${email}' + ', ' + 'profile: ${profile})';
  }

  /// Creates a [User] instance from JSON
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserToJson(this);
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

enum User$ { email, profile }

class UserPatch implements Patch<User> {
  final Map<User$, dynamic> _patch = {};

  static UserPatch create([Map<String, dynamic>? diff]) {
    final patch = UserPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = User$.values.firstWhere((e) => e.name == key);
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

  static UserPatch fromPatch(Map<User$, dynamic> patch) {
    final _patch = UserPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<User$, dynamic> toPatch() => Map.from(_patch);

  User applyTo(User entity) {
    return entity.patchWithUser(patchInput: this);
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

  static UserPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  UserPatch withEmail(String? value) {
    _patch[User$.email] = value;
    return this;
  }

  UserPatch withProfile(Profile? value) {
    _patch[User$.profile] = value;
    return this;
  }

  UserPatch withProfilePatch(ProfilePatch patch) {
    _patch[User$.profile] = patch;
    return this;
  }

  UserPatch withProfilePatchFunc(ProfilePatch Function(ProfilePatch) patch) {
    _patch[User$.profile] = (dynamic current) {
      var currentPatch = ProfilePatch();
      if (current != null) {
        currentPatch = current as ProfilePatch;
      }
      return patch(currentPatch);
    };
    return this;
  }
}

extension UserSerialization on User {
  Map<String, dynamic> toJson() => _$UserToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserToJson(this);
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

extension UserCompareE on User {
  Map<String, dynamic> compareToUser(User other) {
    final Map<String, dynamic> diff = {};

    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    if (profile != other.profile) {
      diff['profile'] = () => other.profile;
    }
    return diff;
  }
}
