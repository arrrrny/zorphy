@Zorphy(
  kind: ZorphyKind.valueObject,
  generateJson: true,
  generateCompareTo: true,
)
abstract class $AndroidResource {
  ///Android resource name.
  String get name;
  /// Creates an AndroidResource of type id.
  static AndroidResource id({required String name}) {
    return AndroidResource(name: name, defType: "id");
  }
}