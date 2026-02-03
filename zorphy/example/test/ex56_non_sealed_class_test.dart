import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:test/test.dart';

part 'ex56_non_sealed_class_test.zorphy.dart';

///we can specify our abstract classes are abastract and non sealed
///this means the exhaustiveness checking in switch statements differs

@Zorphy(nonSealed: true)
abstract class $$Todo2 {
  String get title;

  String get id;

  String get description;
}

@zorphy
abstract class $Todo2_incomplete implements $$Todo2 {}

@zorphy
abstract class $Todo2_complete implements $$Todo2 {
  DateTime get completedDate;
}

@zorphy
abstract class $Todo2_complete_assigned implements $Todo2_complete {
  DateTime get completedDate;

  String get managerId;
}

String getDescription(Todo2 todo) => switch (todo) {
  Todo2_incomplete() => "incomplete",
  Todo2_complete_assigned(managerId: var managerId) =>
    "assigned to: $managerId",
  Todo2_complete(completedDate: var completedDate) =>
    "completed on $completedDate",
  Todo2() =>
    "this code will never be hit because Todo2 is abstract and there are no other subclasses",
};

void main() {
  group("abstract class", () {
    test("0 ", () {
      var todo = Todo2_complete_assigned(
        title: "title",
        id: "id",
        description: "description",
        completedDate: DateTime.now(),
        managerId: "5",
      );
      var description = getDescription(todo);
      var expected = "assigned to: 5";

      expect(description, expected);
    });
  });
}
