import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'basic_example.zorphy.dart';

/// Basic entity example showing the fundamental features of Zorphy.
///
/// This example demonstrates:
/// - Creating a simple entity with required and optional fields
/// - Immutable data classes
/// - Automatic constructor generation
/// - copyWith for creating modified copies
/// - Equality operators
/// - toString representation
/// - Patch operations for partial updates
@zorphy
abstract class $User {
  String get name;
  int get age;
  String? get email;
}

void main() {
  print('=== Basic Example ===\n');

  // Create instances using the generated constructor
  final user1 = User(name: 'Alice', age: 30);
  final user2 = User(name: 'Bob', age: 25, email: 'bob@example.com');

  print('User 1: $user1');
  print('User 2: $user2\n');

  // Equality check
  final user1Copy = User(name: 'Alice', age: 30);
  print('user1 == user1Copy: ${user1 == user1Copy}'); // true
  print('user1 == user2: ${user1 == user2}'); // false
  print('');

  // copyWith - create modified copies
  final olderUser = user1.copyWith(age: 31);
  print('Original: $user1');
  print('Modified: $olderUser');
  print('Are they equal? ${user1 == olderUser}'); // false
  print('');

  // Patch operations - partial updates
  final userPatch = UserPatch.create()..withAge(32)..withEmail('alice@example.com');
  final patchedUser = user1.patchWithUser(patchInput: userPatch);
  print('Original: $user1');
  print('Patched: $patchedUser');
  print('');

  // HashCode for use in Sets and Maps
  final users = {user1, user2, user1Copy};
  print('Unique users in set: ${users.length}'); // 2 (user1 and user1Copy are equal)
  print('');

  // Named parameters make it clear what each value is
  final user3 = User(
    name: 'Charlie',
    age: 35,
    email: 'charlie@example.com',
  );
  print('User 3: $user3');
}
