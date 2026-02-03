import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'ex14_inheritance_test.zorphy.dart';

//TOSTRING

@zorphy
abstract class $A {
  String get a;
}

@zorphy
abstract class $B implements $A {
  int get b;
}

@zorphy
abstract class $C implements $B {
  bool get c;
}

main() {
  test("1", () {
    var a = A(a: "A");
    var b = B(a: "A", b: 1);
    var c = C(a: "A", b: 1, c: true);

    expect(a.toString(), "(A-a:A)");
    expect(b.toString(), "(B-a:A|b:1)");
    expect(c.toString(), "(C-a:A|b:1|c:true)");
  });
}
