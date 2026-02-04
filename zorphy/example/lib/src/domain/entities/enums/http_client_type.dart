import 'package:json_annotation/json_annotation.dart';

enum HttpClientType {
  @JsonValue('WEB_VIEW_CLIENT')
  webViewClient,

  @JsonValue('CURL_CLIENT')
  curlClient,

  @JsonValue('STANDARD')
  standard,

  @JsonValue('PUPPETEER_CLIENT')
  puppeteerClient,
}
