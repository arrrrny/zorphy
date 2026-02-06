import 'no_patch_example.dart';

void main() {
  final user = NoPatchUser(name: 'Alice', age: 30);
  print('User: $user');
  
  // Test JSON serialization
  final json = user.toJson();
  print('JSON: $json');
  
  // Test JSON deserialization
  final fromJson = NoPatchUser.fromJson(json);
  print('From JSON: $fromJson');
  print('Equal: ${user == fromJson}');
}
