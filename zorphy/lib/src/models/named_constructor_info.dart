/// Descriptor for a user-declared named constructor.
///
/// Parsed from `@ZorphyNamedConstructor` annotations placed on the
/// abstract class. The generator uses these to emit additional
/// named constructors (with the same parameters as the default
/// constructor) on the concrete class, each with the declared body.
class NamedConstructorInfo {
  /// Constructor name (e.g. `world`).
  final String name;

  /// Dart statements for the constructor body.
  final String body;

  /// When `true`, emit a `factory` constructor whose [body] constructs and
  /// returns the instance. When `false`, emit a normal constructor with
  /// field-formal parameters, an initializer list, and the [body].
  final bool factory;

  /// Creates a named constructor descriptor.
  const NamedConstructorInfo({
    required this.name,
    required this.body,
    this.factory = false,
  });
}
