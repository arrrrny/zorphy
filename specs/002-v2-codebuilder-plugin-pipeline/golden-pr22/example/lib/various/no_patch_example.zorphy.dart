// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'no_patch_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class NoPatchUser {
  final String name;
  final int age;

  NoPatchUser({required this.name, required this.age});

  NoPatchUser copyWith({String? name, int? age}) {
    return NoPatchUser(name: name ?? this.name, age: age ?? this.age);
  }

  NoPatchUser copyWithNoPatchUser({String? name, int? age}) {
    return copyWith(name: name, age: age);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NoPatchUser && name == other.name && age == other.age;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.age);
  }

  @override
  String toString() {
    return 'NoPatchUser(' + 'name: ${name}' + ', ' + 'age: ${age})';
  }

  /// Creates a [NoPatchUser] instance from JSON
  factory NoPatchUser.fromJson(Map<String, dynamic> json) =>
      _$NoPatchUserFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$NoPatchUserToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension NoPatchUserPropertyHelpers on NoPatchUser {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

extension NoPatchUserSerialization on NoPatchUser {
  Map<String, dynamic> toJson() => _$NoPatchUserToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$NoPatchUserToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

/// Field descriptors for [NoPatchUser] query construction
abstract final class NoPatchUserFields {
  static String _$getname(NoPatchUser e) => e.name;
  static const name = Field<NoPatchUser, String>('name', _$getname);
  static int _$getage(NoPatchUser e) => e.age;
  static const age = Field<NoPatchUser, int>('age', _$getage);
}

extension NoPatchUserCompareE on NoPatchUser {
  Map<String, dynamic> compareToNoPatchUser(NoPatchUser other) {
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
