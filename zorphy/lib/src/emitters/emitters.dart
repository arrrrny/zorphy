/// Hierarchy-wide emission for the v3 polymorphic surface (ISSUE-004, #179).
///
/// `lib/src/emission/` converts finished SPECS to source; these emitters
/// BUILD specs for members that belong to a whole hierarchy rather than to
/// one class. `ZorphyEmitter` still owns the final formatting, so both layers
/// stay `code_builder` all the way down.
library;

export 'hierarchy_emitter.dart';
export 'morphing_emitter.dart';
export 'polymorphic_class_emitter.dart';
