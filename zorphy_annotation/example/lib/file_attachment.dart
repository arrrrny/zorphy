import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'attachment.dart';
import 'image_file_attachment.dart';

part 'file_attachment.zorphy.dart';

@Zorphy(generateJson: true, explicitSubTypes: [$ImageFileAttachment])
abstract class $FileAttachment implements $$Attachment {}
