/// Base class for patch operations in Zorphy
abstract class PatchBase<T> {
  /// Applies the patch to the given object
  T apply(T original);

  /// Merges this patch with another patch
  PatchBase<T> merge(PatchBase<T> other);

  /// Checks if the patch is empty (makes no changes)
  bool get isEmpty;

  /// Creates a combined patch
  PatchBase<T> combine(PatchBase<T> other) => merge(other);
}

/// Represents a patch that makes no changes
class NoOpPatch<T> extends PatchBase<T> {
  @override
  T apply(T original) => original;

  @override
  PatchBase<T> merge(PatchBase<T> other) => other;

  @override
  bool get isEmpty => true;
}