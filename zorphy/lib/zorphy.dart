/// Zorphy - Modern code generation for Dart/Flutter
///
/// This library provides a complete solution for generating
/// boilerplate code like copyWith, JSON serialization, equality,
/// toString, and more.
library zorphy;

// Smart-merge module — PUBLIC API (arrrrny/zorphy#355).
//
// Stable within a major line: breaking changes to `MergeOrchestrator`,
// `MergeMode`, `MergeResult`, `MergeStrategy` and the rest of the merge
// surface ship as a MAJOR bump with a migration path, never a silent
// removal. Consumers must import these through `package:zorphy/zorphy.dart`
// and never reach into `package:zorphy/src/...` (`implementation_imports`).
export 'src/merge/merge.dart';

// Cross-emitter wire-kind vocabulary (shared by the wire-capability matrix
// drift gate): https://github.com/arrrrny/zorphy/issues/316
export 'src/emission/wire_kind.dart';

export 'package:zorphy_annotation/zorphy_annotation.dart';

// CLI module - Entity creation utilities
export 'src/cli/entity_creator.dart';
export 'src/cli/models/entity_config.dart';
export 'src/cli/utils/naming_utils.dart';

// v2 -> v3 migration codemod (ISSUE-019)
export 'src/migration/v3_codemod.dart';
