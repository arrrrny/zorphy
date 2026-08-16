// Regression fixture for issue #88:
// generator: doc-comment '///- ' list-marker lines leak into generated
// constructor — build fails to parse.
//
// The previous field's doc-comment block uses  bullet-list lines
// (common in the zikzak_inappwebview fork's settings docs, e.g.
//  / ). Combined with a
// cross-entity concrete reference (Bar? — concrete form not yet in the
// analysis session), the type-recovery regex captured the comment text
// alongside the actual type token, producing a multi-line type like
//  which leaked into the generated constructor as a
// stray identifier.
//
// Expected after the fix: 
// contains a clean constructor 
// with NO stray  /  tokens, and the build succeeds.
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue_88_doc_comment_list_marker.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $Bar {
  String get name;
}

@Zorphy(generateJson: true)
abstract class $Foo {
  ///The size of the refresh indicator.
  ///
  ///**Officially Supported Platforms/Implementations**:
  ///- Android native WebView
  ///- iOS
  bool? get enabled;

  ///Another field.
  ///
  ///**Supported on**:
  ///- Web
  ///- macOS
  Bar? get bar;
}
