import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

// COPY TO - FROM ABSTRACT SUPERCLASS TO SUB CLASS

part 'ex39_copyTo_test.zorphy.dart';

@Zorphy(explicitSubTypes: [$B])
abstract class $$Super {
  String get x;
}

@Zorphy()
abstract class $A implements $$Super {
  String get x;
  String get z;
}

@Zorphy()
abstract class $B implements $$Super {
  String get x;
  String get y;
}

main() {
  test("super (underlying a) to b (abstract super to sub)", () {
    Super _super = A(x: "x", z: "z");
    var b = _super.changeToB(y: "y");

    //super class is copied and a B class is created.
    expect(b.toString(), "(B-x:x|y:y)");
  });
}
