import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../attachment/attachment.dart';
import '../chat_message/chat_message.dart';
import '../enums/index.dart';

part 'assistant_message.g.dart';
part '../../../../_br_/src/domain/entities/assitant_message/assistant_message.part.dart';

@Zorphy(generateJson: true)
abstract class $AssistantMessage implements $$ChatMessage {
  @override
  ChatMessageRole get role => ChatMessageRole.assistant;
  static AssistantMessage create({
    required String text,
    DateTime? createdAt,
    List<Attachment>? attachments,
  }) => AssistantMessage(
    text: text,
    attachments: attachments ?? [],
    role: ChatMessageRole.assistant,
    createdAt: createdAt ?? DateTime.now(),
  );
}
