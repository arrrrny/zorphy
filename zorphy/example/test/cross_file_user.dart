import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'cross_file_user.g.dart';
part 'cross_file_user.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $User {
  String get name;
  String get email;
}
