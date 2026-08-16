// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'generic_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(
  explicitToJson: true,
  checked: true,
  genericArgumentFactories: true,
)
class ResultWithConverter<T> {
  final bool success;
  @JsonKey(name: 'data_field')
  @GenericConverter()
  final T? data;
  final String? errorMessage;

  ResultWithConverter({required this.success, this.data, this.errorMessage});

  ResultWithConverter copyWith({bool? success, T? data, String? errorMessage}) {
    return ResultWithConverter(
      success: success ?? this.success,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  ResultWithConverter copyWithResultWithConverter({
    bool? success,
    T? data,
    String? errorMessage,
  }) {
    return copyWith(success: success, data: data, errorMessage: errorMessage);
  }

  ResultWithConverter patchWithResultWithConverter({
    ResultWithConverterPatch? patchInput,
  }) {
    final _patcher = patchInput ?? ResultWithConverterPatch();
    final _patchMap = _patcher.patchMap;
    return ResultWithConverter(
      success: _patchMap.containsKey(ResultWithConverter$.success)
          ? (_patchMap[ResultWithConverter$.success] is Function)
                ? _patchMap[ResultWithConverter$.success](this.success)
                : (_patchMap[ResultWithConverter$.success] is Patch)
                ? _patchMap[ResultWithConverter$.success].applyTo(this.success)
                : _patchMap[ResultWithConverter$.success]
          : this.success,
      data: _patchMap.containsKey(ResultWithConverter$.data)
          ? (_patchMap[ResultWithConverter$.data] is Function)
                ? _patchMap[ResultWithConverter$.data](this.data)
                : (_patchMap[ResultWithConverter$.data] is Patch)
                ? _patchMap[ResultWithConverter$.data].applyTo(this.data)
                : _patchMap[ResultWithConverter$.data]
          : this.data,
      errorMessage: _patchMap.containsKey(ResultWithConverter$.errorMessage)
          ? (_patchMap[ResultWithConverter$.errorMessage] is Function)
                ? _patchMap[ResultWithConverter$.errorMessage](
                    this.errorMessage,
                  )
                : (_patchMap[ResultWithConverter$.errorMessage] is Patch)
                ? _patchMap[ResultWithConverter$.errorMessage].applyTo(
                    this.errorMessage,
                  )
                : _patchMap[ResultWithConverter$.errorMessage]
          : this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResultWithConverter &&
        success == other.success &&
        data == other.data &&
        errorMessage == other.errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(this.success, this.data, this.errorMessage);
  }

  @override
  String toString() {
    return 'ResultWithConverter(' +
        'success: ${success}' +
        ', ' +
        'data: ${data}' +
        ', ' +
        'errorMessage: ${errorMessage})';
  }

  /// Creates a [ResultWithConverter] instance from JSON
  factory ResultWithConverter.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ResultWithConverterFromJson(json, fromJsonT);

  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$ResultWithConverterToJson(
      this,
      toJsonT,
    );
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

extension ResultWithConverterPropertyHelpers<T> on ResultWithConverter<T> {
  bool get hasData => data != null;
  bool get noData => data == null;
  T get dataRequired =>
      data ?? (throw StateError('data is required but was null'));
  bool get hasErrorMessage => errorMessage?.isNotEmpty == true;
  bool get noErrorMessage => errorMessage?.isEmpty ?? true;
  String get errorMessageRequired =>
      errorMessage ??
      (throw StateError('errorMessage is required but was null'));
}

extension ResultWithConverterSerialization<T> on ResultWithConverter<T> {
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ResultWithConverterToJson(this, toJsonT);
  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$ResultWithConverterToJson(
      this,
      toJsonT,
    );
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

enum ResultWithConverter$ { success, data, errorMessage }

class ResultWithConverterPatch
    extends PatchBase<ResultWithConverter, ResultWithConverter$> {
  ResultWithConverter applyTo(ResultWithConverter entity) {
    return entity.patchWithResultWithConverter(patchInput: this);
  }

  ResultWithConverterPatch withSuccess(bool? value) {
    patchMap[ResultWithConverter$.success] = value;
    return this;
  }

  ResultWithConverterPatch withData(dynamic value) {
    patchMap[ResultWithConverter$.data] = value;
    return this;
  }

  ResultWithConverterPatch withErrorMessage(String? value) {
    patchMap[ResultWithConverter$.errorMessage] = value;
    return this;
  }
}

/// Field descriptors for [ResultWithConverter] query construction
abstract final class ResultWithConverterFields {
  static bool _$getsuccess<T>(ResultWithConverter<T> e) => e.success;
  static Field<ResultWithConverter<T>, bool> success<T>() =>
      Field<ResultWithConverter<T>, bool>('success', _$getsuccess<T>);
  static T? _$getdata<T>(ResultWithConverter<T> e) => e.data;
  static Field<ResultWithConverter<T>, T?> data<T>() =>
      Field<ResultWithConverter<T>, T?>('data', _$getdata<T>);
  static String? _$geterrorMessage<T>(ResultWithConverter<T> e) =>
      e.errorMessage;
  static Field<ResultWithConverter<T>, String?> errorMessage<T>() =>
      Field<ResultWithConverter<T>, String?>(
        'errorMessage',
        _$geterrorMessage<T>,
      );
}

extension ResultWithConverterCompareE on ResultWithConverter {
  Map<String, dynamic> compareToResultWithConverter(ResultWithConverter other) {
    final Map<String, dynamic> diff = {};

    if (success != other.success) {
      diff['success'] = () => other.success;
    }
    if (data != other.data) {
      diff['data'] = () => other.data;
    }
    if (errorMessage != other.errorMessage) {
      diff['errorMessage'] = () => other.errorMessage;
    }
    return diff;
  }
}

@JsonSerializable(
  explicitToJson: true,
  checked: true,
  genericArgumentFactories: true,
)
class Result<T> {
  final bool success;
  final T? data;
  final String? errorMessage;
  final int? statusCode;

  Result({
    required this.success,
    this.data,
    this.errorMessage,
    this.statusCode,
  });

  Result copyWith({
    bool? success,
    T? data,
    String? errorMessage,
    int? statusCode,
  }) {
    return Result(
      success: success ?? this.success,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
      statusCode: statusCode ?? this.statusCode,
    );
  }

  Result copyWithResult({
    bool? success,
    T? data,
    String? errorMessage,
    int? statusCode,
  }) {
    return copyWith(
      success: success,
      data: data,
      errorMessage: errorMessage,
      statusCode: statusCode,
    );
  }

  Result patchWithResult({ResultPatch? patchInput}) {
    final _patcher = patchInput ?? ResultPatch();
    final _patchMap = _patcher.patchMap;
    return Result(
      success: _patchMap.containsKey(Result$.success)
          ? (_patchMap[Result$.success] is Function)
                ? _patchMap[Result$.success](this.success)
                : (_patchMap[Result$.success] is Patch)
                ? _patchMap[Result$.success].applyTo(this.success)
                : _patchMap[Result$.success]
          : this.success,
      data: _patchMap.containsKey(Result$.data)
          ? (_patchMap[Result$.data] is Function)
                ? _patchMap[Result$.data](this.data)
                : (_patchMap[Result$.data] is Patch)
                ? _patchMap[Result$.data].applyTo(this.data)
                : _patchMap[Result$.data]
          : this.data,
      errorMessage: _patchMap.containsKey(Result$.errorMessage)
          ? (_patchMap[Result$.errorMessage] is Function)
                ? _patchMap[Result$.errorMessage](this.errorMessage)
                : (_patchMap[Result$.errorMessage] is Patch)
                ? _patchMap[Result$.errorMessage].applyTo(this.errorMessage)
                : _patchMap[Result$.errorMessage]
          : this.errorMessage,
      statusCode: _patchMap.containsKey(Result$.statusCode)
          ? (_patchMap[Result$.statusCode] is Function)
                ? _patchMap[Result$.statusCode](this.statusCode)
                : (_patchMap[Result$.statusCode] is Patch)
                ? _patchMap[Result$.statusCode].applyTo(this.statusCode)
                : _patchMap[Result$.statusCode]
          : this.statusCode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Result &&
        success == other.success &&
        data == other.data &&
        errorMessage == other.errorMessage &&
        statusCode == other.statusCode;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.success,
      this.data,
      this.errorMessage,
      this.statusCode,
    );
  }

  @override
  String toString() {
    return 'Result(' +
        'success: ${success}' +
        ', ' +
        'data: ${data}' +
        ', ' +
        'errorMessage: ${errorMessage}' +
        ', ' +
        'statusCode: ${statusCode})';
  }

  /// Creates a [Result] instance from JSON
  factory Result.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ResultFromJson(json, fromJsonT);

  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$ResultToJson(this, toJsonT);
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

extension ResultPropertyHelpers<T> on Result<T> {
  bool get hasData => data != null;
  bool get noData => data == null;
  T get dataRequired =>
      data ?? (throw StateError('data is required but was null'));
  bool get hasErrorMessage => errorMessage?.isNotEmpty == true;
  bool get noErrorMessage => errorMessage?.isEmpty ?? true;
  String get errorMessageRequired =>
      errorMessage ??
      (throw StateError('errorMessage is required but was null'));
  bool get hasStatusCode => statusCode != null;
  bool get noStatusCode => statusCode == null;
  int get statusCodeRequired =>
      statusCode ?? (throw StateError('statusCode is required but was null'));
}

extension ResultSerialization<T> on Result<T> {
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ResultToJson(this, toJsonT);
  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$ResultToJson(this, toJsonT);
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

enum Result$ { success, data, errorMessage, statusCode }

class ResultPatch extends PatchBase<Result, Result$> {
  Result applyTo(Result entity) {
    return entity.patchWithResult(patchInput: this);
  }

  ResultPatch withSuccess(bool? value) {
    patchMap[Result$.success] = value;
    return this;
  }

  ResultPatch withData(dynamic value) {
    patchMap[Result$.data] = value;
    return this;
  }

  ResultPatch withErrorMessage(String? value) {
    patchMap[Result$.errorMessage] = value;
    return this;
  }

  ResultPatch withStatusCode(int? value) {
    patchMap[Result$.statusCode] = value;
    return this;
  }
}

/// Field descriptors for [Result] query construction
abstract final class ResultFields {
  static bool _$getsuccess<T>(Result<T> e) => e.success;
  static Field<Result<T>, bool> success<T>() =>
      Field<Result<T>, bool>('success', _$getsuccess<T>);
  static T? _$getdata<T>(Result<T> e) => e.data;
  static Field<Result<T>, T?> data<T>() =>
      Field<Result<T>, T?>('data', _$getdata<T>);
  static String? _$geterrorMessage<T>(Result<T> e) => e.errorMessage;
  static Field<Result<T>, String?> errorMessage<T>() =>
      Field<Result<T>, String?>('errorMessage', _$geterrorMessage<T>);
  static int? _$getstatusCode<T>(Result<T> e) => e.statusCode;
  static Field<Result<T>, int?> statusCode<T>() =>
      Field<Result<T>, int?>('statusCode', _$getstatusCode<T>);
}

extension ResultCompareE on Result {
  Map<String, dynamic> compareToResult(Result other) {
    final Map<String, dynamic> diff = {};

    if (success != other.success) {
      diff['success'] = () => other.success;
    }
    if (data != other.data) {
      diff['data'] = () => other.data;
    }
    if (errorMessage != other.errorMessage) {
      diff['errorMessage'] = () => other.errorMessage;
    }
    if (statusCode != other.statusCode) {
      diff['statusCode'] = () => other.statusCode;
    }
    return diff;
  }
}

@JsonSerializable(
  explicitToJson: true,
  checked: true,
  genericArgumentFactories: true,
)
class PaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool hasNextPage;
  final bool hasPreviousPage;

  PaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.hasNextPage,
    required this.hasPreviousPage,
  });

  PaginatedResponse copyWith({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
  }) {
    return PaginatedResponse(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      hasPreviousPage: hasPreviousPage ?? this.hasPreviousPage,
    );
  }

  PaginatedResponse copyWithPaginatedResponse({
    List<T>? items,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? hasNextPage,
    bool? hasPreviousPage,
  }) {
    return copyWith(
      items: items,
      currentPage: currentPage,
      totalPages: totalPages,
      totalItems: totalItems,
      hasNextPage: hasNextPage,
      hasPreviousPage: hasPreviousPage,
    );
  }

  PaginatedResponse patchWithPaginatedResponse({
    PaginatedResponsePatch? patchInput,
  }) {
    final _patcher = patchInput ?? PaginatedResponsePatch();
    final _patchMap = _patcher.patchMap;
    return PaginatedResponse(
      items: _patchMap.containsKey(PaginatedResponse$.items)
          ? (_patchMap[PaginatedResponse$.items] is Function)
                ? _patchMap[PaginatedResponse$.items](this.items)
                : (_patchMap[PaginatedResponse$.items] is Patch)
                ? _patchMap[PaginatedResponse$.items].applyTo(this.items)
                : _patchMap[PaginatedResponse$.items]
          : this.items,
      currentPage: _patchMap.containsKey(PaginatedResponse$.currentPage)
          ? (_patchMap[PaginatedResponse$.currentPage] is Function)
                ? _patchMap[PaginatedResponse$.currentPage](this.currentPage)
                : (_patchMap[PaginatedResponse$.currentPage] is Patch)
                ? _patchMap[PaginatedResponse$.currentPage].applyTo(
                    this.currentPage,
                  )
                : _patchMap[PaginatedResponse$.currentPage]
          : this.currentPage,
      totalPages: _patchMap.containsKey(PaginatedResponse$.totalPages)
          ? (_patchMap[PaginatedResponse$.totalPages] is Function)
                ? _patchMap[PaginatedResponse$.totalPages](this.totalPages)
                : (_patchMap[PaginatedResponse$.totalPages] is Patch)
                ? _patchMap[PaginatedResponse$.totalPages].applyTo(
                    this.totalPages,
                  )
                : _patchMap[PaginatedResponse$.totalPages]
          : this.totalPages,
      totalItems: _patchMap.containsKey(PaginatedResponse$.totalItems)
          ? (_patchMap[PaginatedResponse$.totalItems] is Function)
                ? _patchMap[PaginatedResponse$.totalItems](this.totalItems)
                : (_patchMap[PaginatedResponse$.totalItems] is Patch)
                ? _patchMap[PaginatedResponse$.totalItems].applyTo(
                    this.totalItems,
                  )
                : _patchMap[PaginatedResponse$.totalItems]
          : this.totalItems,
      hasNextPage: _patchMap.containsKey(PaginatedResponse$.hasNextPage)
          ? (_patchMap[PaginatedResponse$.hasNextPage] is Function)
                ? _patchMap[PaginatedResponse$.hasNextPage](this.hasNextPage)
                : (_patchMap[PaginatedResponse$.hasNextPage] is Patch)
                ? _patchMap[PaginatedResponse$.hasNextPage].applyTo(
                    this.hasNextPage,
                  )
                : _patchMap[PaginatedResponse$.hasNextPage]
          : this.hasNextPage,
      hasPreviousPage: _patchMap.containsKey(PaginatedResponse$.hasPreviousPage)
          ? (_patchMap[PaginatedResponse$.hasPreviousPage] is Function)
                ? _patchMap[PaginatedResponse$.hasPreviousPage](
                    this.hasPreviousPage,
                  )
                : (_patchMap[PaginatedResponse$.hasPreviousPage] is Patch)
                ? _patchMap[PaginatedResponse$.hasPreviousPage].applyTo(
                    this.hasPreviousPage,
                  )
                : _patchMap[PaginatedResponse$.hasPreviousPage]
          : this.hasPreviousPage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginatedResponse &&
        items == other.items &&
        currentPage == other.currentPage &&
        totalPages == other.totalPages &&
        totalItems == other.totalItems &&
        hasNextPage == other.hasNextPage &&
        hasPreviousPage == other.hasPreviousPage;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.items,
      this.currentPage,
      this.totalPages,
      this.totalItems,
      this.hasNextPage,
      this.hasPreviousPage,
    );
  }

  @override
  String toString() {
    return 'PaginatedResponse(' +
        'items: ${items}' +
        ', ' +
        'currentPage: ${currentPage}' +
        ', ' +
        'totalPages: ${totalPages}' +
        ', ' +
        'totalItems: ${totalItems}' +
        ', ' +
        'hasNextPage: ${hasNextPage}' +
        ', ' +
        'hasPreviousPage: ${hasPreviousPage})';
  }

  /// Creates a [PaginatedResponse] instance from JSON
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$PaginatedResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$PaginatedResponseToJson(this, toJsonT);
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

extension PaginatedResponsePropertyHelpers<T> on PaginatedResponse<T> {
  bool get hasItems => items.isNotEmpty;
  bool get noItems => items.isEmpty;
}

extension PaginatedResponseSerialization<T> on PaginatedResponse<T> {
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$PaginatedResponseToJson(this, toJsonT);
  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$PaginatedResponseToJson(this, toJsonT);
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

enum PaginatedResponse$ {
  items,
  currentPage,
  totalPages,
  totalItems,
  hasNextPage,
  hasPreviousPage,
}

class PaginatedResponsePatch
    extends PatchBase<PaginatedResponse, PaginatedResponse$> {
  PaginatedResponse applyTo(PaginatedResponse entity) {
    return entity.patchWithPaginatedResponse(patchInput: this);
  }

  PaginatedResponsePatch withItems(dynamic value) {
    patchMap[PaginatedResponse$.items] = value;
    return this;
  }

  PaginatedResponsePatch withCurrentPage(int? value) {
    patchMap[PaginatedResponse$.currentPage] = value;
    return this;
  }

  PaginatedResponsePatch withTotalPages(int? value) {
    patchMap[PaginatedResponse$.totalPages] = value;
    return this;
  }

  PaginatedResponsePatch withTotalItems(int? value) {
    patchMap[PaginatedResponse$.totalItems] = value;
    return this;
  }

  PaginatedResponsePatch withHasNextPage(bool? value) {
    patchMap[PaginatedResponse$.hasNextPage] = value;
    return this;
  }

  PaginatedResponsePatch withHasPreviousPage(bool? value) {
    patchMap[PaginatedResponse$.hasPreviousPage] = value;
    return this;
  }
}

/// Field descriptors for [PaginatedResponse] query construction
abstract final class PaginatedResponseFields {
  static List<T> _$getitems<T>(PaginatedResponse<T> e) => e.items;
  static Field<PaginatedResponse<T>, List<T>> items<T>() =>
      Field<PaginatedResponse<T>, List<T>>('items', _$getitems<T>);
  static int _$getcurrentPage<T>(PaginatedResponse<T> e) => e.currentPage;
  static Field<PaginatedResponse<T>, int> currentPage<T>() =>
      Field<PaginatedResponse<T>, int>('currentPage', _$getcurrentPage<T>);
  static int _$gettotalPages<T>(PaginatedResponse<T> e) => e.totalPages;
  static Field<PaginatedResponse<T>, int> totalPages<T>() =>
      Field<PaginatedResponse<T>, int>('totalPages', _$gettotalPages<T>);
  static int _$gettotalItems<T>(PaginatedResponse<T> e) => e.totalItems;
  static Field<PaginatedResponse<T>, int> totalItems<T>() =>
      Field<PaginatedResponse<T>, int>('totalItems', _$gettotalItems<T>);
  static bool _$gethasNextPage<T>(PaginatedResponse<T> e) => e.hasNextPage;
  static Field<PaginatedResponse<T>, bool> hasNextPage<T>() =>
      Field<PaginatedResponse<T>, bool>('hasNextPage', _$gethasNextPage<T>);
  static bool _$gethasPreviousPage<T>(PaginatedResponse<T> e) =>
      e.hasPreviousPage;
  static Field<PaginatedResponse<T>, bool> hasPreviousPage<T>() =>
      Field<PaginatedResponse<T>, bool>(
        'hasPreviousPage',
        _$gethasPreviousPage<T>,
      );
}

extension PaginatedResponseCompareE on PaginatedResponse {
  Map<String, dynamic> compareToPaginatedResponse(PaginatedResponse other) {
    final Map<String, dynamic> diff = {};

    if (items != other.items) {
      diff['items'] = () => other.items;
    }
    if (currentPage != other.currentPage) {
      diff['currentPage'] = () => other.currentPage;
    }
    if (totalPages != other.totalPages) {
      diff['totalPages'] = () => other.totalPages;
    }
    if (totalItems != other.totalItems) {
      diff['totalItems'] = () => other.totalItems;
    }
    if (hasNextPage != other.hasNextPage) {
      diff['hasNextPage'] = () => other.hasNextPage;
    }
    if (hasPreviousPage != other.hasPreviousPage) {
      diff['hasPreviousPage'] = () => other.hasPreviousPage;
    }
    return diff;
  }
}

@JsonSerializable(
  explicitToJson: true,
  checked: true,
  genericArgumentFactories: true,
)
class KeyValue<K, V> {
  final K key;
  final V value;

  KeyValue({required this.key, required this.value});

  KeyValue copyWith({K? key, V? value}) {
    return KeyValue(key: key ?? this.key, value: value ?? this.value);
  }

  KeyValue copyWithKeyValue({K? key, V? value}) {
    return copyWith(key: key, value: value);
  }

  KeyValue patchWithKeyValue({KeyValuePatch? patchInput}) {
    final _patcher = patchInput ?? KeyValuePatch();
    final _patchMap = _patcher.patchMap;
    return KeyValue(
      key: _patchMap.containsKey(KeyValue$.key)
          ? (_patchMap[KeyValue$.key] is Function)
                ? _patchMap[KeyValue$.key](this.key)
                : (_patchMap[KeyValue$.key] is Patch)
                ? _patchMap[KeyValue$.key].applyTo(this.key)
                : _patchMap[KeyValue$.key]
          : this.key,
      value: _patchMap.containsKey(KeyValue$.value)
          ? (_patchMap[KeyValue$.value] is Function)
                ? _patchMap[KeyValue$.value](this.value)
                : (_patchMap[KeyValue$.value] is Patch)
                ? _patchMap[KeyValue$.value].applyTo(this.value)
                : _patchMap[KeyValue$.value]
          : this.value,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KeyValue && key == other.key && value == other.value;
  }

  @override
  int get hashCode {
    return Object.hash(this.key, this.value);
  }

  @override
  String toString() {
    return 'KeyValue(' + 'key: ${key}' + ', ' + 'value: ${value})';
  }

  /// Creates a [KeyValue] instance from JSON
  factory KeyValue.fromJson(
    Map<String, dynamic> json,
    K Function(Object? json) fromJsonK,
    V Function(Object? json) fromJsonV,
  ) => _$KeyValueFromJson(json, fromJsonK, fromJsonV);

  Map<String, dynamic> toJsonLean(
    Object? Function(K value) toJsonK,
    Object? Function(V value) toJsonV,
  ) {
    final Map<String, dynamic> data = _$KeyValueToJson(this, toJsonK, toJsonV);
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

extension KeyValuePropertyHelpers<K, V> on KeyValue<K, V> {}

extension KeyValueSerialization<K, V> on KeyValue<K, V> {
  Map<String, dynamic> toJson(
    Object? Function(K value) toJsonK,
    Object? Function(V value) toJsonV,
  ) => _$KeyValueToJson(this, toJsonK, toJsonV);
  Map<String, dynamic> toJsonLean(
    Object? Function(K value) toJsonK,
    Object? Function(V value) toJsonV,
  ) {
    final Map<String, dynamic> data = _$KeyValueToJson(this, toJsonK, toJsonV);
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

enum KeyValue$ { key, value }

class KeyValuePatch extends PatchBase<KeyValue, KeyValue$> {
  KeyValue applyTo(KeyValue entity) {
    return entity.patchWithKeyValue(patchInput: this);
  }

  KeyValuePatch withKey(dynamic value) {
    patchMap[KeyValue$.key] = value;
    return this;
  }

  KeyValuePatch withValue(dynamic value) {
    patchMap[KeyValue$.value] = value;
    return this;
  }
}

/// Field descriptors for [KeyValue] query construction
abstract final class KeyValueFields {
  static K _$getkey<K, V>(KeyValue<K, V> e) => e.key;
  static Field<KeyValue<K, V>, K> key<K, V>() =>
      Field<KeyValue<K, V>, K>('key', _$getkey<K, V>);
  static V _$getvalue<K, V>(KeyValue<K, V> e) => e.value;
  static Field<KeyValue<K, V>, V> value<K, V>() =>
      Field<KeyValue<K, V>, V>('value', _$getvalue<K, V>);
}

extension KeyValueCompareE on KeyValue {
  Map<String, dynamic> compareToKeyValue(KeyValue other) {
    final Map<String, dynamic> diff = {};

    if (key != other.key) {
      diff['key'] = () => other.key;
    }
    if (value != other.value) {
      diff['value'] = () => other.value;
    }
    return diff;
  }
}

@JsonSerializable(
  explicitToJson: true,
  checked: true,
  genericArgumentFactories: true,
)
class MetadataContainer<T> {
  final T content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final Map<String, dynamic> tags;

  MetadataContainer({
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.tags,
  });

  MetadataContainer copyWith({
    T? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? tags,
  }) {
    return MetadataContainer(
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      tags: tags ?? this.tags,
    );
  }

  MetadataContainer copyWithMetadataContainer({
    T? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    Map<String, dynamic>? tags,
  }) {
    return copyWith(
      content: content,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      tags: tags,
    );
  }

  MetadataContainer patchWithMetadataContainer({
    MetadataContainerPatch? patchInput,
  }) {
    final _patcher = patchInput ?? MetadataContainerPatch();
    final _patchMap = _patcher.patchMap;
    return MetadataContainer(
      content: _patchMap.containsKey(MetadataContainer$.content)
          ? (_patchMap[MetadataContainer$.content] is Function)
                ? _patchMap[MetadataContainer$.content](this.content)
                : (_patchMap[MetadataContainer$.content] is Patch)
                ? _patchMap[MetadataContainer$.content].applyTo(this.content)
                : _patchMap[MetadataContainer$.content]
          : this.content,
      createdAt: _patchMap.containsKey(MetadataContainer$.createdAt)
          ? (_patchMap[MetadataContainer$.createdAt] is Function)
                ? _patchMap[MetadataContainer$.createdAt](this.createdAt)
                : (_patchMap[MetadataContainer$.createdAt] is Patch)
                ? _patchMap[MetadataContainer$.createdAt].applyTo(
                    this.createdAt,
                  )
                : _patchMap[MetadataContainer$.createdAt]
          : this.createdAt,
      updatedAt: _patchMap.containsKey(MetadataContainer$.updatedAt)
          ? (_patchMap[MetadataContainer$.updatedAt] is Function)
                ? _patchMap[MetadataContainer$.updatedAt](this.updatedAt)
                : (_patchMap[MetadataContainer$.updatedAt] is Patch)
                ? _patchMap[MetadataContainer$.updatedAt].applyTo(
                    this.updatedAt,
                  )
                : _patchMap[MetadataContainer$.updatedAt]
          : this.updatedAt,
      createdBy: _patchMap.containsKey(MetadataContainer$.createdBy)
          ? (_patchMap[MetadataContainer$.createdBy] is Function)
                ? _patchMap[MetadataContainer$.createdBy](this.createdBy)
                : (_patchMap[MetadataContainer$.createdBy] is Patch)
                ? _patchMap[MetadataContainer$.createdBy].applyTo(
                    this.createdBy,
                  )
                : _patchMap[MetadataContainer$.createdBy]
          : this.createdBy,
      tags: _patchMap.containsKey(MetadataContainer$.tags)
          ? (_patchMap[MetadataContainer$.tags] is Function)
                ? _patchMap[MetadataContainer$.tags](this.tags)
                : (_patchMap[MetadataContainer$.tags] is Patch)
                ? _patchMap[MetadataContainer$.tags].applyTo(this.tags)
                : _patchMap[MetadataContainer$.tags]
          : this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MetadataContainer &&
        content == other.content &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        createdBy == other.createdBy &&
        tags == other.tags;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.content,
      this.createdAt,
      this.updatedAt,
      this.createdBy,
      this.tags,
    );
  }

  @override
  String toString() {
    return 'MetadataContainer(' +
        'content: ${content}' +
        ', ' +
        'createdAt: ${createdAt}' +
        ', ' +
        'updatedAt: ${updatedAt}' +
        ', ' +
        'createdBy: ${createdBy}' +
        ', ' +
        'tags: ${tags})';
  }

  /// Creates a [MetadataContainer] instance from JSON
  factory MetadataContainer.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$MetadataContainerFromJson(json, fromJsonT);

  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$MetadataContainerToJson(this, toJsonT);
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

extension MetadataContainerPropertyHelpers<T> on MetadataContainer<T> {
  bool get hasCreatedBy => createdBy.isNotEmpty;
  bool get noCreatedBy => createdBy.isEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool get noTags => tags.isEmpty;
}

extension MetadataContainerSerialization<T> on MetadataContainer<T> {
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$MetadataContainerToJson(this, toJsonT);
  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$MetadataContainerToJson(this, toJsonT);
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

enum MetadataContainer$ { content, createdAt, updatedAt, createdBy, tags }

class MetadataContainerPatch
    extends PatchBase<MetadataContainer, MetadataContainer$> {
  MetadataContainer applyTo(MetadataContainer entity) {
    return entity.patchWithMetadataContainer(patchInput: this);
  }

  MetadataContainerPatch withContent(dynamic value) {
    patchMap[MetadataContainer$.content] = value;
    return this;
  }

  MetadataContainerPatch withCreatedAt(DateTime? value) {
    patchMap[MetadataContainer$.createdAt] = value;
    return this;
  }

  MetadataContainerPatch withUpdatedAt(DateTime? value) {
    patchMap[MetadataContainer$.updatedAt] = value;
    return this;
  }

  MetadataContainerPatch withCreatedBy(String? value) {
    patchMap[MetadataContainer$.createdBy] = value;
    return this;
  }

  MetadataContainerPatch withTags(Map<String, dynamic>? value) {
    patchMap[MetadataContainer$.tags] = value;
    return this;
  }
}

/// Field descriptors for [MetadataContainer] query construction
abstract final class MetadataContainerFields {
  static T _$getcontent<T>(MetadataContainer<T> e) => e.content;
  static Field<MetadataContainer<T>, T> content<T>() =>
      Field<MetadataContainer<T>, T>('content', _$getcontent<T>);
  static DateTime _$getcreatedAt<T>(MetadataContainer<T> e) => e.createdAt;
  static Field<MetadataContainer<T>, DateTime> createdAt<T>() =>
      Field<MetadataContainer<T>, DateTime>('createdAt', _$getcreatedAt<T>);
  static DateTime _$getupdatedAt<T>(MetadataContainer<T> e) => e.updatedAt;
  static Field<MetadataContainer<T>, DateTime> updatedAt<T>() =>
      Field<MetadataContainer<T>, DateTime>('updatedAt', _$getupdatedAt<T>);
  static String _$getcreatedBy<T>(MetadataContainer<T> e) => e.createdBy;
  static Field<MetadataContainer<T>, String> createdBy<T>() =>
      Field<MetadataContainer<T>, String>('createdBy', _$getcreatedBy<T>);
  static Map<String, dynamic> _$gettags<T>(MetadataContainer<T> e) => e.tags;
  static Field<MetadataContainer<T>, Map<String, dynamic>> tags<T>() =>
      Field<MetadataContainer<T>, Map<String, dynamic>>('tags', _$gettags<T>);
}

extension MetadataContainerCompareE on MetadataContainer {
  Map<String, dynamic> compareToMetadataContainer(MetadataContainer other) {
    final Map<String, dynamic> diff = {};

    if (content != other.content) {
      diff['content'] = () => other.content;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (updatedAt != other.updatedAt) {
      diff['updatedAt'] = () => other.updatedAt;
    }
    if (createdBy != other.createdBy) {
      diff['createdBy'] = () => other.createdBy;
    }
    if (tags != other.tags) {
      diff['tags'] = () => other.tags;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});

  Product copyWith({String? id, String? name, double? price}) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
    );
  }

  Product copyWithProduct({String? id, String? name, double? price}) {
    return copyWith(id: id, name: name, price: price);
  }

  Product patchWithProduct({ProductPatch? patchInput}) {
    final _patcher = patchInput ?? ProductPatch();
    final _patchMap = _patcher.patchMap;
    return Product(
      id: _patchMap.containsKey(Product$.id)
          ? (_patchMap[Product$.id] is Function)
                ? _patchMap[Product$.id](this.id)
                : (_patchMap[Product$.id] is Patch)
                ? _patchMap[Product$.id].applyTo(this.id)
                : _patchMap[Product$.id]
          : this.id,
      name: _patchMap.containsKey(Product$.name)
          ? (_patchMap[Product$.name] is Function)
                ? _patchMap[Product$.name](this.name)
                : (_patchMap[Product$.name] is Patch)
                ? _patchMap[Product$.name].applyTo(this.name)
                : _patchMap[Product$.name]
          : this.name,
      price: _patchMap.containsKey(Product$.price)
          ? (_patchMap[Product$.price] is Function)
                ? _patchMap[Product$.price](this.price)
                : (_patchMap[Product$.price] is Patch)
                ? _patchMap[Product$.price].applyTo(this.price)
                : _patchMap[Product$.price]
          : this.price,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        id == other.id &&
        name == other.name &&
        price == other.price;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.name, this.price);
  }

  @override
  String toString() {
    return 'Product(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'price: ${price})';
  }

  /// Creates a [Product] instance from JSON
  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ProductToJson(this);
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

extension ProductPropertyHelpers on Product {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

extension ProductSerialization on Product {
  Map<String, dynamic> toJson() => _$ProductToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ProductToJson(this);
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

enum Product$ { id, name, price }

class ProductPatch extends PatchBase<Product, Product$> {
  Product applyTo(Product entity) {
    return entity.patchWithProduct(patchInput: this);
  }

  ProductPatch withId(String? value) {
    patchMap[Product$.id] = value;
    return this;
  }

  ProductPatch withName(String? value) {
    patchMap[Product$.name] = value;
    return this;
  }

  ProductPatch withPrice(double? value) {
    patchMap[Product$.price] = value;
    return this;
  }
}

/// Field descriptors for [Product] query construction
abstract final class ProductFields {
  static String _$getid(Product e) => e.id;
  static const id = Field<Product, String>('id', _$getid);
  static String _$getname(Product e) => e.name;
  static const name = Field<Product, String>('name', _$getname);
  static double _$getprice(Product e) => e.price;
  static const price = Field<Product, double>('price', _$getprice);
}

extension ProductCompareE on Product {
  Map<String, dynamic> compareToProduct(Product other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (price != other.price) {
      diff['price'] = () => other.price;
    }
    return diff;
  }
}
