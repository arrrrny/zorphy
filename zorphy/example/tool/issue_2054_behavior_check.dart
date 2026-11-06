// Behavioral checks for issue #2054 (`@JsonKey(unknownEnumValue:)`).
// Executed by zorphy/test/generation/issue_2054_unknown_enum_value_test.dart
// via `dart run` (cwd: zorphy/example) because the zorphy test package
// cannot import the example package's generated code directly.
//
// Exit code 0 = all checks passed. Any failure prints FAIL and exits 1.
import 'package:zorphy_example/various/issue_2054_unknown_enum_value.dart';

final List<String> failures = <String>[];

void check(String name, bool condition) {
  if (condition) {
    print('PASS: $name');
  } else {
    failures.add(name);
    print('FAIL: $name');
  }
}

void main() {
  // ── An unknown wire value falls back to `unknownEnumValue` ──────
  try {
    final parsed = Parser2054.fromJson({'id': 'x', 'type': 'TELEPORT'});
    check(
      'unknown enum wire value falls back to ParserType2054.empty',
      parsed.type == ParserType2054.empty,
    );
  } catch (e) {
    check('unknown enum wire value does not throw (got: $e)', false);
  }

  // ── A known wire value still decodes normally ───────────────────
  final known = Parser2054.fromJson({'id': 'y', 'type': 'detail'});
  check('known enum wire value decodes', known.type == ParserType2054.detail);

  // ── A missing key still uses `defaultValue` ─────────────────────
  final missing = Parser2054.fromJson({'id': 'z'});
  check(
    'missing enum key uses defaultValue',
    missing.type == ParserType2054.empty,
  );

  if (failures.isEmpty) {
    print('ALL CHECKS PASSED');
    return;
  }
  print('${failures.length} check(s) failed');
  throw StateError('issue #2054 behavior checks failed');
}
