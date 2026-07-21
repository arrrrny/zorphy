import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'url_template.dart';
import 'url_endpoint.dart';

part 'barcode_url_template.zorphy.dart';
part 'barcode_url_template.g.dart';

@Zorphy(generateJson: true)
abstract class $BarcodeUrlTemplate implements $$UrlTemplate {
  @override
  UrlPageType get type => UrlPageType.barcode;
}
