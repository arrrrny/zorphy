import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../attachment/attachment.dart';
import '../chat_message/chat_message.dart';
import '../enums/index.dart';

part 'user_message.g.dart';
part '../../../../_br_/src/domain/entities/user_message/user_message.part.dart';

@Zorphy(generateJson: true)
abstract class $UserMessage implements $$ChatMessage {
  @override
  ChatMessageRole get role => ChatMessageRole.user;
}
