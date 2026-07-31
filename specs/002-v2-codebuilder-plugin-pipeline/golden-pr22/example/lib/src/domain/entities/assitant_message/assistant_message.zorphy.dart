// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'assistant_message.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class AssistantMessage extends ChatMessage {
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

  AssistantMessage({
    this.id,
    required this.text,
    required this.role,
    required this.createdAt,
    this.attachments,
    this.updatedAt,
  }) : super();

  AssistantMessage copyWith({
    String? id,
    String? text,
    ChatMessageRole? role,
    DateTime? createdAt,
    List<Attachment>? attachments,
    DateTime? updatedAt,
  }) {
    return AssistantMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      attachments: attachments ?? this.attachments,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  AssistantMessage copyWithAssistantMessage({
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

  factory AssistantMessage.create({
    required String text,
    DateTime? createdAt,
    List<Attachment>? attachments,
  }) => $AssistantMessage.create(
    text: text,
    createdAt: createdAt,
    attachments: attachments,
  );

  AssistantMessage patchWithAssistantMessage({
    AssistantMessagePatch? patchInput,
  }) {
    final _patcher = patchInput ?? AssistantMessagePatch();
    final _patchMap = _patcher.patchMap;
    return AssistantMessage(
      id: _patchMap.containsKey(AssistantMessage$.id)
          ? (_patchMap[AssistantMessage$.id] is Function)
                ? _patchMap[AssistantMessage$.id](this.id)
                : (_patchMap[AssistantMessage$.id] is Patch)
                ? _patchMap[AssistantMessage$.id].applyTo(this.id)
                : _patchMap[AssistantMessage$.id]
          : this.id,
      text: _patchMap.containsKey(AssistantMessage$.text)
          ? (_patchMap[AssistantMessage$.text] is Function)
                ? _patchMap[AssistantMessage$.text](this.text)
                : (_patchMap[AssistantMessage$.text] is Patch)
                ? _patchMap[AssistantMessage$.text].applyTo(this.text)
                : _patchMap[AssistantMessage$.text]
          : this.text,
      role: _patchMap.containsKey(AssistantMessage$.role)
          ? (_patchMap[AssistantMessage$.role] is Function)
                ? _patchMap[AssistantMessage$.role](this.role)
                : (_patchMap[AssistantMessage$.role] is Patch)
                ? _patchMap[AssistantMessage$.role].applyTo(this.role)
                : _patchMap[AssistantMessage$.role]
          : this.role,
      createdAt: _patchMap.containsKey(AssistantMessage$.createdAt)
          ? (_patchMap[AssistantMessage$.createdAt] is Function)
                ? _patchMap[AssistantMessage$.createdAt](this.createdAt)
                : (_patchMap[AssistantMessage$.createdAt] is Patch)
                ? _patchMap[AssistantMessage$.createdAt].applyTo(this.createdAt)
                : _patchMap[AssistantMessage$.createdAt]
          : this.createdAt,
      attachments: _patchMap.containsKey(AssistantMessage$.attachments)
          ? (_patchMap[AssistantMessage$.attachments] is Function)
                ? _patchMap[AssistantMessage$.attachments](this.attachments)
                : (_patchMap[AssistantMessage$.attachments] is Patch)
                ? _patchMap[AssistantMessage$.attachments].applyTo(
                    this.attachments,
                  )
                : _patchMap[AssistantMessage$.attachments]
          : this.attachments,
      updatedAt: _patchMap.containsKey(AssistantMessage$.updatedAt)
          ? (_patchMap[AssistantMessage$.updatedAt] is Function)
                ? _patchMap[AssistantMessage$.updatedAt](this.updatedAt)
                : (_patchMap[AssistantMessage$.updatedAt] is Patch)
                ? _patchMap[AssistantMessage$.updatedAt].applyTo(this.updatedAt)
                : _patchMap[AssistantMessage$.updatedAt]
          : this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssistantMessage &&
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
    return 'AssistantMessage(' +
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

  /// Creates a [AssistantMessage] instance from JSON
  factory AssistantMessage.fromJson(Map<String, dynamic> json) =>
      _$AssistantMessageFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AssistantMessageToJson(this);
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

extension AssistantMessagePropertyHelpers on AssistantMessage {
  bool get isRoleUser => role == ChatMessageRole.user;
  bool get isRoleAssistant => role == ChatMessageRole.assistant;
  bool get isRoleSystem => role == ChatMessageRole.system;
}

extension AssistantMessageSerialization on AssistantMessage {
  Map<String, dynamic> toJson() => _$AssistantMessageToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AssistantMessageToJson(this);
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

enum AssistantMessage$ { id, text, role, createdAt, attachments, updatedAt }

class AssistantMessagePatch
    extends PatchBase<AssistantMessage, AssistantMessage$> {
  AssistantMessage applyTo(AssistantMessage entity) {
    return entity.patchWithAssistantMessage(patchInput: this);
  }

  AssistantMessagePatch withId(String? value) {
    patchMap[AssistantMessage$.id] = value;
    return this;
  }

  AssistantMessagePatch withText(String? value) {
    patchMap[AssistantMessage$.text] = value;
    return this;
  }

  AssistantMessagePatch withRole(ChatMessageRole? value) {
    patchMap[AssistantMessage$.role] = value;
    return this;
  }

  AssistantMessagePatch withCreatedAt(DateTime? value) {
    patchMap[AssistantMessage$.createdAt] = value;
    return this;
  }

  AssistantMessagePatch withAttachments(List<Attachment>? value) {
    patchMap[AssistantMessage$.attachments] = value;
    return this;
  }

  AssistantMessagePatch withUpdatedAt(DateTime? value) {
    patchMap[AssistantMessage$.updatedAt] = value;
    return this;
  }
}

/// Field descriptors for [AssistantMessage] query construction
abstract final class AssistantMessageFields {
  static String? _$getid(AssistantMessage e) => e.id;
  static const id = Field<AssistantMessage, String?>('id', _$getid);
  static String _$gettext(AssistantMessage e) => e.text;
  static const text = Field<AssistantMessage, String>('text', _$gettext);
  static ChatMessageRole _$getrole(AssistantMessage e) => e.role;
  static const role = Field<AssistantMessage, ChatMessageRole>(
    'role',
    _$getrole,
  );
  static DateTime _$getcreatedAt(AssistantMessage e) => e.createdAt;
  static const createdAt = Field<AssistantMessage, DateTime>(
    'createdAt',
    _$getcreatedAt,
  );
  static List<Attachment>? _$getattachments(AssistantMessage e) =>
      e.attachments;
  static const attachments = Field<AssistantMessage, List<Attachment>?>(
    'attachments',
    _$getattachments,
  );
  static DateTime? _$getupdatedAt(AssistantMessage e) => e.updatedAt;
  static const updatedAt = Field<AssistantMessage, DateTime?>(
    'updatedAt',
    _$getupdatedAt,
  );
}

extension AssistantMessageCompareE on AssistantMessage {
  Map<String, dynamic> compareToAssistantMessage(AssistantMessage other) {
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
