// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'nullable_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class ErrorLog extends $ErrorLog {
  @override
  final String? id;
  @override
  final String message;
  @override
  final String stackTrace;
  @override
  final String logLevel;
  @override
  final String? loggerName;
  @override
  final String? userId;
  @override
  final String? customerId;
  @override
  final Map<String, dynamic>? deviceInfo;
  @override
  final String? ipAddress;
  @override
  final String? appVersion;
  @override
  final String? platform;
  @override
  final DateTime timestamp;
  @override
  final DateTime createdAt;

  ErrorLog({
    this.id,
    required this.message,
    required this.stackTrace,
    required this.logLevel,
    this.loggerName,
    this.userId,
    this.customerId,
    this.deviceInfo,
    this.ipAddress,
    this.appVersion,
    this.platform,
    required this.timestamp,
    required this.createdAt,
  });

  ErrorLog copyWith({
    String? id,
    String? message,
    String? stackTrace,
    String? logLevel,
    String? loggerName,
    String? userId,
    String? customerId,
    Map<String, dynamic>? deviceInfo,
    String? ipAddress,
    String? appVersion,
    String? platform,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    return ErrorLog(
      id: id ?? this.id,
      message: message ?? this.message,
      stackTrace: stackTrace ?? this.stackTrace,
      logLevel: logLevel ?? this.logLevel,
      loggerName: loggerName ?? this.loggerName,
      userId: userId ?? this.userId,
      customerId: customerId ?? this.customerId,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
      appVersion: appVersion ?? this.appVersion,
      platform: platform ?? this.platform,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  ErrorLog copyWithErrorLog({
    String? id,
    String? message,
    String? stackTrace,
    String? logLevel,
    String? loggerName,
    String? userId,
    String? customerId,
    Map<String, dynamic>? deviceInfo,
    String? ipAddress,
    String? appVersion,
    String? platform,
    DateTime? timestamp,
    DateTime? createdAt,
  }) {
    return copyWith(
      id: id,
      message: message,
      stackTrace: stackTrace,
      logLevel: logLevel,
      loggerName: loggerName,
      userId: userId,
      customerId: customerId,
      deviceInfo: deviceInfo,
      ipAddress: ipAddress,
      appVersion: appVersion,
      platform: platform,
      timestamp: timestamp,
      createdAt: createdAt,
    );
  }

  ErrorLog patchWithErrorLog({ErrorLogPatch? patchInput}) {
    final _patcher = patchInput ?? ErrorLogPatch();
    final _patchMap = _patcher.toPatch();
    return ErrorLog(
      id: _patchMap.containsKey(ErrorLog$.id)
          ? (_patchMap[ErrorLog$.id] is Function)
                ? _patchMap[ErrorLog$.id](this.id)
                : _patchMap[ErrorLog$.id]
          : this.id,
      message: _patchMap.containsKey(ErrorLog$.message)
          ? (_patchMap[ErrorLog$.message] is Function)
                ? _patchMap[ErrorLog$.message](this.message)
                : _patchMap[ErrorLog$.message]
          : this.message,
      stackTrace: _patchMap.containsKey(ErrorLog$.stackTrace)
          ? (_patchMap[ErrorLog$.stackTrace] is Function)
                ? _patchMap[ErrorLog$.stackTrace](this.stackTrace)
                : _patchMap[ErrorLog$.stackTrace]
          : this.stackTrace,
      logLevel: _patchMap.containsKey(ErrorLog$.logLevel)
          ? (_patchMap[ErrorLog$.logLevel] is Function)
                ? _patchMap[ErrorLog$.logLevel](this.logLevel)
                : _patchMap[ErrorLog$.logLevel]
          : this.logLevel,
      loggerName: _patchMap.containsKey(ErrorLog$.loggerName)
          ? (_patchMap[ErrorLog$.loggerName] is Function)
                ? _patchMap[ErrorLog$.loggerName](this.loggerName)
                : _patchMap[ErrorLog$.loggerName]
          : this.loggerName,
      userId: _patchMap.containsKey(ErrorLog$.userId)
          ? (_patchMap[ErrorLog$.userId] is Function)
                ? _patchMap[ErrorLog$.userId](this.userId)
                : _patchMap[ErrorLog$.userId]
          : this.userId,
      customerId: _patchMap.containsKey(ErrorLog$.customerId)
          ? (_patchMap[ErrorLog$.customerId] is Function)
                ? _patchMap[ErrorLog$.customerId](this.customerId)
                : _patchMap[ErrorLog$.customerId]
          : this.customerId,
      deviceInfo: _patchMap.containsKey(ErrorLog$.deviceInfo)
          ? (_patchMap[ErrorLog$.deviceInfo] is Function)
                ? _patchMap[ErrorLog$.deviceInfo](this.deviceInfo)
                : _patchMap[ErrorLog$.deviceInfo]
          : this.deviceInfo,
      ipAddress: _patchMap.containsKey(ErrorLog$.ipAddress)
          ? (_patchMap[ErrorLog$.ipAddress] is Function)
                ? _patchMap[ErrorLog$.ipAddress](this.ipAddress)
                : _patchMap[ErrorLog$.ipAddress]
          : this.ipAddress,
      appVersion: _patchMap.containsKey(ErrorLog$.appVersion)
          ? (_patchMap[ErrorLog$.appVersion] is Function)
                ? _patchMap[ErrorLog$.appVersion](this.appVersion)
                : _patchMap[ErrorLog$.appVersion]
          : this.appVersion,
      platform: _patchMap.containsKey(ErrorLog$.platform)
          ? (_patchMap[ErrorLog$.platform] is Function)
                ? _patchMap[ErrorLog$.platform](this.platform)
                : _patchMap[ErrorLog$.platform]
          : this.platform,
      timestamp: _patchMap.containsKey(ErrorLog$.timestamp)
          ? (_patchMap[ErrorLog$.timestamp] is Function)
                ? _patchMap[ErrorLog$.timestamp](this.timestamp)
                : _patchMap[ErrorLog$.timestamp]
          : this.timestamp,
      createdAt: _patchMap.containsKey(ErrorLog$.createdAt)
          ? (_patchMap[ErrorLog$.createdAt] is Function)
                ? _patchMap[ErrorLog$.createdAt](this.createdAt)
                : _patchMap[ErrorLog$.createdAt]
          : this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorLog &&
        id == other.id &&
        message == other.message &&
        stackTrace == other.stackTrace &&
        logLevel == other.logLevel &&
        loggerName == other.loggerName &&
        userId == other.userId &&
        customerId == other.customerId &&
        deviceInfo == other.deviceInfo &&
        ipAddress == other.ipAddress &&
        appVersion == other.appVersion &&
        platform == other.platform &&
        timestamp == other.timestamp &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.message,
      this.stackTrace,
      this.logLevel,
      this.loggerName,
      this.userId,
      this.customerId,
      this.deviceInfo,
      this.ipAddress,
      this.appVersion,
      this.platform,
      this.timestamp,
      this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ErrorLog(' +
        'id: ${id}' +
        ', ' +
        'message: ${message}' +
        ', ' +
        'stackTrace: ${stackTrace}' +
        ', ' +
        'logLevel: ${logLevel}' +
        ', ' +
        'loggerName: ${loggerName}' +
        ', ' +
        'userId: ${userId}' +
        ', ' +
        'customerId: ${customerId}' +
        ', ' +
        'deviceInfo: ${deviceInfo}' +
        ', ' +
        'ipAddress: ${ipAddress}' +
        ', ' +
        'appVersion: ${appVersion}' +
        ', ' +
        'platform: ${platform}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'createdAt: ${createdAt})';
  }

  /// Creates a [ErrorLog] instance from JSON
  factory ErrorLog.fromJson(Map<String, dynamic> json) =>
      _$ErrorLogFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ErrorLogToJson(this);
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

enum ErrorLog$ {
  id,
  message,
  stackTrace,
  logLevel,
  loggerName,
  userId,
  customerId,
  deviceInfo,
  ipAddress,
  appVersion,
  platform,
  timestamp,
  createdAt,
}

class ErrorLogPatch implements Patch<ErrorLog> {
  final Map<ErrorLog$, dynamic> _patch = {};

  static ErrorLogPatch create([Map<String, dynamic>? diff]) {
    final patch = ErrorLogPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = ErrorLog$.values.firstWhere((e) => e.name == key);
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

  static ErrorLogPatch fromPatch(Map<ErrorLog$, dynamic> patch) {
    final _patch = ErrorLogPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<ErrorLog$, dynamic> toPatch() => Map.from(_patch);

  ErrorLog applyTo(ErrorLog entity) {
    return entity.patchWithErrorLog(patchInput: this);
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

  static ErrorLogPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ErrorLogPatch withId(String? value) {
    _patch[ErrorLog$.id] = value;
    return this;
  }

  ErrorLogPatch withMessage(String? value) {
    _patch[ErrorLog$.message] = value;
    return this;
  }

  ErrorLogPatch withStackTrace(String? value) {
    _patch[ErrorLog$.stackTrace] = value;
    return this;
  }

  ErrorLogPatch withLogLevel(String? value) {
    _patch[ErrorLog$.logLevel] = value;
    return this;
  }

  ErrorLogPatch withLoggerName(String? value) {
    _patch[ErrorLog$.loggerName] = value;
    return this;
  }

  ErrorLogPatch withUserId(String? value) {
    _patch[ErrorLog$.userId] = value;
    return this;
  }

  ErrorLogPatch withCustomerId(String? value) {
    _patch[ErrorLog$.customerId] = value;
    return this;
  }

  ErrorLogPatch withDeviceInfo(Map<String, dynamic>? value) {
    _patch[ErrorLog$.deviceInfo] = value;
    return this;
  }

  ErrorLogPatch withIpAddress(String? value) {
    _patch[ErrorLog$.ipAddress] = value;
    return this;
  }

  ErrorLogPatch withAppVersion(String? value) {
    _patch[ErrorLog$.appVersion] = value;
    return this;
  }

  ErrorLogPatch withPlatform(String? value) {
    _patch[ErrorLog$.platform] = value;
    return this;
  }

  ErrorLogPatch withTimestamp(DateTime? value) {
    _patch[ErrorLog$.timestamp] = value;
    return this;
  }

  ErrorLogPatch withCreatedAt(DateTime? value) {
    _patch[ErrorLog$.createdAt] = value;
    return this;
  }
}

extension ErrorLogSerialization on ErrorLog {
  Map<String, dynamic> toJson() => _$ErrorLogToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ErrorLogToJson(this);
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

extension ErrorLogCompareE on ErrorLog {
  Map<String, dynamic> compareToErrorLog(ErrorLog other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (message != other.message) {
      diff['message'] = () => other.message;
    }
    if (stackTrace != other.stackTrace) {
      diff['stackTrace'] = () => other.stackTrace;
    }
    if (logLevel != other.logLevel) {
      diff['logLevel'] = () => other.logLevel;
    }
    if (loggerName != other.loggerName) {
      diff['loggerName'] = () => other.loggerName;
    }
    if (userId != other.userId) {
      diff['userId'] = () => other.userId;
    }
    if (customerId != other.customerId) {
      diff['customerId'] = () => other.customerId;
    }
    if (deviceInfo != other.deviceInfo) {
      diff['deviceInfo'] = () => other.deviceInfo;
    }
    if (ipAddress != other.ipAddress) {
      diff['ipAddress'] = () => other.ipAddress;
    }
    if (appVersion != other.appVersion) {
      diff['appVersion'] = () => other.appVersion;
    }
    if (platform != other.platform) {
      diff['platform'] = () => other.platform;
    }
    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    return diff;
  }
}
