import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'file_attachment.dart';
import 'link_attachment.dart';

part 'attachment.zorphy.dart';

@Zorphy(
  generateJson: true,
  explicitSubTypes: [$FileAttachment, $LinkAttachment],
  nonSealed: true,
)
abstract class $$Attachment {
  String get name;
  String get mimeType;
  List<int> get bytes;
}
