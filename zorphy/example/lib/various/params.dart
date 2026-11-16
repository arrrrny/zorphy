import 'package:zorphy/zorphy.dart';

part 'params.g.dart';
part '../_br_/various/params.part.dart';

@Zorphy(generateJson: true, generateFilter: true)
abstract class $Params {
  String get token;
}
