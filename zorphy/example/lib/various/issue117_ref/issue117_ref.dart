// Regression fixture for issue #117: cross-file cross-entity reference.
//
// $Issue117Ref is declared in this file. Issue117Repro (in
// issue117_repro.dart) references $Issue117Ref as a field type — the canonical
// CLI-generated shape (FieldNormalizer prepends the $ prefix).
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue117_ref.zorphy.dart';
part 'issue117_ref.g.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class $Issue117Ref {
  String get id;
}

