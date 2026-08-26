// Tests for interface-scoped copyWithField generation.
//
// Verifies that entities implementing an interface get a
// `copyWith{InterfaceName}Field` method that restricts field selectors
// to only the fields exposed by that interface.
library test.generation.interface_copywithfield_test;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final fixture = File(
    'example/lib/various/interface_copywithfield_example.zorphy.dart',
  );

  setUpAll(() {
    if (!fixture.existsSync()) {
      fail(
        'Fixture not generated. Run: cd example && '
        'dart run build_runner build --delete-conflicting-outputs',
      );
    }
  });

  group('golden: interface-scoped copyWithField', () {
    late String output;

    setUpAll(() {
      output = fixture.readAsStringSync();
    });

    test('entity has the standard copyWithField for all fields', () {
      expect(
        output,
        contains('InterfaceCar copyWithField<T>'),
      );
    });

    test('entity has copyWithVehicleField for interface fields only', () {
      expect(
        output,
        contains('InterfaceCar copyWithVehicleField<T>'),
      );
    });

    test('copyWithVehicleField signature matches the pattern', () {
      expect(
        output,
        contains(
          'InterfaceCar copyWithVehicleField<T>'
          '(Field<InterfaceCar, T> field, T value)',
        ),
      );
    });

    test('copyWithVehicleField accepts Vehicle interface fields', () {
      expect(output, contains("case 'make':"));
      expect(output, contains('return copyWith(make: value as String);'));
      expect(output, contains("case 'model':"));
      expect(output, contains('return copyWith(model: value as String);'));
      expect(output, contains("case 'year':"));
      expect(output, contains('return copyWith(year: value as int);'));
    });

    test('copyWithVehicleField does not accept Car-specific fields', () {
      // The switch statement in copyWithVehicleField should only handle
      // Vehicle fields (make, model, year) and throw for others like 'doors'.
      // We verify this by checking that 'doors' is NOT in the Vehicle-scoped
      // method's switch cases.
      final vehicleFieldMethodMatch = RegExp(
        r'copyWithVehicleField<T>\(.*?\{(.*?)\}',
        dotAll: true,
      ).firstMatch(output);
      if (vehicleFieldMethodMatch != null) {
        final methodBody = vehicleFieldMethodMatch.group(1) ?? '';
        expect(
          methodBody.contains("case 'doors':"),
          isFalse,
          reason: 'copyWithVehicleField should not accept doors field',
        );
      }
    });

    test('copyWithVehicleField throws for unknown fields', () {
      expect(
        output,
        contains(
          "'Vehicle interface has no settable field with this name'",
        ),
      );
    });

    test('copyWithVehicleField has proper documentation', () {
      expect(
        output,
        contains(
          '/// Returns a copy of this entity with the Vehicle [field] set to [value].',
        ),
      );
      expect(
        output,
        contains('/// Only fields exposed by the Vehicle interface are accepted.'),
      );
    });
  });

  group('behavior: runner executed in example package context', () {
    test('all runtime checks pass', () async {
      final runner = File('example/tool/interface_copywithfield_behavior_check.dart');
      if (!runner.existsSync()) {
        fail('Behavior runner missing: example/tool/interface_copywithfield_behavior_check.dart');
      }
      final result = await Process.run(
        'dart',
        ['run', 'tool/interface_copywithfield_behavior_check.dart'],
        workingDirectory: 'example',
      );
      final stdoutText = result.stdout as String;
      // Surface the runner output for CI debugging on failure.
      expect(stdoutText, contains('ALL CHECKS PASSED'));
      expect(result.exitCode, 0, reason: stdoutText);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
