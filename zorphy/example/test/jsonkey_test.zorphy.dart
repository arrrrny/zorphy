// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'jsonkey_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class User extends $User {
  @override
  final String id;
  @override
  final String userName;
  @override
  final String emailAddress;

  User({
    required this.id,
    required this.userName,
    required this.emailAddress,
  });

  User copyWith({
    String? id,
    String? userName,
    String? emailAddress,
  }) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      emailAddress: emailAddress ?? this.emailAddress,
    );
  }

  User copyWithUser({
    String? id,
    String? userName,
    String? emailAddress,
  }) {
    return copyWith(
      id: id,
      userName: userName,
      emailAddress: emailAddress,
    );
  }

  User patchWithUser({
    UserPatch? patchInput,
  }) {
    final _patcher = patchInput ?? UserPatch();
    final _patchMap = _patcher.toPatch();
    return User(
        id: _patchMap.containsKey(User$.id)
            ? (_patchMap[User$.id] is Function)
                ? _patchMap[User$.id](this.id)
                : _patchMap[User$.id]
            : this.id,
        userName: _patchMap.containsKey(User$.userName)
            ? (_patchMap[User$.userName] is Function)
                ? _patchMap[User$.userName](this.userName)
                : _patchMap[User$.userName]
            : this.userName,
        emailAddress: _patchMap.containsKey(User$.emailAddress)
            ? (_patchMap[User$.emailAddress] is Function)
                ? _patchMap[User$.emailAddress](this.emailAddress)
                : _patchMap[User$.emailAddress]
            : this.emailAddress);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        id == other.id &&
        userName == other.userName &&
        emailAddress == other.emailAddress;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.userName, this.emailAddress);
  }

  @override
  String toString() {
    return 'User(' +
        'id: ${id}' +
        ', ' +
        'userName: ${userName}' +
        ', ' +
        'emailAddress: ${emailAddress})';
  }

  /// Creates a [User] instance from JSON
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

enum User$ { id, userName, emailAddress }

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

  UserPatch withId(String? value) {
    _patch[User$.id] = value;
    return this;
  }

  UserPatch withUserName(String? value) {
    _patch[User$.userName] = value;
    return this;
  }

  UserPatch withEmailAddress(String? value) {
    _patch[User$.emailAddress] = value;
    return this;
  }
}

extension UserSerialization on User {
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

extension UserCompareE on User {
  Map<String, dynamic> compareToUser(User other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (userName != other.userName) {
      diff['userName'] = () => other.userName;
    }
    if (emailAddress != other.emailAddress) {
      diff['emailAddress'] = () => other.emailAddress;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Profile extends $Profile {
  @override
  final String userId;
  @override
  final String displayName;
  @override
  final String? internalToken;

  Profile({
    required this.userId,
    required this.displayName,
    this.internalToken,
  });

  Profile copyWith({
    String? userId,
    String? displayName,
    String? internalToken,
  }) {
    return Profile(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      internalToken: internalToken ?? this.internalToken,
    );
  }

  Profile copyWithProfile({
    String? userId,
    String? displayName,
    String? internalToken,
  }) {
    return copyWith(
      userId: userId,
      displayName: displayName,
      internalToken: internalToken,
    );
  }

  Profile patchWithProfile({
    ProfilePatch? patchInput,
  }) {
    final _patcher = patchInput ?? ProfilePatch();
    final _patchMap = _patcher.toPatch();
    return Profile(
        userId: _patchMap.containsKey(Profile$.userId)
            ? (_patchMap[Profile$.userId] is Function)
                ? _patchMap[Profile$.userId](this.userId)
                : _patchMap[Profile$.userId]
            : this.userId,
        displayName: _patchMap.containsKey(Profile$.displayName)
            ? (_patchMap[Profile$.displayName] is Function)
                ? _patchMap[Profile$.displayName](this.displayName)
                : _patchMap[Profile$.displayName]
            : this.displayName,
        internalToken: _patchMap.containsKey(Profile$.internalToken)
            ? (_patchMap[Profile$.internalToken] is Function)
                ? _patchMap[Profile$.internalToken](this.internalToken)
                : _patchMap[Profile$.internalToken]
            : this.internalToken);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Profile &&
        userId == other.userId &&
        displayName == other.displayName &&
        internalToken == other.internalToken;
  }

  @override
  int get hashCode {
    return Object.hash(this.userId, this.displayName, this.internalToken);
  }

  @override
  String toString() {
    return 'Profile(' +
        'userId: ${userId}' +
        ', ' +
        'displayName: ${displayName}' +
        ', ' +
        'internalToken: ${internalToken})';
  }

  /// Creates a [Profile] instance from JSON
  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);
}

enum Profile$ { userId, displayName, internalToken }

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

  ProfilePatch withUserId(String? value) {
    _patch[Profile$.userId] = value;
    return this;
  }

  ProfilePatch withDisplayName(String? value) {
    _patch[Profile$.displayName] = value;
    return this;
  }

  ProfilePatch withInternalToken(String? value) {
    _patch[Profile$.internalToken] = value;
    return this;
  }
}

extension ProfileSerialization on Profile {
  Map<String, dynamic> toJson() => _$ProfileToJson(this);
}

extension ProfileCompareE on Profile {
  Map<String, dynamic> compareToProfile(Profile other) {
    final Map<String, dynamic> diff = {};

    if (userId != other.userId) {
      diff['userId'] = () => other.userId;
    }
    if (displayName != other.displayName) {
      diff['displayName'] = () => other.displayName;
    }
    if (internalToken != other.internalToken) {
      diff['internalToken'] = () => other.internalToken;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Settings extends $Settings {
  @override
  final String theme;
  @override
  final String language;
  @override
  final bool? debugMode;

  Settings({
    required this.theme,
    required this.language,
    this.debugMode,
  });

  Settings copyWith({
    String? theme,
    String? language,
    bool? debugMode,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      language: language ?? this.language,
      debugMode: debugMode ?? this.debugMode,
    );
  }

  Settings copyWithSettings({
    String? theme,
    String? language,
    bool? debugMode,
  }) {
    return copyWith(
      theme: theme,
      language: language,
      debugMode: debugMode,
    );
  }

  Settings patchWithSettings({
    SettingsPatch? patchInput,
  }) {
    final _patcher = patchInput ?? SettingsPatch();
    final _patchMap = _patcher.toPatch();
    return Settings(
        theme: _patchMap.containsKey(Settings$.theme)
            ? (_patchMap[Settings$.theme] is Function)
                ? _patchMap[Settings$.theme](this.theme)
                : _patchMap[Settings$.theme]
            : this.theme,
        language: _patchMap.containsKey(Settings$.language)
            ? (_patchMap[Settings$.language] is Function)
                ? _patchMap[Settings$.language](this.language)
                : _patchMap[Settings$.language]
            : this.language,
        debugMode: _patchMap.containsKey(Settings$.debugMode)
            ? (_patchMap[Settings$.debugMode] is Function)
                ? _patchMap[Settings$.debugMode](this.debugMode)
                : _patchMap[Settings$.debugMode]
            : this.debugMode);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Settings &&
        theme == other.theme &&
        language == other.language &&
        debugMode == other.debugMode;
  }

  @override
  int get hashCode {
    return Object.hash(this.theme, this.language, this.debugMode);
  }

  @override
  String toString() {
    return 'Settings(' +
        'theme: ${theme}' +
        ', ' +
        'language: ${language}' +
        ', ' +
        'debugMode: ${debugMode})';
  }

  /// Creates a [Settings] instance from JSON
  factory Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);
}

enum Settings$ { theme, language, debugMode }

class SettingsPatch implements Patch<Settings> {
  final Map<Settings$, dynamic> _patch = {};

  static SettingsPatch create([Map<String, dynamic>? diff]) {
    final patch = SettingsPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Settings$.values.firstWhere((e) => e.name == key);
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

  static SettingsPatch fromPatch(Map<Settings$, dynamic> patch) {
    final _patch = SettingsPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Settings$, dynamic> toPatch() => Map.from(_patch);

  Settings applyTo(Settings entity) {
    return entity.patchWithSettings(patchInput: this);
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

  static SettingsPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  SettingsPatch withTheme(String? value) {
    _patch[Settings$.theme] = value;
    return this;
  }

  SettingsPatch withLanguage(String? value) {
    _patch[Settings$.language] = value;
    return this;
  }

  SettingsPatch withDebugMode(bool? value) {
    _patch[Settings$.debugMode] = value;
    return this;
  }
}

extension SettingsSerialization on Settings {
  Map<String, dynamic> toJson() => _$SettingsToJson(this);
}

extension SettingsCompareE on Settings {
  Map<String, dynamic> compareToSettings(Settings other) {
    final Map<String, dynamic> diff = {};

    if (theme != other.theme) {
      diff['theme'] = () => other.theme;
    }
    if (language != other.language) {
      diff['language'] = () => other.language;
    }
    if (debugMode != other.debugMode) {
      diff['debugMode'] = () => other.debugMode;
    }
    return diff;
  }
}
