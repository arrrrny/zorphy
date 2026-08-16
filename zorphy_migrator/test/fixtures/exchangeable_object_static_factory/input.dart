@ExchangeableObject()
class AndroidResource_ {
  ///Android resource name.
  String name;

  ///Optional default resource type.
  String? defType;

  ///Optional default package to find.
  String? defPackage;

  AndroidResource_({required this.name, this.defType, this.defPackage});

  static AndroidResource_ id({required String name, String? defPackage}) {
    return AndroidResource_(name: name, defType: "id", defPackage: defPackage);
  }
}
