import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:test/test.dart';

part 'ex61_private_getter_test.zorphy.dart';

//shows the private getter stuff

main() {
  test("1", () {
    var cat = Cat(name: "Tom", ageInYears: 3);
    var dog = Dog(name: "Rex", ageInYears: 3);

    expect(cat.age(), 21);
    expect(dog.age(), 15);
  });
}

extension Pet_E on Pet {
  int age() => switch (this) {
    Cat() => _ageInYears * 7,
    Dog() => _ageInYears * 5,
  };
}

@zorphy
abstract class $$Pet {
  int get _ageInYears;

  String get name;
}

@zorphy
abstract class $Cat implements $$Pet {}

@zorphy
abstract class $Dog implements $$Pet {}
