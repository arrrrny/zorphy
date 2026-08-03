/// AST-Based Smart Regeneration engine.
///
/// Provides non-destructive code merging for zorphy-generated files.
///
/// **Quick start:**
/// ```dart
/// import 'package:zorphy/src/merge/merge.dart';
///
/// final result = MergeOrchestrator.merge(
///   existingContent: currentFileContent,
///   generatedContent: newGeneratedContent,
/// );
/// if (result.hasChanges) writeFile(path, result.content);
/// ```

library;

export 'ast_diff.dart';
export 'merge_orchestrator.dart';
export 'merge_strategy.dart';
export 'merge_types.dart';
export 'region_parser.dart';
