// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'user_message.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class UserMessage extends ChatMessage {
  @override
  final String? id;
  @override
  final String text;
  @override
  final ChatMessageRole role;
  @override
  final DateTime createdAt;
  @override
  final List<Attachment>? attachments;
  @override
  final DateTime? updatedAt;

  UserMessage({
    this.id,
    required this.text,
    required this.role,
    required this.createdAt,
    this.attachments,
    this.updatedAt,
  }) : super();

  UserMessage copyWith({
    String? id,
    String? text,
    ChatMessageRole? role,
    DateTime? createdAt,
    List<Attachment>? attachments,
    DateTime? updatedAt,
  }) {
    return UserMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  UserMessage copyWithUserMessage({
    String? id,
    String? text,
    ChatMessageRole? role,
    DateTime? createdAt,
    List<Attachment>? attachments,
    DateTime? updatedAt,
  }) {
    return copyWith(
      id: id,
      text: text,
      role: role,
      createdAt: createdAt,
      attachments: attachments,
      updatedAt: updatedAt,
    );
  }

  UserMessage patchWithUserMessage({UserMessagePatch? patchInput}) {
    final _patcher = patchInput ?? UserMessagePatch();
    final _patchMap = _patcher.patchMap;
    return UserMessage(
      id: _patchMap.containsKey(UserMessage$.id)
          ? (_patchMap[UserMessage$.id] is Function)
                ? _patchMap[UserMessage$.id](this.id)
                : (_patchMap[UserMessage$.id] is Patch)
                ? _patchMap[UserMessage$.id].applyTo(this.id)
                : _patchMap[UserMessage$.id]
          : this.id,
      text: _patchMap.containsKey(UserMessage$.text)
          ? (_patchMap[UserMessage$.text] is Function)
                ? _patchMap[UserMessage$.text](this.text)
                : (_patchMap[UserMessage$.text] is Patch)
                ? _patchMap[UserMessage$.text].applyTo(this.text)
                : _patchMap[UserMessage$.text]
          : this.text,
      role: _patchMap.containsKey(UserMessage$.role)
          ? (_patchMap[UserMessage$.role] is Function)
                ? _patchMap[UserMessage$.role](this.role)
                : (_patchMap[UserMessage$.role] is Patch)
                ? _patchMap[UserMessage$.role].applyTo(this.role)
                : _patchMap[UserMessage$.role]
          : this.role,
      createdAt: _patchMap.containsKey(UserMessage$.createdAt)
          ? (_patchMap[UserMessage$.createdAt] is Function)
                ? _patchMap[UserMessage$.createdAt](this.createdAt)
                : (_patchMap[UserMessage$.createdAt] is Patch)
                ? _patchMap[UserMessage$.createdAt].applyTo(this.createdAt)
                : _patchMap[UserMessage$.createdAt]
          : this.createdAt,
      attachments: _patchMap.containsKey(UserMessage$.attachments)
          ? (_patchMap[UserMessage$.attachments] is Function)
                ? _patchMap[UserMessage$.attachments](this.attachments)
                : (_patchMap[UserMessage$.attachments] is Patch)
                ? _patchMap[UserMessage$.attachments].applyTo(this.attachments)
                : _patchMap[UserMessage$.attachments]
          : this.attachments,
      updatedAt: _patchMap.containsKey(UserMessage$.updatedAt)
          ? (_patchMap[UserMessage$.updatedAt] is Function)
                ? _patchMap[UserMessage$.updatedAt](this.updatedAt)
                : (_patchMap[UserMessage$.updatedAt] is Patch)
                ? _patchMap[UserMessage$.updatedAt].applyTo(this.updatedAt)
                : _patchMap[UserMessage$.updatedAt]
          : this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserMessage &&
        id == other.id &&
        text == other.text &&
        role == other.role &&
        createdAt == other.createdAt &&
        attachments == other.attachments &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.text,
      this.role,
      this.createdAt,
      this.attachments,
      this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserMessage(' +
        'id: ${id}' +
        ', ' +
        'text: ${text}' +
        ', ' +
        'role: ${role}' +
        ', ' +
        'createdAt: ${createdAt}' +
        ', ' +
        'attachments: ${attachments}' +
        ', ' +
        'updatedAt: ${updatedAt})';
  }

  /// Creates a [UserMessage] instance from JSON
  factory UserMessage.fromJson(Map<String, dynamic> json) =>
      _$UserMessageFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserMessageToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }

  Map<String, dynamic> toJson() {
    final json = _$UserMessageToJson(this);
    json['__typename'] = 'UserMessage';
    return json;
  }
}

extension UserMessagePropertyHelpers on UserMessage {
  bool get isRoleUser => role == ChatMessageRole.user;
  bool get isRoleAssistant => role == ChatMessageRole.assistant;
  bool get isRoleSystem => role == ChatMessageRole.system;
}

extension UserMessageSerialization on UserMessage {
  Map<String, dynamic> toJson() => _$UserMessageToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserMessageToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum UserMessage$ { id, text, role, createdAt, attachments, updatedAt }

class UserMessagePatch extends PatchBase<UserMessage, UserMessage$> {
  UserMessage applyTo(UserMessage entity) {
    return entity.patchWithUserMessage(patchInput: this);
  }

  UserMessagePatch withId(String? value) {
    patchMap[UserMessage$.id] = value;
    return this;
  }

  UserMessagePatch withText(String? value) {
    patchMap[UserMessage$.text] = value;
    return this;
  }

  UserMessagePatch withRole(ChatMessageRole? value) {
    patchMap[UserMessage$.role] = value;
    return this;
  }

  UserMessagePatch withCreatedAt(DateTime? value) {
    patchMap[UserMessage$.createdAt] = value;
    return this;
  }

  UserMessagePatch withAttachments(List<Attachment>? value) {
    patchMap[UserMessage$.attachments] = value;
    return this;
  }

  UserMessagePatch withUpdatedAt(DateTime? value) {
    patchMap[UserMessage$.updatedAt] = value;
    return this;
  }
}

/// Field descriptors for [UserMessage] query construction
abstract final class UserMessageFields {
  static String? _$getid(UserMessage e) => e.id;
  static const id = Field<UserMessage, String?>('id', _$getid);
  static String _$gettext(UserMessage e) => e.text;
  static const text = Field<UserMessage, String>('text', _$gettext);
  static ChatMessageRole _$getrole(UserMessage e) => e.role;
  static const role = Field<UserMessage, ChatMessageRole>('role', _$getrole);
  static DateTime _$getcreatedAt(UserMessage e) => e.createdAt;
  static const createdAt = Field<UserMessage, DateTime>(
    'createdAt',
    _$getcreatedAt,
  );
  static List<Attachment>? _$getattachments(UserMessage e) => e.attachments;
  static const attachments = Field<UserMessage, List<Attachment>?>(
    'attachments',
    _$getattachments,
  );
  static DateTime? _$getupdatedAt(UserMessage e) => e.updatedAt;
  static const updatedAt = Field<UserMessage, DateTime?>(
    'updatedAt',
    _$getupdatedAt,
  );
}

extension UserMessageCompareE on UserMessage {
  Map<String, dynamic> compareToUserMessage(UserMessage other) {
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
