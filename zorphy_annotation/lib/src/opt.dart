/// Optional type wrapper for Zorphy
class Opt<T> {
  final T? _value;

  const Opt._(this._value);

  T? get value => _value;

  bool get isPresent => _value != null;

  bool get isEmpty => _value == null;

  static Opt<T> empty<T>() => Opt<T>._(null);

  static Opt<T> of<T>(T value) => Opt._(value);

  static Opt<T> ofNullable<T>(T? value) => Opt._(value);

  T orElse(T other) => _value ?? other;

  T orElseGet(T Function() supplier) => _value ?? supplier();

  void ifPresent(void Function(T value) consumer) {
    if (_value != null) {
      consumer(_value!);
    }
  }

  Opt<U> map<U>(U Function(T value) mapper) {
    if (_value == null) {
      return Opt.empty<U>();
    }
    return Opt.ofNullable(mapper(_value!));
  }
}

/// Extension to allow calling opt() on any value
extension OptExtension<T> on T {
  Opt<T> opt() => Opt.ofNullable(this);
}
