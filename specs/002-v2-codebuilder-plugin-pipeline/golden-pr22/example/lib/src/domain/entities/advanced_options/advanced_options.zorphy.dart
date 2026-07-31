// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'advanced_options.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class AdvancedOptions extends Options {
  final int level;

  AdvancedOptions({
    required String label,
    required bool enabled,
    required this.level,
  }) : super(label: label, enabled: enabled);

  AdvancedOptions copyWith({String? label, bool? enabled, int? level}) {
    return AdvancedOptions(
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      level: level ?? this.level,
    );
  }

  AdvancedOptions copyWithAdvancedOptions({
    String? label,
    bool? enabled,
    int? level,
  }) {
    return copyWith(label: label, enabled: enabled, level: level);
  }

  AdvancedOptions copyWithOptions({String? label, bool? enabled}) {
    return copyWith(label: label, enabled: enabled);
  }

  AdvancedOptions patchWithAdvancedOptions({AdvancedOptionsPatch? patchInput}) {
    final _patcher = patchInput ?? AdvancedOptionsPatch();
    final _patchMap = _patcher.patchMap;
    return AdvancedOptions(
      label: _patchMap.containsKey(AdvancedOptions$.label)
          ? (_patchMap[AdvancedOptions$.label] is Function)
                ? _patchMap[AdvancedOptions$.label](this.label)
                : (_patchMap[AdvancedOptions$.label] is Patch)
                ? _patchMap[AdvancedOptions$.label].applyTo(this.label)
                : _patchMap[AdvancedOptions$.label]
          : this.label,
      enabled: _patchMap.containsKey(AdvancedOptions$.enabled)
          ? (_patchMap[AdvancedOptions$.enabled] is Function)
                ? _patchMap[AdvancedOptions$.enabled](this.enabled)
                : (_patchMap[AdvancedOptions$.enabled] is Patch)
                ? _patchMap[AdvancedOptions$.enabled].applyTo(this.enabled)
                : _patchMap[AdvancedOptions$.enabled]
          : this.enabled,
      level: _patchMap.containsKey(AdvancedOptions$.level)
          ? (_patchMap[AdvancedOptions$.level] is Function)
                ? _patchMap[AdvancedOptions$.level](this.level)
                : (_patchMap[AdvancedOptions$.level] is Patch)
                ? _patchMap[AdvancedOptions$.level].applyTo(this.level)
                : _patchMap[AdvancedOptions$.level]
          : this.level,
    );
  }

  AdvancedOptions patchWithOptions({OptionsPatch? patchInput}) {
    final _patcher = patchInput ?? OptionsPatch();
    final _patchMap = _patcher.patchMap;
    return AdvancedOptions(
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
      level: this.level,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvancedOptions &&
        label == other.label &&
        enabled == other.enabled &&
        level == other.level;
  }

  @override
  int get hashCode {
    return Object.hash(this.label, this.enabled, this.level);
  }

  @override
  String toString() {
    return 'AdvancedOptions(' +
        'label: ${label}' +
        ', ' +
        'enabled: ${enabled}' +
        ', ' +
        'level: ${level})';
  }
}

extension AdvancedOptionsPropertyHelpers on AdvancedOptions {}

enum AdvancedOptions$ { label, enabled, level }

class AdvancedOptionsPatch
    extends PatchBase<AdvancedOptions, AdvancedOptions$> {
  AdvancedOptions applyTo(AdvancedOptions entity) {
    return entity.patchWithAdvancedOptions(patchInput: this);
  }

  AdvancedOptionsPatch withLabel(String? value) {
    patchMap[AdvancedOptions$.label] = value;
    return this;
  }

  AdvancedOptionsPatch withEnabled(bool? value) {
    patchMap[AdvancedOptions$.enabled] = value;
    return this;
  }

  AdvancedOptionsPatch withLevel(int? value) {
    patchMap[AdvancedOptions$.level] = value;
    return this;
  }
}

extension AdvancedOptionsCompareE on AdvancedOptions {
  Map<String, dynamic> compareToAdvancedOptions(AdvancedOptions other) {
    final Map<String, dynamic> diff = {};

    if (label != other.label) {
      diff['label'] = () => other.label;
    }
    if (enabled != other.enabled) {
      diff['enabled'] = () => other.enabled;
    }
    if (level != other.level) {
      diff['level'] = () => other.level;
    }
    return diff;
  }
}
