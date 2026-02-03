import 'package:zorphy_annotation/zorphy.dart';
part 'comprehensive_nested_patch_demo.morphy.dart';

/// A person's profile information
@zorphy
abstract class $PersonProfile {
  String get firstName;
  String get lastName;
  String? get bio;
  int get age;
}

/// Contact information
@zorphy
abstract class $ContactInfo {
  String get email;
  String? get phone;
}
