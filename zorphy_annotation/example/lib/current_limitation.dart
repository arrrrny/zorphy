// /// Another sealed class example for shapes
// @Zorphy(explicitSubTypes: [$Circle, $Rectangle, $Triangle])
// abstract class $$Shape {
//   double get area;
//   double get perimeter;
// }

// @Zorphy(generateJson: true)
// abstract class $Circle implements $$Shape {
//   double get radius;

//   @override
//   double get area => 3.14159 * radius * radius;

//   @override
//   double get perimeter => 2 * 3.14159 * radius;
// }

// @Zorphy(generateJson: true)
// abstract class $Rectangle implements $$Shape {
//   double get width;
//   double get height;

//   @override
//   double get area => width * height;

//   @override
//   double get perimeter => 2 * (width + height);
// }

// @Zorphy(generateJson: true)
// abstract class $Triangle implements $$Shape {
//   double get base;
//   double get height;
//   double get sideA;
//   double get sideB;
//   double get sideC;

//   @override
//   double get area => 0.5 * base * height;

//   @override
//   double get perimeter => sideA + sideB + sideC;
// }

//   // Shapes example
//   final circle = Circle(radius: 5.0);
//   final rectangle = Rectangle(width: 4.0, height: 6.0);
//   final triangle = Triangle(
//     base: 3.0,
//     height: 4.0,
//     sideA: 3.0,
//     sideB: 4.0,
//     sideC: 5.0,
//   );

//   final shapes = <$$Shape>[circle, rectangle, triangle];

//   print('Shape areas:');
//   for (final shape in shapes) {
//     print(
//         '  $shape (area: ${shape.area.toStringAsFixed(2)}, perimeter: ${shape.perimeter.toStringAsFixed(2)})');
//   }
//   print('');
//   print('Circle: ${circle.toJson()}');
