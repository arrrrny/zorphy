// Regression for issue #278: a value-class hierarchy split across two
// libraries must merge the base's fields into the leaf.
//
// The shared-part builder used to resolve each library in isolation
// (`HierarchyResolver.resolveLibrary`), so a leaf whose base lives in another
// library generated standalone: no `extends Base`, no inherited `color` field,
// and every `Circle.fromTrusted(color:, radius:)` construction site failed to
// compile. This test drives the REAL builder through build_runner over a
// two-library fixture and asserts the generated leaf is a subtype of its base
// and carries the merged payload.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final basePart = File('example/lib/_br_/crosslib/base_shape.part.dart');
  final circlePart = File('example/lib/_br_/crosslib/circle.part.dart');

  late String base;
  late String circle;

  setUpAll(() {
    if (!circlePart.existsSync()) {
      fail(
        'Missing generated file: ${circlePart.path}\n'
        'Run: cd example && dart run build_runner build',
      );
    }
    base = basePart.readAsStringSync();
    circle = circlePart.readAsStringSync();
  });

  group('#278 cross-library base-class merge', () {
    test('the leaf extends the generated base class', () {
      expect(circle, contains('final class Circle extends Shape'));
    });

    test('the leaf constructor takes the inherited field', () {
      expect(circle, contains('const Circle.fromTrusted({required this.color'));
      expect(circle, contains('required this.radius'));
    });

    test('the leaf redeclares the inherited field with @override', () {
      expect(circle, matches(RegExp(r'@override\s+final String color;')));
      expect(circle, contains('final double radius;'));
    });

    test('the leaf payload includes the inherited field in copyWith', () {
      expect(
        circle,
        contains('Circle copyWith({String? color, double? radius})'),
      );
    });

    test('the leaf Fields descriptor lists the inherited field (#247)', () {
      expect(circle, contains('CircleFields'));
      expect(circle, contains("name: 'color'"));
      expect(circle, contains("name: 'radius'"));
    });

    test('the base library still emits its own standalone root', () {
      // The base is declared in its own library, so it stays a standalone
      // root there — the leaf in the other library extends it.
      expect(base, contains('final class Shape implements ZorphyValueBase'));
    });
  });
}
