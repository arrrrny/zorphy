import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:test/test.dart';

part 'ex60_copywith_generic_test.zorphy.dart';

//this shows a bug where the copywith doesn't quite work properly

main() {
  test("1", () {
    var a = A<int>(x: 1, y: 2);

    var aAsInt = a.copyWithAFn(x: () => 2);

    expect(aAsInt.runtimeType, A<int>);
  });
}

@Zorphy(generateCopyWithFn: true)
abstract class $A<T> {
  T get x;
  T get y;
}
