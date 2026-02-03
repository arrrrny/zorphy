// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex40_bug_fixed_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

sealed class $MonitorI {
  String get monitorId;
  int get locationId;
  String get monitorName;
  String get monitorPostcode;
  bool get isExcluded;

  const $MonitorI._internal();
}

class Monitor_PurpleAir implements $$MonitorI {
  final String monitorId;
  final int locationId;
  final String monitorName;
  final String monitorPostcode;
  final bool isExcluded;
  final String purpleAirSensorApiId;

  Monitor_PurpleAir({
    required this.monitorId,
    required this.locationId,
    required this.monitorName,
    required this.monitorPostcode,
    required this.isExcluded,
    required this.purpleAirSensorApiId,
  });

  Monitor_PurpleAir copyWith({
    String? monitorId,
    int? locationId,
    String? monitorName,
    String? monitorPostcode,
    bool? isExcluded,
    String? purpleAirSensorApiId,
  }) {
    return Monitor_PurpleAir(
      monitorId: monitorId ?? this.monitorId,
      locationId: locationId ?? this.locationId,
      monitorName: monitorName ?? this.monitorName,
      monitorPostcode: monitorPostcode ?? this.monitorPostcode,
      isExcluded: isExcluded ?? this.isExcluded,
      purpleAirSensorApiId: purpleAirSensorApiId ?? this.purpleAirSensorApiId,
    );
  }

  Monitor_PurpleAir copyWithMonitor_PurpleAir({
    String? monitorId,
    int? locationId,
    String? monitorName,
    String? monitorPostcode,
    bool? isExcluded,
    String? purpleAirSensorApiId,
  }) {
    return copyWith(
      monitorId: monitorId,
      locationId: locationId,
      monitorName: monitorName,
      monitorPostcode: monitorPostcode,
      isExcluded: isExcluded,
      purpleAirSensorApiId: purpleAirSensorApiId,
    );
  }

  Monitor_PurpleAir patchWithMonitor_PurpleAir({
    Monitor_PurpleAirPatch? patchInput,
  }) {
    final _patcher = patchInput ?? Monitor_PurpleAirPatch();
    final _patchMap = _patcher.toPatch();
    return Monitor_PurpleAir(
      monitorId: _patchMap.containsKey(Monitor_PurpleAir$.monitorId)
          ? (_patchMap[Monitor_PurpleAir$.monitorId] is Function)
                ? _patchMap[Monitor_PurpleAir$.monitorId](this.monitorId)
                : _patchMap[Monitor_PurpleAir$.monitorId]
          : this.monitorId,
      locationId: _patchMap.containsKey(Monitor_PurpleAir$.locationId)
          ? (_patchMap[Monitor_PurpleAir$.locationId] is Function)
                ? _patchMap[Monitor_PurpleAir$.locationId](this.locationId)
                : _patchMap[Monitor_PurpleAir$.locationId]
          : this.locationId,
      monitorName: _patchMap.containsKey(Monitor_PurpleAir$.monitorName)
          ? (_patchMap[Monitor_PurpleAir$.monitorName] is Function)
                ? _patchMap[Monitor_PurpleAir$.monitorName](this.monitorName)
                : _patchMap[Monitor_PurpleAir$.monitorName]
          : this.monitorName,
      monitorPostcode: _patchMap.containsKey(Monitor_PurpleAir$.monitorPostcode)
          ? (_patchMap[Monitor_PurpleAir$.monitorPostcode] is Function)
                ? _patchMap[Monitor_PurpleAir$.monitorPostcode](
                    this.monitorPostcode,
                  )
                : _patchMap[Monitor_PurpleAir$.monitorPostcode]
          : this.monitorPostcode,
      isExcluded: _patchMap.containsKey(Monitor_PurpleAir$.isExcluded)
          ? (_patchMap[Monitor_PurpleAir$.isExcluded] is Function)
                ? _patchMap[Monitor_PurpleAir$.isExcluded](this.isExcluded)
                : _patchMap[Monitor_PurpleAir$.isExcluded]
          : this.isExcluded,
      purpleAirSensorApiId:
          _patchMap.containsKey(Monitor_PurpleAir$.purpleAirSensorApiId)
          ? (_patchMap[Monitor_PurpleAir$.purpleAirSensorApiId] is Function)
                ? _patchMap[Monitor_PurpleAir$.purpleAirSensorApiId](
                    this.purpleAirSensorApiId,
                  )
                : _patchMap[Monitor_PurpleAir$.purpleAirSensorApiId]
          : this.purpleAirSensorApiId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Monitor_PurpleAir &&
        monitorId == other.monitorId &&
        locationId == other.locationId &&
        monitorName == other.monitorName &&
        monitorPostcode == other.monitorPostcode &&
        isExcluded == other.isExcluded &&
        purpleAirSensorApiId == other.purpleAirSensorApiId;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.monitorId,
      this.locationId,
      this.monitorName,
      this.monitorPostcode,
      this.isExcluded,
      this.purpleAirSensorApiId,
    );
  }

  @override
  String toString() {
    return 'Monitor_PurpleAir(' +
        'monitorId: ${monitorId}' +
        ', ' +
        'locationId: ${locationId}' +
        ', ' +
        'monitorName: ${monitorName}' +
        ', ' +
        'monitorPostcode: ${monitorPostcode}' +
        ', ' +
        'isExcluded: ${isExcluded}' +
        ', ' +
        'purpleAirSensorApiId: ${purpleAirSensorApiId})';
  }
}

enum Monitor_PurpleAir$ {
  monitorId,
  locationId,
  monitorName,
  monitorPostcode,
  isExcluded,
  purpleAirSensorApiId,
}

class Monitor_PurpleAirPatch implements Patch<Monitor_PurpleAir> {
  final Map<Monitor_PurpleAir$, dynamic> _patch = {};

  static Monitor_PurpleAirPatch create([Map<String, dynamic>? diff]) {
    final patch = Monitor_PurpleAirPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Monitor_PurpleAir$.values.firstWhere(
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

  static Monitor_PurpleAirPatch fromPatch(
    Map<Monitor_PurpleAir$, dynamic> patch,
  ) {
    final _patch = Monitor_PurpleAirPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Monitor_PurpleAir$, dynamic> toPatch() => Map.from(_patch);

  Monitor_PurpleAir applyTo(Monitor_PurpleAir entity) {
    return entity.patchWithMonitor_PurpleAir(patchInput: this);
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

  static Monitor_PurpleAirPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  Monitor_PurpleAirPatch withMonitorId(String? value) {
    _patch[Monitor_PurpleAir$.monitorId] = value;
    return this;
  }

  Monitor_PurpleAirPatch withLocationId(int? value) {
    _patch[Monitor_PurpleAir$.locationId] = value;
    return this;
  }

  Monitor_PurpleAirPatch withMonitorName(String? value) {
    _patch[Monitor_PurpleAir$.monitorName] = value;
    return this;
  }

  Monitor_PurpleAirPatch withMonitorPostcode(String? value) {
    _patch[Monitor_PurpleAir$.monitorPostcode] = value;
    return this;
  }

  Monitor_PurpleAirPatch withIsExcluded(bool? value) {
    _patch[Monitor_PurpleAir$.isExcluded] = value;
    return this;
  }

  Monitor_PurpleAirPatch withPurpleAirSensorApiId(String? value) {
    _patch[Monitor_PurpleAir$.purpleAirSensorApiId] = value;
    return this;
  }
}

extension Monitor_PurpleAirCompareE on Monitor_PurpleAir {
  Map<String, dynamic> compareToMonitor_PurpleAir(Monitor_PurpleAir other) {
    final Map<String, dynamic> diff = {};

    if (monitorId != other.monitorId) {
      diff['monitorId'] = () => other.monitorId;
    }
    if (locationId != other.locationId) {
      diff['locationId'] = () => other.locationId;
    }
    if (monitorName != other.monitorName) {
      diff['monitorName'] = () => other.monitorName;
    }
    if (monitorPostcode != other.monitorPostcode) {
      diff['monitorPostcode'] = () => other.monitorPostcode;
    }
    if (isExcluded != other.isExcluded) {
      diff['isExcluded'] = () => other.isExcluded;
    }
    if (purpleAirSensorApiId != other.purpleAirSensorApiId) {
      diff['purpleAirSensorApiId'] = () => other.purpleAirSensorApiId;
    }
    return diff;
  }
}
