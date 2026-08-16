@ExchangeableObject()
class AndroidResource_ {
  ///Android resource name.
  String name;

  AndroidResource_({required this.name});

  /// Creates an AndroidResource of type id.
  static AndroidResource_ id({required String name}) {
    return AndroidResource_(name: name, defType: "id");
  }
}