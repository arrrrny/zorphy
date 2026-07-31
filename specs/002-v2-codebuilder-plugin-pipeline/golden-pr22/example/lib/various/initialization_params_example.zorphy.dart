// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'initialization_params_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class InitializationParamsExample {
  final Duration timeout;
  final bool forceRefresh;
  final Params? params;
  final Params? credentials;
  final Params? settings;
  @JsonKey(toJson: LocaleConverter.toJson, fromJson: LocaleConverter.fromJson)
  final Locale? locale;

  InitializationParamsExample({
    required this.timeout,
    required this.forceRefresh,
    this.params,
    this.credentials,
    this.settings,
    this.locale,
  });

  InitializationParamsExample copyWith({
    Duration? timeout,
    bool? forceRefresh,
    Params? params,
    Params? credentials,
    Params? settings,
    Locale? locale,
  }) {
    return InitializationParamsExample(
      timeout: timeout ?? this.timeout,
      forceRefresh: forceRefresh ?? this.forceRefresh,
      params: params ?? this.params,
      credentials: credentials ?? this.credentials,
      settings: settings ?? this.settings,
      locale: locale ?? this.locale,
    );
  }

  InitializationParamsExample copyWithInitializationParamsExample({
    Duration? timeout,
    bool? forceRefresh,
    Params? params,
    Params? credentials,
    Params? settings,
    Locale? locale,
  }) {
    return copyWith(
      timeout: timeout,
      forceRefresh: forceRefresh,
      params: params,
      credentials: credentials,
      settings: settings,
      locale: locale,
    );
  }

  InitializationParamsExample patchWithInitializationParamsExample({
    InitializationParamsExamplePatch? patchInput,
  }) {
    final _patcher = patchInput ?? InitializationParamsExamplePatch();
    final _patchMap = _patcher.patchMap;
    return InitializationParamsExample(
      timeout: _patchMap.containsKey(InitializationParamsExample$.timeout)
          ? (_patchMap[InitializationParamsExample$.timeout] is Function)
                ? _patchMap[InitializationParamsExample$.timeout](this.timeout)
                : (_patchMap[InitializationParamsExample$.timeout] is Patch)
                ? _patchMap[InitializationParamsExample$.timeout].applyTo(
                    this.timeout,
                  )
                : _patchMap[InitializationParamsExample$.timeout]
          : this.timeout,
      forceRefresh:
          _patchMap.containsKey(InitializationParamsExample$.forceRefresh)
          ? (_patchMap[InitializationParamsExample$.forceRefresh] is Function)
                ? _patchMap[InitializationParamsExample$.forceRefresh](
                    this.forceRefresh,
                  )
                : (_patchMap[InitializationParamsExample$.forceRefresh]
                      is Patch)
                ? _patchMap[InitializationParamsExample$.forceRefresh].applyTo(
                    this.forceRefresh,
                  )
                : _patchMap[InitializationParamsExample$.forceRefresh]
          : this.forceRefresh,
      params: _patchMap.containsKey(InitializationParamsExample$.params)
          ? (_patchMap[InitializationParamsExample$.params] is Function)
                ? _patchMap[InitializationParamsExample$.params](this.params)
                : (_patchMap[InitializationParamsExample$.params] is Patch)
                ? _patchMap[InitializationParamsExample$.params].applyTo(
                    this.params,
                  )
                : _patchMap[InitializationParamsExample$.params]
          : this.params,
      credentials:
          _patchMap.containsKey(InitializationParamsExample$.credentials)
          ? (_patchMap[InitializationParamsExample$.credentials] is Function)
                ? _patchMap[InitializationParamsExample$.credentials](
                    this.credentials,
                  )
                : (_patchMap[InitializationParamsExample$.credentials] is Patch)
                ? _patchMap[InitializationParamsExample$.credentials].applyTo(
                    this.credentials,
                  )
                : _patchMap[InitializationParamsExample$.credentials]
          : this.credentials,
      settings: _patchMap.containsKey(InitializationParamsExample$.settings)
          ? (_patchMap[InitializationParamsExample$.settings] is Function)
                ? _patchMap[InitializationParamsExample$.settings](
                    this.settings,
                  )
                : (_patchMap[InitializationParamsExample$.settings] is Patch)
                ? _patchMap[InitializationParamsExample$.settings].applyTo(
                    this.settings,
                  )
                : _patchMap[InitializationParamsExample$.settings]
          : this.settings,
      locale: _patchMap.containsKey(InitializationParamsExample$.locale)
          ? (_patchMap[InitializationParamsExample$.locale] is Function)
                ? _patchMap[InitializationParamsExample$.locale](this.locale)
                : (_patchMap[InitializationParamsExample$.locale] is Patch)
                ? _patchMap[InitializationParamsExample$.locale].applyTo(
                    this.locale,
                  )
                : _patchMap[InitializationParamsExample$.locale]
          : this.locale,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InitializationParamsExample &&
        timeout == other.timeout &&
        forceRefresh == other.forceRefresh &&
        params == other.params &&
        credentials == other.credentials &&
        settings == other.settings &&
        locale == other.locale;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.timeout,
      this.forceRefresh,
      this.params,
      this.credentials,
      this.settings,
      this.locale,
    );
  }

  @override
  String toString() {
    return 'InitializationParamsExample(' +
        'timeout: ${timeout}' +
        ', ' +
        'forceRefresh: ${forceRefresh}' +
        ', ' +
        'params: ${params}' +
        ', ' +
        'credentials: ${credentials}' +
        ', ' +
        'settings: ${settings}' +
        ', ' +
        'locale: ${locale})';
  }

  /// Creates a [InitializationParamsExample] instance from JSON
  factory InitializationParamsExample.fromJson(Map<String, dynamic> json) =>
      _$InitializationParamsExampleFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$InitializationParamsExampleToJson(this);
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

extension InitializationParamsExamplePropertyHelpers
    on InitializationParamsExample {
  bool get hasParams => params != null;
  bool get noParams => params == null;
  Params get paramsRequired =>
      params ?? (throw StateError('params is required but was null'));
  bool get hasCredentials => credentials != null;
  bool get noCredentials => credentials == null;
  Params get credentialsRequired =>
      credentials ?? (throw StateError('credentials is required but was null'));
  bool get hasSettings => settings != null;
  bool get noSettings => settings == null;
  Params get settingsRequired =>
      settings ?? (throw StateError('settings is required but was null'));
  bool get hasLocale => locale != null;
  bool get noLocale => locale == null;
  Locale get localeRequired =>
      locale ?? (throw StateError('locale is required but was null'));
}

extension InitializationParamsExampleSerialization
    on InitializationParamsExample {
  Map<String, dynamic> toJson() => _$InitializationParamsExampleToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$InitializationParamsExampleToJson(this);
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

enum InitializationParamsExample$ {
  timeout,
  forceRefresh,
  params,
  credentials,
  settings,
  locale,
}

class InitializationParamsExamplePatch
    extends
        PatchBase<InitializationParamsExample, InitializationParamsExample$> {
  InitializationParamsExample applyTo(InitializationParamsExample entity) {
    return entity.patchWithInitializationParamsExample(patchInput: this);
  }

  InitializationParamsExamplePatch withTimeout(Duration? value) {
    patchMap[InitializationParamsExample$.timeout] = value;
    return this;
  }

  InitializationParamsExamplePatch withForceRefresh(bool? value) {
    patchMap[InitializationParamsExample$.forceRefresh] = value;
    return this;
  }

  InitializationParamsExamplePatch withParams(Params? value) {
    patchMap[InitializationParamsExample$.params] = value;
    return this;
  }

  InitializationParamsExamplePatch withCredentials(Params? value) {
    patchMap[InitializationParamsExample$.credentials] = value;
    return this;
  }

  InitializationParamsExamplePatch withSettings(Params? value) {
    patchMap[InitializationParamsExample$.settings] = value;
    return this;
  }

  InitializationParamsExamplePatch withLocale(Locale? value) {
    patchMap[InitializationParamsExample$.locale] = value;
    return this;
  }
}

/// Field descriptors for [InitializationParamsExample] query construction
abstract final class InitializationParamsExampleFields {
  static Duration _$gettimeout(InitializationParamsExample e) => e.timeout;
  static const timeout = Field<InitializationParamsExample, Duration>(
    'timeout',
    _$gettimeout,
  );
  static bool _$getforceRefresh(InitializationParamsExample e) =>
      e.forceRefresh;
  static const forceRefresh = Field<InitializationParamsExample, bool>(
    'forceRefresh',
    _$getforceRefresh,
  );
  static Params? _$getparams(InitializationParamsExample e) => e.params;
  static const params = Field<InitializationParamsExample, Params?>(
    'params',
    _$getparams,
  );
  static Params? _$getcredentials(InitializationParamsExample e) =>
      e.credentials;
  static const credentials = Field<InitializationParamsExample, Params?>(
    'credentials',
    _$getcredentials,
  );
  static Params? _$getsettings(InitializationParamsExample e) => e.settings;
  static const settings = Field<InitializationParamsExample, Params?>(
    'settings',
    _$getsettings,
  );
  static Locale? _$getlocale(InitializationParamsExample e) => e.locale;
  static const locale = Field<InitializationParamsExample, Locale?>(
    'locale',
    _$getlocale,
  );
}

extension InitializationParamsExampleCompareE on InitializationParamsExample {
  Map<String, dynamic> compareToInitializationParamsExample(
    InitializationParamsExample other,
  ) {
    final Map<String, dynamic> diff = {};

    if (timeout != other.timeout) {
      diff['timeout'] = () => other.timeout;
    }
    if (forceRefresh != other.forceRefresh) {
      diff['forceRefresh'] = () => other.forceRefresh;
    }
    if (params != other.params) {
      diff['params'] = () => other.params;
    }
    if (credentials != other.credentials) {
      diff['credentials'] = () => other.credentials;
    }
    if (settings != other.settings) {
      diff['settings'] = () => other.settings;
    }
    if (locale != other.locale) {
      diff['locale'] = () => other.locale;
    }
    return diff;
  }
}
