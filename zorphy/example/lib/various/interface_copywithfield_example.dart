import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'interface_copywithfield_example.zorphy.dart';

/// Fixture for interface-scoped copyWithField: verifies that entities
/// implementing an interface get a `copyWith{InterfaceName}Field` method
/// that restricts field selectors to only the fields exposed by that
/// interface.
///
/// Pattern:
///   - `$Vehicle` is a base interface with `make`, `model`, `year`.
///   - `$InterfaceCar` implements `$Vehicle` and adds `doors`.
///   - The generated `InterfaceCar` should have:
///     * `copyWithField` (all fields: make, model, year, doors)
///     * `copyWithVehicleField` (only Vehicle fields: make, model, year)
@Zorphy(generateJson: true, nonSealed: true)
abstract class $Vehicle {
  String get make;
  String get model;
  int get year;
}

@Zorphy(generateJson: true)
abstract class $InterfaceCar implements $Vehicle {
  int get doors;
}
