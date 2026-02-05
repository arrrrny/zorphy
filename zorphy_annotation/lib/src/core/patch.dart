/// Patch interface for Zorphy code generation
///
/// This interface defines the contract for generated Patch classes,
/// which provide a way to apply partial updates to objects.
///
/// ## Usage
///
/// Patch classes are automatically generated for Zorphy-annotated classes:
/// ```dart
/// @Zorphy()
/// class User {
///   final String name;
///   final int age;
///
///   User({required this.name, required this.age});
/// }
///
/// // Generated:
/// class UserPatch implements Patch<User> {
///   final User$ _patch = {};
///
///   UserPatch withName(String name) { ... }
///   UserPatch withAge(int age) { ... }
///
///   @override
///   User applyTo(User entity) { ... }
/// }
/// ```
///
/// ## Applying Patches
///
/// ```dart
/// final patch = UserPatch()
///   ..withName("Alice")
///   ..withAge(30);
///
/// final updated = patch.applyTo(user);
/// ```
///
/// See also:
/// - [PatchBase] - Alternative patch abstraction with merge support
abstract class Patch<T> {
  /// Applies this patch to the given entity
  ///
  /// Returns a new instance with the patch changes applied.
  /// The original entity remains unmodified.
  T applyTo(T entity);

  /// Creates a patch from a JSON map
  ///
  /// This method must be implemented by generated Patch classes.
  /// The JSON map should contain field names as keys and new values.
  ///
  /// Example:
  /// ```dart
  /// final json = {'name': 'Alice', 'age': 30};
  /// final patch = UserPatch.fromJson(json);
  /// ```
  static Patch<T> fromJson<T>(Map<String, dynamic> json) {
    throw UnimplementedError(
      'fromJson must be implemented by generated Patch classes',
    );
  }
}
