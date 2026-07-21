import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy_example/lib/src/domain/entities/enums/url_page_type.dart';

import 'url_endpoint.dart';

part 'url_template.zorphy.dart';
part 'url_template.g.dart';

@Zorphy(
  generateJson: true,
  explicitSubTypes: [
    $BarcodeUrlTemplate,
  ],
  nonSealed: true,
)
abstract class $$UrlTemplate {
  String get id;
  UrlPageType get type;
  List<$UrlEndpoint> get endpoints;
  Map<String, dynamic>? get metadata;
  DateTime? get createdAt;
  DateTime? get updatedAt;
}

@Zorphy(generateJson: true)
abstract class $BarcodeUrlTemplate implements $$UrlTemplate {
  @override
  UrlPageType get type => UrlPageType.barcode;
}
