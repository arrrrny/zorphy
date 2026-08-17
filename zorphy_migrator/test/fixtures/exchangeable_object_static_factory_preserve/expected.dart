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
  /// Creates an AndroidResource_ preserving the old name in this comment.
  static AndroidResource id({required String name}) {
    final tag = 'tag: AndroidResource_';
    return AndroidResource(name: name, defType: "id");
  }
}
