// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex60_nonsealed_methods_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class ChatMessage extends $ChatMessage {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final String conversationId;
  @override
  final String? content;

  ChatMessage({
    required this.id,
    required this.createdAt,
    required this.conversationId,
    this.content,
  });

  ChatMessage copyWith({
    String? id,
    DateTime? createdAt,
    String? conversationId,
    String? content,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
    );
  }

  ChatMessage copyWithChatMessage({
    String? id,
    DateTime? createdAt,
    String? conversationId,
    String? content,
  }) {
    return copyWith(
      id: id,
      createdAt: createdAt,
      conversationId: conversationId,
      content: content,
    );
  }

  ChatMessage patchWithChatMessage({ChatMessagePatch? patchInput}) {
    final _patcher = patchInput ?? ChatMessagePatch();
    final _patchMap = _patcher.toPatch();
    return ChatMessage(
      id: _patchMap.containsKey(ChatMessage$.id)
          ? (_patchMap[ChatMessage$.id] is Function)
                ? _patchMap[ChatMessage$.id](this.id)
                : _patchMap[ChatMessage$.id]
          : this.id,
      createdAt: _patchMap.containsKey(ChatMessage$.createdAt)
          ? (_patchMap[ChatMessage$.createdAt] is Function)
                ? _patchMap[ChatMessage$.createdAt](this.createdAt)
                : _patchMap[ChatMessage$.createdAt]
          : this.createdAt,
      conversationId: _patchMap.containsKey(ChatMessage$.conversationId)
          ? (_patchMap[ChatMessage$.conversationId] is Function)
                ? _patchMap[ChatMessage$.conversationId](this.conversationId)
                : _patchMap[ChatMessage$.conversationId]
          : this.conversationId,
      content: _patchMap.containsKey(ChatMessage$.content)
          ? (_patchMap[ChatMessage$.content] is Function)
                ? _patchMap[ChatMessage$.content](this.content)
                : _patchMap[ChatMessage$.content]
          : this.content,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage &&
        id == other.id &&
        createdAt == other.createdAt &&
        conversationId == other.conversationId &&
        content == other.content;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.createdAt,
      this.conversationId,
      this.content,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(' +
        'id: ${id}' +
        ', ' +
        'createdAt: ${createdAt}' +
        ', ' +
        'conversationId: ${conversationId}' +
        ', ' +
        'content: ${content})';
  }
}

enum ChatMessage$ { id, createdAt, conversationId, content }

class ChatMessagePatch implements Patch<ChatMessage> {
  final Map<ChatMessage$, dynamic> _patch = {};

  static ChatMessagePatch create([Map<String, dynamic>? diff]) {
    final patch = ChatMessagePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = ChatMessage$.values.firstWhere(
            (e) => e.name == key,
          );
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static ChatMessagePatch fromPatch(Map<ChatMessage$, dynamic> patch) {
    final _patch = ChatMessagePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<ChatMessage$, dynamic> toPatch() => Map.from(_patch);

  ChatMessage applyTo(ChatMessage entity) {
    return entity.patchWithChatMessage(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if (value?.toJsonLean != null) return value.toJsonLean();
    } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static ChatMessagePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ChatMessagePatch withId(String? value) {
    _patch[ChatMessage$.id] = value;
    return this;
  }

  ChatMessagePatch withCreatedAt(DateTime? value) {
    _patch[ChatMessage$.createdAt] = value;
    return this;
  }

  ChatMessagePatch withConversationId(String? value) {
    _patch[ChatMessage$.conversationId] = value;
    return this;
  }

  ChatMessagePatch withContent(String? value) {
    _patch[ChatMessage$.content] = value;
    return this;
  }
}

extension ChatMessageCompareE on ChatMessage {
  Map<String, dynamic> compareToChatMessage(ChatMessage other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (conversationId != other.conversationId) {
      diff['conversationId'] = () => other.conversationId;
    }
    if (content != other.content) {
      diff['content'] = () => other.content;
    }
    return diff;
  }
}

class SystemMessage extends $$SystemMessage implements ChatMessage {
  @override
  final String id;
  @override
  final DateTime createdAt;
  @override
  final String conversationId;
  @override
  final String? content;
  @override
  final String? systemType;
  @override
  final String? metadata;

  SystemMessage({
    required this.id,
    required this.createdAt,
    required this.conversationId,
    this.content,
    this.systemType,
    this.metadata,
  });

  SystemMessage copyWith({
    String? id,
    DateTime? createdAt,
    String? conversationId,
    String? content,
    String? systemType,
    String? metadata,
  }) {
    return SystemMessage(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      systemType: systemType ?? this.systemType,
      metadata: metadata ?? this.metadata,
    );
  }

  SystemMessage copyWithSystemMessage({
    String? id,
    DateTime? createdAt,
    String? conversationId,
    String? content,
    String? systemType,
    String? metadata,
  }) {
    return copyWith(
      id: id,
      createdAt: createdAt,
      conversationId: conversationId,
      content: content,
      systemType: systemType,
      metadata: metadata,
    );
  }

  SystemMessage patchWithSystemMessage({SystemMessagePatch? patchInput}) {
    final _patcher = patchInput ?? SystemMessagePatch();
    final _patchMap = _patcher.toPatch();
    return SystemMessage(
      id: _patchMap.containsKey(SystemMessage$.id)
          ? (_patchMap[SystemMessage$.id] is Function)
                ? _patchMap[SystemMessage$.id](this.id)
                : _patchMap[SystemMessage$.id]
          : this.id,
      createdAt: _patchMap.containsKey(SystemMessage$.createdAt)
          ? (_patchMap[SystemMessage$.createdAt] is Function)
                ? _patchMap[SystemMessage$.createdAt](this.createdAt)
                : _patchMap[SystemMessage$.createdAt]
          : this.createdAt,
      conversationId: _patchMap.containsKey(SystemMessage$.conversationId)
          ? (_patchMap[SystemMessage$.conversationId] is Function)
                ? _patchMap[SystemMessage$.conversationId](this.conversationId)
                : _patchMap[SystemMessage$.conversationId]
          : this.conversationId,
      content: _patchMap.containsKey(SystemMessage$.content)
          ? (_patchMap[SystemMessage$.content] is Function)
                ? _patchMap[SystemMessage$.content](this.content)
                : _patchMap[SystemMessage$.content]
          : this.content,
      systemType: _patchMap.containsKey(SystemMessage$.systemType)
          ? (_patchMap[SystemMessage$.systemType] is Function)
                ? _patchMap[SystemMessage$.systemType](this.systemType)
                : _patchMap[SystemMessage$.systemType]
          : this.systemType,
      metadata: _patchMap.containsKey(SystemMessage$.metadata)
          ? (_patchMap[SystemMessage$.metadata] is Function)
                ? _patchMap[SystemMessage$.metadata](this.metadata)
                : _patchMap[SystemMessage$.metadata]
          : this.metadata,
    );
  }

  SystemMessage copyWithChatMessage({
    String? id,
    DateTime? createdAt,
    String? conversationId,
    String? content,
  }) {
    return copyWith(
      id: id,
      createdAt: createdAt,
      conversationId: conversationId,
      content: content,
    );
  }

  SystemMessage patchWithChatMessage({ChatMessagePatch? patchInput}) {
    final _patcher = patchInput ?? ChatMessagePatch();
    final _patchMap = _patcher.toPatch();
    return SystemMessage(
      id: _patchMap.containsKey(ChatMessage$.id)
          ? (_patchMap[ChatMessage$.id] is Function)
                ? _patchMap[ChatMessage$.id](this.id)
                : _patchMap[ChatMessage$.id]
          : this.id,
      createdAt: _patchMap.containsKey(ChatMessage$.createdAt)
          ? (_patchMap[ChatMessage$.createdAt] is Function)
                ? _patchMap[ChatMessage$.createdAt](this.createdAt)
                : _patchMap[ChatMessage$.createdAt]
          : this.createdAt,
      conversationId: _patchMap.containsKey(ChatMessage$.conversationId)
          ? (_patchMap[ChatMessage$.conversationId] is Function)
                ? _patchMap[ChatMessage$.conversationId](this.conversationId)
                : _patchMap[ChatMessage$.conversationId]
          : this.conversationId,
      content: _patchMap.containsKey(ChatMessage$.content)
          ? (_patchMap[ChatMessage$.content] is Function)
                ? _patchMap[ChatMessage$.content](this.content)
                : _patchMap[ChatMessage$.content]
          : this.content,
      systemType: this.systemType,
      metadata: this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SystemMessage &&
        id == other.id &&
        createdAt == other.createdAt &&
        conversationId == other.conversationId &&
        content == other.content &&
        systemType == other.systemType &&
        metadata == other.metadata;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.createdAt,
      this.conversationId,
      this.content,
      this.systemType,
      this.metadata,
    );
  }

  @override
  String toString() {
    return 'SystemMessage(' +
        'id: ${id}' +
        ', ' +
        'createdAt: ${createdAt}' +
        ', ' +
        'conversationId: ${conversationId}' +
        ', ' +
        'content: ${content}' +
        ', ' +
        'systemType: ${systemType}' +
        ', ' +
        'metadata: ${metadata})';
  }
}

enum SystemMessage$ {
  id,
  createdAt,
  conversationId,
  content,
  systemType,
  metadata,
}

class SystemMessagePatch implements Patch<SystemMessage> {
  final Map<SystemMessage$, dynamic> _patch = {};

  static SystemMessagePatch create([Map<String, dynamic>? diff]) {
    final patch = SystemMessagePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = SystemMessage$.values.firstWhere(
            (e) => e.name == key,
          );
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static SystemMessagePatch fromPatch(Map<SystemMessage$, dynamic> patch) {
    final _patch = SystemMessagePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<SystemMessage$, dynamic> toPatch() => Map.from(_patch);

  SystemMessage applyTo(SystemMessage entity) {
    return entity.patchWithSystemMessage(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if (value?.toJsonLean != null) return value.toJsonLean();
    } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static SystemMessagePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  SystemMessagePatch withId(String? value) {
    _patch[SystemMessage$.id] = value;
    return this;
  }

  SystemMessagePatch withCreatedAt(DateTime? value) {
    _patch[SystemMessage$.createdAt] = value;
    return this;
  }

  SystemMessagePatch withConversationId(String? value) {
    _patch[SystemMessage$.conversationId] = value;
    return this;
  }

  SystemMessagePatch withContent(String? value) {
    _patch[SystemMessage$.content] = value;
    return this;
  }

  SystemMessagePatch withSystemType(String? value) {
    _patch[SystemMessage$.systemType] = value;
    return this;
  }

  SystemMessagePatch withMetadata(String? value) {
    _patch[SystemMessage$.metadata] = value;
    return this;
  }
}

extension SystemMessageCompareE on SystemMessage {
  Map<String, dynamic> compareToSystemMessage(SystemMessage other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (conversationId != other.conversationId) {
      diff['conversationId'] = () => other.conversationId;
    }
    if (content != other.content) {
      diff['content'] = () => other.content;
    }
    if (systemType != other.systemType) {
      diff['systemType'] = () => other.systemType;
    }
    if (metadata != other.metadata) {
      diff['metadata'] = () => other.metadata;
    }
    return diff;
  }
}

class SparkMessage implements $$SystemMessage {
  final String? systemType;
  final String? metadata;
  final String id;
  final DateTime createdAt;
  final String conversationId;
  final String? content;
  final String spark;

  SparkMessage({
    this.systemType,
    this.metadata,
    required this.id,
    required this.createdAt,
    required this.conversationId,
    this.content,
    required this.spark,
  });

  SparkMessage copyWith({
    String? systemType,
    String? metadata,
    String? id,
    DateTime? createdAt,
    String? conversationId,
    String? content,
    String? spark,
  }) {
    return SparkMessage(
      systemType: systemType ?? this.systemType,
      metadata: metadata ?? this.metadata,
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      conversationId: conversationId ?? this.conversationId,
      content: content ?? this.content,
      spark: spark ?? this.spark,
    );
  }

  SparkMessage copyWithSparkMessage({
    String? systemType,
    String? metadata,
    String? id,
    DateTime? createdAt,
    String? conversationId,
    String? content,
    String? spark,
  }) {
    return copyWith(
      systemType: systemType,
      metadata: metadata,
      id: id,
      createdAt: createdAt,
      conversationId: conversationId,
      content: content,
      spark: spark,
    );
  }

  SparkMessage patchWithSparkMessage({SparkMessagePatch? patchInput}) {
    final _patcher = patchInput ?? SparkMessagePatch();
    final _patchMap = _patcher.toPatch();
    return SparkMessage(
      systemType: _patchMap.containsKey(SparkMessage$.systemType)
          ? (_patchMap[SparkMessage$.systemType] is Function)
                ? _patchMap[SparkMessage$.systemType](this.systemType)
                : _patchMap[SparkMessage$.systemType]
          : this.systemType,
      metadata: _patchMap.containsKey(SparkMessage$.metadata)
          ? (_patchMap[SparkMessage$.metadata] is Function)
                ? _patchMap[SparkMessage$.metadata](this.metadata)
                : _patchMap[SparkMessage$.metadata]
          : this.metadata,
      id: _patchMap.containsKey(SparkMessage$.id)
          ? (_patchMap[SparkMessage$.id] is Function)
                ? _patchMap[SparkMessage$.id](this.id)
                : _patchMap[SparkMessage$.id]
          : this.id,
      createdAt: _patchMap.containsKey(SparkMessage$.createdAt)
          ? (_patchMap[SparkMessage$.createdAt] is Function)
                ? _patchMap[SparkMessage$.createdAt](this.createdAt)
                : _patchMap[SparkMessage$.createdAt]
          : this.createdAt,
      conversationId: _patchMap.containsKey(SparkMessage$.conversationId)
          ? (_patchMap[SparkMessage$.conversationId] is Function)
                ? _patchMap[SparkMessage$.conversationId](this.conversationId)
                : _patchMap[SparkMessage$.conversationId]
          : this.conversationId,
      content: _patchMap.containsKey(SparkMessage$.content)
          ? (_patchMap[SparkMessage$.content] is Function)
                ? _patchMap[SparkMessage$.content](this.content)
                : _patchMap[SparkMessage$.content]
          : this.content,
      spark: _patchMap.containsKey(SparkMessage$.spark)
          ? (_patchMap[SparkMessage$.spark] is Function)
                ? _patchMap[SparkMessage$.spark](this.spark)
                : _patchMap[SparkMessage$.spark]
          : this.spark,
    );
  }

  SparkMessage copyWithChatMessage({
    String? id,
    DateTime? createdAt,
    String? conversationId,
    String? content,
  }) {
    return copyWith(
      id: id,
      createdAt: createdAt,
      conversationId: conversationId,
      content: content,
    );
  }

  SparkMessage patchWithChatMessage({ChatMessagePatch? patchInput}) {
    final _patcher = patchInput ?? ChatMessagePatch();
    final _patchMap = _patcher.toPatch();
    return SparkMessage(
      systemType: this.systemType,
      metadata: this.metadata,
      id: _patchMap.containsKey(ChatMessage$.id)
          ? (_patchMap[ChatMessage$.id] is Function)
                ? _patchMap[ChatMessage$.id](this.id)
                : _patchMap[ChatMessage$.id]
          : this.id,
      createdAt: _patchMap.containsKey(ChatMessage$.createdAt)
          ? (_patchMap[ChatMessage$.createdAt] is Function)
                ? _patchMap[ChatMessage$.createdAt](this.createdAt)
                : _patchMap[ChatMessage$.createdAt]
          : this.createdAt,
      conversationId: _patchMap.containsKey(ChatMessage$.conversationId)
          ? (_patchMap[ChatMessage$.conversationId] is Function)
                ? _patchMap[ChatMessage$.conversationId](this.conversationId)
                : _patchMap[ChatMessage$.conversationId]
          : this.conversationId,
      content: _patchMap.containsKey(ChatMessage$.content)
          ? (_patchMap[ChatMessage$.content] is Function)
                ? _patchMap[ChatMessage$.content](this.content)
                : _patchMap[ChatMessage$.content]
          : this.content,
      spark: this.spark,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SparkMessage &&
        systemType == other.systemType &&
        metadata == other.metadata &&
        id == other.id &&
        createdAt == other.createdAt &&
        conversationId == other.conversationId &&
        content == other.content &&
        spark == other.spark;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.systemType,
      this.metadata,
      this.id,
      this.createdAt,
      this.conversationId,
      this.content,
      this.spark,
    );
  }

  @override
  String toString() {
    return 'SparkMessage(' +
        'systemType: ${systemType}' +
        ', ' +
        'metadata: ${metadata}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'createdAt: ${createdAt}' +
        ', ' +
        'conversationId: ${conversationId}' +
        ', ' +
        'content: ${content}' +
        ', ' +
        'spark: ${spark})';
  }
}

enum SparkMessage$ {
  systemType,
  metadata,
  id,
  createdAt,
  conversationId,
  content,
  spark,
}

class SparkMessagePatch implements Patch<SparkMessage> {
  final Map<SparkMessage$, dynamic> _patch = {};

  static SparkMessagePatch create([Map<String, dynamic>? diff]) {
    final patch = SparkMessagePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = SparkMessage$.values.firstWhere(
            (e) => e.name == key,
          );
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static SparkMessagePatch fromPatch(Map<SparkMessage$, dynamic> patch) {
    final _patch = SparkMessagePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<SparkMessage$, dynamic> toPatch() => Map.from(_patch);

  SparkMessage applyTo(SparkMessage entity) {
    return entity.patchWithSparkMessage(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if (value?.toJsonLean != null) return value.toJsonLean();
    } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static SparkMessagePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  SparkMessagePatch withSystemType(String? value) {
    _patch[SparkMessage$.systemType] = value;
    return this;
  }

  SparkMessagePatch withMetadata(String? value) {
    _patch[SparkMessage$.metadata] = value;
    return this;
  }

  SparkMessagePatch withId(String? value) {
    _patch[SparkMessage$.id] = value;
    return this;
  }

  SparkMessagePatch withCreatedAt(DateTime? value) {
    _patch[SparkMessage$.createdAt] = value;
    return this;
  }

  SparkMessagePatch withConversationId(String? value) {
    _patch[SparkMessage$.conversationId] = value;
    return this;
  }

  SparkMessagePatch withContent(String? value) {
    _patch[SparkMessage$.content] = value;
    return this;
  }

  SparkMessagePatch withSpark(String? value) {
    _patch[SparkMessage$.spark] = value;
    return this;
  }
}

extension SparkMessageCompareE on SparkMessage {
  Map<String, dynamic> compareToSparkMessage(SparkMessage other) {
    final Map<String, dynamic> diff = {};

    if (systemType != other.systemType) {
      diff['systemType'] = () => other.systemType;
    }
    if (metadata != other.metadata) {
      diff['metadata'] = () => other.metadata;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (conversationId != other.conversationId) {
      diff['conversationId'] = () => other.conversationId;
    }
    if (content != other.content) {
      diff['content'] = () => other.content;
    }
    if (spark != other.spark) {
      diff['spark'] = () => other.spark;
    }
    return diff;
  }
}
