import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../attachment/attachment.dart';
import '../chat_message/chat_message.dart';
import '../enums/index.dart';

part 'user_message.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $UserMessage implements $$ChatMessage {
  @override
  ChatMessageRole get role => ChatMessageRole.user;
}
