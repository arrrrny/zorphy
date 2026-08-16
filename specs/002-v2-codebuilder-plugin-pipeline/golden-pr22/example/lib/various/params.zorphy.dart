// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'params.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Params {
  final String token;

  Params({required this.token});

  Params copyWith({String? token}) {
    return Params(token: token ?? this.token);
  }

  Params copyWithParams({String? token}) {
    return copyWith(token: token);
  }

  Params patchWithParams({ParamsPatch? patchInput}) {
    final _patcher = patchInput ?? ParamsPatch();
    final _patchMap = _patcher.patchMap;
    return Params(
      token: _patchMap.containsKey(Params$.token)
          ? (_patchMap[Params$.token] is Function)
                ? _patchMap[Params$.token](this.token)
                : (_patchMap[Params$.token] is Patch)
                ? _patchMap[Params$.token].applyTo(this.token)
                : _patchMap[Params$.token]
          : this.token,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Params && token == other.token;
  }

  @override
  int get hashCode {
    return Object.hash(token, 0);
  }

  @override
  String toString() {
    return 'Params(' + 'token: ${token})';
  }

  /// Creates a [Params] instance from JSON
  factory Params.fromJson(Map<String, dynamic> json) => _$ParamsFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ParamsToJson(this);
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

extension ParamsPropertyHelpers on Params {
  bool get hasToken => token.isNotEmpty;
  bool get noToken => token.isEmpty;
}

extension ParamsSerialization on Params {
  Map<String, dynamic> toJson() => _$ParamsToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ParamsToJson(this);
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

enum Params$ { token }

class ParamsPatch extends PatchBase<Params, Params$> {
  Params applyTo(Params entity) {
    return entity.patchWithParams(patchInput: this);
  }

  ParamsPatch withToken(String? value) {
    patchMap[Params$.token] = value;
    return this;
  }
}

/// Field descriptors for [Params] query construction
abstract final class ParamsFields {
  static String _$gettoken(Params e) => e.token;
  static const token = Field<Params, String>('token', _$gettoken);
}

extension ParamsCompareE on Params {
  Map<String, dynamic> compareToParams(Params other) {
    final Map<String, dynamic> diff = {};

    if (token != other.token) {
      diff['token'] = () => other.token;
    }
    return diff;
  }
}
