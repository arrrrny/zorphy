// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'chat_message.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

abstract class ChatMessage {
  String? get id;
  String get text;
  ChatMessageRole get role;
  DateTime get createdAt;
  List<Attachment>? get attachments;
  DateTime? get updatedAt;

  ChatMessage();

  /// Creates a [ChatMessage] instance from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    if (json['__typename'] == "UserMessage") {
      return UserMessage.fromJson(json);
    } else if (json['__typename'] == "AssistantMessage") {
      return AssistantMessage.fromJson(json);
    }
    throw UnsupportedError(
      "The __typename '${json['__typename']}' is not supported by the $className.fromJson constructor.",
    );
  }

  Map<String, dynamic> toJson() {
    if (this is UserMessage) {
      final json = (this as UserMessage).toJsonLean();
      json['__typename'] = "UserMessage";
      return json;
    } else if (this is AssistantMessage) {
      final json = (this as AssistantMessage).toJsonLean();
      json['__typename'] = "AssistantMessage";
      return json;
    }
    throw UnsupportedError("Unknown subtype: $runtimeType");
  }
}

extension ChatMessagePolymorphicE on ChatMessage {
  bool get isUserMessage => this is UserMessage;
  UserMessage? get asUserMessage =>
      this is UserMessage ? this as UserMessage : null;
  bool get isAssistantMessage => this is AssistantMessage;
  AssistantMessage? get asAssistantMessage =>
      this is AssistantMessage ? this as AssistantMessage : null;
}

extension ChatMessagePropertyHelpers on ChatMessage {
  bool get hasId => id?.isNotEmpty == true;
  bool get noId => id?.isEmpty ?? true;
  String get idRequired =>
      id ?? (throw StateError('id is required but was null'));
  bool get hasText => text.isNotEmpty;
  bool get noText => text.isEmpty;
  bool get isRoleUser => role == ChatMessageRole.user;
  bool get isRoleAssistant => role == ChatMessageRole.assistant;
  bool get isRoleSystem => role == ChatMessageRole.system;
  List<Attachment> get attachmentsRequired =>
      attachments ?? (throw StateError('attachments is required but was null'));
  bool get hasAttachments => attachments?.isNotEmpty ?? false;
  bool get noAttachments => attachments?.isEmpty ?? true;
  bool get hasUpdatedAt => updatedAt != null;
  bool get noUpdatedAt => updatedAt == null;
  DateTime get updatedAtRequired =>
      updatedAt ?? (throw StateError('updatedAt is required but was null'));
}

enum ChatMessage$ { id, text, role, createdAt, attachments, updatedAt }

/// Field descriptors for [ChatMessage] query construction
abstract final class ChatMessageFields {
  static String? _$getid(ChatMessage e) => e.id;
  static const id = Field<ChatMessage, String?>('id', _$getid);
  static String _$gettext(ChatMessage e) => e.text;
  static const text = Field<ChatMessage, String>('text', _$gettext);
  static ChatMessageRole _$getrole(ChatMessage e) => e.role;
  static const role = Field<ChatMessage, ChatMessageRole>('role', _$getrole);
  static DateTime _$getcreatedAt(ChatMessage e) => e.createdAt;
  static const createdAt = Field<ChatMessage, DateTime>(
    'createdAt',
    _$getcreatedAt,
  );
  static List<Attachment>? _$getattachments(ChatMessage e) => e.attachments;
  static const attachments = Field<ChatMessage, List<Attachment>?>(
    'attachments',
    _$getattachments,
  );
  static DateTime? _$getupdatedAt(ChatMessage e) => e.updatedAt;
  static const updatedAt = Field<ChatMessage, DateTime?>(
    'updatedAt',
    _$getupdatedAt,
  );
}

extension ChatMessageCompareE on ChatMessage {
  Map<String, dynamic> compareToChatMessage(ChatMessage other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (text != other.text) {
      diff['text'] = () => other.text;
    }
    if (role != other.role) {
      diff['role'] = () => other.role;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (attachments != other.attachments) {
      diff['attachments'] = () => other.attachments;
    }
    if (updatedAt != other.updatedAt) {
      diff['updatedAt'] = () => other.updatedAt;
    }
    return diff;
  }
}

extension ChatMessageChangeToE on ChatMessage {
  UserMessage changeToUserMessage({
    ChatMessageRole? role,
    String? id,
    String? text,
    DateTime? createdAt,
    List<Attachment>? attachments,
    DateTime? updatedAt,
  }) {
    final _patcher = UserMessagePatch();
    if (role != null) {
      _patcher.withRole(role);
    }
    if (id != null) {
      _patcher.withId(id);
    }
    if (text != null) {
      _patcher.withText(text);
    }
    if (createdAt != null) {
      _patcher.withCreatedAt(createdAt);
    }
    if (attachments != null) {
      _patcher.withAttachments(attachments);
    }
    if (updatedAt != null) {
      _patcher.withUpdatedAt(updatedAt);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return UserMessage.fromJson(_json);
  }

  AssistantMessage changeToAssistantMessage({
    ChatMessageRole? role,
    String? id,
    String? text,
    DateTime? createdAt,
    List<Attachment>? attachments,
    DateTime? updatedAt,
  }) {
    final _patcher = AssistantMessagePatch();
    if (role != null) {
      _patcher.withRole(role);
    }
    if (id != null) {
      _patcher.withId(id);
    }
    if (text != null) {
      _patcher.withText(text);
    }
    if (createdAt != null) {
      _patcher.withCreatedAt(createdAt);
    }
    if (attachments != null) {
      _patcher.withAttachments(attachments);
    }
    if (updatedAt != null) {
      _patcher.withUpdatedAt(updatedAt);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return AssistantMessage.fromJson(_json);
  }
}
