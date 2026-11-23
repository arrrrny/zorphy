/// Emission layer for hierarchy-wide members (ISSUE-004, #179).
///
/// Generators in `lib/src/generators/` emit members belonging to ONE class.
/// The emitters here emit members that exist only because several classes
/// form one hierarchy — a morphing method on a subtype, a `when` matcher on
/// the root — so they read the hierarchy off [ClassMetadata] rather than one
/// class's field list.
///
/// Both emitters produce `code_builder` [Spec] objects; nothing here builds
/// source text. Neither introduces a preset or a `generate*` toggle: under
/// the v3 zero-toggle contract (ISSUE-001) a hierarchy-wide member is gated
/// by the feature family that already owns it — sibling morphing rides
/// `generateChangeTo`, `when`/`maybeWhen` ride `generatePropertyHelpers` —
/// so the annotation surface is unchanged.
library;

import 'package:code_builder/code_builder.dart';

import '../models/class_metadata.dart';
import '../models/generation_config.dart';

/// A member family that spans a polymorphic hierarchy.
abstract class HierarchyEmitter {
  /// Whether this emitter contributes members for [metadata] under [config].
  bool shouldEmit(ClassMetadata metadata, GenerationConfig config);

  /// The specs to append to [metadata]'s generated library.
  List<Spec> emit(ClassMetadata metadata);
}
