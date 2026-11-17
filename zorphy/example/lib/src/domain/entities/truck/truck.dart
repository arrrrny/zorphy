import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../vehicle/vehicle.dart';

part 'truck.g.dart';
part '../../../../_br_/src/domain/entities/truck/truck.part.dart';

@Zorphy(generateJson: true)
abstract class $Truck implements $Vehicle {
  double get payload;
}
