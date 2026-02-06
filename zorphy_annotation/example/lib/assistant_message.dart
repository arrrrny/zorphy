import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'chat_message.dart';
import 'chat_message_role.dart';

part 'assistant_message.zorphy.dart';

@Zorphy(generateJson: true)
abstract class $AssistantMessage implements $$ChatMessage {
  factory $AssistantMessage.create({required String text}) => AssistantMessage(
        text: text,
        attachments: [],
        role: ChatMessageRole.assistant,
        createdAt: DateTime.now(),
      );
  @override
  ChatMessageRole get role => ChatMessageRole.assistant;
}
