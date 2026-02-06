import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'attachment.dart';

part 'link_attachment.zorphy.dart';
part 'link_attachment.g.dart';

@Zorphy(generateJson: true)
abstract class $LinkAttachment implements $$Attachment {
  String get url;
}
