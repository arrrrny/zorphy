// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'car.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Car extends Vehicle {
  final int doors;

  Car({
    required String make,
    required String model,
    required int year,
    required this.doors,
  }) : super(make: make, model: model, year: year);

  Car copyWith({String? make, String? model, int? year, int? doors}) {
    return Car(
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      doors: doors ?? this.doors,
    );
  }

  Car copyWithCar({String? make, String? model, int? year, int? doors}) {
    return copyWith(make: make, model: model, year: year, doors: doors);
  }

  Car copyWithVehicle({String? make, String? model, int? year}) {
    return copyWith(make: make, model: model, year: year);
  }

  Car patchWithCar({CarPatch? patchInput}) {
    final _patcher = patchInput ?? CarPatch();
    final _patchMap = _patcher.patchMap;
    return Car(
      make: _patchMap.containsKey(Car$.make)
          ? (_patchMap[Car$.make] is Function)
                ? _patchMap[Car$.make](this.make)
                : (_patchMap[Car$.make] is Patch)
                ? _patchMap[Car$.make].applyTo(this.make)
                : _patchMap[Car$.make]
          : this.make,
      model: _patchMap.containsKey(Car$.model)
          ? (_patchMap[Car$.model] is Function)
                ? _patchMap[Car$.model](this.model)
                : (_patchMap[Car$.model] is Patch)
                ? _patchMap[Car$.model].applyTo(this.model)
                : _patchMap[Car$.model]
          : this.model,
      year: _patchMap.containsKey(Car$.year)
          ? (_patchMap[Car$.year] is Function)
                ? _patchMap[Car$.year](this.year)
                : (_patchMap[Car$.year] is Patch)
                ? _patchMap[Car$.year].applyTo(this.year)
                : _patchMap[Car$.year]
          : this.year,
      doors: _patchMap.containsKey(Car$.doors)
          ? (_patchMap[Car$.doors] is Function)
                ? _patchMap[Car$.doors](this.doors)
                : (_patchMap[Car$.doors] is Patch)
                ? _patchMap[Car$.doors].applyTo(this.doors)
                : _patchMap[Car$.doors]
          : this.doors,
    );
  }

  Car patchWithVehicle({VehiclePatch? patchInput}) {
    final _patcher = patchInput ?? VehiclePatch();
    final _patchMap = _patcher.patchMap;
    return Car(
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
      doors: this.doors,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Car &&
        make == other.make &&
        model == other.model &&
        year == other.year &&
        doors == other.doors;
  }

  @override
  int get hashCode {
    return Object.hash(this.make, this.model, this.year, this.doors);
  }

  @override
  String toString() {
    return 'Car(' +
        'make: ${make}' +
        ', ' +
        'model: ${model}' +
        ', ' +
        'year: ${year}' +
        ', ' +
        'doors: ${doors})';
  }

  /// Creates a [Car] instance from JSON
  factory Car.fromJson(Map<String, dynamic> json) => _$CarFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CarToJson(this);
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

extension CarPropertyHelpers on Car {}

extension CarSerialization on Car {
  Map<String, dynamic> toJson() => _$CarToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CarToJson(this);
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

enum Car$ { make, model, year, doors }

class CarPatch extends PatchBase<Car, Car$> {
  Car applyTo(Car entity) {
    return entity.patchWithCar(patchInput: this);
  }

  CarPatch withMake(String? value) {
    patchMap[Car$.make] = value;
    return this;
  }

  CarPatch withModel(String? value) {
    patchMap[Car$.model] = value;
    return this;
  }

  CarPatch withYear(int? value) {
    patchMap[Car$.year] = value;
    return this;
  }

  CarPatch withDoors(int? value) {
    patchMap[Car$.doors] = value;
    return this;
  }
}

/// Field descriptors for [Car] query construction
abstract final class CarFields {
  static String _$getmake(Car e) => e.make;
  static const make = Field<Car, String>('make', _$getmake);
  static String _$getmodel(Car e) => e.model;
  static const model = Field<Car, String>('model', _$getmodel);
  static int _$getyear(Car e) => e.year;
  static const year = Field<Car, int>('year', _$getyear);
  static int _$getdoors(Car e) => e.doors;
  static const doors = Field<Car, int>('doors', _$getdoors);
}

extension CarCompareE on Car {
  Map<String, dynamic> compareToCar(Car other) {
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
    if (doors != other.doors) {
      diff['doors'] = () => other.doors;
    }
    return diff;
  }
}
