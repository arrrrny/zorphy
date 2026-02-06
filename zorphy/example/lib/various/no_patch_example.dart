import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'no_patch_example.zorphy.dart';
part 'no_patch_example.g.dart';

@Zorphy(generatePatch: false, generateJson: true)
abstract class $NoPatchUser {
  String get name;
  int get age;
}
