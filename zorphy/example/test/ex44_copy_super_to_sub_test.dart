import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'ex44_copy_super_to_sub_test.zorphy.dart';

/// ChangeTo_ function is used to change the underlying type from one to another
/// To enable ChangeTo on a class we need to add the type to the list of explicitSubTypes in the annotation

/// To copy from a super class to a sub we will always change the underlining type.
/// Therefore we will always use changeTo_

/// A reminder that copyWith always retains the original type
/// even though it can be used polymorphically; ie on super and sub classes.

// ignore_for_file: unnecessary_type_check

@Zorphy(explicitSubTypes: [$Sub])
abstract class $Super {
  String get id;
}

@zorphy
abstract class $Sub implements $Super {
  String get description;
}

main() {
  test("1", () {
    var _super = Super(id: "id");
    var result = _super.changeToSub(description: "description");
    expect(result is Sub, true);
  });
}
