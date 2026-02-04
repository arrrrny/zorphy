// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'cross_file_user.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class User extends $User {
  @override
  final String name;
  @override
  final String email;

  User({
    required this.name,
    required this.email,
  });

  User copyWith({
    String? name,
    String? email,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  User copyWithUser({
    String? name,
    String? email,
  }) {
    return copyWith(
      name: name,
      email: email,
    );
  }

  User patchWithUser({
    UserPatch? patchInput,
  }) {
    final _patcher = patchInput ?? UserPatch();
    final _patchMap = _patcher.toPatch();
    return User(
        name: _patchMap.containsKey(User$.name)
            ? (_patchMap[User$.name] is Function)
                ? _patchMap[User$.name](this.name)
                : _patchMap[User$.name]
            : this.name,
        email: _patchMap.containsKey(User$.email)
            ? (_patchMap[User$.email] is Function)
                ? _patchMap[User$.email](this.email)
                : _patchMap[User$.email]
            : this.email);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && name == other.name && email == other.email;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.email);
  }

  @override
  String toString() {
    return 'User(' + 'name: ${name}' + ', ' + 'email: ${email})';
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

enum User$ { name, email }

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

  UserPatch withName(String? value) {
    _patch[User$.name] = value;
    return this;
  }

  UserPatch withEmail(String? value) {
    _patch[User$.email] = value;
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

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    return diff;
  }
}
