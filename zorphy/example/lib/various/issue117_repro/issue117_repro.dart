// Fixture for issue #117: cross-file cross-entity reference.
//
// $Issue117Repro has a field 'ref' typed $Issue117Ref (the abstract form
// emitted by the CLI FieldNormalizer). The source file imports the
// referenced entity file so the abstract type resolves.
//
// Expected (post-fix): the generated `.zorphy.dart` part file produces
// valid Dart that passes `dart analyze` with zero errors. Specifically,
// `Issue117Ref` (the concrete form generated in issue117_ref.zorphy.dart)
// must resolve inside this file's part file too — which it does because
// the part file inherits the parent library's imports.
import 'package:zorphy_annotation/zorphy_annotation.dart';
import '../issue117_ref/issue117_ref.dart';

part 'issue117_repro.zorphy.dart';
part 'issue117_repro.g.dart';

/// Issue117Repro entity — cross-entity reference (issue #117 fixture)
@Zorphy(generateJson: true, generateCompareTo: true)
abstract class $Issue117Repro {
  $Issue117Ref get ref;
  bool get summarized;
  String? get summary;
}
