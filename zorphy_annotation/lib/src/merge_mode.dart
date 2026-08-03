/// Controls how zorphy regenerates output files.
///
/// - [smart]: Parse existing file, merge intelligently (default).
///   Preserves user edits in non-generated regions.
/// - [force]: Overwrite the entire file (legacy build_runner behavior).
///
/// This enum is re-exported from `zorphy_annotation` for use in
/// annotation parameters (e.g. future per-class merge control).
/// The canonical definition lives in `zorphy`'s merge engine.
enum MergeMode {
  /// Parse existing file, merge intelligently (default).
  smart,

  /// Overwrite the entire file (current build_runner behavior).
  force,
}
