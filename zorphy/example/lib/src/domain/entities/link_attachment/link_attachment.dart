import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../attachment/attachment.dart';

part 'link_attachment.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $LinkAttachment implements $$Attachment {
  String get url;
}
