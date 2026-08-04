/// Optional type wrapper for Zorphy
class Opt<T> {
  final T? _value;

  /// Creates an Opt with a pre-wrapped nullable value.
  const Opt._(this._value);

  /// Returns the wrapped value, or null if empty.
  T? get value => _value;

  /// Returns true when a non-null value is present.
  bool get isPresent => _value != null;

  /// Returns true when the wrapped value is null.
  bool get isEmpty => _value == null;

  /// Creates an empty Opt with no value.
  static Opt<T> empty<T>() => Opt<T>._(null);

  /// Wraps a non-null value in an Opt.
  static Opt<T> of<T>(T value) => Opt._(value);

  /// Wraps a nullable value in an Opt.
  static Opt<T> ofNullable<T>(T? value) => Opt._(value);

  /// Returns the value or a fallback when empty.
  T orElse(T other) => _value ?? other;

  /// Returns the value or computes a fallback when empty.
  T orElseGet(T Function() supplier) => _value ?? supplier();

  /// Executes [consumer] when a value is present.
  void ifPresent(void Function(T value) consumer) {
    if (_value != null) {
      consumer(_value);
    }
  }

  /// Maps the value to a new Opt, preserving emptiness.
  Opt<U> map<U>(U Function(T value) mapper) {
    if (_value == null) {
      return Opt.empty<U>();
    }
    return Opt.ofNullable(mapper(_value));
  }
}

/// Extension to allow calling opt() on any value
extension OptExtension<T> on T {
  /// Wraps this value in an Opt.
  Opt<T> opt() => Opt.ofNullable(this);
}
