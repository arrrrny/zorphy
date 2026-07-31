// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'base_config.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class BaseConfig {
  final String name;
  final Options? options;

  BaseConfig({required this.name, this.options});

  BaseConfig copyWith({String? name, Options? options}) {
    return BaseConfig(
      name: name ?? this.name,
      options: options ?? this.options,
    );
  }

  BaseConfig copyWithBaseConfig({String? name, Options? options}) {
    return copyWith(name: name, options: options);
  }

  BaseConfig patchWithBaseConfig({BaseConfigPatch? patchInput}) {
    final _patcher = patchInput ?? BaseConfigPatch();
    final _patchMap = _patcher.patchMap;
    return BaseConfig(
      name: _patchMap.containsKey(BaseConfig$.name)
          ? (_patchMap[BaseConfig$.name] is Function)
                ? _patchMap[BaseConfig$.name](this.name)
                : (_patchMap[BaseConfig$.name] is Patch)
                ? _patchMap[BaseConfig$.name].applyTo(this.name)
                : _patchMap[BaseConfig$.name]
          : this.name,
      options: _patchMap.containsKey(BaseConfig$.options)
          ? (_patchMap[BaseConfig$.options] is Function)
                ? _patchMap[BaseConfig$.options](this.options)
                : (_patchMap[BaseConfig$.options] is Patch)
                ? _patchMap[BaseConfig$.options].applyTo(this.options)
                : _patchMap[BaseConfig$.options]
          : this.options,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BaseConfig &&
        name == other.name &&
        options == other.options;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.options);
  }

  @override
  String toString() {
    return 'BaseConfig(' + 'name: ${name}' + ', ' + 'options: ${options})';
  }
}

extension BaseConfigPropertyHelpers on BaseConfig {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasOptions => options != null;
  bool get noOptions => options == null;
  Options get optionsRequired =>
      options ?? (throw StateError('options is required but was null'));
}

enum BaseConfig$ { name, options }

class BaseConfigPatch extends PatchBase<BaseConfig, BaseConfig$> {
  BaseConfig applyTo(BaseConfig entity) {
    return entity.patchWithBaseConfig(patchInput: this);
  }

  BaseConfigPatch withName(String? value) {
    patchMap[BaseConfig$.name] = value;
    return this;
  }

  BaseConfigPatch withOptions(Options? value) {
    patchMap[BaseConfig$.options] = value;
    return this;
  }
}

extension BaseConfigCompareE on BaseConfig {
  Map<String, dynamic> compareToBaseConfig(BaseConfig other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (options != other.options) {
      diff['options'] = () => other.options;
    }
    return diff;
  }
}
