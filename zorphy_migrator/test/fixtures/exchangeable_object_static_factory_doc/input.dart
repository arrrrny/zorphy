@ExchangeableObject()
class AndroidResource_ {
  ///Android resource name.
  String name;

  ///Optional default resource type.
  String? defType;

  AndroidResource_({required this.name, this.defType});

  /// Creates an AndroidResource of type id.
  static AndroidResource_ id({required String name}) {
    return AndroidResource_(name: name, defType: "id");
  }
}