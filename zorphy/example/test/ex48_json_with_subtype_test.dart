// ignore_for_file: unnecessary_cast

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'ex48_json_with_subtype_test.g.dart';
part 'ex48_json_with_subtype_test.zorphy.dart';

/// Every subtype needs to also implement toJson & fromJson

@Zorphy(generateJson: true) //, explicitSubTypes: [$B, $C])
abstract class $A {
  String get id;

  $X get x;

  List<$X> get xs;
}

// @Zorphy(generateJson: true)
// abstract class $B implements $A {}

@Zorphy(generateJson: true)
abstract class $X {
  List<int> get items;
}

main() {
  test("1 toJson", () {
    var a = A(
      id: "1",
      x: X(items: [1, 2, 3]),
      xs: [
        X(items: [1]),
        X(items: [2]),
      ],
    );

    expect(
      a.toJson(),
      {
        'id': '1',
        'x': {
          'items': [1, 2, 3],
          '_className_': 'X'
        },
        'xs': [
          {
            'items': [1],
            '_className_': 'X'
          },
          {
            'items': [2],
            '_className_': 'X'
          }
        ],
        '_className_': 'A'
      },
    );
  });
}
