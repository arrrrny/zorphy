import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

// COPY WITH FROM SUPER CLASS TO SUB CLASS

part 'ex36_create_subclass_from_super_test.zorphy.dart';

/// Use .copyToX to create a subclass from a superclass
/// todo: whats the difference between copyToX & cwX

@Zorphy(explicitSubTypes: [$B])
abstract class $A {
  String get x;
}

@Zorphy()
abstract class $B implements $A {
  String get x;
  String get y;
}

main() {
  test("a to b (super to sub)", () {
    A a = A(x: "x");
    B b = a.changeToB(y: "y");

    expect(b.toString(), "(B-x:x|y:y)");
  });
}
