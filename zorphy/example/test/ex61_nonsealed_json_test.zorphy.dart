// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex61_nonsealed_json_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class ApiResponse implements $$ApiResponse {
  final String status;
  final String message;
  final DateTime timestamp;

  ApiResponse({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  ApiResponse copyWith({String? status, String? message, DateTime? timestamp}) {
    return ApiResponse(
      status: status ?? this.status,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  ApiResponse copyWithApiResponse({
    String? status,
    String? message,
    DateTime? timestamp,
  }) {
    return copyWith(status: status, message: message, timestamp: timestamp);
  }

  factory ApiResponse.success(String message) => ApiResponse.success(message);

  factory ApiResponse.error(String error) => ApiResponse.error(error);

  ApiResponse patchWithApiResponse({ApiResponsePatch? patchInput}) {
    final _patcher = patchInput ?? ApiResponsePatch();
    final _patchMap = _patcher.toPatch();
    return ApiResponse(
      status: _patchMap.containsKey(ApiResponse$.status)
          ? (_patchMap[ApiResponse$.status] is Function)
                ? _patchMap[ApiResponse$.status](this.status)
                : _patchMap[ApiResponse$.status]
          : this.status,
      message: _patchMap.containsKey(ApiResponse$.message)
          ? (_patchMap[ApiResponse$.message] is Function)
                ? _patchMap[ApiResponse$.message](this.message)
                : _patchMap[ApiResponse$.message]
          : this.message,
      timestamp: _patchMap.containsKey(ApiResponse$.timestamp)
          ? (_patchMap[ApiResponse$.timestamp] is Function)
                ? _patchMap[ApiResponse$.timestamp](this.timestamp)
                : _patchMap[ApiResponse$.timestamp]
          : this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApiResponse &&
        status == other.status &&
        message == other.message &&
        timestamp == other.timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(this.status, this.message, this.timestamp);
  }

  @override
  String toString() {
    return 'ApiResponse(' +
        'status: ${status}' +
        ', ' +
        'message: ${message}' +
        ', ' +
        'timestamp: ${timestamp})';
  }

  /// Creates a [ApiResponse] instance from JSON
  factory ApiResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiResponseFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ApiResponseToJson(this);
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

enum ApiResponse$ { status, message, timestamp }

class ApiResponsePatch implements Patch<ApiResponse> {
  final Map<ApiResponse$, dynamic> _patch = {};

  static ApiResponsePatch create([Map<String, dynamic>? diff]) {
    final patch = ApiResponsePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = ApiResponse$.values.firstWhere(
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

  static ApiResponsePatch fromPatch(Map<ApiResponse$, dynamic> patch) {
    final _patch = ApiResponsePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<ApiResponse$, dynamic> toPatch() => Map.from(_patch);

  ApiResponse applyTo(ApiResponse entity) {
    return entity.patchWithApiResponse(patchInput: this);
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

  static ApiResponsePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ApiResponsePatch withStatus(String? value) {
    _patch[ApiResponse$.status] = value;
    return this;
  }

  ApiResponsePatch withMessage(String? value) {
    _patch[ApiResponse$.message] = value;
    return this;
  }

  ApiResponsePatch withTimestamp(DateTime? value) {
    _patch[ApiResponse$.timestamp] = value;
    return this;
  }
}

extension ApiResponseSerialization on ApiResponse {
  Map<String, dynamic> toJson() => _$ApiResponseToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ApiResponseToJson(this);
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

extension ApiResponseCompareE on ApiResponse {
  Map<String, dynamic> compareToApiResponse(ApiResponse other) {
    final Map<String, dynamic> diff = {};

    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    if (message != other.message) {
      diff['message'] = () => other.message;
    }
    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class DetailedApiResponse implements $$ApiResponse {
  final String status;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> data;

  DetailedApiResponse({
    required this.status,
    required this.message,
    required this.timestamp,
    required this.data,
  });

  DetailedApiResponse copyWith({
    String? status,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? data,
  }) {
    return DetailedApiResponse(
      status: status ?? this.status,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
    );
  }

  DetailedApiResponse copyWithDetailedApiResponse({
    String? status,
    String? message,
    DateTime? timestamp,
    Map<String, dynamic>? data,
  }) {
    return copyWith(
      status: status,
      message: message,
      timestamp: timestamp,
      data: data,
    );
  }

  DetailedApiResponse patchWithDetailedApiResponse({
    DetailedApiResponsePatch? patchInput,
  }) {
    final _patcher = patchInput ?? DetailedApiResponsePatch();
    final _patchMap = _patcher.toPatch();
    return DetailedApiResponse(
      status: _patchMap.containsKey(DetailedApiResponse$.status)
          ? (_patchMap[DetailedApiResponse$.status] is Function)
                ? _patchMap[DetailedApiResponse$.status](this.status)
                : _patchMap[DetailedApiResponse$.status]
          : this.status,
      message: _patchMap.containsKey(DetailedApiResponse$.message)
          ? (_patchMap[DetailedApiResponse$.message] is Function)
                ? _patchMap[DetailedApiResponse$.message](this.message)
                : _patchMap[DetailedApiResponse$.message]
          : this.message,
      timestamp: _patchMap.containsKey(DetailedApiResponse$.timestamp)
          ? (_patchMap[DetailedApiResponse$.timestamp] is Function)
                ? _patchMap[DetailedApiResponse$.timestamp](this.timestamp)
                : _patchMap[DetailedApiResponse$.timestamp]
          : this.timestamp,
      data: _patchMap.containsKey(DetailedApiResponse$.data)
          ? (_patchMap[DetailedApiResponse$.data] is Function)
                ? _patchMap[DetailedApiResponse$.data](this.data)
                : _patchMap[DetailedApiResponse$.data]
          : this.data,
    );
  }

  DetailedApiResponse copyWithApiResponse({
    String? status,
    String? message,
    DateTime? timestamp,
  }) {
    return copyWith(status: status, message: message, timestamp: timestamp);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetailedApiResponse &&
        status == other.status &&
        message == other.message &&
        timestamp == other.timestamp &&
        data == other.data;
  }

  @override
  int get hashCode {
    return Object.hash(this.status, this.message, this.timestamp, this.data);
  }

  @override
  String toString() {
    return 'DetailedApiResponse(' +
        'status: ${status}' +
        ', ' +
        'message: ${message}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'data: ${data})';
  }

  /// Creates a [DetailedApiResponse] instance from JSON
  factory DetailedApiResponse.fromJson(Map<String, dynamic> json) =>
      _$DetailedApiResponseFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$DetailedApiResponseToJson(this);
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

enum DetailedApiResponse$ { status, message, timestamp, data }

class DetailedApiResponsePatch implements Patch<DetailedApiResponse> {
  final Map<DetailedApiResponse$, dynamic> _patch = {};

  static DetailedApiResponsePatch create([Map<String, dynamic>? diff]) {
    final patch = DetailedApiResponsePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = DetailedApiResponse$.values.firstWhere(
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

  static DetailedApiResponsePatch fromPatch(
    Map<DetailedApiResponse$, dynamic> patch,
  ) {
    final _patch = DetailedApiResponsePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<DetailedApiResponse$, dynamic> toPatch() => Map.from(_patch);

  DetailedApiResponse applyTo(DetailedApiResponse entity) {
    return entity.patchWithDetailedApiResponse(patchInput: this);
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

  static DetailedApiResponsePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  DetailedApiResponsePatch withStatus(String? value) {
    _patch[DetailedApiResponse$.status] = value;
    return this;
  }

  DetailedApiResponsePatch withMessage(String? value) {
    _patch[DetailedApiResponse$.message] = value;
    return this;
  }

  DetailedApiResponsePatch withTimestamp(DateTime? value) {
    _patch[DetailedApiResponse$.timestamp] = value;
    return this;
  }

  DetailedApiResponsePatch withData(Map<String, dynamic>? value) {
    _patch[DetailedApiResponse$.data] = value;
    return this;
  }
}

extension DetailedApiResponseSerialization on DetailedApiResponse {
  Map<String, dynamic> toJson() => _$DetailedApiResponseToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$DetailedApiResponseToJson(this);
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

extension DetailedApiResponseCompareE on DetailedApiResponse {
  Map<String, dynamic> compareToDetailedApiResponse(DetailedApiResponse other) {
    final Map<String, dynamic> diff = {};

    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    if (message != other.message) {
      diff['message'] = () => other.message;
    }
    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }
    if (data != other.data) {
      diff['data'] = () => other.data;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class BaseEntity extends $$BaseEntity {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  BaseEntity({required this.id, required this.createdAt, this.updatedAt});

  BaseEntity copyWith({String? id, DateTime? createdAt, DateTime? updatedAt}) {
    return BaseEntity(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  BaseEntity copyWithBaseEntity({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return copyWith(id: id, createdAt: createdAt, updatedAt: updatedAt);
  }

  BaseEntity patchWithBaseEntity({BaseEntityPatch? patchInput}) {
    final _patcher = patchInput ?? BaseEntityPatch();
    final _patchMap = _patcher.toPatch();
    return BaseEntity(
      id: _patchMap.containsKey(BaseEntity$.id)
          ? (_patchMap[BaseEntity$.id] is Function)
                ? _patchMap[BaseEntity$.id](this.id)
                : _patchMap[BaseEntity$.id]
          : this.id,
      createdAt: _patchMap.containsKey(BaseEntity$.createdAt)
          ? (_patchMap[BaseEntity$.createdAt] is Function)
                ? _patchMap[BaseEntity$.createdAt](this.createdAt)
                : _patchMap[BaseEntity$.createdAt]
          : this.createdAt,
      updatedAt: _patchMap.containsKey(BaseEntity$.updatedAt)
          ? (_patchMap[BaseEntity$.updatedAt] is Function)
                ? _patchMap[BaseEntity$.updatedAt](this.updatedAt)
                : _patchMap[BaseEntity$.updatedAt]
          : this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseEntity &&
        id == other.id &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.createdAt, this.updatedAt);
  }

  @override
  String toString() {
    return 'BaseEntity(' +
        'id: ${id}' +
        ', ' +
        'createdAt: ${createdAt}' +
        ', ' +
        'updatedAt: ${updatedAt})';
  }

  /// Creates a [BaseEntity] instance from JSON
  factory BaseEntity.fromJson(Map<String, dynamic> json) =>
      _$BaseEntityFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BaseEntityToJson(this);
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

enum BaseEntity$ { id, createdAt, updatedAt }

class BaseEntityPatch implements Patch<BaseEntity> {
  final Map<BaseEntity$, dynamic> _patch = {};

  static BaseEntityPatch create([Map<String, dynamic>? diff]) {
    final patch = BaseEntityPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = BaseEntity$.values.firstWhere((e) => e.name == key);
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

  static BaseEntityPatch fromPatch(Map<BaseEntity$, dynamic> patch) {
    final _patch = BaseEntityPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<BaseEntity$, dynamic> toPatch() => Map.from(_patch);

  BaseEntity applyTo(BaseEntity entity) {
    return entity.patchWithBaseEntity(patchInput: this);
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

  static BaseEntityPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  BaseEntityPatch withId(String? value) {
    _patch[BaseEntity$.id] = value;
    return this;
  }

  BaseEntityPatch withCreatedAt(DateTime? value) {
    _patch[BaseEntity$.createdAt] = value;
    return this;
  }

  BaseEntityPatch withUpdatedAt(DateTime? value) {
    _patch[BaseEntity$.updatedAt] = value;
    return this;
  }
}

extension BaseEntitySerialization on BaseEntity {
  Map<String, dynamic> toJson() => _$BaseEntityToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BaseEntityToJson(this);
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

extension BaseEntityCompareE on BaseEntity {
  Map<String, dynamic> compareToBaseEntity(BaseEntity other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (updatedAt != other.updatedAt) {
      diff['updatedAt'] = () => other.updatedAt;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class User implements $$BaseEntity {
  final String id;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String name;
  final String email;

  User({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    required this.name,
    required this.email,
  });

  User copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? email,
  }) {
    return User(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      email: email ?? this.email,
    );
  }

  User copyWithUser({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? email,
  }) {
    return copyWith(
      id: id,
      createdAt: createdAt,
      updatedAt: updatedAt,
      name: name,
      email: email,
    );
  }

  User patchWithUser({UserPatch? patchInput}) {
    final _patcher = patchInput ?? UserPatch();
    final _patchMap = _patcher.toPatch();
    return User(
      id: _patchMap.containsKey(User$.id)
          ? (_patchMap[User$.id] is Function)
                ? _patchMap[User$.id](this.id)
                : _patchMap[User$.id]
          : this.id,
      createdAt: _patchMap.containsKey(User$.createdAt)
          ? (_patchMap[User$.createdAt] is Function)
                ? _patchMap[User$.createdAt](this.createdAt)
                : _patchMap[User$.createdAt]
          : this.createdAt,
      updatedAt: _patchMap.containsKey(User$.updatedAt)
          ? (_patchMap[User$.updatedAt] is Function)
                ? _patchMap[User$.updatedAt](this.updatedAt)
                : _patchMap[User$.updatedAt]
          : this.updatedAt,
      name: _patchMap.containsKey(User$.name)
          ? (_patchMap[User$.name] is Function)
                ? _patchMap[User$.name](this.name)
                : _patchMap[User$.name]
          : this.name,
      email: _patchMap.containsKey(User$.email)
          ? (_patchMap[User$.email] is Function)
                ? _patchMap[User$.email](this.email)
                : _patchMap[User$.email]
          : this.email,
    );
  }

  User copyWithBaseEntity({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return copyWith(id: id, createdAt: createdAt, updatedAt: updatedAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        id == other.id &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        name == other.name &&
        email == other.email;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.createdAt,
      this.updatedAt,
      this.name,
      this.email,
    );
  }

  @override
  String toString() {
    return 'User(' +
        'id: ${id}' +
        ', ' +
        'createdAt: ${createdAt}' +
        ', ' +
        'updatedAt: ${updatedAt}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'email: ${email})';
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
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum User$ { id, createdAt, updatedAt, name, email }

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

  UserPatch withCreatedAt(DateTime? value) {
    _patch[User$.createdAt] = value;
    return this;
  }

  UserPatch withUpdatedAt(DateTime? value) {
    _patch[User$.updatedAt] = value;
    return this;
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
      return json..forEach((key, value) {
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

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (updatedAt != other.updatedAt) {
      diff['updatedAt'] = () => other.updatedAt;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    return diff;
  }
}
