import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'chat_message.dart';
import 'chat_message_role.dart';

part 'user_message.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $UserMessage implements $$ChatMessage {
  @override
  ChatMessageRole get role => ChatMessageRole.user;
}
