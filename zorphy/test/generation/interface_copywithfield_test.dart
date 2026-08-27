// Tests for interface-scoped copyWithField generation.
//
// Verifies that entities implementing an interface get a copyWithField
// method that handles ALL fields (parent + own) using the parent's
// Field type for LSP-safe polymorphic dispatch.
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

    test('Vehicle has copyWithField with Vehicle fields', () {
      expect(output, contains('Vehicle copyWithField<T>'));
      expect(output, contains("case 'make':"));
      expect(output, contains("case 'model':"));
      expect(output, contains("case 'year':"));
    });

    test('InterfaceCar has copyWithField with ALL fields (Vehicle + own)', () {
      expect(output, contains('InterfaceCar copyWithField<T>'));
      expect(output, contains("case 'make':"));
      expect(output, contains("case 'model':"));
      expect(output, contains("case 'year':"));
      expect(output, contains("case 'doors':"));
    });

    test('InterfaceCar copyWithField uses parent Field type (Field<Vehicle, T>)', () {
      // The override uses Field<Vehicle, T> (parent type), NOT Field<InterfaceCar, T>.
      // This keeps the override LSP-safe: both parent and child Field tokens
      // are accepted via Dart's declaration-site covariance.
      expect(
        output,
        contains('Field<Vehicle, T> field'),
      );
      expect(
        output,
        isNot(contains('Field<InterfaceCar, T> field')),
      );
    });

    test('InterfaceCar copyWithField has @override annotation', () {
      expect(output, contains('@override'));
    });

    test('InterfaceCar copyWithField throws for unknown fields', () {
      expect(
        output,
        contains("'InterfaceCar has no settable field with this name'"),
      );
    });

    test('Vehicle copyWithField throws for unknown fields', () {
      expect(
        output,
        contains("'Vehicle has no settable field with this name'"),
      );
    });

    test('InterfaceCar copyWithField has proper documentation', () {
      expect(
        output,
        contains(
          '/// Returns a copy of this entity with [field] set to [value].',
        ),
      );
    });
  });

  group('behavior: runner executed in example package context', () {
    test(
      'all runtime checks pass (including polymorphic path)',
      () async {
        final runner = File(
          'example/tool/interface_copywithfield_behavior_check.dart',
        );
        if (!runner.existsSync()) {
          fail(
            'Behavior runner missing: example/tool/interface_copywithfield_behavior_check.dart',
          );
        }
        final result = await Process.run('dart', [
          'run',
          'tool/interface_copywithfield_behavior_check.dart',
        ], workingDirectory: 'example');
        final stdoutText = result.stdout as String;
        // Surface the runner output for CI debugging on failure.
        expect(stdoutText, contains('ALL CHECKS PASSED'));
        expect(result.exitCode, 0, reason: stdoutText);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
