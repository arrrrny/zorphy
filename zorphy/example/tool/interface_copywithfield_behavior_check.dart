// Behavioral checks for interface-scoped copyWithField. Executed by
// zorphy/test/generation/interface_copywithfield_test.dart via
// `dart run` (cwd: zorphy/example) because the zorphy test package
// cannot import the example package's generated code directly.
//
// Exit code 0 = all checks passed. Any failure prints FAIL and exits 1.
import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy_example/various/interface_copywithfield_example.dart';

final List<String> failures = <String>[];

void check(String name, bool condition) {
  if (condition) {
    print('PASS: $name');
  } else {
    failures.add(name);
    print('FAIL: $name');
  }
}

void main() {
  // ── Interface-scoped copyWithField for Car->Vehicle ────────────
  final car = InterfaceCar(
    make: 'Toyota',
    model: 'Camry',
    year: 2020,
    doors: 4,
  );

  // Test copyWithVehicleField with Vehicle interface fields
  final updatedMake = car.copyWithVehicleField(
    VehicleFields.make,
    'Honda',
  );
  check(
    'copyWithVehicleField updates make field',
    updatedMake.make == 'Honda' &&
        updatedMake.model == 'Camry' &&
        updatedMake.year == 2020 &&
        updatedMake.doors == 4,
  );

  final updatedModel = car.copyWithVehicleField(
    VehicleFields.model,
    'Accord',
  );
  check(
    'copyWithVehicleField updates model field',
    updatedModel.model == 'Accord' && updatedModel.make == 'Toyota',
  );

  final updatedYear = car.copyWithVehicleField(
    VehicleFields.year,
    2021,
  );
  check(
    'copyWithVehicleField updates year field',
    updatedYear.year == 2021 && updatedYear.make == 'Toyota',
  );

  // Verify interface restriction: copyWithVehicleField should accept
  // only Vehicle fields, not InterfaceCar-specific fields.
  // The doors field is InterfaceCar-specific, so passing it should throw.
  ArgumentError? interfaceRestrictionError;
  try {
    // Cast InterfaceCarFields.doors to Field<InterfaceCar, dynamic> to
    // bypass compile-time type checking and test runtime validation.
    final Field<InterfaceCar, dynamic> doorsField =
        const Field<InterfaceCar, int>('doors');
    car.copyWithVehicleField(doorsField, 2);
  } on ArgumentError catch (e) {
    interfaceRestrictionError = e;
  }
  check(
    'copyWithVehicleField rejects Car-specific fields',
    interfaceRestrictionError != null &&
        interfaceRestrictionError.toString().contains('Vehicle interface'),
  );

  // Verify standard copyWithField still works for all fields
  final updatedDoors = car.copyWithField(
    InterfaceCarFields.doors,
    2,
  );
  check(
    'copyWithField (standard) updates doors field',
    updatedDoors.doors == 2 && updatedDoors.make == 'Toyota',
  );

  // Verify immutability
  check(
    'original car is untouched',
    car.make == 'Toyota' &&
        car.model == 'Camry' &&
        car.year == 2020 &&
        car.doors == 4,
  );

  // ── Summary ─────────────────────────────────────────────────────
  if (failures.isEmpty) {
    print('ALL CHECKS PASSED');
    return;
  }
  print('${failures.length} CHECK(S) FAILED');
  throw StateError('${failures.length} interface copyWithField check(s) failed');
}
