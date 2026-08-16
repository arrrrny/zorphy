// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'enum_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Task {
  final String id;
  final String title;
  final Status status;
  final Priority priority;
  final List<String>? tags;

  Task({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.tags,
  });

  Task copyWith({
    String? id,
    String? title,
    Status? status,
    Priority? priority,
    List<String>? tags,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
    );
  }

  Task copyWithTask({
    String? id,
    String? title,
    Status? status,
    Priority? priority,
    List<String>? tags,
  }) {
    return copyWith(
      id: id,
      title: title,
      status: status,
      priority: priority,
      tags: tags,
    );
  }

  Task patchWithTask({TaskPatch? patchInput}) {
    final _patcher = patchInput ?? TaskPatch();
    final _patchMap = _patcher.patchMap;
    return Task(
      id: _patchMap.containsKey(Task$.id)
          ? (_patchMap[Task$.id] is Function)
                ? _patchMap[Task$.id](this.id)
                : (_patchMap[Task$.id] is Patch)
                ? _patchMap[Task$.id].applyTo(this.id)
                : _patchMap[Task$.id]
          : this.id,
      title: _patchMap.containsKey(Task$.title)
          ? (_patchMap[Task$.title] is Function)
                ? _patchMap[Task$.title](this.title)
                : (_patchMap[Task$.title] is Patch)
                ? _patchMap[Task$.title].applyTo(this.title)
                : _patchMap[Task$.title]
          : this.title,
      status: _patchMap.containsKey(Task$.status)
          ? (_patchMap[Task$.status] is Function)
                ? _patchMap[Task$.status](this.status)
                : (_patchMap[Task$.status] is Patch)
                ? _patchMap[Task$.status].applyTo(this.status)
                : _patchMap[Task$.status]
          : this.status,
      priority: _patchMap.containsKey(Task$.priority)
          ? (_patchMap[Task$.priority] is Function)
                ? _patchMap[Task$.priority](this.priority)
                : (_patchMap[Task$.priority] is Patch)
                ? _patchMap[Task$.priority].applyTo(this.priority)
                : _patchMap[Task$.priority]
          : this.priority,
      tags: _patchMap.containsKey(Task$.tags)
          ? (_patchMap[Task$.tags] is Function)
                ? _patchMap[Task$.tags](this.tags)
                : (_patchMap[Task$.tags] is Patch)
                ? _patchMap[Task$.tags].applyTo(this.tags)
                : _patchMap[Task$.tags]
          : this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        id == other.id &&
        title == other.title &&
        status == other.status &&
        priority == other.priority &&
        tags == other.tags;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.title,
      this.status,
      this.priority,
      this.tags,
    );
  }

  @override
  String toString() {
    return 'Task(' +
        'id: ${id}' +
        ', ' +
        'title: ${title}' +
        ', ' +
        'status: ${status}' +
        ', ' +
        'priority: ${priority}' +
        ', ' +
        'tags: ${tags})';
  }

  /// Creates a [Task] instance from JSON
  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TaskToJson(this);
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

extension TaskPropertyHelpers on Task {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
  bool get hasTitle => title.isNotEmpty;
  bool get noTitle => title.isEmpty;
  bool get isStatusActive => status == Status.active;
  bool get isStatusInactive => status == Status.inactive;
  bool get isStatusPending => status == Status.pending;
  bool get isStatusSuspended => status == Status.suspended;
  bool get isPriorityLow => priority == Priority.low;
  bool get isPriorityMedium => priority == Priority.medium;
  bool get isPriorityHigh => priority == Priority.high;
  bool get isPriorityCritical => priority == Priority.critical;
  List<String> get tagsRequired =>
      tags ?? (throw StateError('tags is required but was null'));
  bool get hasTags => tags?.isNotEmpty ?? false;
  bool get noTags => tags?.isEmpty ?? true;
}

extension TaskSerialization on Task {
  Map<String, dynamic> toJson() => _$TaskToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TaskToJson(this);
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

enum Task$ { id, title, status, priority, tags }

class TaskPatch extends PatchBase<Task, Task$> {
  Task applyTo(Task entity) {
    return entity.patchWithTask(patchInput: this);
  }

  TaskPatch withId(String? value) {
    patchMap[Task$.id] = value;
    return this;
  }

  TaskPatch withTitle(String? value) {
    patchMap[Task$.title] = value;
    return this;
  }

  TaskPatch withStatus(Status? value) {
    patchMap[Task$.status] = value;
    return this;
  }

  TaskPatch withPriority(Priority? value) {
    patchMap[Task$.priority] = value;
    return this;
  }

  TaskPatch withTags(List<String>? value) {
    patchMap[Task$.tags] = value;
    return this;
  }
}

/// Field descriptors for [Task] query construction
abstract final class TaskFields {
  static String _$getid(Task e) => e.id;
  static const id = Field<Task, String>('id', _$getid);
  static String _$gettitle(Task e) => e.title;
  static const title = Field<Task, String>('title', _$gettitle);
  static Status _$getstatus(Task e) => e.status;
  static const status = Field<Task, Status>('status', _$getstatus);
  static Priority _$getpriority(Task e) => e.priority;
  static const priority = Field<Task, Priority>('priority', _$getpriority);
  static List<String>? _$gettags(Task e) => e.tags;
  static const tags = Field<Task, List<String>?>('tags', _$gettags);
}

extension TaskCompareE on Task {
  Map<String, dynamic> compareToTask(Task other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    if (priority != other.priority) {
      diff['priority'] = () => other.priority;
    }
    if (tags != other.tags) {
      diff['tags'] = () => other.tags;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class UserProfile {
  final String userId;
  final String username;
  final UserRole role;
  final DateTime lastLogin;

  UserProfile({
    required this.userId,
    required this.username,
    required this.role,
    required this.lastLogin,
  });

  UserProfile copyWith({
    String? userId,
    String? username,
    UserRole? role,
    DateTime? lastLogin,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      role: role ?? this.role,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  UserProfile copyWithUserProfile({
    String? userId,
    String? username,
    UserRole? role,
    DateTime? lastLogin,
  }) {
    return copyWith(
      userId: userId,
      username: username,
      role: role,
      lastLogin: lastLogin,
    );
  }

  UserProfile patchWithUserProfile({UserProfilePatch? patchInput}) {
    final _patcher = patchInput ?? UserProfilePatch();
    final _patchMap = _patcher.patchMap;
    return UserProfile(
      userId: _patchMap.containsKey(UserProfile$.userId)
          ? (_patchMap[UserProfile$.userId] is Function)
                ? _patchMap[UserProfile$.userId](this.userId)
                : (_patchMap[UserProfile$.userId] is Patch)
                ? _patchMap[UserProfile$.userId].applyTo(this.userId)
                : _patchMap[UserProfile$.userId]
          : this.userId,
      username: _patchMap.containsKey(UserProfile$.username)
          ? (_patchMap[UserProfile$.username] is Function)
                ? _patchMap[UserProfile$.username](this.username)
                : (_patchMap[UserProfile$.username] is Patch)
                ? _patchMap[UserProfile$.username].applyTo(this.username)
                : _patchMap[UserProfile$.username]
          : this.username,
      role: _patchMap.containsKey(UserProfile$.role)
          ? (_patchMap[UserProfile$.role] is Function)
                ? _patchMap[UserProfile$.role](this.role)
                : (_patchMap[UserProfile$.role] is Patch)
                ? _patchMap[UserProfile$.role].applyTo(this.role)
                : _patchMap[UserProfile$.role]
          : this.role,
      lastLogin: _patchMap.containsKey(UserProfile$.lastLogin)
          ? (_patchMap[UserProfile$.lastLogin] is Function)
                ? _patchMap[UserProfile$.lastLogin](this.lastLogin)
                : (_patchMap[UserProfile$.lastLogin] is Patch)
                ? _patchMap[UserProfile$.lastLogin].applyTo(this.lastLogin)
                : _patchMap[UserProfile$.lastLogin]
          : this.lastLogin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        userId == other.userId &&
        username == other.username &&
        role == other.role &&
        lastLogin == other.lastLogin;
  }

  @override
  int get hashCode {
    return Object.hash(this.userId, this.username, this.role, this.lastLogin);
  }

  @override
  String toString() {
    return 'UserProfile(' +
        'userId: ${userId}' +
        ', ' +
        'username: ${username}' +
        ', ' +
        'role: ${role}' +
        ', ' +
        'lastLogin: ${lastLogin})';
  }

  /// Creates a [UserProfile] instance from JSON
  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserProfileToJson(this);
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

extension UserProfilePropertyHelpers on UserProfile {
  bool get hasUserId => userId.isNotEmpty;
  bool get noUserId => userId.isEmpty;
  bool get hasUsername => username.isNotEmpty;
  bool get noUsername => username.isEmpty;
  bool get isRoleAdmin => role == UserRole.admin;
  bool get isRoleModerator => role == UserRole.moderator;
  bool get isRoleUser => role == UserRole.user;
  bool get isRoleGuest => role == UserRole.guest;
}

extension UserProfileSerialization on UserProfile {
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserProfileToJson(this);
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

enum UserProfile$ { userId, username, role, lastLogin }

class UserProfilePatch extends PatchBase<UserProfile, UserProfile$> {
  UserProfile applyTo(UserProfile entity) {
    return entity.patchWithUserProfile(patchInput: this);
  }

  UserProfilePatch withUserId(String? value) {
    patchMap[UserProfile$.userId] = value;
    return this;
  }

  UserProfilePatch withUsername(String? value) {
    patchMap[UserProfile$.username] = value;
    return this;
  }

  UserProfilePatch withRole(UserRole? value) {
    patchMap[UserProfile$.role] = value;
    return this;
  }

  UserProfilePatch withLastLogin(DateTime? value) {
    patchMap[UserProfile$.lastLogin] = value;
    return this;
  }
}

/// Field descriptors for [UserProfile] query construction
abstract final class UserProfileFields {
  static String _$getuserId(UserProfile e) => e.userId;
  static const userId = Field<UserProfile, String>('userId', _$getuserId);
  static String _$getusername(UserProfile e) => e.username;
  static const username = Field<UserProfile, String>('username', _$getusername);
  static UserRole _$getrole(UserProfile e) => e.role;
  static const role = Field<UserProfile, UserRole>('role', _$getrole);
  static DateTime _$getlastLogin(UserProfile e) => e.lastLogin;
  static const lastLogin = Field<UserProfile, DateTime>(
    'lastLogin',
    _$getlastLogin,
  );
}

extension UserProfileCompareE on UserProfile {
  Map<String, dynamic> compareToUserProfile(UserProfile other) {
    final Map<String, dynamic> diff = {};

    if (userId != other.userId) {
      diff['userId'] = () => other.userId;
    }
    if (username != other.username) {
      diff['username'] = () => other.username;
    }
    if (role != other.role) {
      diff['role'] = () => other.role;
    }
    if (lastLogin != other.lastLogin) {
      diff['lastLogin'] = () => other.lastLogin;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class SystemConfig {
  final String configKey;
  final String configValue;
  final Status configStatus;
  final Priority updatePriority;
  final bool requiresRestart;

  SystemConfig({
    required this.configKey,
    required this.configValue,
    required this.configStatus,
    required this.updatePriority,
    required this.requiresRestart,
  });

  SystemConfig copyWith({
    String? configKey,
    String? configValue,
    Status? configStatus,
    Priority? updatePriority,
    bool? requiresRestart,
  }) {
    return SystemConfig(
      configKey: configKey ?? this.configKey,
      configValue: configValue ?? this.configValue,
      configStatus: configStatus ?? this.configStatus,
      updatePriority: updatePriority ?? this.updatePriority,
      requiresRestart: requiresRestart ?? this.requiresRestart,
    );
  }

  SystemConfig copyWithSystemConfig({
    String? configKey,
    String? configValue,
    Status? configStatus,
    Priority? updatePriority,
    bool? requiresRestart,
  }) {
    return copyWith(
      configKey: configKey,
      configValue: configValue,
      configStatus: configStatus,
      updatePriority: updatePriority,
      requiresRestart: requiresRestart,
    );
  }

  SystemConfig patchWithSystemConfig({SystemConfigPatch? patchInput}) {
    final _patcher = patchInput ?? SystemConfigPatch();
    final _patchMap = _patcher.patchMap;
    return SystemConfig(
      configKey: _patchMap.containsKey(SystemConfig$.configKey)
          ? (_patchMap[SystemConfig$.configKey] is Function)
                ? _patchMap[SystemConfig$.configKey](this.configKey)
                : (_patchMap[SystemConfig$.configKey] is Patch)
                ? _patchMap[SystemConfig$.configKey].applyTo(this.configKey)
                : _patchMap[SystemConfig$.configKey]
          : this.configKey,
      configValue: _patchMap.containsKey(SystemConfig$.configValue)
          ? (_patchMap[SystemConfig$.configValue] is Function)
                ? _patchMap[SystemConfig$.configValue](this.configValue)
                : (_patchMap[SystemConfig$.configValue] is Patch)
                ? _patchMap[SystemConfig$.configValue].applyTo(this.configValue)
                : _patchMap[SystemConfig$.configValue]
          : this.configValue,
      configStatus: _patchMap.containsKey(SystemConfig$.configStatus)
          ? (_patchMap[SystemConfig$.configStatus] is Function)
                ? _patchMap[SystemConfig$.configStatus](this.configStatus)
                : (_patchMap[SystemConfig$.configStatus] is Patch)
                ? _patchMap[SystemConfig$.configStatus].applyTo(
                    this.configStatus,
                  )
                : _patchMap[SystemConfig$.configStatus]
          : this.configStatus,
      updatePriority: _patchMap.containsKey(SystemConfig$.updatePriority)
          ? (_patchMap[SystemConfig$.updatePriority] is Function)
                ? _patchMap[SystemConfig$.updatePriority](this.updatePriority)
                : (_patchMap[SystemConfig$.updatePriority] is Patch)
                ? _patchMap[SystemConfig$.updatePriority].applyTo(
                    this.updatePriority,
                  )
                : _patchMap[SystemConfig$.updatePriority]
          : this.updatePriority,
      requiresRestart: _patchMap.containsKey(SystemConfig$.requiresRestart)
          ? (_patchMap[SystemConfig$.requiresRestart] is Function)
                ? _patchMap[SystemConfig$.requiresRestart](this.requiresRestart)
                : (_patchMap[SystemConfig$.requiresRestart] is Patch)
                ? _patchMap[SystemConfig$.requiresRestart].applyTo(
                    this.requiresRestart,
                  )
                : _patchMap[SystemConfig$.requiresRestart]
          : this.requiresRestart,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SystemConfig &&
        configKey == other.configKey &&
        configValue == other.configValue &&
        configStatus == other.configStatus &&
        updatePriority == other.updatePriority &&
        requiresRestart == other.requiresRestart;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.configKey,
      this.configValue,
      this.configStatus,
      this.updatePriority,
      this.requiresRestart,
    );
  }

  @override
  String toString() {
    return 'SystemConfig(' +
        'configKey: ${configKey}' +
        ', ' +
        'configValue: ${configValue}' +
        ', ' +
        'configStatus: ${configStatus}' +
        ', ' +
        'updatePriority: ${updatePriority}' +
        ', ' +
        'requiresRestart: ${requiresRestart})';
  }

  /// Creates a [SystemConfig] instance from JSON
  factory SystemConfig.fromJson(Map<String, dynamic> json) =>
      _$SystemConfigFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$SystemConfigToJson(this);
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

extension SystemConfigPropertyHelpers on SystemConfig {
  bool get hasConfigKey => configKey.isNotEmpty;
  bool get noConfigKey => configKey.isEmpty;
  bool get hasConfigValue => configValue.isNotEmpty;
  bool get noConfigValue => configValue.isEmpty;
  bool get isConfigStatusActive => configStatus == Status.active;
  bool get isConfigStatusInactive => configStatus == Status.inactive;
  bool get isConfigStatusPending => configStatus == Status.pending;
  bool get isConfigStatusSuspended => configStatus == Status.suspended;
  bool get isUpdatePriorityLow => updatePriority == Priority.low;
  bool get isUpdatePriorityMedium => updatePriority == Priority.medium;
  bool get isUpdatePriorityHigh => updatePriority == Priority.high;
  bool get isUpdatePriorityCritical => updatePriority == Priority.critical;
}

extension SystemConfigSerialization on SystemConfig {
  Map<String, dynamic> toJson() => _$SystemConfigToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$SystemConfigToJson(this);
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

enum SystemConfig$ {
  configKey,
  configValue,
  configStatus,
  updatePriority,
  requiresRestart,
}

class SystemConfigPatch extends PatchBase<SystemConfig, SystemConfig$> {
  SystemConfig applyTo(SystemConfig entity) {
    return entity.patchWithSystemConfig(patchInput: this);
  }

  SystemConfigPatch withConfigKey(String? value) {
    patchMap[SystemConfig$.configKey] = value;
    return this;
  }

  SystemConfigPatch withConfigValue(String? value) {
    patchMap[SystemConfig$.configValue] = value;
    return this;
  }

  SystemConfigPatch withConfigStatus(Status? value) {
    patchMap[SystemConfig$.configStatus] = value;
    return this;
  }

  SystemConfigPatch withUpdatePriority(Priority? value) {
    patchMap[SystemConfig$.updatePriority] = value;
    return this;
  }

  SystemConfigPatch withRequiresRestart(bool? value) {
    patchMap[SystemConfig$.requiresRestart] = value;
    return this;
  }
}

/// Field descriptors for [SystemConfig] query construction
abstract final class SystemConfigFields {
  static String _$getconfigKey(SystemConfig e) => e.configKey;
  static const configKey = Field<SystemConfig, String>(
    'configKey',
    _$getconfigKey,
  );
  static String _$getconfigValue(SystemConfig e) => e.configValue;
  static const configValue = Field<SystemConfig, String>(
    'configValue',
    _$getconfigValue,
  );
  static Status _$getconfigStatus(SystemConfig e) => e.configStatus;
  static const configStatus = Field<SystemConfig, Status>(
    'configStatus',
    _$getconfigStatus,
  );
  static Priority _$getupdatePriority(SystemConfig e) => e.updatePriority;
  static const updatePriority = Field<SystemConfig, Priority>(
    'updatePriority',
    _$getupdatePriority,
  );
  static bool _$getrequiresRestart(SystemConfig e) => e.requiresRestart;
  static const requiresRestart = Field<SystemConfig, bool>(
    'requiresRestart',
    _$getrequiresRestart,
  );
}

extension SystemConfigCompareE on SystemConfig {
  Map<String, dynamic> compareToSystemConfig(SystemConfig other) {
    final Map<String, dynamic> diff = {};

    if (configKey != other.configKey) {
      diff['configKey'] = () => other.configKey;
    }
    if (configValue != other.configValue) {
      diff['configValue'] = () => other.configValue;
    }
    if (configStatus != other.configStatus) {
      diff['configStatus'] = () => other.configStatus;
    }
    if (updatePriority != other.updatePriority) {
      diff['updatePriority'] = () => other.updatePriority;
    }
    if (requiresRestart != other.requiresRestart) {
      diff['requiresRestart'] = () => other.requiresRestart;
    }
    return diff;
  }
}
