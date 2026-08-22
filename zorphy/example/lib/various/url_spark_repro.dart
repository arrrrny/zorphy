import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'spark_repro.dart';

part 'url_spark_repro.zorphy.dart';
part 'url_spark_repro.g.dart';

@Zorphy(generateJson: true)
abstract class $UrlSpark implements $Spark {
  @override
  String get id;
  String get url;
}
