import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../attachment/attachment.dart';
import '../chat_message/chat_message.dart';
import '../enums/index.dart';

part 'assistant_message.zorphy.dart';
part 'assistant_message.g.dart';

@Zorphy(generateJson: true)
abstract class $AssistantMessage implements $$ChatMessage {
  @override
  ChatMessageRole get role => ChatMessageRole.assistant;
  factory $AssistantMessage.create({required String text}) => AssistantMessage(
    text: text,
    attachments: [],
    role: ChatMessageRole.assistant,
    createdAt: DateTime.now(),
  );
}
