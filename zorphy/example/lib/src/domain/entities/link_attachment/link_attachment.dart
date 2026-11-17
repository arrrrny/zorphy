import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../attachment/attachment.dart';

part 'link_attachment.g.dart';
part '../../../../_br_/src/domain/entities/link_attachment/link_attachment.part.dart';

@Zorphy(generateJson: true)
abstract class $LinkAttachment implements $$Attachment {
  String get url;
}
