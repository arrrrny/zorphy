import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'url_endpoint.zorphy.dart';
part 'url_endpoint.g.dart';

@Zorphy(generateJson: true)
abstract class $UrlEndpoint {
  String get url;
}
