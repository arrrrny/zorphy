@ExchangeableEnum()
class NavigationType_ {
  // ignore: unused_field
  final String _value;
  const NavigationType_._internal(this._value);

  ///A link with an href attribute was activated by the user.
  static const LINK_ACTIVATED = const NavigationType_._internal(
    'LINK_ACTIVATED',
  );

  ///A form was submitted.
  static const FORM_SUBMITTED = const NavigationType_._internal(
    'FORM_SUBMITTED',
  );
}

@ExchangeableEnum()
class JsAlertResponseAction_ {
  // ignore: unused_field
  final int _value;
  const JsAlertResponseAction_._internal(this._value);

  ///Confirm that the user hit confirm button.
  static const CONFIRM = const JsAlertResponseAction_._internal(0);
}

@ExchangeableEnum()
class URLRequestNetworkServiceType_ {
  // ignore: unused_field
  final int _value;
  const URLRequestNetworkServiceType_._internal(this._value);

  static const DEFAULT = const URLRequestNetworkServiceType_._internal(0);
  static const VIDEO = const URLRequestNetworkServiceType_._internal(2);
  static const BACKGROUND = const URLRequestNetworkServiceType_._internal(3);
}
