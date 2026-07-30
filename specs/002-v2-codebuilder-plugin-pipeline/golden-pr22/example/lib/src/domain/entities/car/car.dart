import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../vehicle/vehicle.dart';

part 'car.zorphy.dart';
part 'car.g.dart';

@Zorphy(generateJson: true)
abstract class $Car implements $Vehicle {
  int get doors;
}
