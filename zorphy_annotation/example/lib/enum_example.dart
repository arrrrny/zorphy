import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'enum_example.zorphy.dart';
part 'enum_example.g.dart';

/// Enum definitions for the example
enum Status {
  active,
  inactive,
  pending,
  suspended,
}

enum Priority {
  low,
  medium,
  high,
  critical,
}

enum UserRole {
  admin,
  moderator,
  user,
  guest,
}

/// Example demonstrating enum field support.
///
/// This example shows:
/// - Enum fields in entities
/// - JSON serialization with enums
/// - Pattern matching with enums
/// - Enums with switch expressions

/// Task entity with enum fields
@Zorphy(generateJson: true)
abstract class $Task {
  String get id;
  String get title;
  Status get status;
  Priority get priority;
  List<String>? get tags;
}

/// User entity with enum role
@Zorphy(generateJson: true)
abstract class $UserProfile {
  String get userId;
  String get username;
  UserRole get role;
  DateTime get lastLogin;
}

/// Configuration entity with multiple enums
@Zorphy(generateJson: true)
abstract class $SystemConfig {
  String get configKey;
  String get configValue;
  Status get configStatus;
  Priority get updatePriority;
  bool get requiresRestart;
}

void main() {
  print('=== Enum Example ===\n');

  // Create a task with enum fields
  final task = Task(
    id: 'task-001',
    title: 'Complete project documentation',
    status: Status.active,
    priority: Priority.high,
    tags: ['documentation', 'urgent'],
  );

  print('Task: ${task.title}');
  print('Status: ${task.status.name}'); // Active
  print('Priority: ${task.priority.name}'); // high
  print('');

  // Create multiple tasks with different states
  final tasks = [
    Task(
      id: 'task-001',
      title: 'Fix login bug',
      status: Status.active,
      priority: Priority.critical,
    ),
    Task(
      id: 'task-002',
      title: 'Update documentation',
      status: Status.pending,
      priority: Priority.medium,
    ),
    Task(
      id: 'task-003',
      title: 'Code review',
      status: Status.inactive,
      priority: Priority.low,
    ),
  ];

  print('All Tasks:');
  for (final t in tasks) {
    print('  [${t.priority.name}] ${t.title} - ${t.status.name}');
  }
  print('');

  // Enum pattern matching
  print('Task Analysis:');
  for (final t in tasks) {
    final analysis = analyzeTask(t);
    print('  ${t.title}: $analysis');
  }
  print('');

  // User profile with role enum
  final admin = UserProfile(
    userId: 'user-001',
    username: 'alice_admin',
    role: UserRole.admin,
    lastLogin: DateTime(2024, 2, 1, 10, 30),
  );

  final guest = UserProfile(
    userId: 'user-002',
    username: 'bob_guest',
    role: UserRole.guest,
    lastLogin: DateTime(2024, 2, 1, 14, 20),
  );

  print('User Permissions:');
  print('  ${admin.username}: ${getPermissions(admin.role)}');
  print('  ${guest.username}: ${getPermissions(guest.role)}');
  print('');

  // JSON serialization with enums
  print('JSON Serialization:');
  final taskJson = task.toJson();
  print('Task JSON: $taskJson');
  print('');

  // Restore from JSON
  final restoredTask = Task.fromJson(taskJson);
  print('Restored task: ${restoredTask.title}');
  print('Status matches? ${restoredTask.status == task.status}'); // true
  print('');

  // copyWith enums
  final promotedTask = task.copyWith(
    status: Status.active,
    priority: Priority.critical,
  );
  print('Promoted task:');
  print('  ${promotedTask.title}');
  print('  Status: ${promotedTask.status.name}');
  print('  Priority: ${promotedTask.priority.name}');
}

String analyzeTask(Task task) {
  return switch (task.priority) {
    Priority.critical => 'URGENT - Immediate attention required!',
    Priority.high => 'Important - Handle soon',
    Priority.medium => 'Normal priority',
    Priority.low => 'Can wait',
  };
}

String getPermissions(UserRole role) {
  return switch (role) {
    UserRole.admin => 'Full access: read, write, delete, manage users',
    UserRole.moderator => 'Moderator access: read, write, moderate content',
    UserRole.user => 'Standard access: read, write own content',
    UserRole.guest => 'Limited access: read only',
  };
}
