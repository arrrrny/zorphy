import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../car/car.dart';
import '../truck/truck.dart';

part 'vehicle.g.dart';
part '../../../../_br_/src/domain/entities/vehicle/vehicle.part.dart';

/// A concrete base class with explicitSubTypes.
/// Can be instantiated directly AND has polymorphic subtypes.
@Zorphy(generateJson: true, explicitSubTypes: [$Car, $Truck], nonSealed: true)
abstract class $Vehicle {
  String get make;
  String get model;
  int get year;
}
