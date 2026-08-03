/// Controls how zorphy regenerates output files.
///
/// - [smart]: Parse existing file, merge intelligently (default).
///   Preserves user edits in non-generated regions.
/// - [force]: Overwrite the entire file (current build_runner behavior).
///
/// This is the canonical MergeMode definition used by both the annotation
/// package and zorphy's merge engine (MergeOrchestrator).
enum MergeMode {
  /// Parse existing file, merge intelligently (default).
  smart,

  /// Overwrite the entire file (current build_runner behavior).
  force,
}
