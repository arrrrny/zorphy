import 'package:json_annotation/json_annotation.dart';

enum UrlPageType {
  @JsonValue('BARCODE')
  barcode,

  @JsonValue('SEARCH')
  search,

  @JsonValue('PRODUCT')
  product,

  @JsonValue('BARCODE_WEB')
  barcodeWeb,

  @JsonValue('SEARCH_WEB')
  searchWeb,

  @JsonValue('PRODUCT_WEB')
  productWeb,
}
