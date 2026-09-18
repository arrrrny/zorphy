import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'issue138_endpoint.dart';
import 'issue138_spark.dart';

part 'issue138_zik.zorphy.dart';
part 'issue138_zik.g.dart';

@Zorphy(generateJson: true)
abstract class $Issue138Zik {
  String get id;
  $Issue138Spark? get spark;
  String get url;
  $Issue138UrlEndpoint get urlEndpoint;

  // Bodies span multiple lines with trailing commas — exactly the shape the
  // issue reported, where the analyzer cannot recover the body and the
  // generator synthesizes the abstract-factory delegation instead.
  static Issue138Zik create({
    required String url,
    required Issue138UrlEndpoint urlEndpoint,
    Issue138Spark? spark,
  }) => Issue138Zik(id: 'id', url: url, spark: spark, urlEndpoint: urlEndpoint);

  static Issue138Zik fromUrlSpark({
    required Issue138UrlSpark spark,
    required Issue138UrlEndpoint urlEndpoint,
  }) => Issue138Zik(id: 'id', url: spark.url, urlEndpoint: urlEndpoint);
}
