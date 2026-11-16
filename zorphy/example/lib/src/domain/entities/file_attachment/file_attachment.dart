import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../attachment/attachment.dart';
import '../image_file_attachment/image_file_attachment.dart';

part 'file_attachment.g.dart';
part '../../../../_br_/src/domain/entities/file_attachment/file_attachment.part.dart';

@Zorphy(generateJson: true, explicitSubTypes: [$ImageFileAttachment])
abstract class $FileAttachment implements $$Attachment {}
