/// Runtime behavior check for interface-scoped copyWithField.
///
/// Verifies that:
/// 1. InterfaceCar.copyWithField handles ALL fields (Vehicle + own)
/// 2. Vehicle copyWithField handles Vehicle fields only
/// 3. Polymorphic path works: Vehicle variable = InterfaceCar instance
/// 4. Both work correctly at runtime

import 'package:zorphy_annotation/zorphy_annotation.dart';
import '../lib/various/interface_copywithfield_example.dart';

void main() {
  var allPassed = true;

  final car = InterfaceCar(
    make: 'Toyota',
    model: 'Camry',
    year: 2024,
    doors: 4,
  );

  // 1. InterfaceCar.copyWithField handles ALL fields (Vehicle + own)
  final car1 = car.copyWithField(InterfaceCarFields.make, 'Honda');
  if (car1.make != 'Honda') {
    print('FAIL: copyWithField(make) did not update value');
    allPassed = false;
  }

  final car2 = car.copyWithField(InterfaceCarFields.model, 'Civic');
  if (car2.model != 'Civic') {
    print('FAIL: copyWithField(model) did not update value');
    allPassed = false;
  }

  final car3 = car.copyWithField(InterfaceCarFields.year, 2025);
  if (car3.year != 2025) {
    print('FAIL: copyWithField(year) did not update value');
    allPassed = false;
  }

  final car4 = car.copyWithField(InterfaceCarFields.doors, 2);
  if (car4.doors != 2) {
    print('FAIL: copyWithField(doors) did not update value');
    allPassed = false;
  }

  // 2. Vehicle copyWithField handles Vehicle fields only
  final vehicle = Vehicle(make: 'Ford', model: 'Focus', year: 2023);
  final v1 = vehicle.copyWithField(VehicleFields.make, 'Chevy');
  if (v1.make != 'Chevy') {
    print('FAIL: Vehicle.copyWithField(make) did not update value');
    allPassed = false;
  }

  // 3. Polymorphic path: Vehicle variable = InterfaceCar instance
  Vehicle v = car;
  final v2 = v.copyWithField(VehicleFields.make, 'Honda');
  if (v2.make != 'Honda') {
    print('FAIL: polymorphic copyWithField(make) did not update value');
    allPassed = false;
  }

  // 4. Vehicle copyWithField throws for non-Vehicle fields
  try {
    vehicle.copyWithField(InterfaceCarFields.doors, 6);
    print('FAIL: Vehicle.copyWithField(doors) should have thrown');
    allPassed = false;
  } catch (e) {
    if (e is! ArgumentError) {
      print('FAIL: Vehicle.copyWithField(doors) threw wrong type: ${e.runtimeType}');
      allPassed = false;
    }
  }

  if (allPassed) {
    print('ALL CHECKS PASSED');
  }
}
