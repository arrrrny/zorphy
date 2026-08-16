@ExchangeableObject()
class NavigationAction_ {
  ///The URL request object associated with the navigation action.
  URLRequest_ request;

  ///Indicates whether the request was made for the main frame.
  bool isForMainFrame;

  ///Gets whether a gesture was associated with the request.
  @SupportedPlatforms(platforms: [IOSPlatform()])
  bool? hasGesture;

  ///The title of the document being navigated to.
  String? title;

  NavigationAction_({
    required this.request,
    required this.isForMainFrame,
    this.hasGesture,
    this.title = 'default-title',
  });
}

@ExchangeableObject()
class URLRequest_ {
  ///The URL of the request.
  String? url;

  URLRequest_({this.url});
}
