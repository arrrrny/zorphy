@ExchangeableObject()
class ActivityButton_ {
  ///The image template for the activity button.
  String templateImage;

  ///The extension identifier for the activity button.
  String extensionIdentifier;

  @ExchangeableObjectConstructor()
  ActivityButton_({
    required this.templateImage,
    required this.extensionIdentifier,
  });
}
