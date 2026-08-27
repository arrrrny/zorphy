// Tests for issue #131: `copyWithField(Field<E, T> field, T value)`.
//
// Two layers:
//
//   1. Golden assertions against the regenerated fixture
//      `example/lib/various/issue_131_copywithfield_example.zorphy.dart`
//      (CI regenerates it with `dart run build_runner build` in
//      zorphy/example before tests run).
//
//   2. Behavioral checks executed in the example package context via
//      `dart run tool/issue_131_behavior_check.dart` — the zorphy test
//      package cannot import the example package's generated code
//      directly, so the runner script performs the runtime assertions
//      (single-field flip, type safety, immutability of the receiver)
//      and this test asserts on its exit code.
library test.generation.issue_131_copywithfield_test;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final fixture = File(
    'example/lib/various/issue_131_copywithfield_example.zorphy.dart',
  );
  final runner = File('example/tool/issue_131_behavior_check.dart');
  late String output;

  setUpAll(() {
    if (!fixture.existsSync()) {
      fail(
        'Fixture not generated. Run: cd example && '
        'dart run build_runner build --delete-conflicting-outputs',
      );
    }
    output = fixture.readAsStringSync();
  });

  group('golden: non-generic entity', () {
    test('copyWithField is generated with the documented signature', () {
      expect(
        output,
        contains(
          'WalkthroughStep copyWithField<T>'
          '(Field<WalkthroughStep, T> field, T value)',
        ),
      );
    });

    test('delegates to copyWith per field with a type cast', () {
      expect(output, contains("case 'completed':"));
      expect(output, contains('return copyWith(completed: value as bool);'));
      expect(output, contains('return copyWith(note: value as String?);'));
    });

    test('unknown selectors throw ArgumentError', () {
      expect(
        output,
        contains(
          "throw ArgumentError.value(\n"
          "          field.name,\n"
          "          'field',\n"
          "          'WalkthroughStep has no settable field with this name',",
        ),
      );
    });

    test('doc comment states the copyWith delegation semantics', () {
      expect(
        output,
        contains(
          '/// Returns a copy of this entity with [field] set to [value].',
        ),
      );
      expect(
        output,
        contains('/// Delegates to [copyWith]: the receiver is never mutated'),
      );
    });
  });

  group('golden: generic entity', () {
    test('method type parameter does not shadow the class type parameter', () {
      // The class generic is `T`, so the method's value type parameter
      // must be renamed (TValue) to keep `ProgressBox<T>` resolvable.
      expect(output, contains('ProgressBox copyWithField<TValue>('));
      expect(output, contains('Field<ProgressBox<T>, TValue> field,'));
    });

    test('generic fields keep the class type parameter in the cast', () {
      expect(output, contains('return copyWith(value: value as T?);'));
    });
  });

  group('behavior: runner executed in example package context', () {
    test('all runtime checks pass', () async {
      if (!runner.existsSync()) {
        fail(
          'Behavior runner missing: example/tool/issue_131_behavior_check.dart',
        );
      }
      final result = await Process.run('dart', [
        'run',
        'tool/issue_131_behavior_check.dart',
      ], workingDirectory: 'example');
      final stdoutText = result.stdout as String;
      // Surface the runner output for CI debugging on failure.
      expect(stdoutText, contains('ALL CHECKS PASSED'));
      expect(result.exitCode, 0, reason: stdoutText);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
