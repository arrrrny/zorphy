import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy.dart';
part 'ex22_null_safety_test.zorphy.dart';

//NULL FIELD NAMES - NULL SAFETY USING ?

@zorphy
abstract class $Pet {
  String? get type;
  String get name;
}

main() {
  test("1", () {
    var a = Pet(name: "mitzy");

    expect(a.name, "mitzy");
    expect(a.type, null);
  });
}
