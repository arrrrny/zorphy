// Regression for issue #278: a value-class hierarchy split across libraries
// must merge inherited fields, including a base reached through an intermediate
// library rather than a direct import.
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

import '../support/provision_example_fixture.dart';

void main() {
  final basePart = File('example/lib/crosslib/base_shape.zorphy.dart');
  final intermediatePart = File(
    'example/lib/crosslib/intermediate.zorphy.dart',
  );
  final circlePart = File('example/lib/crosslib/circle.zorphy.dart');

  late String base;
  late String intermediate;
  late String circle;

  setUpAll(() {
    // Provision the example build_runner output on demand (issue #287): the
    // cost-guards benchmark runs a scoped `build_runner` from the package root
    // that cleans the example's generated parts, and `test/benchmark/` sorts
    // before `test/generation/`, so a fresh clone — or a tree the benchmark
    // just cleaned — has no crosslib parts until the example is rebuilt here.
    provisionExampleFixture();
    if (!circlePart.existsSync()) {
      fail(
        'Missing generated file: ${circlePart.path}\n'
        'Run: cd example && dart run build_runner build',
      );
    }
    base = basePart.readAsStringSync();
    intermediate = intermediatePart.readAsStringSync();
    circle = circlePart.readAsStringSync();
  });

  group('#278 cross-library base-class merge', () {
    test('the leaf extends the transitive intermediate class', () {
      expect(circle, contains('final class Circle extends Intermediate'));
    });

    test('the intermediate class extends the cross-library base', () {
      expect(intermediate, contains('final class Intermediate extends Shape'));
      expect(intermediate, contains('required this.color'));
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
