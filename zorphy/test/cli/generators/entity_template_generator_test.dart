import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zorphy/src/cli/generators/entity_template_generator.dart';
import 'package:zorphy/src/cli/models/entity_config.dart';

/// The scaffold must satisfy the annotation it writes (issue #297). A
/// root `@ZorphyEntity` promises `principalKey: #id`; the v3 archetype
/// diagnostics reject a key that names no field (`ZORPHY_E001`), so a
/// scaffold without an `id` never builds and every file importing it
/// fails to analyze.
void main() {
  const idLine = '  String get id;';
  int idDeclarations(String source) =>
      RegExp(r'^\s+String get id;', multiLine: true).allMatches(source).length;

  group('a root entity', () {
    test('with no fields declares the id its principalKey promises', () {
      final source = EntityTemplateGenerator.generate(
        const EntityConfig(name: 'Todo'),
        const [],
      );

      expect(source, contains('@ZorphyEntity(principalKey: #id)'));
      expect(source, contains(idLine));
    });

    test('reuses an id the caller declared instead of duplicating it', () {
      final source = EntityTemplateGenerator.generate(
        const EntityConfig(
          name: 'Todo',
          fields: [
            FieldDefinition(name: 'id', type: 'String'),
            FieldDefinition(name: 'title', type: 'String'),
          ],
        ),
        const [],
      );

      expect(idDeclarations(source), 1);
      expect(source, contains('get title;'));
    });

    test('declares the id ahead of fields that have none', () {
      final source = EntityTemplateGenerator.generate(
        const EntityConfig(
          name: 'Todo',
          fields: [FieldDefinition(name: 'title', type: 'String')],
        ),
        const [],
      );

      expect(source, contains('@ZorphyEntity(principalKey: #id)'));
      expect(source.indexOf(idLine), lessThan(source.indexOf('get title;')));
    });
  });

  group('a class without its own identity', () {
    test('value object declares no id', () {
      final source = EntityTemplateGenerator.generate(
        const EntityConfig(name: 'Money', kind: ZorphyKind.valueObject),
        const [],
      );

      expect(source, contains('@ZorphyValue()'));
      expect(idDeclarations(source), 0);
    });

    test('sealed root is a union and declares no id', () {
      final source = EntityTemplateGenerator.generate(
        const EntityConfig(name: 'Shape', isSealed: true),
        const [],
      );

      expect(source, contains('@ZorphyUnion()'));
      expect(idDeclarations(source), 0);
    });

    test('implementing an interface inherits its identity', () {
      final source = EntityTemplateGenerator.generate(
        const EntityConfig(name: 'Admin', extendsInterface: '\$User'),
        const [],
      );

      expect(source, contains('implements \$User'));
      expect(idDeclarations(source), 0);
    });

    test('subtype and inline subtype declare no id', () {
      final parent = const EntityConfig(name: 'Shape', isSealed: true);
      final subtype = EntityTemplateGenerator.generateSubtype(
        parent,
        const EntityConfig(name: 'Circle'),
        'Shape',
        true,
        const [],
      );
      final inline = EntityTemplateGenerator.generateInlineSubtype(
        'Square',
        'Shape',
        true,
        const [],
        parent,
      );

      expect(idDeclarations(subtype), 0);
      expect(idDeclarations(inline), 0);
    });
  });

  group('the part directive names the v3 shared part', () {
    String partDirective(EntityConfig config, {bool subtype = false}) {
      final source = subtype
          ? EntityTemplateGenerator.generateSubtype(
              const EntityConfig(name: 'Shape', isSealed: true),
              config,
              'Shape',
              true,
              const [],
            )
          : EntityTemplateGenerator.generate(config, const []);
      return RegExp(
        r"^part '(.+)';",
        multiLine: true,
      ).firstMatch(source)!.group(1)!;
    }

    test('the default location mirrors the library path under lib/_br_/', () {
      expect(
        partDirective(const EntityConfig(name: 'Todo')),
        '../../../../_br_/src/domain/entities/todo/todo.part.dart',
      );
    });

    test('follows a custom lib/ output dir', () {
      expect(
        partDirective(
          const EntityConfig(name: 'Money', outputDir: 'lib/src/core/params'),
        ),
        '../../../../_br_/src/core/params/money/money.part.dart',
      );
    });

    test('a library outside lib/ reads its part from the package root', () {
      expect(
        partDirective(
          const EntityConfig(name: 'Sample', outputDir: 'test/fixtures'),
        ),
        '../../../_br_/test/fixtures/sample/sample.part.dart',
      );
    });

    test('an absolute output dir is rebased on its lib segment', () {
      expect(
        partDirective(
          const EntityConfig(
            name: 'Todo',
            outputDir: '/tmp/proj/lib/src/domain/entities',
          ),
        ),
        '../../../../_br_/src/domain/entities/todo/todo.part.dart',
      );
    });

    test('an absolute dir no package claims is its own root', () {
      expect(
        partDirective(
          const EntityConfig(name: 'Sample', outputDir: '/tmp/proj/src'),
        ),
        '../_br_/sample/sample.part.dart',
      );
    });

    test('an absolute dir inside a package is read from its pubspec root', () {
      final root = Directory.systemTemp.createTempSync('zorphy_297_root_');
      try {
        File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x\n');
        final inside = p.join(root.path, 'domain', 'entities');
        expect(
          partDirective(EntityConfig(name: 'Sample', outputDir: inside)),
          '../../../_br_/domain/entities/sample/sample.part.dart',
        );
      } finally {
        root.deleteSync(recursive: true);
      }
    });

    test('a subtype library points at its own shared part', () {
      expect(
        partDirective(const EntityConfig(name: 'Circle'), subtype: true),
        '../../../../_br_/src/domain/entities/circle/circle.part.dart',
      );
    });
  });
}
