import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'chat_message.dart';
import 'user_message.dart';

part 'chat.zorphy.dart';
part 'chat.g.dart';

@Zorphy(generateJson: true)
abstract class $Chat {
  String? get id;
  String get title;
  List<$$ChatMessage> get messages;
  DateTime get createdAt;
  DateTime? get updatedAt;

  static Chat create({required UserMessage message}) => Chat(
    title: message.text.substring(
      0,
      message.text.length > 60 ? 60 : message.text.length,
    ),
    messages: [message],
    createdAt: DateTime.now(),
  );
}
