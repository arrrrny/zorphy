//import 'package:test/test.dart';
//import 'package:zorphy_annotation/zorphy.dart';//import 'package:meta/meta.dart';
//
//part 'ex6_test.zorphy.dart';
//
////CURRENTLY NOT ALLOWING CUSTOM GETTERS (CAN JUST USE A FUNCTION)
////  this is where mixins would have been a better approach
//
//@zorphy
//abstract class $A {
//  String get z;
//
//  const $A();
//}
//
//@zorphy
//abstract class $B {
//  String get y;
//  String get z => y;
//
//  const $B();
//}
//
//main() {
//  test("1", () {
//    var a = $B(type: "cat");
//
//    expect(a.type, "cat");
//  });
//}
