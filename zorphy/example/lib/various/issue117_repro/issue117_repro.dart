// Regression fixture for issue #117: cross-file cross-entity reference.
//
// $Issue117Repro has a field 'ref' typed $Issue117Ref (the abstract form emitted
// by the CLI FieldNormalizer). The source imports the referenced entity file.
//
// Before the fix (issue #117): the generated patchWithIssue117Repro emitted
//   ref: _patchMap.containsKey(Issue117Repro$.ref)
//       ? ((...) as $Issue117Ref)
//       : this.ref,
// where the cast target $Issue117Ref (the abstract supertype) could not be
// assigned to the constructor parameter Issue117Ref (the concrete subtype),
// producing:
//   error - issue117_repro.zorphy.dart: The argument type 'Object' can't
//     be assigned to the parameter type 'Issue117Ref'.
//
// After the fix: the patch generator emits the cast as
//   ... as Issue117Ref
// (the concrete form, via helpers.replaceDollarTypesWithConcrete), matching
// the field's declared type and resolving cleanly.
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
