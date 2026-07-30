// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'truck.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Truck extends Vehicle {
  final double payload;

  Truck({
    required String make,
    required String model,
    required int year,
    required this.payload,
  }) : super(make: make, model: model, year: year);

  Truck copyWith({String? make, String? model, int? year, double? payload}) {
    return Truck(
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      payload: payload ?? this.payload,
    );
  }

  Truck copyWithTruck({
    String? make,
    String? model,
    int? year,
    double? payload,
  }) {
    return copyWith(make: make, model: model, year: year, payload: payload);
  }

  Truck copyWithVehicle({String? make, String? model, int? year}) {
    return copyWith(make: make, model: model, year: year);
  }

  Truck patchWithTruck({TruckPatch? patchInput}) {
    final _patcher = patchInput ?? TruckPatch();
    final _patchMap = _patcher.patchMap;
    return Truck(
      make: _patchMap.containsKey(Truck$.make)
          ? (_patchMap[Truck$.make] is Function)
                ? _patchMap[Truck$.make](this.make)
                : (_patchMap[Truck$.make] is Patch)
                ? _patchMap[Truck$.make].applyTo(this.make)
                : _patchMap[Truck$.make]
          : this.make,
      model: _patchMap.containsKey(Truck$.model)
          ? (_patchMap[Truck$.model] is Function)
                ? _patchMap[Truck$.model](this.model)
                : (_patchMap[Truck$.model] is Patch)
                ? _patchMap[Truck$.model].applyTo(this.model)
                : _patchMap[Truck$.model]
          : this.model,
      year: _patchMap.containsKey(Truck$.year)
          ? (_patchMap[Truck$.year] is Function)
                ? _patchMap[Truck$.year](this.year)
                : (_patchMap[Truck$.year] is Patch)
                ? _patchMap[Truck$.year].applyTo(this.year)
                : _patchMap[Truck$.year]
          : this.year,
      payload: _patchMap.containsKey(Truck$.payload)
          ? (_patchMap[Truck$.payload] is Function)
                ? _patchMap[Truck$.payload](this.payload)
                : (_patchMap[Truck$.payload] is Patch)
                ? _patchMap[Truck$.payload].applyTo(this.payload)
                : _patchMap[Truck$.payload]
          : this.payload,
    );
  }

  Truck patchWithVehicle({VehiclePatch? patchInput}) {
    final _patcher = patchInput ?? VehiclePatch();
    final _patchMap = _patcher.patchMap;
    return Truck(
      make: _patchMap.containsKey(Vehicle$.make)
          ? (_patchMap[Vehicle$.make] is Function)
                ? _patchMap[Vehicle$.make](this.make)
                : (_patchMap[Vehicle$.make] is Patch)
                ? _patchMap[Vehicle$.make].applyTo(this.make)
                : _patchMap[Vehicle$.make]
          : this.make,
      model: _patchMap.containsKey(Vehicle$.model)
          ? (_patchMap[Vehicle$.model] is Function)
                ? _patchMap[Vehicle$.model](this.model)
                : (_patchMap[Vehicle$.model] is Patch)
                ? _patchMap[Vehicle$.model].applyTo(this.model)
                : _patchMap[Vehicle$.model]
          : this.model,
      year: _patchMap.containsKey(Vehicle$.year)
          ? (_patchMap[Vehicle$.year] is Function)
                ? _patchMap[Vehicle$.year](this.year)
                : (_patchMap[Vehicle$.year] is Patch)
                ? _patchMap[Vehicle$.year].applyTo(this.year)
                : _patchMap[Vehicle$.year]
          : this.year,
      payload: this.payload,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Truck &&
        make == other.make &&
        model == other.model &&
        year == other.year &&
        payload == other.payload;
  }

  @override
  int get hashCode {
    return Object.hash(this.make, this.model, this.year, this.payload);
  }

  @override
  String toString() {
    return 'Truck(' +
        'make: ${make}' +
        ', ' +
        'model: ${model}' +
        ', ' +
        'year: ${year}' +
        ', ' +
        'payload: ${payload})';
  }

  /// Creates a [Truck] instance from JSON
  factory Truck.fromJson(Map<String, dynamic> json) => _$TruckFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TruckToJson(this);
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

extension TruckPropertyHelpers on Truck {}

extension TruckSerialization on Truck {
  Map<String, dynamic> toJson() => _$TruckToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TruckToJson(this);
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

enum Truck$ { make, model, year, payload }

class TruckPatch extends PatchBase<Truck, Truck$> {
  Truck applyTo(Truck entity) {
    return entity.patchWithTruck(patchInput: this);
  }

  TruckPatch withMake(String? value) {
    patchMap[Truck$.make] = value;
    return this;
  }

  TruckPatch withModel(String? value) {
    patchMap[Truck$.model] = value;
    return this;
  }

  TruckPatch withYear(int? value) {
    patchMap[Truck$.year] = value;
    return this;
  }

  TruckPatch withPayload(double? value) {
    patchMap[Truck$.payload] = value;
    return this;
  }
}

/// Field descriptors for [Truck] query construction
abstract final class TruckFields {
  static String _$getmake(Truck e) => e.make;
  static const make = Field<Truck, String>('make', _$getmake);
  static String _$getmodel(Truck e) => e.model;
  static const model = Field<Truck, String>('model', _$getmodel);
  static int _$getyear(Truck e) => e.year;
  static const year = Field<Truck, int>('year', _$getyear);
  static double _$getpayload(Truck e) => e.payload;
  static const payload = Field<Truck, double>('payload', _$getpayload);
}

extension TruckCompareE on Truck {
  Map<String, dynamic> compareToTruck(Truck other) {
    final Map<String, dynamic> diff = {};

    if (make != other.make) {
      diff['make'] = () => other.make;
    }
    if (model != other.model) {
      diff['model'] = () => other.model;
    }
    if (year != other.year) {
      diff['year'] = () => other.year;
    }
    if (payload != other.payload) {
      diff['payload'] = () => other.payload;
    }
    return diff;
  }
}
