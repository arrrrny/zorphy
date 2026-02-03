/// Patch interface for Zorphy code generation
///
/// This is used by generated Patch classes to provide a common interface
/// for partial updates to objects.
abstract class Patch<T> {
  /// Applies this patch to the given entity
  T applyTo(T entity);

  /// Creates a patch from a JSON map
  static Patch<T> fromJson<T>(Map<String, dynamic> json) {
    throw UnimplementedError(
        'fromJson must be implemented by generated Patch classes');
  }
}
