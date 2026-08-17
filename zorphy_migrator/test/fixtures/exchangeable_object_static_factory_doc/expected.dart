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
  /// Creates an AndroidResource of type id.
  static AndroidResource id({required String name}) {
    return AndroidResource(name: name, defType: "id");
  }
}