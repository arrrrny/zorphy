import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../file_attachment/file_attachment.dart';
import '../link_attachment/link_attachment.dart';

part '../../../../_br_/src/domain/entities/attachment/attachment.part.dart';

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
