// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'chat.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Chat {
  final String? id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Chat({
    this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    this.updatedAt,
  });

  Chat copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Chat copyWithChat({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return copyWith(
      id: id,
      title: title,
      messages: messages,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory Chat.create({required UserMessage message}) =>
      $Chat.create(message: message);

  Chat patchWithChat({ChatPatch? patchInput}) {
    final _patcher = patchInput ?? ChatPatch();
    final _patchMap = _patcher.patchMap;
    return Chat(
      id: _patchMap.containsKey(Chat$.id)
          ? (_patchMap[Chat$.id] is Function)
                ? _patchMap[Chat$.id](this.id)
                : (_patchMap[Chat$.id] is Patch)
                ? _patchMap[Chat$.id].applyTo(this.id)
                : _patchMap[Chat$.id]
          : this.id,
      title: _patchMap.containsKey(Chat$.title)
          ? (_patchMap[Chat$.title] is Function)
                ? _patchMap[Chat$.title](this.title)
                : (_patchMap[Chat$.title] is Patch)
                ? _patchMap[Chat$.title].applyTo(this.title)
                : _patchMap[Chat$.title]
          : this.title,
      messages: _patchMap.containsKey(Chat$.messages)
          ? (_patchMap[Chat$.messages] is Function)
                ? _patchMap[Chat$.messages](this.messages)
                : (_patchMap[Chat$.messages] is Patch)
                ? _patchMap[Chat$.messages].applyTo(this.messages)
                : _patchMap[Chat$.messages]
          : this.messages,
      createdAt: _patchMap.containsKey(Chat$.createdAt)
          ? (_patchMap[Chat$.createdAt] is Function)
                ? _patchMap[Chat$.createdAt](this.createdAt)
                : (_patchMap[Chat$.createdAt] is Patch)
                ? _patchMap[Chat$.createdAt].applyTo(this.createdAt)
                : _patchMap[Chat$.createdAt]
          : this.createdAt,
      updatedAt: _patchMap.containsKey(Chat$.updatedAt)
          ? (_patchMap[Chat$.updatedAt] is Function)
                ? _patchMap[Chat$.updatedAt](this.updatedAt)
                : (_patchMap[Chat$.updatedAt] is Patch)
                ? _patchMap[Chat$.updatedAt].applyTo(this.updatedAt)
                : _patchMap[Chat$.updatedAt]
          : this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat &&
        id == other.id &&
        title == other.title &&
        messages == other.messages &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.title,
      this.messages,
      this.createdAt,
      this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Chat(' +
        'id: ${id}' +
        ', ' +
        'title: ${title}' +
        ', ' +
        'messages: ${messages}' +
        ', ' +
        'createdAt: ${createdAt}' +
        ', ' +
        'updatedAt: ${updatedAt})';
  }

  /// Creates a [Chat] instance from JSON
  factory Chat.fromJson(Map<String, dynamic> json) => _$ChatFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ChatToJson(this);
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

extension ChatPropertyHelpers on Chat {
  bool get hasId => id?.isNotEmpty == true;
  bool get noId => id?.isEmpty ?? true;
  String get idRequired =>
      id ?? (throw StateError('id is required but was null'));
  bool get hasTitle => title.isNotEmpty;
  bool get noTitle => title.isEmpty;
  bool get hasMessages => messages.isNotEmpty;
  bool get noMessages => messages.isEmpty;
  bool get hasUpdatedAt => updatedAt != null;
  bool get noUpdatedAt => updatedAt == null;
  DateTime get updatedAtRequired =>
      updatedAt ?? (throw StateError('updatedAt is required but was null'));
}

extension ChatSerialization on Chat {
  Map<String, dynamic> toJson() => _$ChatToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ChatToJson(this);
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

enum Chat$ { id, title, messages, createdAt, updatedAt }

class ChatPatch extends PatchBase<Chat, Chat$> {
  Chat applyTo(Chat entity) {
    return entity.patchWithChat(patchInput: this);
  }

  ChatPatch withId(String? value) {
    patchMap[Chat$.id] = value;
    return this;
  }

  ChatPatch withTitle(String? value) {
    patchMap[Chat$.title] = value;
    return this;
  }

  ChatPatch withMessages(List<ChatMessage>? value) {
    patchMap[Chat$.messages] = value;
    return this;
  }

  ChatPatch withCreatedAt(DateTime? value) {
    patchMap[Chat$.createdAt] = value;
    return this;
  }

  ChatPatch withUpdatedAt(DateTime? value) {
    patchMap[Chat$.updatedAt] = value;
    return this;
  }
}

/// Field descriptors for [Chat] query construction
abstract final class ChatFields {
  static String? _$getid(Chat e) => e.id;
  static const id = Field<Chat, String?>('id', _$getid);
  static String _$gettitle(Chat e) => e.title;
  static const title = Field<Chat, String>('title', _$gettitle);
  static List<ChatMessage> _$getmessages(Chat e) => e.messages;
  static const messages = Field<Chat, List<ChatMessage>>(
    'messages',
    _$getmessages,
  );
  static DateTime _$getcreatedAt(Chat e) => e.createdAt;
  static const createdAt = Field<Chat, DateTime>('createdAt', _$getcreatedAt);
  static DateTime? _$getupdatedAt(Chat e) => e.updatedAt;
  static const updatedAt = Field<Chat, DateTime?>('updatedAt', _$getupdatedAt);
}

extension ChatCompareE on Chat {
  Map<String, dynamic> compareToChat(Chat other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (messages != other.messages) {
      diff['messages'] = () => other.messages;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (updatedAt != other.updatedAt) {
      diff['updatedAt'] = () => other.updatedAt;
    }
    return diff;
  }
}
