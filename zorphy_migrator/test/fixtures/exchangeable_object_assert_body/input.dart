@ExchangeableObject()
class UIImage_ {
  ///The name of the image asset.
  String? name;

  @ExchangeableObjectConstructor()
  UIImage_({this.name}) {
    assert(this.name != null);
  }
}
