/// Base class for patch operations in Zorphy
///
/// Provides an alternative to [Patch] with support for merging
/// patches and checking if a patch is empty (no changes).
///
/// ## Comparison with Patch
///
/// [Patch]:
/// - Simpler interface
/// - Focuses on applying changes
/// - Used by generated code
///
/// [PatchBase]:
/// - More feature-rich
/// - Supports merging patches
/// - Can check if empty
/// - Better for manual patch creation
///
/// ## Usage
///
/// ```dart
/// class MyPatch<T> extends PatchBase<T> {
///   final Map<String, dynamic> _changes;
///
///   MyPatch(this._changes);
///
///   @override
///   T apply(T original) {
///     // Apply _changes to original
///     return modified;
///   }
///
///   @override
///   MyPatch<T> merge(PatchBase<T> other) {
///     // Combine _changes with other
///     return MyPatch(combined);
///   }
///
///   @override
///   bool get isEmpty => _changes.isEmpty;
/// }
/// ```
///
/// See also:
/// - [Patch] - Simpler patch interface used by generated code
/// - [NoOpPatch] - Implementation that makes no changes
abstract class PatchBase<T> {
  /// Applies the patch to the given object
  ///
  /// Returns a modified version of [original] with the patch applied.
  /// The original object is not modified.
  T apply(T original);

  /// Merges this patch with another patch
  ///
  /// Returns a new patch that combines both patches' changes.
  /// When there are conflicts, [other] takes precedence.
  PatchBase<T> merge(PatchBase<T> other);

  /// Checks if the patch is empty (makes no changes)
  ///
  /// An empty patch returns the original object unchanged when applied.
  bool get isEmpty;

  /// Creates a combined patch
  ///
  /// Alias for [merge] for more readable code.
  PatchBase<T> combine(PatchBase<T> other) => merge(other);
}

/// Represents a patch that makes no changes
///
/// This is useful as a default value or when you need a null object
/// for patches.
///
/// ## Usage
///
/// ```dart
/// final patch = getUserPatch(userId) ?? NoOpPatch<User>();
/// final updated = patch.applyTo(user);
/// ```
class NoOpPatch<T> extends PatchBase<T> {
  @override
  T apply(T original) => original;

  @override
  PatchBase<T> merge(PatchBase<T> other) => other;

  @override
  bool get isEmpty => true;
}
