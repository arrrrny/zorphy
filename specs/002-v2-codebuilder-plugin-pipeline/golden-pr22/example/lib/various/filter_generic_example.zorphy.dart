// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'filter_generic_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class CreateParams<T, P> {
  final T data;
  final P? params;

  CreateParams({required this.data, this.params});

  CreateParams copyWith({T? data, P? params}) {
    return CreateParams(data: data ?? this.data, params: params ?? this.params);
  }

  CreateParams copyWithCreateParams({T? data, P? params}) {
    return copyWith(data: data, params: params);
  }

  CreateParams patchWithCreateParams({CreateParamsPatch? patchInput}) {
    final _patcher = patchInput ?? CreateParamsPatch();
    final _patchMap = _patcher.patchMap;
    return CreateParams(
      data: _patchMap.containsKey(CreateParams$.data)
          ? (_patchMap[CreateParams$.data] is Function)
                ? _patchMap[CreateParams$.data](this.data)
                : (_patchMap[CreateParams$.data] is Patch)
                ? _patchMap[CreateParams$.data].applyTo(this.data)
                : _patchMap[CreateParams$.data]
          : this.data,
      params: _patchMap.containsKey(CreateParams$.params)
          ? (_patchMap[CreateParams$.params] is Function)
                ? _patchMap[CreateParams$.params](this.params)
                : (_patchMap[CreateParams$.params] is Patch)
                ? _patchMap[CreateParams$.params].applyTo(this.params)
                : _patchMap[CreateParams$.params]
          : this.params,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateParams &&
        data == other.data &&
        params == other.params;
  }

  @override
  int get hashCode {
    return Object.hash(this.data, this.params);
  }

  @override
  String toString() {
    return 'CreateParams(' + 'data: ${data}' + ', ' + 'params: ${params})';
  }
}

extension CreateParamsPropertyHelpers<T, P> on CreateParams<T, P> {
  bool get hasParams => params != null;
  bool get noParams => params == null;
  P get paramsRequired =>
      params ?? (throw StateError('params is required but was null'));
}

enum CreateParams$ { data, params }

class CreateParamsPatch extends PatchBase<CreateParams, CreateParams$> {
  CreateParams applyTo(CreateParams entity) {
    return entity.patchWithCreateParams(patchInput: this);
  }

  CreateParamsPatch withData(dynamic value) {
    patchMap[CreateParams$.data] = value;
    return this;
  }

  CreateParamsPatch withParams(dynamic value) {
    patchMap[CreateParams$.params] = value;
    return this;
  }
}

/// Field descriptors for [CreateParams] query construction
abstract final class CreateParamsFields {
  static T _$getdata<T, P>(CreateParams<T, P> e) => e.data;
  static Field<CreateParams<T, P>, T> data<T, P>() =>
      Field<CreateParams<T, P>, T>('data', _$getdata<T, P>);
  static P? _$getparams<T, P>(CreateParams<T, P> e) => e.params;
  static Field<CreateParams<T, P>, P?> params<T, P>() =>
      Field<CreateParams<T, P>, P?>('params', _$getparams<T, P>);
}

extension CreateParamsCompareE on CreateParams {
  Map<String, dynamic> compareToCreateParams(CreateParams other) {
    final Map<String, dynamic> diff = {};

    if (data != other.data) {
      diff['data'] = () => other.data;
    }
    if (params != other.params) {
      diff['params'] = () => other.params;
    }
    return diff;
  }
}
