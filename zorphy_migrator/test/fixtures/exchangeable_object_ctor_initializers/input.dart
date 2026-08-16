@ExchangeableObject()
class BadgeView_ {
  ///The badge text.
  String text;

  @ExchangeableObjectConstructor()
  BadgeView_({
    required this.text,
  }) : assert(text.length < 100);
}
