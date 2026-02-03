import 'package:zorphy_annotation/zorphy.dart';

import 'age_group.dart';
import 'generation.dart';
import 'income_level.dart';

part 'demographics.zorphy.dart';
part 'demographics.g.dart';

@Zorphy(generateJson: true)
abstract class $Demographics {
  AgeGroup? get ageGroup;
  Generation? get generation;
  List<String>? get locations;
  IncomeLevel? get incomeLevel;
  List<String>? get lifestyle;
}
