// Regression tests for the `!Type` external-type field marker (issue #349).
//
// The `!` prefix (e.g. `url:!WebUri?`) marks a field type as EXTERNAL — a
// type living outside the entity tree (plugin wrappers like `WebUri`, SDK
// classes, ...). External types must be:
//   1. kept as-is by `FieldDefinition.parse` (no `$` prefix, `!` stripped),
//   2. NOT `$`-prefixed by `FieldNormalizer`,
//   3. NOT resolved to entity/enum imports by `ImportResolver`,
//   4. skipped by on-disk validation (zuraffa side).
//
// Before the fix, `--field request:!URLRequest` produced `$!URLRequest get
// request;` in the generated source (the `!` was treated as part of the
// type name by `_determinePrefix`), which the builder then misparsed into a
// phantom `$` field (`required dynamic $`) and the build failed.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/zorphy.dart';

void main() {
  group('FieldDefinition.parse external marker (!)', () {
    test('parses !Type', () {
      final f = FieldDefinition.parse('url:!WebUri');
      expect(f.name, 'url');
      expect(f.type, 'WebUri');
      expect(f.nullable, isFalse);
      expect(f.isExternal, isTrue);
      expect(f.fullType, 'WebUri');
    });

    test('parses !Type?', () {
      final f = FieldDefinition.parse('url:!WebUri?');
      expect(f.name, 'url');
      expect(f.type, 'WebUri');
      expect(f.nullable, isTrue);
      expect(f.isExternal, isTrue);
      expect(f.fullType, 'WebUri?');
    });

    test('plain type is not external', () {
      final f = FieldDefinition.parse('id:String');
      expect(f.isExternal, isFalse);
    });

    test('rejects bare !', () {
      expect(() => FieldDefinition.parse('url:!'), throwsArgumentError);
    });
  });

  group('EntityCreator end-to-end external marker (!)', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('zorphy_349_');
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    Future<String> createEntityWithExternalField(String refType) async {
      final creator = EntityCreator(baseOutputDir: tmp.path);
      final field = FieldDefinition.parse('url:$refType');
      final result = await creator.create(
        EntityConfig(
          name: 'ExternalHolder',
          outputDir: tmp.path,
          fields: [field],
        ),
      );
      expect(result.isSuccess, isTrue, reason: result.error);
      return File(result.filePath).readAsString();
    }

    test(
      'external field emits plain type, no \$ prefix, no bogus import',
      () async {
        final src = await createEntityWithExternalField('!WebUri?');

        // The field declaration must be the PLAIN type (no `\$` prefix, no
        // `!` leak).
        expect(
          src,
          contains('WebUri? get url;'),
          reason:
              'External type must be emitted verbatim without the `\$` '
              'prefix or the `!` marker.',
        );
        expect(
          src,
          isNot(contains(r'$!WebUri')),
          reason:
              '`\$!WebUri` is the #349 defect — `!` was treated as part '
              'of the type name and `\$`-prefixed by `_determinePrefix`.',
        );
        expect(
          src,
          isNot(contains(r'$WebUri')),
          reason: 'External types are not entities — no `\$` prefix.',
        );
        // No entity import for the external type, and no bogus enum import.
        expect(
          src,
          isNot(contains("import '../web_uri/web_uri.dart';")),
          reason: 'No entity import must be resolved for an external type.',
        );
        expect(
          src,
          isNot(contains("import '../enums/index.dart';")),
          reason: 'No enum import must be resolved for an external type.',
        );
      },
    );

    test('external non-nullable field emits plain type', () async {
      final src = await createEntityWithExternalField('!WebUri');
      expect(src, contains('WebUri get url;'));
      expect(src, isNot(contains(r'$WebUri')));
    });

    test(
      'external field next to entity field keeps sibling prefixing',
      () async {
        final creator = EntityCreator(baseOutputDir: tmp.path);
        final result = await creator.create(
          EntityConfig(
            name: 'MixedHolder',
            outputDir: tmp.path,
            fields: [
              FieldDefinition.parse('url:!WebUri?'),
              FieldDefinition.parse('peer:SiblingEntity?'),
            ],
          ),
        );
        expect(result.isSuccess, isTrue, reason: result.error);
        final src = await File(result.filePath).readAsString();
        // External stays plain; forward-referenced sibling entity keeps the
        // `$` prefix (existing behavior must not regress).
        expect(src, contains('WebUri? get url;'));
        expect(src, contains(r'$SiblingEntity? get peer;'));
        // The sibling import is still resolved.
        expect(
          src,
          contains("import '../sibling_entity/sibling_entity.dart';"),
        );
      },
    );
  });
}
