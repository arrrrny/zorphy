// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'nullable_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class ErrorLog {
  final String? id;
  final String message;
  final String stackTrace;
  final String logLevel;
  final String? loggerName;
  final String? userId;
  final String? customerId;
  final Map<String, dynamic>? deviceInfo;
  final String? ipAddress;
  final String? appVersion;
  final String? platform;
  final DateTime timestamp;
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
    final _patchMap = _patcher.patchMap;
    return ErrorLog(
      id: _patchMap.containsKey(ErrorLog$.id)
          ? (_patchMap[ErrorLog$.id] is Function)
                ? _patchMap[ErrorLog$.id](this.id)
                : (_patchMap[ErrorLog$.id] is Patch)
                ? _patchMap[ErrorLog$.id].applyTo(this.id)
                : _patchMap[ErrorLog$.id]
          : this.id,
      message: _patchMap.containsKey(ErrorLog$.message)
          ? (_patchMap[ErrorLog$.message] is Function)
                ? _patchMap[ErrorLog$.message](this.message)
                : (_patchMap[ErrorLog$.message] is Patch)
                ? _patchMap[ErrorLog$.message].applyTo(this.message)
                : _patchMap[ErrorLog$.message]
          : this.message,
      stackTrace: _patchMap.containsKey(ErrorLog$.stackTrace)
          ? (_patchMap[ErrorLog$.stackTrace] is Function)
                ? _patchMap[ErrorLog$.stackTrace](this.stackTrace)
                : (_patchMap[ErrorLog$.stackTrace] is Patch)
                ? _patchMap[ErrorLog$.stackTrace].applyTo(this.stackTrace)
                : _patchMap[ErrorLog$.stackTrace]
          : this.stackTrace,
      logLevel: _patchMap.containsKey(ErrorLog$.logLevel)
          ? (_patchMap[ErrorLog$.logLevel] is Function)
                ? _patchMap[ErrorLog$.logLevel](this.logLevel)
                : (_patchMap[ErrorLog$.logLevel] is Patch)
                ? _patchMap[ErrorLog$.logLevel].applyTo(this.logLevel)
                : _patchMap[ErrorLog$.logLevel]
          : this.logLevel,
      loggerName: _patchMap.containsKey(ErrorLog$.loggerName)
          ? (_patchMap[ErrorLog$.loggerName] is Function)
                ? _patchMap[ErrorLog$.loggerName](this.loggerName)
                : (_patchMap[ErrorLog$.loggerName] is Patch)
                ? _patchMap[ErrorLog$.loggerName].applyTo(this.loggerName)
                : _patchMap[ErrorLog$.loggerName]
          : this.loggerName,
      userId: _patchMap.containsKey(ErrorLog$.userId)
          ? (_patchMap[ErrorLog$.userId] is Function)
                ? _patchMap[ErrorLog$.userId](this.userId)
                : (_patchMap[ErrorLog$.userId] is Patch)
                ? _patchMap[ErrorLog$.userId].applyTo(this.userId)
                : _patchMap[ErrorLog$.userId]
          : this.userId,
      customerId: _patchMap.containsKey(ErrorLog$.customerId)
          ? (_patchMap[ErrorLog$.customerId] is Function)
                ? _patchMap[ErrorLog$.customerId](this.customerId)
                : (_patchMap[ErrorLog$.customerId] is Patch)
                ? _patchMap[ErrorLog$.customerId].applyTo(this.customerId)
                : _patchMap[ErrorLog$.customerId]
          : this.customerId,
      deviceInfo: _patchMap.containsKey(ErrorLog$.deviceInfo)
          ? (_patchMap[ErrorLog$.deviceInfo] is Function)
                ? _patchMap[ErrorLog$.deviceInfo](this.deviceInfo)
                : (_patchMap[ErrorLog$.deviceInfo] is Patch)
                ? _patchMap[ErrorLog$.deviceInfo].applyTo(this.deviceInfo)
                : _patchMap[ErrorLog$.deviceInfo]
          : this.deviceInfo,
      ipAddress: _patchMap.containsKey(ErrorLog$.ipAddress)
          ? (_patchMap[ErrorLog$.ipAddress] is Function)
                ? _patchMap[ErrorLog$.ipAddress](this.ipAddress)
                : (_patchMap[ErrorLog$.ipAddress] is Patch)
                ? _patchMap[ErrorLog$.ipAddress].applyTo(this.ipAddress)
                : _patchMap[ErrorLog$.ipAddress]
          : this.ipAddress,
      appVersion: _patchMap.containsKey(ErrorLog$.appVersion)
          ? (_patchMap[ErrorLog$.appVersion] is Function)
                ? _patchMap[ErrorLog$.appVersion](this.appVersion)
                : (_patchMap[ErrorLog$.appVersion] is Patch)
                ? _patchMap[ErrorLog$.appVersion].applyTo(this.appVersion)
                : _patchMap[ErrorLog$.appVersion]
          : this.appVersion,
      platform: _patchMap.containsKey(ErrorLog$.platform)
          ? (_patchMap[ErrorLog$.platform] is Function)
                ? _patchMap[ErrorLog$.platform](this.platform)
                : (_patchMap[ErrorLog$.platform] is Patch)
                ? _patchMap[ErrorLog$.platform].applyTo(this.platform)
                : _patchMap[ErrorLog$.platform]
          : this.platform,
      timestamp: _patchMap.containsKey(ErrorLog$.timestamp)
          ? (_patchMap[ErrorLog$.timestamp] is Function)
                ? _patchMap[ErrorLog$.timestamp](this.timestamp)
                : (_patchMap[ErrorLog$.timestamp] is Patch)
                ? _patchMap[ErrorLog$.timestamp].applyTo(this.timestamp)
                : _patchMap[ErrorLog$.timestamp]
          : this.timestamp,
      createdAt: _patchMap.containsKey(ErrorLog$.createdAt)
          ? (_patchMap[ErrorLog$.createdAt] is Function)
                ? _patchMap[ErrorLog$.createdAt](this.createdAt)
                : (_patchMap[ErrorLog$.createdAt] is Patch)
                ? _patchMap[ErrorLog$.createdAt].applyTo(this.createdAt)
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

extension ErrorLogPropertyHelpers on ErrorLog {
  bool get hasId => id?.isNotEmpty == true;
  bool get noId => id?.isEmpty ?? true;
  String get idRequired =>
      id ?? (throw StateError('id is required but was null'));
  bool get hasMessage => message.isNotEmpty;
  bool get noMessage => message.isEmpty;
  bool get hasStackTrace => stackTrace.isNotEmpty;
  bool get noStackTrace => stackTrace.isEmpty;
  bool get hasLogLevel => logLevel.isNotEmpty;
  bool get noLogLevel => logLevel.isEmpty;
  bool get hasLoggerName => loggerName?.isNotEmpty == true;
  bool get noLoggerName => loggerName?.isEmpty ?? true;
  String get loggerNameRequired =>
      loggerName ?? (throw StateError('loggerName is required but was null'));
  bool get hasUserId => userId?.isNotEmpty == true;
  bool get noUserId => userId?.isEmpty ?? true;
  String get userIdRequired =>
      userId ?? (throw StateError('userId is required but was null'));
  bool get hasCustomerId => customerId?.isNotEmpty == true;
  bool get noCustomerId => customerId?.isEmpty ?? true;
  String get customerIdRequired =>
      customerId ?? (throw StateError('customerId is required but was null'));
  Map<String, dynamic> get deviceInfoRequired =>
      deviceInfo ?? (throw StateError('deviceInfo is required but was null'));
  bool get hasDeviceInfo => deviceInfo?.isNotEmpty ?? false;
  bool get noDeviceInfo => deviceInfo?.isEmpty ?? true;
  bool get hasIpAddress => ipAddress?.isNotEmpty == true;
  bool get noIpAddress => ipAddress?.isEmpty ?? true;
  String get ipAddressRequired =>
      ipAddress ?? (throw StateError('ipAddress is required but was null'));
  bool get hasAppVersion => appVersion?.isNotEmpty == true;
  bool get noAppVersion => appVersion?.isEmpty ?? true;
  String get appVersionRequired =>
      appVersion ?? (throw StateError('appVersion is required but was null'));
  bool get hasPlatform => platform?.isNotEmpty == true;
  bool get noPlatform => platform?.isEmpty ?? true;
  String get platformRequired =>
      platform ?? (throw StateError('platform is required but was null'));
}

extension ErrorLogSerialization on ErrorLog {
  Map<String, dynamic> toJson() => _$ErrorLogToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ErrorLogToJson(this);
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

class ErrorLogPatch extends PatchBase<ErrorLog, ErrorLog$> {
  ErrorLog applyTo(ErrorLog entity) {
    return entity.patchWithErrorLog(patchInput: this);
  }

  ErrorLogPatch withId(String? value) {
    patchMap[ErrorLog$.id] = value;
    return this;
  }

  ErrorLogPatch withMessage(String? value) {
    patchMap[ErrorLog$.message] = value;
    return this;
  }

  ErrorLogPatch withStackTrace(String? value) {
    patchMap[ErrorLog$.stackTrace] = value;
    return this;
  }

  ErrorLogPatch withLogLevel(String? value) {
    patchMap[ErrorLog$.logLevel] = value;
    return this;
  }

  ErrorLogPatch withLoggerName(String? value) {
    patchMap[ErrorLog$.loggerName] = value;
    return this;
  }

  ErrorLogPatch withUserId(String? value) {
    patchMap[ErrorLog$.userId] = value;
    return this;
  }

  ErrorLogPatch withCustomerId(String? value) {
    patchMap[ErrorLog$.customerId] = value;
    return this;
  }

  ErrorLogPatch withDeviceInfo(Map<String, dynamic>? value) {
    patchMap[ErrorLog$.deviceInfo] = value;
    return this;
  }

  ErrorLogPatch withIpAddress(String? value) {
    patchMap[ErrorLog$.ipAddress] = value;
    return this;
  }

  ErrorLogPatch withAppVersion(String? value) {
    patchMap[ErrorLog$.appVersion] = value;
    return this;
  }

  ErrorLogPatch withPlatform(String? value) {
    patchMap[ErrorLog$.platform] = value;
    return this;
  }

  ErrorLogPatch withTimestamp(DateTime? value) {
    patchMap[ErrorLog$.timestamp] = value;
    return this;
  }

  ErrorLogPatch withCreatedAt(DateTime? value) {
    patchMap[ErrorLog$.createdAt] = value;
    return this;
  }
}

/// Field descriptors for [ErrorLog] query construction
abstract final class ErrorLogFields {
  static String? _$getid(ErrorLog e) => e.id;
  static const id = Field<ErrorLog, String?>('id', _$getid);
  static String _$getmessage(ErrorLog e) => e.message;
  static const message = Field<ErrorLog, String>('message', _$getmessage);
  static String _$getstackTrace(ErrorLog e) => e.stackTrace;
  static const stackTrace = Field<ErrorLog, String>(
    'stackTrace',
    _$getstackTrace,
  );
  static String _$getlogLevel(ErrorLog e) => e.logLevel;
  static const logLevel = Field<ErrorLog, String>('logLevel', _$getlogLevel);
  static String? _$getloggerName(ErrorLog e) => e.loggerName;
  static const loggerName = Field<ErrorLog, String?>(
    'loggerName',
    _$getloggerName,
  );
  static String? _$getuserId(ErrorLog e) => e.userId;
  static const userId = Field<ErrorLog, String?>('userId', _$getuserId);
  static String? _$getcustomerId(ErrorLog e) => e.customerId;
  static const customerId = Field<ErrorLog, String?>(
    'customerId',
    _$getcustomerId,
  );
  static Map<String, dynamic>? _$getdeviceInfo(ErrorLog e) => e.deviceInfo;
  static const deviceInfo = Field<ErrorLog, Map<String, dynamic>?>(
    'deviceInfo',
    _$getdeviceInfo,
  );
  static String? _$getipAddress(ErrorLog e) => e.ipAddress;
  static const ipAddress = Field<ErrorLog, String?>(
    'ipAddress',
    _$getipAddress,
  );
  static String? _$getappVersion(ErrorLog e) => e.appVersion;
  static const appVersion = Field<ErrorLog, String?>(
    'appVersion',
    _$getappVersion,
  );
  static String? _$getplatform(ErrorLog e) => e.platform;
  static const platform = Field<ErrorLog, String?>('platform', _$getplatform);
  static DateTime _$gettimestamp(ErrorLog e) => e.timestamp;
  static const timestamp = Field<ErrorLog, DateTime>(
    'timestamp',
    _$gettimestamp,
  );
  static DateTime _$getcreatedAt(ErrorLog e) => e.createdAt;
  static const createdAt = Field<ErrorLog, DateTime>(
    'createdAt',
    _$getcreatedAt,
  );
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
