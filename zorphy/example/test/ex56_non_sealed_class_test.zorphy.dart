// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex56_non_sealed_class_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

///we can specify our abstract classes are abastract and non sealed
///this means the exhaustiveness checking in switch statements differs
class Todo2 extends $$Todo2 {
  @override
  final String title;
  @override
  final String id;
  @override
  final String description;

  Todo2({required this.title, required this.id, required this.description});

  Todo2 copyWith({String? title, String? id, String? description}) {
    return Todo2(
      title: title ?? this.title,
      id: id ?? this.id,
      description: description ?? this.description,
    );
  }

  Todo2 copyWithTodo2({String? title, String? id, String? description}) {
    return copyWith(title: title, id: id, description: description);
  }

  Todo2 patchWithTodo2({Todo2Patch? patchInput}) {
    final _patcher = patchInput ?? Todo2Patch();
    final _patchMap = _patcher.toPatch();
    return Todo2(
      title: _patchMap.containsKey(Todo2$.title)
          ? (_patchMap[Todo2$.title] is Function)
                ? _patchMap[Todo2$.title](this.title)
                : _patchMap[Todo2$.title]
          : this.title,
      id: _patchMap.containsKey(Todo2$.id)
          ? (_patchMap[Todo2$.id] is Function)
                ? _patchMap[Todo2$.id](this.id)
                : _patchMap[Todo2$.id]
          : this.id,
      description: _patchMap.containsKey(Todo2$.description)
          ? (_patchMap[Todo2$.description] is Function)
                ? _patchMap[Todo2$.description](this.description)
                : _patchMap[Todo2$.description]
          : this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo2 &&
        title == other.title &&
        id == other.id &&
        description == other.description;
  }

  @override
  int get hashCode {
    return Object.hash(this.title, this.id, this.description);
  }

  @override
  String toString() {
    return 'Todo2(' +
        'title: ${title}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'description: ${description})';
  }
}

enum Todo2$ { title, id, description }

class Todo2Patch implements Patch<Todo2> {
  final Map<Todo2$, dynamic> _patch = {};

  static Todo2Patch create([Map<String, dynamic>? diff]) {
    final patch = Todo2Patch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Todo2$.values.firstWhere((e) => e.name == key);
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

  static Todo2Patch fromPatch(Map<Todo2$, dynamic> patch) {
    final _patch = Todo2Patch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Todo2$, dynamic> toPatch() => Map.from(_patch);

  Todo2 applyTo(Todo2 entity) {
    return entity.patchWithTodo2(patchInput: this);
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

  static Todo2Patch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  Todo2Patch withTitle(String? value) {
    _patch[Todo2$.title] = value;
    return this;
  }

  Todo2Patch withId(String? value) {
    _patch[Todo2$.id] = value;
    return this;
  }

  Todo2Patch withDescription(String? value) {
    _patch[Todo2$.description] = value;
    return this;
  }
}

extension Todo2CompareE on Todo2 {
  Map<String, dynamic> compareToTodo2(Todo2 other) {
    final Map<String, dynamic> diff = {};

    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (description != other.description) {
      diff['description'] = () => other.description;
    }
    return diff;
  }
}

class Todo2_incomplete implements $$Todo2 {
  final String title;
  final String id;
  final String description;

  Todo2_incomplete({
    required this.title,
    required this.id,
    required this.description,
  });

  Todo2_incomplete copyWith({String? title, String? id, String? description}) {
    return Todo2_incomplete(
      title: title ?? this.title,
      id: id ?? this.id,
      description: description ?? this.description,
    );
  }

  Todo2_incomplete copyWithTodo2_incomplete({
    String? title,
    String? id,
    String? description,
  }) {
    return copyWith(title: title, id: id, description: description);
  }

  Todo2_incomplete patchWithTodo2_incomplete({
    Todo2_incompletePatch? patchInput,
  }) {
    final _patcher = patchInput ?? Todo2_incompletePatch();
    final _patchMap = _patcher.toPatch();
    return Todo2_incomplete(
      title: _patchMap.containsKey(Todo2_incomplete$.title)
          ? (_patchMap[Todo2_incomplete$.title] is Function)
                ? _patchMap[Todo2_incomplete$.title](this.title)
                : _patchMap[Todo2_incomplete$.title]
          : this.title,
      id: _patchMap.containsKey(Todo2_incomplete$.id)
          ? (_patchMap[Todo2_incomplete$.id] is Function)
                ? _patchMap[Todo2_incomplete$.id](this.id)
                : _patchMap[Todo2_incomplete$.id]
          : this.id,
      description: _patchMap.containsKey(Todo2_incomplete$.description)
          ? (_patchMap[Todo2_incomplete$.description] is Function)
                ? _patchMap[Todo2_incomplete$.description](this.description)
                : _patchMap[Todo2_incomplete$.description]
          : this.description,
    );
  }

  Todo2_incomplete copyWithTodo2({
    String? title,
    String? id,
    String? description,
  }) {
    return copyWith(title: title, id: id, description: description);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo2_incomplete &&
        title == other.title &&
        id == other.id &&
        description == other.description;
  }

  @override
  int get hashCode {
    return Object.hash(this.title, this.id, this.description);
  }

  @override
  String toString() {
    return 'Todo2_incomplete(' +
        'title: ${title}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'description: ${description})';
  }
}

enum Todo2_incomplete$ { title, id, description }

class Todo2_incompletePatch implements Patch<Todo2_incomplete> {
  final Map<Todo2_incomplete$, dynamic> _patch = {};

  static Todo2_incompletePatch create([Map<String, dynamic>? diff]) {
    final patch = Todo2_incompletePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Todo2_incomplete$.values.firstWhere(
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

  static Todo2_incompletePatch fromPatch(
    Map<Todo2_incomplete$, dynamic> patch,
  ) {
    final _patch = Todo2_incompletePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Todo2_incomplete$, dynamic> toPatch() => Map.from(_patch);

  Todo2_incomplete applyTo(Todo2_incomplete entity) {
    return entity.patchWithTodo2_incomplete(patchInput: this);
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

  static Todo2_incompletePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  Todo2_incompletePatch withTitle(String? value) {
    _patch[Todo2_incomplete$.title] = value;
    return this;
  }

  Todo2_incompletePatch withId(String? value) {
    _patch[Todo2_incomplete$.id] = value;
    return this;
  }

  Todo2_incompletePatch withDescription(String? value) {
    _patch[Todo2_incomplete$.description] = value;
    return this;
  }
}

extension Todo2_incompleteCompareE on Todo2_incomplete {
  Map<String, dynamic> compareToTodo2_incomplete(Todo2_incomplete other) {
    final Map<String, dynamic> diff = {};

    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (description != other.description) {
      diff['description'] = () => other.description;
    }
    return diff;
  }
}

class Todo2_complete implements $$Todo2 {
  final String title;
  final String id;
  final String description;
  final DateTime completedDate;

  Todo2_complete({
    required this.title,
    required this.id,
    required this.description,
    required this.completedDate,
  });

  Todo2_complete copyWith({
    String? title,
    String? id,
    String? description,
    DateTime? completedDate,
  }) {
    return Todo2_complete(
      title: title ?? this.title,
      id: id ?? this.id,
      description: description ?? this.description,
      completedDate: completedDate ?? this.completedDate,
    );
  }

  Todo2_complete copyWithTodo2_complete({
    String? title,
    String? id,
    String? description,
    DateTime? completedDate,
  }) {
    return copyWith(
      title: title,
      id: id,
      description: description,
      completedDate: completedDate,
    );
  }

  Todo2_complete patchWithTodo2_complete({Todo2_completePatch? patchInput}) {
    final _patcher = patchInput ?? Todo2_completePatch();
    final _patchMap = _patcher.toPatch();
    return Todo2_complete(
      title: _patchMap.containsKey(Todo2_complete$.title)
          ? (_patchMap[Todo2_complete$.title] is Function)
                ? _patchMap[Todo2_complete$.title](this.title)
                : _patchMap[Todo2_complete$.title]
          : this.title,
      id: _patchMap.containsKey(Todo2_complete$.id)
          ? (_patchMap[Todo2_complete$.id] is Function)
                ? _patchMap[Todo2_complete$.id](this.id)
                : _patchMap[Todo2_complete$.id]
          : this.id,
      description: _patchMap.containsKey(Todo2_complete$.description)
          ? (_patchMap[Todo2_complete$.description] is Function)
                ? _patchMap[Todo2_complete$.description](this.description)
                : _patchMap[Todo2_complete$.description]
          : this.description,
      completedDate: _patchMap.containsKey(Todo2_complete$.completedDate)
          ? (_patchMap[Todo2_complete$.completedDate] is Function)
                ? _patchMap[Todo2_complete$.completedDate](this.completedDate)
                : _patchMap[Todo2_complete$.completedDate]
          : this.completedDate,
    );
  }

  Todo2_complete copyWithTodo2({
    String? title,
    String? id,
    String? description,
  }) {
    return copyWith(title: title, id: id, description: description);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo2_complete &&
        title == other.title &&
        id == other.id &&
        description == other.description &&
        completedDate == other.completedDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.title,
      this.id,
      this.description,
      this.completedDate,
    );
  }

  @override
  String toString() {
    return 'Todo2_complete(' +
        'title: ${title}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'description: ${description}' +
        ', ' +
        'completedDate: ${completedDate})';
  }
}

enum Todo2_complete$ { title, id, description, completedDate }

class Todo2_completePatch implements Patch<Todo2_complete> {
  final Map<Todo2_complete$, dynamic> _patch = {};

  static Todo2_completePatch create([Map<String, dynamic>? diff]) {
    final patch = Todo2_completePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Todo2_complete$.values.firstWhere(
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

  static Todo2_completePatch fromPatch(Map<Todo2_complete$, dynamic> patch) {
    final _patch = Todo2_completePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Todo2_complete$, dynamic> toPatch() => Map.from(_patch);

  Todo2_complete applyTo(Todo2_complete entity) {
    return entity.patchWithTodo2_complete(patchInput: this);
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

  static Todo2_completePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  Todo2_completePatch withTitle(String? value) {
    _patch[Todo2_complete$.title] = value;
    return this;
  }

  Todo2_completePatch withId(String? value) {
    _patch[Todo2_complete$.id] = value;
    return this;
  }

  Todo2_completePatch withDescription(String? value) {
    _patch[Todo2_complete$.description] = value;
    return this;
  }

  Todo2_completePatch withCompletedDate(DateTime? value) {
    _patch[Todo2_complete$.completedDate] = value;
    return this;
  }
}

extension Todo2_completeCompareE on Todo2_complete {
  Map<String, dynamic> compareToTodo2_complete(Todo2_complete other) {
    final Map<String, dynamic> diff = {};

    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (description != other.description) {
      diff['description'] = () => other.description;
    }
    if (completedDate != other.completedDate) {
      diff['completedDate'] = () => other.completedDate;
    }
    return diff;
  }
}

class Todo2_complete_assigned implements $$Todo2 {
  final DateTime completedDate;
  final String title;
  final String id;
  final String description;
  final String managerId;

  Todo2_complete_assigned({
    required this.completedDate,
    required this.title,
    required this.id,
    required this.description,
    required this.managerId,
  });

  Todo2_complete_assigned copyWith({
    DateTime? completedDate,
    String? title,
    String? id,
    String? description,
    String? managerId,
  }) {
    return Todo2_complete_assigned(
      completedDate: completedDate ?? this.completedDate,
      title: title ?? this.title,
      id: id ?? this.id,
      description: description ?? this.description,
      managerId: managerId ?? this.managerId,
    );
  }

  Todo2_complete_assigned copyWithTodo2_complete_assigned({
    DateTime? completedDate,
    String? title,
    String? id,
    String? description,
    String? managerId,
  }) {
    return copyWith(
      completedDate: completedDate,
      title: title,
      id: id,
      description: description,
      managerId: managerId,
    );
  }

  Todo2_complete_assigned patchWithTodo2_complete_assigned({
    Todo2_complete_assignedPatch? patchInput,
  }) {
    final _patcher = patchInput ?? Todo2_complete_assignedPatch();
    final _patchMap = _patcher.toPatch();
    return Todo2_complete_assigned(
      completedDate:
          _patchMap.containsKey(Todo2_complete_assigned$.completedDate)
          ? (_patchMap[Todo2_complete_assigned$.completedDate] is Function)
                ? _patchMap[Todo2_complete_assigned$.completedDate](
                    this.completedDate,
                  )
                : _patchMap[Todo2_complete_assigned$.completedDate]
          : this.completedDate,
      title: _patchMap.containsKey(Todo2_complete_assigned$.title)
          ? (_patchMap[Todo2_complete_assigned$.title] is Function)
                ? _patchMap[Todo2_complete_assigned$.title](this.title)
                : _patchMap[Todo2_complete_assigned$.title]
          : this.title,
      id: _patchMap.containsKey(Todo2_complete_assigned$.id)
          ? (_patchMap[Todo2_complete_assigned$.id] is Function)
                ? _patchMap[Todo2_complete_assigned$.id](this.id)
                : _patchMap[Todo2_complete_assigned$.id]
          : this.id,
      description: _patchMap.containsKey(Todo2_complete_assigned$.description)
          ? (_patchMap[Todo2_complete_assigned$.description] is Function)
                ? _patchMap[Todo2_complete_assigned$.description](
                    this.description,
                  )
                : _patchMap[Todo2_complete_assigned$.description]
          : this.description,
      managerId: _patchMap.containsKey(Todo2_complete_assigned$.managerId)
          ? (_patchMap[Todo2_complete_assigned$.managerId] is Function)
                ? _patchMap[Todo2_complete_assigned$.managerId](this.managerId)
                : _patchMap[Todo2_complete_assigned$.managerId]
          : this.managerId,
    );
  }

  Todo2_complete_assigned copyWithTodo2_complete({DateTime? completedDate}) {
    return copyWith(completedDate: completedDate);
  }

  Todo2_complete_assigned copyWithTodo2({
    String? title,
    String? id,
    String? description,
  }) {
    return copyWith(title: title, id: id, description: description);
  }

  Todo2_complete_assigned patchWithTodo2_complete({
    Todo2_completePatch? patchInput,
  }) {
    final _patcher = patchInput ?? Todo2_completePatch();
    final _patchMap = _patcher.toPatch();
    return Todo2_complete_assigned(
      completedDate: _patchMap.containsKey(Todo2_complete$.completedDate)
          ? (_patchMap[Todo2_complete$.completedDate] is Function)
                ? _patchMap[Todo2_complete$.completedDate](this.completedDate)
                : _patchMap[Todo2_complete$.completedDate]
          : this.completedDate,
      title: this.title,
      id: this.id,
      description: this.description,
      managerId: this.managerId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Todo2_complete_assigned &&
        completedDate == other.completedDate &&
        title == other.title &&
        id == other.id &&
        description == other.description &&
        managerId == other.managerId;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.completedDate,
      this.title,
      this.id,
      this.description,
      this.managerId,
    );
  }

  @override
  String toString() {
    return 'Todo2_complete_assigned(' +
        'completedDate: ${completedDate}' +
        ', ' +
        'title: ${title}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'description: ${description}' +
        ', ' +
        'managerId: ${managerId})';
  }
}

enum Todo2_complete_assigned$ {
  completedDate,
  title,
  id,
  description,
  managerId,
}

class Todo2_complete_assignedPatch implements Patch<Todo2_complete_assigned> {
  final Map<Todo2_complete_assigned$, dynamic> _patch = {};

  static Todo2_complete_assignedPatch create([Map<String, dynamic>? diff]) {
    final patch = Todo2_complete_assignedPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Todo2_complete_assigned$.values.firstWhere(
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

  static Todo2_complete_assignedPatch fromPatch(
    Map<Todo2_complete_assigned$, dynamic> patch,
  ) {
    final _patch = Todo2_complete_assignedPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Todo2_complete_assigned$, dynamic> toPatch() => Map.from(_patch);

  Todo2_complete_assigned applyTo(Todo2_complete_assigned entity) {
    return entity.patchWithTodo2_complete_assigned(patchInput: this);
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

  static Todo2_complete_assignedPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  Todo2_complete_assignedPatch withCompletedDate(DateTime? value) {
    _patch[Todo2_complete_assigned$.completedDate] = value;
    return this;
  }

  Todo2_complete_assignedPatch withTitle(String? value) {
    _patch[Todo2_complete_assigned$.title] = value;
    return this;
  }

  Todo2_complete_assignedPatch withId(String? value) {
    _patch[Todo2_complete_assigned$.id] = value;
    return this;
  }

  Todo2_complete_assignedPatch withDescription(String? value) {
    _patch[Todo2_complete_assigned$.description] = value;
    return this;
  }

  Todo2_complete_assignedPatch withManagerId(String? value) {
    _patch[Todo2_complete_assigned$.managerId] = value;
    return this;
  }
}

extension Todo2_complete_assignedCompareE on Todo2_complete_assigned {
  Map<String, dynamic> compareToTodo2_complete_assigned(
    Todo2_complete_assigned other,
  ) {
    final Map<String, dynamic> diff = {};

    if (completedDate != other.completedDate) {
      diff['completedDate'] = () => other.completedDate;
    }
    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (description != other.description) {
      diff['description'] = () => other.description;
    }
    if (managerId != other.managerId) {
      diff['managerId'] = () => other.managerId;
    }
    return diff;
  }
}
