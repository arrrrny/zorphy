import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'ex23_comments_test.zorphy.dart';

//TAKE COMMENTS FROM CLASS

///This is my class level comment
@zorphy
abstract class $Cat {
  ///Type is a thingy thing
  String get type;

  String get colour; //no comment
}

main() {
  test("1", () {
    var a = Cat(type: "cat", colour: "blue");

    expect(a.type, "cat");
  });
}
