import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zorphy/src/cli/entity_creator.dart';
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

  group('the part directive names the colocated <library>.zorphy.dart', () {
    String partDirective(EntityConfig config, {bool subtype = false}) {
      // EntityCreator resolves the on-disk output dir to a package-relative
      // one before generating; the generator itself stays filesystem-free.
      final generatorConfig = config.copyWith(
        outputDir: EntityCreator.packageRelativeOutputDir(
          config.outputDir ?? config.defaultOutputDir,
        ),
      );
      final source = subtype
          ? EntityTemplateGenerator.generateSubtype(
              const EntityConfig(name: 'Shape', isSealed: true),
              generatorConfig,
              'Shape',
              true,
              const [],
            )
          : EntityTemplateGenerator.generate(generatorConfig, const []);
      return RegExp(
        r"^part '(.+)';",
        multiLine: true,
      ).firstMatch(source)!.group(1)!;
    }

    test('the default location is colocated beside the library', () {
      expect(
        partDirective(const EntityConfig(name: 'Todo')),
        'todo.zorphy.dart',
      );
    });

    test('follows a custom lib/ output dir', () {
      expect(
        partDirective(
          const EntityConfig(name: 'Money', outputDir: 'lib/src/core/params'),
        ),
        'money.zorphy.dart',
      );
    });

    test('a library outside lib/ is colocated beside it', () {
      expect(
        partDirective(
          const EntityConfig(name: 'Sample', outputDir: 'test/fixtures'),
        ),
        'sample.zorphy.dart',
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
        'todo.zorphy.dart',
      );
    });

    test('an absolute dir no package claims is its own root', () {
      expect(
        partDirective(
          const EntityConfig(name: 'Sample', outputDir: '/tmp/proj/src'),
        ),
        'sample.zorphy.dart',
      );
    });

    test('an absolute dir inside a package is read from its pubspec root', () {
      final root = Directory.systemTemp.createTempSync('zorphy_297_root_');
      try {
        File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('name: x\n');
        final inside = p.join(root.path, 'domain', 'entities');
        expect(
          partDirective(EntityConfig(name: 'Sample', outputDir: inside)),
          'sample.zorphy.dart',
        );
      } finally {
        root.deleteSync(recursive: true);
      }
    });

    test('a lib directory above the package root is not mistaken for it', () {
      // The package root is `<tmp>/lib/app` (it holds the pubspec); the
      // `lib` segment sits ABOVE it, so the package-relative dir is
      // `domain/entities`, never `lib/app/domain/entities`.
      final root = Directory.systemTemp.createTempSync('zorphy_297_libroot_');
      try {
        final packageRoot = p.join(root.path, 'lib', 'app');
        Directory(packageRoot).createSync(recursive: true);
        final pubspec = File(p.join(packageRoot, 'pubspec.yaml'));
        pubspec.writeAsStringSync('name: x\n');
        final inside = p.join(packageRoot, 'domain', 'entities');
        expect(
          partDirective(EntityConfig(name: 'Sample', outputDir: inside)),
          'sample.zorphy.dart',
        );
      } finally {
        root.deleteSync(recursive: true);
      }
    });

    test('the part literal is the bare colocated file name', () {
      // Colocation means the part URI never embeds the output dir, so no
      // path segment (and no quote in one) can reach the single-quoted
      // literal — the directive is always `<snakeName>.zorphy.dart`.
      final source = EntityTemplateGenerator.generate(
        const EntityConfig(name: 'Sample', outputDir: "lib/owner's_models"),
        const [],
      );
      expect(source, contains("part 'sample.zorphy.dart';"));
      expect(source, isNot(contains('_br_')));
    });

    test('a subtype library points at its own colocated part', () {
      expect(
        partDirective(const EntityConfig(name: 'Circle'), subtype: true),
        'circle.zorphy.dart',
      );
    });

    test(
      'the part is named <library>.zorphy.dart, never a _br_ mirror path',
      () {
        final uri = partDirective(const EntityConfig(name: 'Todo'));
        expect(uri, endsWith('.zorphy.dart'));
        expect(uri, isNot(contains('_br_')));
        expect(uri, isNot(endsWith('.part.dart')));
      },
    );
  });
}
