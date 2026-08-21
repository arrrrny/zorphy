@ExchangeableObject()
class AndroidResource_ {
  ///Android resource name.
  String name;

  ///Optional default resource type.
  String? defType;

  AndroidResource_({required this.name, this.defType});

  /// Creates an AndroidResource_ preserving the old name in this comment.
  static AndroidResource_ id({required String name}) {
    final tag = 'tag: AndroidResource_';
    return AndroidResource_(name: name, defType: "id");
  }
}
