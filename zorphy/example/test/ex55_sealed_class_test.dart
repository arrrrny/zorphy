import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:test/test.dart';

part 'ex55_sealed_class_test.zorphy.dart';

///the default for abstract classes is they are sealed
///this means we can use exhaustiveness checking

@zorphy
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
};

void main() {
  group("sealed", () {
    test("0 ", () {
      // var todo = Todo2_complete_assigned(title: "title", id: "id", description: "description", completedDate: DateTime.now(), managerId: "5");
      // var description = getDescription(todo);
      // var expected = "assigned to: 5";
      //
      // expect(description, expected);
    });
  });
}
