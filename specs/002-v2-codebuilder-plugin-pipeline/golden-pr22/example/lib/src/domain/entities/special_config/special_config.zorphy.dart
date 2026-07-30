// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'special_config.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class SpecialConfig extends BaseConfig {
  @override
  final AdvancedOptions? options;
  final int priority;

  SpecialConfig({required String name, this.options, required this.priority})
    : super(name: name, options: options);

  SpecialConfig copyWith({
    String? name,
    covariant AdvancedOptions? options,
    int? priority,
  }) {
    return SpecialConfig(
      name: name ?? this.name,
      options: options ?? this.options,
      priority: priority ?? this.priority,
    );
  }

  SpecialConfig copyWithSpecialConfig({
    String? name,
    AdvancedOptions? options,
    int? priority,
  }) {
    return copyWith(name: name, options: options, priority: priority);
  }

  SpecialConfig copyWithBaseConfig({
    String? name,
    covariant AdvancedOptions? options,
  }) {
    return copyWith(name: name, options: options);
  }

  SpecialConfig patchWithSpecialConfig({SpecialConfigPatch? patchInput}) {
    final _patcher = patchInput ?? SpecialConfigPatch();
    final _patchMap = _patcher.patchMap;
    return SpecialConfig(
      name: _patchMap.containsKey(SpecialConfig$.name)
          ? (_patchMap[SpecialConfig$.name] is Function)
                ? _patchMap[SpecialConfig$.name](this.name)
                : (_patchMap[SpecialConfig$.name] is Patch)
                ? _patchMap[SpecialConfig$.name].applyTo(this.name)
                : _patchMap[SpecialConfig$.name]
          : this.name,
      options: _patchMap.containsKey(SpecialConfig$.options)
          ? (_patchMap[SpecialConfig$.options] is Function)
                ? _patchMap[SpecialConfig$.options](this.options)
                : (_patchMap[SpecialConfig$.options] is Patch)
                ? _patchMap[SpecialConfig$.options].applyTo(this.options)
                : _patchMap[SpecialConfig$.options]
          : this.options,
      priority: _patchMap.containsKey(SpecialConfig$.priority)
          ? (_patchMap[SpecialConfig$.priority] is Function)
                ? _patchMap[SpecialConfig$.priority](this.priority)
                : (_patchMap[SpecialConfig$.priority] is Patch)
                ? _patchMap[SpecialConfig$.priority].applyTo(this.priority)
                : _patchMap[SpecialConfig$.priority]
          : this.priority,
    );
  }

  SpecialConfig patchWithBaseConfig({BaseConfigPatch? patchInput}) {
    final _patcher = patchInput ?? BaseConfigPatch();
    final _patchMap = _patcher.patchMap;
    return SpecialConfig(
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
      priority: this.priority,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpecialConfig &&
        name == other.name &&
        options == other.options &&
        priority == other.priority;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.options, this.priority);
  }

  @override
  String toString() {
    return 'SpecialConfig(' +
        'name: ${name}' +
        ', ' +
        'options: ${options}' +
        ', ' +
        'priority: ${priority})';
  }
}

extension SpecialConfigPropertyHelpers on SpecialConfig {
  bool get hasOptions => options != null;
  bool get noOptions => options == null;
  AdvancedOptions get optionsRequired =>
      options ?? (throw StateError('options is required but was null'));
}

enum SpecialConfig$ { name, options, priority }

class SpecialConfigPatch extends PatchBase<SpecialConfig, SpecialConfig$> {
  SpecialConfig applyTo(SpecialConfig entity) {
    return entity.patchWithSpecialConfig(patchInput: this);
  }

  SpecialConfigPatch withName(String? value) {
    patchMap[SpecialConfig$.name] = value;
    return this;
  }

  SpecialConfigPatch withOptions(AdvancedOptions? value) {
    patchMap[SpecialConfig$.options] = value;
    return this;
  }

  SpecialConfigPatch withOptionsPatch(AdvancedOptionsPatch patch) {
    patchMap[SpecialConfig$.options] = patch;
    return this;
  }

  SpecialConfigPatch withOptionsPatchFunc(
    AdvancedOptionsPatch Function(AdvancedOptionsPatch) patch,
  ) {
    patchMap[SpecialConfig$.options] = (dynamic current) {
      var currentPatch = AdvancedOptionsPatch();
      return patch(currentPatch).applyTo(current as AdvancedOptions);
    };
    return this;
  }

  SpecialConfigPatch withPriority(int? value) {
    patchMap[SpecialConfig$.priority] = value;
    return this;
  }
}

extension SpecialConfigCompareE on SpecialConfig {
  Map<String, dynamic> compareToSpecialConfig(SpecialConfig other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (options != other.options) {
      diff['options'] = () => other.options;
    }
    if (priority != other.priority) {
      diff['priority'] = () => other.priority;
    }
    return diff;
  }
}
