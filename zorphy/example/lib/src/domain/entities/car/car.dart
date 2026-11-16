import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../vehicle/vehicle.dart';

part 'car.g.dart';
part '../../../../_br_/src/domain/entities/car/car.part.dart';

@Zorphy(generateJson: true)
abstract class $Car implements $Vehicle {
  int get doors;
}
