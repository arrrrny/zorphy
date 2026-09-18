import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue138_endpoint.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $Issue138UrlEndpoint {
  String get id;
  String get path;
}
