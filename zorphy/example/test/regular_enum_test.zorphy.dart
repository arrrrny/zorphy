// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'regular_enum_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class Task extends $Task {
  @override
  final String title;
  @override
  final String description;
  @override
  final Priority priority;
  @override
  final Status status;
  @override
  final DateTime createdAt;

  Task({
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  Task copyWith({
    String? title,
    String? description,
    Priority? priority,
    Status? status,
    DateTime? createdAt,
  }) {
    return Task(
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Task copyWithTask({
    String? title,
    String? description,
    Priority? priority,
    Status? status,
    DateTime? createdAt,
  }) {
    return copyWith(
      title: title,
      description: description,
      priority: priority,
      status: status,
      createdAt: createdAt,
    );
  }

  Task patchWithTask({
    TaskPatch? patchInput,
  }) {
    final _patcher = patchInput ?? TaskPatch();
    final _patchMap = _patcher.toPatch();
    return Task(
        title: _patchMap.containsKey(Task$.title)
            ? (_patchMap[Task$.title] is Function)
                ? _patchMap[Task$.title](this.title)
                : _patchMap[Task$.title]
            : this.title,
        description: _patchMap.containsKey(Task$.description)
            ? (_patchMap[Task$.description] is Function)
                ? _patchMap[Task$.description](this.description)
                : _patchMap[Task$.description]
            : this.description,
        priority: _patchMap.containsKey(Task$.priority)
            ? (_patchMap[Task$.priority] is Function)
                ? _patchMap[Task$.priority](this.priority)
                : _patchMap[Task$.priority]
            : this.priority,
        status: _patchMap.containsKey(Task$.status)
            ? (_patchMap[Task$.status] is Function)
                ? _patchMap[Task$.status](this.status)
                : _patchMap[Task$.status]
            : this.status,
        createdAt: _patchMap.containsKey(Task$.createdAt)
            ? (_patchMap[Task$.createdAt] is Function)
                ? _patchMap[Task$.createdAt](this.createdAt)
                : _patchMap[Task$.createdAt]
            : this.createdAt);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        title == other.title &&
        description == other.description &&
        priority == other.priority &&
        status == other.status &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(this.title, this.description, this.priority, this.status,
        this.createdAt);
  }

  @override
  String toString() {
    return 'Task(' +
        'title: ${title}' +
        ', ' +
        'description: ${description}' +
        ', ' +
        'priority: ${priority}' +
        ', ' +
        'status: ${status}' +
        ', ' +
        'createdAt: ${createdAt})';
  }

  /// Creates a [Task] instance from JSON
  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

enum Task$ { title, description, priority, status, createdAt }

class TaskPatch implements Patch<Task> {
  final Map<Task$, dynamic> _patch = {};

  static TaskPatch create([Map<String, dynamic>? diff]) {
    final patch = TaskPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Task$.values.firstWhere((e) => e.name == key);
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

  static TaskPatch fromPatch(Map<Task$, dynamic> patch) {
    final _patch = TaskPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Task$, dynamic> toPatch() => Map.from(_patch);

  Task applyTo(Task entity) {
    return entity.patchWithTask(patchInput: this);
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

  static TaskPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  TaskPatch withTitle(String? value) {
    _patch[Task$.title] = value;
    return this;
  }

  TaskPatch withDescription(String? value) {
    _patch[Task$.description] = value;
    return this;
  }

  TaskPatch withPriority(Priority? value) {
    _patch[Task$.priority] = value;
    return this;
  }

  TaskPatch withStatus(Status? value) {
    _patch[Task$.status] = value;
    return this;
  }

  TaskPatch withCreatedAt(DateTime? value) {
    _patch[Task$.createdAt] = value;
    return this;
  }
}

extension TaskSerialization on Task {
  Map<String, dynamic> toJson() => _$TaskToJson(this);
}

extension TaskCompareE on Task {
  Map<String, dynamic> compareToTask(Task other) {
    final Map<String, dynamic> diff = {};

    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (description != other.description) {
      diff['description'] = () => other.description;
    }
    if (priority != other.priority) {
      diff['priority'] = () => other.priority;
    }
    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Project extends $Project {
  @override
  final String name;
  @override
  final List<Task> tasks;
  @override
  final Map<String, Priority> defaultPriorities;

  Project({
    required this.name,
    required this.tasks,
    required this.defaultPriorities,
  });

  Project copyWith({
    String? name,
    List<Task>? tasks,
    Map<String, Priority>? defaultPriorities,
  }) {
    return Project(
      name: name ?? this.name,
      tasks: tasks ?? this.tasks,
      defaultPriorities: defaultPriorities ?? this.defaultPriorities,
    );
  }

  Project copyWithProject({
    String? name,
    List<Task>? tasks,
    Map<String, Priority>? defaultPriorities,
  }) {
    return copyWith(
      name: name,
      tasks: tasks,
      defaultPriorities: defaultPriorities,
    );
  }

  Project patchWithProject({
    ProjectPatch? patchInput,
  }) {
    final _patcher = patchInput ?? ProjectPatch();
    final _patchMap = _patcher.toPatch();
    return Project(
        name: _patchMap.containsKey(Project$.name)
            ? (_patchMap[Project$.name] is Function)
                ? _patchMap[Project$.name](this.name)
                : _patchMap[Project$.name]
            : this.name,
        tasks: _patchMap.containsKey(Project$.tasks)
            ? (_patchMap[Project$.tasks] is Function)
                ? _patchMap[Project$.tasks](this.tasks)
                : _patchMap[Project$.tasks]
            : this.tasks,
        defaultPriorities: _patchMap.containsKey(Project$.defaultPriorities)
            ? (_patchMap[Project$.defaultPriorities] is Function)
                ? _patchMap[Project$.defaultPriorities](this.defaultPriorities)
                : _patchMap[Project$.defaultPriorities]
            : this.defaultPriorities);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project &&
        name == other.name &&
        tasks == other.tasks &&
        defaultPriorities == other.defaultPriorities;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.tasks, this.defaultPriorities);
  }

  @override
  String toString() {
    return 'Project(' +
        'name: ${name}' +
        ', ' +
        'tasks: ${tasks}' +
        ', ' +
        'defaultPriorities: ${defaultPriorities})';
  }

  /// Creates a [Project] instance from JSON
  factory Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);
}

enum Project$ { name, tasks, defaultPriorities }

class ProjectPatch implements Patch<Project> {
  final Map<Project$, dynamic> _patch = {};

  static ProjectPatch create([Map<String, dynamic>? diff]) {
    final patch = ProjectPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Project$.values.firstWhere((e) => e.name == key);
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

  static ProjectPatch fromPatch(Map<Project$, dynamic> patch) {
    final _patch = ProjectPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Project$, dynamic> toPatch() => Map.from(_patch);

  Project applyTo(Project entity) {
    return entity.patchWithProject(patchInput: this);
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

  static ProjectPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ProjectPatch withName(String? value) {
    _patch[Project$.name] = value;
    return this;
  }

  ProjectPatch withTasks(List<Task>? value) {
    _patch[Project$.tasks] = value;
    return this;
  }

  ProjectPatch withDefaultPriorities(Map<String, Priority>? value) {
    _patch[Project$.defaultPriorities] = value;
    return this;
  }
}

extension ProjectSerialization on Project {
  Map<String, dynamic> toJson() => _$ProjectToJson(this);
}

extension ProjectCompareE on Project {
  Map<String, dynamic> compareToProject(Project other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (tasks != other.tasks) {
      diff['tasks'] = () => other.tasks;
    }
    if (defaultPriorities != other.defaultPriorities) {
      diff['defaultPriorities'] = () => other.defaultPriorities;
    }
    return diff;
  }
}
