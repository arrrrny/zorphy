@ZorphyValue()
abstract class $NavigationAction {
  ///The URL request object associated with the navigation action.
  URLRequest get request;

  ///Indicates whether the request was made for the main frame.
  bool get isForMainFrame;

  ///Gets whether a gesture was associated with the request.
  bool? get hasGesture;

  ///The title of the document being navigated to.
  @JsonKey(defaultValue: 'default-title')
  String? get title;
}

@ZorphyValue()
abstract class $URLRequest {
  ///The URL of the request.
  String? get url;
}
