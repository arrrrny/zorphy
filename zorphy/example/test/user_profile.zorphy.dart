// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'user_profile.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class UserProfile extends $UserProfile {
  @override
  final String userId;
  @override
  final String name;
  @override
  final Demographics? demographics;
  @override
  final Map<String, Demographics> demographicsHistory;
  @override
  final List<Demographics> savedProfiles;

  UserProfile({
    required this.userId,
    required this.name,
    this.demographics,
    required this.demographicsHistory,
    required this.savedProfiles,
  });

  UserProfile copyWith({
    String? userId,
    String? name,
    Demographics? demographics,
    Map<String, Demographics>? demographicsHistory,
    List<Demographics>? savedProfiles,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      demographics: demographics ?? this.demographics,
      demographicsHistory: demographicsHistory ?? this.demographicsHistory,
      savedProfiles: savedProfiles ?? this.savedProfiles,
    );
  }

  UserProfile copyWithUserProfile({
    String? userId,
    String? name,
    Demographics? demographics,
    Map<String, Demographics>? demographicsHistory,
    List<Demographics>? savedProfiles,
  }) {
    return copyWith(
      userId: userId,
      name: name,
      demographics: demographics,
      demographicsHistory: demographicsHistory,
      savedProfiles: savedProfiles,
    );
  }

  UserProfile patchWithUserProfile({UserProfilePatch? patchInput}) {
    final _patcher = patchInput ?? UserProfilePatch();
    final _patchMap = _patcher.toPatch();
    return UserProfile(
      userId: _patchMap.containsKey(UserProfile$.userId)
          ? (_patchMap[UserProfile$.userId] is Function)
                ? _patchMap[UserProfile$.userId](this.userId)
                : _patchMap[UserProfile$.userId]
          : this.userId,
      name: _patchMap.containsKey(UserProfile$.name)
          ? (_patchMap[UserProfile$.name] is Function)
                ? _patchMap[UserProfile$.name](this.name)
                : _patchMap[UserProfile$.name]
          : this.name,
      demographics: _patchMap.containsKey(UserProfile$.demographics)
          ? (_patchMap[UserProfile$.demographics] is Function)
                ? _patchMap[UserProfile$.demographics](this.demographics)
                : _patchMap[UserProfile$.demographics]
          : this.demographics,
      demographicsHistory:
          _patchMap.containsKey(UserProfile$.demographicsHistory)
          ? (_patchMap[UserProfile$.demographicsHistory] is Function)
                ? _patchMap[UserProfile$.demographicsHistory](
                    this.demographicsHistory,
                  )
                : _patchMap[UserProfile$.demographicsHistory]
          : this.demographicsHistory,
      savedProfiles: _patchMap.containsKey(UserProfile$.savedProfiles)
          ? (_patchMap[UserProfile$.savedProfiles] is Function)
                ? _patchMap[UserProfile$.savedProfiles](this.savedProfiles)
                : _patchMap[UserProfile$.savedProfiles]
          : this.savedProfiles,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        userId == other.userId &&
        name == other.name &&
        demographics == other.demographics &&
        demographicsHistory == other.demographicsHistory &&
        savedProfiles == other.savedProfiles;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.userId,
      this.name,
      this.demographics,
      this.demographicsHistory,
      this.savedProfiles,
    );
  }

  @override
  String toString() {
    return 'UserProfile(' +
        'userId: ${userId}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'demographics: ${demographics}' +
        ', ' +
        'demographicsHistory: ${demographicsHistory}' +
        ', ' +
        'savedProfiles: ${savedProfiles})';
  }

  /// Creates a [UserProfile] instance from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
}

enum UserProfile$ {
  userId,
  name,
  demographics,
  demographicsHistory,
  savedProfiles,
}

class UserProfilePatch implements Patch<UserProfile> {
  final Map<UserProfile$, dynamic> _patch = {};

  static UserProfilePatch create([Map<String, dynamic>? diff]) {
    final patch = UserProfilePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = UserProfile$.values.firstWhere(
            (e) => e.name == key,
          );
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

  static UserProfilePatch fromPatch(Map<UserProfile$, dynamic> patch) {
    final _patch = UserProfilePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<UserProfile$, dynamic> toPatch() => Map.from(_patch);

  UserProfile applyTo(UserProfile entity) {
    return entity.patchWithUserProfile(patchInput: this);
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

  static UserProfilePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  UserProfilePatch withUserId(String? value) {
    _patch[UserProfile$.userId] = value;
    return this;
  }

  UserProfilePatch withName(String? value) {
    _patch[UserProfile$.name] = value;
    return this;
  }

  UserProfilePatch withDemographics(Demographics? value) {
    _patch[UserProfile$.demographics] = value;
    return this;
  }

  UserProfilePatch withDemographicsHistory(Map<String, Demographics>? value) {
    _patch[UserProfile$.demographicsHistory] = value;
    return this;
  }

  UserProfilePatch withSavedProfiles(List<Demographics>? value) {
    _patch[UserProfile$.savedProfiles] = value;
    return this;
  }
}

extension UserProfileSerialization on UserProfile {
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserProfileToJson(this);
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

extension UserProfileCompareE on UserProfile {
  Map<String, dynamic> compareToUserProfile(UserProfile other) {
    final Map<String, dynamic> diff = {};

    if (userId != other.userId) {
      diff['userId'] = () => other.userId;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (demographics != other.demographics) {
      diff['demographics'] = () => other.demographics;
    }
    if (demographicsHistory != other.demographicsHistory) {
      diff['demographicsHistory'] = () => other.demographicsHistory;
    }
    if (savedProfiles != other.savedProfiles) {
      diff['savedProfiles'] = () => other.savedProfiles;
    }
    return diff;
  }
}
