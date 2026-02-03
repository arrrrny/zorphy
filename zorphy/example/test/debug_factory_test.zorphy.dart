// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'debug_factory_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class SimpleResponse implements $$SimpleResponse {
  final String message;
  final String status;

  SimpleResponse({required this.message, required this.status});

  SimpleResponse copyWith({String? message, String? status}) {
    return SimpleResponse(
      message: message ?? this.message,
      status: status ?? this.status,
    );
  }

  SimpleResponse copyWithSimpleResponse({String? message, String? status}) {
    return copyWith(message: message, status: status);
  }

  factory SimpleResponse.success(String message) =>
      SimpleResponse.success(message);

  factory SimpleResponse.error(String error) => SimpleResponse.error(error);

  SimpleResponse patchWithSimpleResponse({SimpleResponsePatch? patchInput}) {
    final _patcher = patchInput ?? SimpleResponsePatch();
    final _patchMap = _patcher.toPatch();
    return SimpleResponse(
      message: _patchMap.containsKey(SimpleResponse$.message)
          ? (_patchMap[SimpleResponse$.message] is Function)
                ? _patchMap[SimpleResponse$.message](this.message)
                : _patchMap[SimpleResponse$.message]
          : this.message,
      status: _patchMap.containsKey(SimpleResponse$.status)
          ? (_patchMap[SimpleResponse$.status] is Function)
                ? _patchMap[SimpleResponse$.status](this.status)
                : _patchMap[SimpleResponse$.status]
          : this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimpleResponse &&
        message == other.message &&
        status == other.status;
  }

  @override
  int get hashCode {
    return Object.hash(this.message, this.status);
  }

  @override
  String toString() {
    return 'SimpleResponse(' +
        'message: ${message}' +
        ', ' +
        'status: ${status})';
  }

  /// Creates a [SimpleResponse] instance from JSON
  factory SimpleResponse.fromJson(Map<String, dynamic> json) =>
      _$SimpleResponseFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$SimpleResponseToJson(this);
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

enum SimpleResponse$ { message, status }

class SimpleResponsePatch implements Patch<SimpleResponse> {
  final Map<SimpleResponse$, dynamic> _patch = {};

  static SimpleResponsePatch create([Map<String, dynamic>? diff]) {
    final patch = SimpleResponsePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = SimpleResponse$.values.firstWhere(
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

  static SimpleResponsePatch fromPatch(Map<SimpleResponse$, dynamic> patch) {
    final _patch = SimpleResponsePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<SimpleResponse$, dynamic> toPatch() => Map.from(_patch);

  SimpleResponse applyTo(SimpleResponse entity) {
    return entity.patchWithSimpleResponse(patchInput: this);
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

  static SimpleResponsePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  SimpleResponsePatch withMessage(String? value) {
    _patch[SimpleResponse$.message] = value;
    return this;
  }

  SimpleResponsePatch withStatus(String? value) {
    _patch[SimpleResponse$.status] = value;
    return this;
  }
}

extension SimpleResponseSerialization on SimpleResponse {
  Map<String, dynamic> toJson() => _$SimpleResponseToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$SimpleResponseToJson(this);
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

extension SimpleResponseCompareE on SimpleResponse {
  Map<String, dynamic> compareToSimpleResponse(SimpleResponse other) {
    final Map<String, dynamic> diff = {};

    if (message != other.message) {
      diff['message'] = () => other.message;
    }
    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class BasicResponse implements $$SimpleResponse {
  final String message;
  final String status;

  BasicResponse({required this.message, required this.status});

  BasicResponse copyWith({String? message, String? status}) {
    return BasicResponse(
      message: message ?? this.message,
      status: status ?? this.status,
    );
  }

  BasicResponse copyWithBasicResponse({String? message, String? status}) {
    return copyWith(message: message, status: status);
  }

  BasicResponse patchWithBasicResponse({BasicResponsePatch? patchInput}) {
    final _patcher = patchInput ?? BasicResponsePatch();
    final _patchMap = _patcher.toPatch();
    return BasicResponse(
      message: _patchMap.containsKey(BasicResponse$.message)
          ? (_patchMap[BasicResponse$.message] is Function)
                ? _patchMap[BasicResponse$.message](this.message)
                : _patchMap[BasicResponse$.message]
          : this.message,
      status: _patchMap.containsKey(BasicResponse$.status)
          ? (_patchMap[BasicResponse$.status] is Function)
                ? _patchMap[BasicResponse$.status](this.status)
                : _patchMap[BasicResponse$.status]
          : this.status,
    );
  }

  BasicResponse copyWithSimpleResponse({String? message, String? status}) {
    return copyWith(message: message, status: status);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BasicResponse &&
        message == other.message &&
        status == other.status;
  }

  @override
  int get hashCode {
    return Object.hash(this.message, this.status);
  }

  @override
  String toString() {
    return 'BasicResponse(' +
        'message: ${message}' +
        ', ' +
        'status: ${status})';
  }

  /// Creates a [BasicResponse] instance from JSON
  factory BasicResponse.fromJson(Map<String, dynamic> json) =>
      _$BasicResponseFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BasicResponseToJson(this);
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

enum BasicResponse$ { message, status }

class BasicResponsePatch implements Patch<BasicResponse> {
  final Map<BasicResponse$, dynamic> _patch = {};

  static BasicResponsePatch create([Map<String, dynamic>? diff]) {
    final patch = BasicResponsePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = BasicResponse$.values.firstWhere(
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

  static BasicResponsePatch fromPatch(Map<BasicResponse$, dynamic> patch) {
    final _patch = BasicResponsePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<BasicResponse$, dynamic> toPatch() => Map.from(_patch);

  BasicResponse applyTo(BasicResponse entity) {
    return entity.patchWithBasicResponse(patchInput: this);
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

  static BasicResponsePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  BasicResponsePatch withMessage(String? value) {
    _patch[BasicResponse$.message] = value;
    return this;
  }

  BasicResponsePatch withStatus(String? value) {
    _patch[BasicResponse$.status] = value;
    return this;
  }
}

extension BasicResponseSerialization on BasicResponse {
  Map<String, dynamic> toJson() => _$BasicResponseToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BasicResponseToJson(this);
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

extension BasicResponseCompareE on BasicResponse {
  Map<String, dynamic> compareToBasicResponse(BasicResponse other) {
    final Map<String, dynamic> diff = {};

    if (message != other.message) {
      diff['message'] = () => other.message;
    }
    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class DetailedResponse implements $$SimpleResponse {
  final String message;
  final String status;
  final Map<String, dynamic> data;

  DetailedResponse({
    required this.message,
    required this.status,
    required this.data,
  });

  DetailedResponse copyWith({
    String? message,
    String? status,
    Map<String, dynamic>? data,
  }) {
    return DetailedResponse(
      message: message ?? this.message,
      status: status ?? this.status,
      data: data ?? this.data,
    );
  }

  DetailedResponse copyWithDetailedResponse({
    String? message,
    String? status,
    Map<String, dynamic>? data,
  }) {
    return copyWith(message: message, status: status, data: data);
  }

  DetailedResponse patchWithDetailedResponse({
    DetailedResponsePatch? patchInput,
  }) {
    final _patcher = patchInput ?? DetailedResponsePatch();
    final _patchMap = _patcher.toPatch();
    return DetailedResponse(
      message: _patchMap.containsKey(DetailedResponse$.message)
          ? (_patchMap[DetailedResponse$.message] is Function)
                ? _patchMap[DetailedResponse$.message](this.message)
                : _patchMap[DetailedResponse$.message]
          : this.message,
      status: _patchMap.containsKey(DetailedResponse$.status)
          ? (_patchMap[DetailedResponse$.status] is Function)
                ? _patchMap[DetailedResponse$.status](this.status)
                : _patchMap[DetailedResponse$.status]
          : this.status,
      data: _patchMap.containsKey(DetailedResponse$.data)
          ? (_patchMap[DetailedResponse$.data] is Function)
                ? _patchMap[DetailedResponse$.data](this.data)
                : _patchMap[DetailedResponse$.data]
          : this.data,
    );
  }

  DetailedResponse copyWithSimpleResponse({String? message, String? status}) {
    return copyWith(message: message, status: status);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DetailedResponse &&
        message == other.message &&
        status == other.status &&
        data == other.data;
  }

  @override
  int get hashCode {
    return Object.hash(this.message, this.status, this.data);
  }

  @override
  String toString() {
    return 'DetailedResponse(' +
        'message: ${message}' +
        ', ' +
        'status: ${status}' +
        ', ' +
        'data: ${data})';
  }

  /// Creates a [DetailedResponse] instance from JSON
  factory DetailedResponse.fromJson(Map<String, dynamic> json) =>
      _$DetailedResponseFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$DetailedResponseToJson(this);
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

enum DetailedResponse$ { message, status, data }

class DetailedResponsePatch implements Patch<DetailedResponse> {
  final Map<DetailedResponse$, dynamic> _patch = {};

  static DetailedResponsePatch create([Map<String, dynamic>? diff]) {
    final patch = DetailedResponsePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = DetailedResponse$.values.firstWhere(
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

  static DetailedResponsePatch fromPatch(
    Map<DetailedResponse$, dynamic> patch,
  ) {
    final _patch = DetailedResponsePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<DetailedResponse$, dynamic> toPatch() => Map.from(_patch);

  DetailedResponse applyTo(DetailedResponse entity) {
    return entity.patchWithDetailedResponse(patchInput: this);
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

  static DetailedResponsePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  DetailedResponsePatch withMessage(String? value) {
    _patch[DetailedResponse$.message] = value;
    return this;
  }

  DetailedResponsePatch withStatus(String? value) {
    _patch[DetailedResponse$.status] = value;
    return this;
  }

  DetailedResponsePatch withData(Map<String, dynamic>? value) {
    _patch[DetailedResponse$.data] = value;
    return this;
  }
}

extension DetailedResponseSerialization on DetailedResponse {
  Map<String, dynamic> toJson() => _$DetailedResponseToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$DetailedResponseToJson(this);
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

extension DetailedResponseCompareE on DetailedResponse {
  Map<String, dynamic> compareToDetailedResponse(DetailedResponse other) {
    final Map<String, dynamic> diff = {};

    if (message != other.message) {
      diff['message'] = () => other.message;
    }
    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    if (data != other.data) {
      diff['data'] = () => other.data;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class ConcreteResponse implements $$SimpleResponse {
  final String message;
  final String status;
  final DateTime timestamp;
  final bool isSuccess;

  ConcreteResponse({
    required this.message,
    required this.status,
    required this.timestamp,
    required this.isSuccess,
  });

  ConcreteResponse copyWith({
    String? message,
    String? status,
    DateTime? timestamp,
    bool? isSuccess,
  }) {
    return ConcreteResponse(
      message: message ?? this.message,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  ConcreteResponse copyWithConcreteResponse({
    String? message,
    String? status,
    DateTime? timestamp,
    bool? isSuccess,
  }) {
    return copyWith(
      message: message,
      status: status,
      timestamp: timestamp,
      isSuccess: isSuccess,
    );
  }

  ConcreteResponse patchWithConcreteResponse({
    ConcreteResponsePatch? patchInput,
  }) {
    final _patcher = patchInput ?? ConcreteResponsePatch();
    final _patchMap = _patcher.toPatch();
    return ConcreteResponse(
      message: _patchMap.containsKey(ConcreteResponse$.message)
          ? (_patchMap[ConcreteResponse$.message] is Function)
                ? _patchMap[ConcreteResponse$.message](this.message)
                : _patchMap[ConcreteResponse$.message]
          : this.message,
      status: _patchMap.containsKey(ConcreteResponse$.status)
          ? (_patchMap[ConcreteResponse$.status] is Function)
                ? _patchMap[ConcreteResponse$.status](this.status)
                : _patchMap[ConcreteResponse$.status]
          : this.status,
      timestamp: _patchMap.containsKey(ConcreteResponse$.timestamp)
          ? (_patchMap[ConcreteResponse$.timestamp] is Function)
                ? _patchMap[ConcreteResponse$.timestamp](this.timestamp)
                : _patchMap[ConcreteResponse$.timestamp]
          : this.timestamp,
      isSuccess: _patchMap.containsKey(ConcreteResponse$.isSuccess)
          ? (_patchMap[ConcreteResponse$.isSuccess] is Function)
                ? _patchMap[ConcreteResponse$.isSuccess](this.isSuccess)
                : _patchMap[ConcreteResponse$.isSuccess]
          : this.isSuccess,
    );
  }

  ConcreteResponse copyWithSimpleResponse({String? message, String? status}) {
    return copyWith(message: message, status: status);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConcreteResponse &&
        message == other.message &&
        status == other.status &&
        timestamp == other.timestamp &&
        isSuccess == other.isSuccess;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.message,
      this.status,
      this.timestamp,
      this.isSuccess,
    );
  }

  @override
  String toString() {
    return 'ConcreteResponse(' +
        'message: ${message}' +
        ', ' +
        'status: ${status}' +
        ', ' +
        'timestamp: ${timestamp}' +
        ', ' +
        'isSuccess: ${isSuccess})';
  }

  /// Creates a [ConcreteResponse] instance from JSON
  factory ConcreteResponse.fromJson(Map<String, dynamic> json) =>
      _$ConcreteResponseFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ConcreteResponseToJson(this);
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

enum ConcreteResponse$ { message, status, timestamp, isSuccess }

class ConcreteResponsePatch implements Patch<ConcreteResponse> {
  final Map<ConcreteResponse$, dynamic> _patch = {};

  static ConcreteResponsePatch create([Map<String, dynamic>? diff]) {
    final patch = ConcreteResponsePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = ConcreteResponse$.values.firstWhere(
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

  static ConcreteResponsePatch fromPatch(
    Map<ConcreteResponse$, dynamic> patch,
  ) {
    final _patch = ConcreteResponsePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<ConcreteResponse$, dynamic> toPatch() => Map.from(_patch);

  ConcreteResponse applyTo(ConcreteResponse entity) {
    return entity.patchWithConcreteResponse(patchInput: this);
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

  static ConcreteResponsePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ConcreteResponsePatch withMessage(String? value) {
    _patch[ConcreteResponse$.message] = value;
    return this;
  }

  ConcreteResponsePatch withStatus(String? value) {
    _patch[ConcreteResponse$.status] = value;
    return this;
  }

  ConcreteResponsePatch withTimestamp(DateTime? value) {
    _patch[ConcreteResponse$.timestamp] = value;
    return this;
  }

  ConcreteResponsePatch withIsSuccess(bool? value) {
    _patch[ConcreteResponse$.isSuccess] = value;
    return this;
  }
}

extension ConcreteResponseSerialization on ConcreteResponse {
  Map<String, dynamic> toJson() => _$ConcreteResponseToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ConcreteResponseToJson(this);
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

extension ConcreteResponseCompareE on ConcreteResponse {
  Map<String, dynamic> compareToConcreteResponse(ConcreteResponse other) {
    final Map<String, dynamic> diff = {};

    if (message != other.message) {
      diff['message'] = () => other.message;
    }
    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    if (timestamp != other.timestamp) {
      diff['timestamp'] = () => other.timestamp;
    }
    if (isSuccess != other.isSuccess) {
      diff['isSuccess'] = () => other.isSuccess;
    }
    return diff;
  }
}
