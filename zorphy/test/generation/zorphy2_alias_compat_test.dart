import 'dart:io';

import 'package:test/test.dart';

/// Verifies the deprecated `@zorphy2`/`@Zorphy2` alias keeps working
/// through the unified single-pass builder: alias-annotated classes must
/// generate the same standard output as `@zorphy` classes, into the
/// `.zorphy.dart` part file.
void main() {
  final fixture = File('example/lib/various/zorphy2_alias_example.zorphy.dart');
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

  test('@zorphy2 const alias generates a full standard class', () {
    expect(output, contains('class LegacyShape'));
    expect(output, contains('LegacyShape copyWith('));
    expect(output, contains('class LegacyShapePatch'));
    expect(output, contains('bool operator =='));
  });

  test('@Zorphy2 annotation form generates a full standard class', () {
    expect(output, contains('class LegacyPoint'));
    expect(output, contains('LegacyPoint copyWith('));
    expect(output, contains('class LegacyPointPatch'));
  });
}
