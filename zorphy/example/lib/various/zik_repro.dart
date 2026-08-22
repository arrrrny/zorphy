import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'spark_repro.dart';
import 'url_spark_repro.dart';

part 'zik_repro.zorphy.dart';
part 'zik_repro.g.dart';

@Zorphy(generateJson: true)
abstract class $Zik {
  $$Spark? get spark;
  String get url;

  static Zik create({required String url, Spark? spark}) =>
      Zik(url: url, spark: spark);

  static Zik fromUrlSpark({required UrlSpark spark}) =>
      Zik.create(url: spark.url, spark: spark);
}
