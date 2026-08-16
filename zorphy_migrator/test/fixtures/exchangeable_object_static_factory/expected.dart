@Zorphy(
  kind: ZorphyKind.valueObject,
  generateJson: true,
  generateCompareTo: true,
)
abstract class $AndroidResource {
  ///Android resource name.
  String get name;
  ///Optional default resource type.
  String? get defType;
  ///Optional default package to find.
  String? get defPackage;
  static AndroidResource id({required String name, String? defPackage}) {
    final myAndroidResource_ = 'test';
    return AndroidResource(name: name, defType: "id", defPackage: defPackage);
  }
  static AndroidResource layout({required String name, String? defPackage}) {
    return AndroidResource(name: name, defType: "layout", defPackage: defPackage);
  }
}
