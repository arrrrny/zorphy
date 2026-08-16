@Zorphy(
  kind: ZorphyKind.valueObject,
  generateJson: true,
  generateCompareTo: true,
)
abstract class $ActivityButton {
  ///The image template for the activity button.
  String get templateImage;
  ///The extension identifier for the activity button.
  String get extensionIdentifier;
}
