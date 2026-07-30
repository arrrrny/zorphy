import 'package:zorphy/zorphy.dart';

part 'params.zorphy.dart';
part 'params.g.dart';

@Zorphy(generateJson: true, generateFilter: true)
abstract class $Params {
  String get token;
}
