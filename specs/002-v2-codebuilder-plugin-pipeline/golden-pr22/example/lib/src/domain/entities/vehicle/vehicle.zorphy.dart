// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'vehicle.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Vehicle {
  final String make;
  final String model;
  final int year;

  Vehicle({required this.make, required this.model, required this.year});

  Vehicle copyWith({String? make, String? model, int? year}) {
    return Vehicle(
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
    );
  }

  Vehicle copyWithVehicle({String? make, String? model, int? year}) {
    return copyWith(make: make, model: model, year: year);
  }

  Vehicle patchWithVehicle({VehiclePatch? patchInput}) {
    final _patcher = patchInput ?? VehiclePatch();
    final _patchMap = _patcher.patchMap;
    return Vehicle(
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
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle &&
        make == other.make &&
        model == other.model &&
        year == other.year;
  }

  @override
  int get hashCode {
    return Object.hash(this.make, this.model, this.year);
  }

  @override
  String toString() {
    return 'Vehicle(' +
        'make: ${make}' +
        ', ' +
        'model: ${model}' +
        ', ' +
        'year: ${year})';
  }

  /// Creates a [Vehicle] instance from JSON
  factory Vehicle.fromJson(Map<String, dynamic> json) {
    if (json['__typename'] == null || json['__typename'] == "Vehicle") {
      return _$VehicleFromJson(json);
    } else if (json['__typename'] == "Car") {
      return Car.fromJson(json);
    } else if (json['__typename'] == "Truck") {
      return Truck.fromJson(json);
    }
    throw UnsupportedError(
      "The __typename '${json['__typename']}' is not supported by the $className.fromJson constructor.",
    );
  }

  Map<String, dynamic> toJson() {
    if (this is Car) {
      final json = (this as Car).toJsonLean();
      json['__typename'] = "Car";
      return json;
    } else if (this is Truck) {
      final json = (this as Truck).toJsonLean();
      json['__typename'] = "Truck";
      return json;
    }
    final json = toJsonLean();
    json['__typename'] = 'Vehicle';
    return json;
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$VehicleToJson(this);
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

extension VehiclePolymorphicE on Vehicle {
  bool get isCar => this is Car;
  Car? get asCar => this is Car ? this as Car : null;
  bool get isTruck => this is Truck;
  Truck? get asTruck => this is Truck ? this as Truck : null;
}

extension VehiclePropertyHelpers on Vehicle {
  bool get hasMake => make.isNotEmpty;
  bool get noMake => make.isEmpty;
  bool get hasModel => model.isNotEmpty;
  bool get noModel => model.isEmpty;
}

enum Vehicle$ { make, model, year }

class VehiclePatch extends PatchBase<Vehicle, Vehicle$> {
  Vehicle applyTo(Vehicle entity) {
    return entity.patchWithVehicle(patchInput: this);
  }

  VehiclePatch withMake(String? value) {
    patchMap[Vehicle$.make] = value;
    return this;
  }

  VehiclePatch withModel(String? value) {
    patchMap[Vehicle$.model] = value;
    return this;
  }

  VehiclePatch withYear(int? value) {
    patchMap[Vehicle$.year] = value;
    return this;
  }
}

/// Field descriptors for [Vehicle] query construction
abstract final class VehicleFields {
  static String _$getmake(Vehicle e) => e.make;
  static const make = Field<Vehicle, String>('make', _$getmake);
  static String _$getmodel(Vehicle e) => e.model;
  static const model = Field<Vehicle, String>('model', _$getmodel);
  static int _$getyear(Vehicle e) => e.year;
  static const year = Field<Vehicle, int>('year', _$getyear);
}

extension VehicleCompareE on Vehicle {
  Map<String, dynamic> compareToVehicle(Vehicle other) {
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
    return diff;
  }
}

extension VehicleChangeToE on Vehicle {
  Car changeToCar({
    required int doors,
    String? make,
    String? model,
    int? year,
  }) {
    final _patcher = CarPatch();
    _patcher.withDoors(doors);
    if (make != null) {
      _patcher.withMake(make);
    }
    if (model != null) {
      _patcher.withModel(model);
    }
    if (year != null) {
      _patcher.withYear(year);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return Car.fromJson(_json);
  }

  Truck changeToTruck({
    required double payload,
    String? make,
    String? model,
    int? year,
  }) {
    final _patcher = TruckPatch();
    _patcher.withPayload(payload);
    if (make != null) {
      _patcher.withMake(make);
    }
    if (model != null) {
      _patcher.withModel(model);
    }
    if (year != null) {
      _patcher.withYear(year);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return Truck.fromJson(_json);
  }
}
