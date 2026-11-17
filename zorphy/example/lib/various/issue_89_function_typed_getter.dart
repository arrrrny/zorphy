// Repro fixture for issue #89 — function-typed getter (callback field)
// on a value-object entity breaks the generated `.zorphy.dart`.
//
// Mirrors the exact annotation shape from the issue:
//   @Zorphy(kind: ZorphyKind.valueObject, generateJson: true,
//           generateCompareTo: true)
//   abstract class $Foo {
//     String get id;
//     void Function(WebUri? url)? get onClick;
//   }

import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue_89_function_typed_getter.g.dart';
part '../_br_/various/issue_89_function_typed_getter.part.dart';

class WebUri {
  const WebUri(this.url);
  final String url;
}

@Zorphy(
  kind: ZorphyKind.valueObject,
  generateJson: true,
  generateCompareTo: true,
)
abstract class $Foo {
  String get id;
  void Function(WebUri? url)? get onClick;
}
