// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'options.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class Options {
  final String label;
  final bool enabled;

  Options({required this.label, required this.enabled});

  Options copyWith({String? label, bool? enabled}) {
    return Options(
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
    );
  }

  Options copyWithOptions({String? label, bool? enabled}) {
    return copyWith(label: label, enabled: enabled);
  }

  Options patchWithOptions({OptionsPatch? patchInput}) {
    final _patcher = patchInput ?? OptionsPatch();
    final _patchMap = _patcher.patchMap;
    return Options(
      label: _patchMap.containsKey(Options$.label)
          ? (_patchMap[Options$.label] is Function)
                ? _patchMap[Options$.label](this.label)
                : (_patchMap[Options$.label] is Patch)
                ? _patchMap[Options$.label].applyTo(this.label)
                : _patchMap[Options$.label]
          : this.label,
      enabled: _patchMap.containsKey(Options$.enabled)
          ? (_patchMap[Options$.enabled] is Function)
                ? _patchMap[Options$.enabled](this.enabled)
                : (_patchMap[Options$.enabled] is Patch)
                ? _patchMap[Options$.enabled].applyTo(this.enabled)
                : _patchMap[Options$.enabled]
          : this.enabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Options && label == other.label && enabled == other.enabled;
  }

  @override
  int get hashCode {
    return Object.hash(this.label, this.enabled);
  }

  @override
  String toString() {
    return 'Options(' + 'label: ${label}' + ', ' + 'enabled: ${enabled})';
  }
}

extension OptionsPropertyHelpers on Options {
  bool get hasLabel => label.isNotEmpty;
  bool get noLabel => label.isEmpty;
}

enum Options$ { label, enabled }

class OptionsPatch extends PatchBase<Options, Options$> {
  Options applyTo(Options entity) {
    return entity.patchWithOptions(patchInput: this);
  }

  OptionsPatch withLabel(String? value) {
    patchMap[Options$.label] = value;
    return this;
  }

  OptionsPatch withEnabled(bool? value) {
    patchMap[Options$.enabled] = value;
    return this;
  }
}

extension OptionsCompareE on Options {
  Map<String, dynamic> compareToOptions(Options other) {
    final Map<String, dynamic> diff = {};

    if (label != other.label) {
      diff['label'] = () => other.label;
    }
    if (enabled != other.enabled) {
      diff['enabled'] = () => other.enabled;
    }
    return diff;
  }
}
