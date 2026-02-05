/// Optional type wrapper for Zorphy
///
/// Provides a functional way to handle nullable values with a rich API
/// inspired by functional programming patterns (similar to Java's Optional,
/// Rust's Option, or Haskell's Maybe).
///
/// ## Benefits Over Null
///
/// - Explicit API forces handling of empty case
/// - Rich methods for transformation and consumption
/// - Chainable operations
/// - Better type safety
///
/// ## Usage Examples
///
/// ### Creating Optional Values
/// ```dart
/// final present = Opt.of("value");
/// final empty = Opt.empty<String>();
/// final nullable = Opt.ofNullable(null);
/// final fromExtension = "value".opt();
/// ```
///
/// ### Checking Presence
/// ```dart
/// if (opt.isPresent) {
///   print(opt.value);
/// }
///
/// if (opt.isEmpty) {
///   print("No value");
/// }
/// ```
///
/// ### Getting Values
/// ```dart
/// final value = opt.orElse("default");
/// final computed = opt.orElseGet(() => computeValue());
/// ```
///
/// ### Transforming
/// ```dart
/// final length = opt.map((s) => s.length);
/// final uppercased = opt.map((s) => s.toUpperCase());
/// ```
///
/// ### Consuming
/// ```dart
/// opt.ifPresent((value) {
///   print("Got: $value");
/// });
/// ```
///
/// See also:
/// - [OptExtension] - Extension method for creating Opt from any value
class Opt<T> {
  final T? _value;

  const Opt._(this._value);

  /// The wrapped value, or null if empty
  T? get value => _value;

  /// Whether this Opt contains a non-null value
  bool get isPresent => _value != null;

  /// Whether this Opt is empty (contains null)
  bool get isEmpty => _value == null;

  /// Creates an empty Opt
  ///
  /// Example:
  /// ```dart
  /// final opt = Opt.empty<String>();
  /// print(opt.isPresent); // false
  /// ```
  static Opt<T> empty<T>() => Opt<T>._(null);

  /// Creates an Opt containing [value]
  ///
  /// [value] must not be null. For nullable values, use [ofNullable].
  ///
  /// Example:
  /// ```dart
  /// final opt = Opt.of("hello");
  /// print(opt.value); // "hello"
  /// ```
  static Opt<T> of<T>(T value) => Opt._(value);

  /// Creates an Opt from a nullable [value]
  ///
  /// If [value] is null, returns an empty Opt.
  ///
  /// Example:
  /// ```dart
  /// final opt1 = Opt.ofNullable("hello");
  /// final opt2 = Opt.ofNullable(null);
  /// print(opt1.isPresent); // true
  /// print(opt2.isPresent); // false
  /// ```
  static Opt<T> ofNullable<T>(T? value) => Opt._(value);

  /// Returns the value if present, otherwise [other]
  ///
  /// Example:
  /// ```dart
  /// final name = opt.orElse("Unknown");
  /// ```
  T orElse(T other) => _value ?? other;

  /// Returns the value if present, otherwise calls [supplier]
  ///
  /// Example:
  /// ```dart
  /// final name = opt.orElseGet(() => fetchDefaultName());
  /// ```
  T orElseGet(T Function() supplier) => _value ?? supplier();

  /// Executes [consumer] with the value if present
  ///
  /// Example:
  /// ```dart
  /// usernameOpt.ifPresent((name) {
  ///   print("Hello, $name");
  /// });
  /// ```
  void ifPresent(void Function(T value) consumer) {
    if (_value != null) {
      consumer(_value!);
    }
  }

  /// Transforms the value using [mapper] if present
  ///
  /// Returns empty Opt if this Opt is empty or if [mapper] returns null.
  ///
  /// Example:
  /// ```dart
  /// final length = nameOpt.map((s) => s.length);
  /// final words = sentenceOpt.map((s) => s.split(' '));
  /// ```
  Opt<U> map<U>(U Function(T value) mapper) {
    if (_value == null) {
      return Opt.empty<U>();
    }
    return Opt.ofNullable(mapper(_value!));
  }
}

/// Extension that allows calling [opt] on any value
///
/// This provides a convenient way to create Opt instances.
///
/// ## Usage
///
/// ```dart
/// final opt1 = "value".opt();
/// final opt2 = null.opt();
///
/// // Chain operations
/// final length = username
///   .opt()
///   .map((s) => s.length)
///   .orElse(0);
/// ```
extension OptExtension<T> on T {
  /// Creates an Opt containing this value
  ///
  /// If this value is null, returns an empty Opt.
  ///
  /// Example:
  /// ```dart
  /// final opt = "hello".opt();
  /// final empty = null.opt();
  /// ```
  Opt<T> opt() => Opt.ofNullable(this);
}
