// Regression test for issue #2054:
// "zorphy: @JsonKey(unknownEnumValue:) is silently dropped — generated
//  fromJson throws on unknown enum wire values"
//
// Two layers, following the issue_131 pattern:
//
//   1. Golden assertions against the regenerated fixture
//      `example/lib/various/issue_2054_unknown_enum_value.zorphy.dart`
//      (CI regenerates it in zorphy/example before tests run).
//
//   2. Behavioral checks executed in the example package context via
//      `dart run tool/issue_2054_behavior_check.dart` — the zorphy test
//      package cannot import the example package's generated code directly.
library test.generation.issue_2054_unknown_enum_value_test;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final fixture = File(
    'example/lib/various/issue_2054_unknown_enum_value.zorphy.dart',
  );
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

  group('golden: @JsonKey(unknownEnumValue:) is preserved', () {
    test('the generated field keeps unknownEnumValue', () {
      expect(
        output,
        contains('unknownEnumValue: ParserType2054.empty'),
        reason:
            'zorphy must re-emit `unknownEnumValue` on the generated '
            'field, otherwise json_serializable cannot pass it through to '
            '\$enumDecodeNullable',
      );
    });

    test('the generated field keeps defaultValue alongside it', () {
      expect(output, contains('defaultValue: ParserType2054.empty'));
    });
  });

  group('behavior: unknown wire values degrade instead of throwing', () {
    test('behavior check runner exits 0', () {
      final result = Process.runSync(Platform.resolvedExecutable, [
        'run',
        'tool/issue_2054_behavior_check.dart',
      ], workingDirectory: 'example');

      final combined = '${result.stdout}\n${result.stderr}';

      expect(
        result.exitCode,
        0,
        reason: 'issue #2054 behavior checks failed:\n$combined',
      );
      expect(combined, contains('ALL CHECKS PASSED'));
    });
  });
}
