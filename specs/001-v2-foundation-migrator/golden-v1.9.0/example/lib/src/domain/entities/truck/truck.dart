import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../vehicle/vehicle.dart';

part 'truck.zorphy.dart';
part 'truck.g.dart';

@Zorphy(generateJson: true)
abstract class $Truck implements $Vehicle {
  double get payload;
}
