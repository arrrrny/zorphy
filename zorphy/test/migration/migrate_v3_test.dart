// TDD acceptance for the v2 -> v3 AST migration codemod (ISSUE-019, #194).
//
// The codemod must, on a representative v2 polymorphic corpus:
//   - strip every v2 preset and `generate*` boolean argument,
//   - turn `@Zorphy` on an `id`-bearing class into
//     `@ZorphyEntity(principalKey: #id)`,
//   - turn `@Zorphy` on an `id`-less class into `@ZorphyValue()`,
//   - turn `@ZorphySealed` into `@ZorphyUnion`,
//   - rewrite `.fromJson(map)` to `.fromWire(map)` with a trust-boundary TODO,
//   - rewrite `.toJson()` to `.toWire()`,
// and the migrated output must be free of any v2 preset / `generate*` toggle.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zorphy/src/migration/v3_codemod.dart';

void main() {
  final fixtureDir = p.join('test', 'migration', 'fixtures');

  String fixture(String name) =>
      File(p.join(fixtureDir, name)).readAsStringSync();

  group('v3 codemod — annotations', () {
    test('id-bearing @Zorphy becomes @ZorphyEntity(principalKey: #id)', () {
      final out = const V3Codemod().transform(fixture('entity_with_id.dart'));
      expect(out, contains('@ZorphyEntity(principalKey: #id)'));
      expect(out, isNot(contains('@Zorphy(')));
      expect(out, isNot(contains('ZorphyPreset')));
      expect(out, isNot(contains('generateJson')));
      expect(out, isNot(contains('generatePatch')));
    });

    test('id-less @Zorphy becomes @ZorphyValue()', () {
      final out = const V3Codemod().transform(fixture('value_without_id.dart'));
      expect(out, contains('@ZorphyValue()'));
      expect(out, isNot(contains('@Zorphy(')));
      expect(out, isNot(contains('generateCompareTo')));
    });

    test('@ZorphySealed becomes @ZorphyUnion', () {
      final out = const V3Codemod().transform(
        fixture('sealed_with_codecs.dart'),
      );
      expect(out, contains('@ZorphyUnion('));
      expect(out, isNot(contains('@ZorphySealed')));
    });
  });

  group('v3 codemod — codecs', () {
    test(
      '.fromJson(map) becomes .fromWire(map) with a trust-boundary TODO',
      () {
        final out = const V3Codemod().transform(
          fixture('sealed_with_codecs.dart'),
        );
        expect(out, contains('.fromWire(map)'));
        expect(out, isNot(contains('.fromJson(')));
        expect(out, contains('TODO(trust-boundary): handle BoundaryErr'));
      },
    );

    test('.toJson() becomes .toWire()', () {
      final out = const V3Codemod().transform(
        fixture('sealed_with_codecs.dart'),
      );
      expect(out, contains('.toWire()'));
      expect(out, isNot(contains('.toJson()')));
    });
  });

  group('v3 codemod — whole-corpus invariants', () {
    test('no v2 preset or generate* toggle survives anywhere', () {
      for (final name in [
        'entity_with_id.dart',
        'value_without_id.dart',
        'sealed_with_codecs.dart',
      ]) {
        final out = const V3Codemod().transform(fixture(name));
        expect(out, isNot(matches(RegExp(r'ZorphyPreset'))), reason: name);
        expect(out, isNot(matches(RegExp(r'generate[A-Z]\w*'))), reason: name);
        expect(out, isNot(contains('@ZorphySealed')), reason: name);
      }
    });

    test('a file with no v2 constructs is returned unchanged', () {
      const clean = 'void main() { print("hi"); }\n';
      expect(const V3Codemod().transform(clean), clean);
    });
  });
}
