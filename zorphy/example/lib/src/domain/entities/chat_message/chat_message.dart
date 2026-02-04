import 'package:zorphy_annotation/zorphy_annotation.dart';
import '../assitant_message/assistant_message.dart';
import '../attachment/attachment.dart';
import '../enums/index.dart';
import '../user_message/user_message.dart';

part 'chat_message.zorphy.dart';

@Zorphy(
  generateJson: true,
  explicitSubTypes: [$UserMessage, $AssistantMessage],
  nonSealed: true,
)
abstract class $$ChatMessage {
  String? get id;
  String get text;
  ChatMessageRole get role;
  DateTime get createdAt;
  List<$$Attachment>? get attachments;
  DateTime? get updatedAt;
}

extension ChatMessageExtension on $$ChatMessage {
  bool get isUser => role == ChatMessageRole.user;
}
