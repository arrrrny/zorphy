import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue_148_list_map_cast_example.zorphy.dart';
part 'issue_148_list_map_cast_example.g.dart';

/// Fixture for issue #148: composite list fields must not be hard-cast at
/// the generated cast sites.
///
/// `MarketplaceResult` mirrors the zik_zak entity (arrrrny/zik_zak#625)
/// where a raw `jsonDecode` payload routed through the generated
/// `copyWithField` switch or a patch-merge arm threw an uncaught
/// `TypeError`: the payload list arrives as `List<dynamic>` (with
/// `Map<String, dynamic>` elements) and the generated code cast the whole
/// list to `List<Map<String, dynamic>>`. `NullablePayloads` exercises the
/// same shape on a nullable field.
@Zorphy(generateJson: true)
abstract class $MarketplaceResult {
  bool get success;
  List<Map<String, dynamic>> get marketplaces;
  List<Map<String, dynamic>> get errors;
}

@Zorphy(generateJson: true)
abstract class $NullablePayloads {
  List<Map<String, dynamic>>? get payloads;
}

/// Exercises typed map values at the same cast sites: a decoded
/// `Map<String, dynamic>` entry must be converted entry-wise to the
/// declared `Map<String, String>` element type instead of failing a
/// hard element cast.
@Zorphy(generateJson: true)
abstract class $TaggedResult {
  List<Map<String, String>> get tags;
  List<Map<String, String>>? get maybeTags;
}
