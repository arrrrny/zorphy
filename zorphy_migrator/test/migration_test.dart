import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zorphy_migrator/src/cli.dart';
import 'package:zorphy_migrator/src/exchangeable_detector.dart';
import 'package:zorphy_migrator/src/freezed_detector.dart';
import 'package:zorphy_migrator/src/mapping.dart';
import 'package:zorphy_migrator/src/model.dart';
import 'package:zorphy_migrator/src/rewriter.dart';

final fixturesDir = p.join(Directory.current.path, 'test', 'fixtures');

/// Fixtures that must convert to `expected.dart` byte-identically.
const convertibleFixtures = [
  'simple_class',
  'nullable_fields',
  'generics',
  'union',
  'default_value',
  'json_key',
  'json_roundtrip',
];

/// Fixtures that must stay untouched and land in the report.
const reportOnlyFixtures = ['unfreezed', 'custom_method'];

void main() {
  group('golden fixtures', () {
    for (final name in convertibleFixtures) {
      test('$name converts byte-identical to expected.dart', () async {
        final dir = p.join(fixturesDir, name);
        final inputFile = p.join(dir, 'input.dart');
        final expected = File(
          p.join(dir, 'expected.dart'),
        ).readAsStringSync();

        final models = await FreezedDetector().detect([
          File(inputFile).absolute.path,
        ]);
        expect(
          models.where((m) => m.isMigratable),
          isNotEmpty,
          reason: 'no migratable class detected in $name',
        );

        final source = File(inputFile).readAsStringSync();
        final renderer = ZorphyRenderer(
          siblingClassNames: models.map((m) => m.name).toSet(),
        );
        final rewriter = Rewriter();
        final revised = rewriter.applySpans(
          source,
          replacementsFor(models, renderer.render),
        );

        expect(revised.trimRight(), expected.trimRight());
      });
    }

    for (final name in reportOnlyFixtures) {
      test('$name is report-only (untouched, manual item recorded)', () async {
        final dir = p.join(fixturesDir, name);
        final inputFile = File(p.join(dir, 'input.dart'));
        final source = inputFile.readAsStringSync();

        final models = await FreezedDetector().detect([
          inputFile.absolute.path,
        ]);
        expect(models, isNotEmpty, reason: 'no class detected in $name');

        final renderer = ZorphyRenderer(
          siblingClassNames: models.map((m) => m.name).toSet(),
        );
        final rewriter = Rewriter();
        final revised = rewriter.applySpans(
          source,
          replacementsFor(models, renderer.render),
        );

        // File content unchanged — nothing migratable was rewritten.
        expect(revised, source);
        // Every detected class carries at least one manual item.
        for (final m in models) {
          expect(
            m.manualItems,
            isNotEmpty,
            reason: '${m.name} should produce a manual item',
          );
        }
      });
    }
  });

  group('exchangeable fixtures (@ExchangeableObject/@ExchangeableEnum)', () {
    for (final name in ['exchangeable_object', 'exchangeable_enum']) {
      test('$name converts byte-identical to expected.dart', () async {
        final dir = p.join(fixturesDir, name);
        final inputFile = p.join(dir, 'input.dart');
        final expected = File(
          p.join(dir, 'expected.dart'),
        ).readAsStringSync();

        final models = await ExchangeableDetector().detect([
          File(inputFile).absolute.path,
        ]);
        expect(
          models.where((m) => m.isMigratable),
          isNotEmpty,
          reason: 'no migratable model detected in $name',
        );

        final source = File(inputFile).readAsStringSync();
        final renderer = ZorphyRenderer(
          siblingClassNames: models.map((m) => m.name).toSet(),
        );
        final rewriter = Rewriter();
        final revised = rewriter.applySpans(
          source,
          replacementsFor(models, renderer.render),
        );

        expect(revised.trimRight(), expected.trimRight());
      });
    }

    test('detector strips the codegen `_` suffix and records dialects', () async {
      final inputFile = File(
        p.join(fixturesDir, 'exchangeable_object', 'input.dart'),
      );
      final models = await ExchangeableDetector().detect([
        inputFile.absolute.path,
      ]);
      final names = models.map((m) => m.name).toSet();
      expect(names, containsAll(['NavigationAction', 'URLRequest']));
      expect(
        models.every((m) => m.dialect == ModelDialect.exchangeableObject),
        isTrue,
      );
      // Fields carry types, required flags and constructor defaults.
      final navigation = models.singleWhere((m) => m.name == 'NavigationAction');
      final title = navigation.fields.singleWhere((f) => f.name == 'title');
      expect(title.defaultExpression, "'default-title'");
      expect(title.isRequired, isFalse);
      expect(
        navigation.fields.singleWhere((f) => f.name == 'request').isRequired,
        isTrue,
      );
      expect(
        navigation.fields.singleWhere((f) => f.name == 'request').type,
        'URLRequest_',
      );
    });

    test('enum detector preserves members and reports non-sequential wires',
        () async {
      final inputFile = File(
        p.join(fixturesDir, 'exchangeable_enum', 'input.dart'),
      );
      final models = await ExchangeableDetector().detect([
        inputFile.absolute.path,
      ]);
      final navigation = models.singleWhere((m) => m.name == 'NavigationType');
      expect(
        navigation.enumMembers,
        ['LINK_ACTIVATED', 'FORM_SUBMITTED'],
      );
      expect(navigation.manualItems, isEmpty);
      expect(navigation.isMigratable, isTrue);
    });
  });

  group('CLI', () {
    late Directory scratch;

    setUp(() {
      scratch = Directory.systemTemp.createTempSync('zorphy_migrator_test');
    });

    tearDown(() {
      scratch.deleteSync(recursive: true);
    });

    /// Stages a fixture into a minimal valid Dart package — the migrator
    /// uses resolved AST, so a package context with freezed_annotation
    /// resolvable is required (by design; it errors with exit 2 otherwise).
    String stageFixture(String name) {
      final target = p.join(scratch.path, name);
      Directory(target).createSync(recursive: true);
      for (final file in Directory(
        p.join(fixturesDir, name),
      ).listSync()) {
        // Only stage the freezed input — expected.dart is zorphy output
        // and must not be scanned as a migration source.
        if (file is File && p.basename(file.path) == 'input.dart') {
          file.copySync(p.join(target, p.basename(file.path)));
        }
      }
      File(p.join(target, 'pubspec.yaml')).writeAsStringSync(
        'name: scratch_$name\n'
        'environment:\n'
        '  sdk: ">=3.8.0 <4.0.0"\n'
        'dependencies:\n'
        '  freezed_annotation: ^3.1.0\n',
      );
      final result = Process.runSync('dart', ['pub', 'get'],
          workingDirectory: target);
      if (result.exitCode != 0) {
        fail('pub get failed in scratch package: ${result.stderr}');
      }
      return target;
    }

    test('--dry-run writes no files', () async {
      final dir = stageFixture('simple_class');
      final inputFile = File(p.join(dir, 'input.dart'));
      final before = inputFile.readAsBytesSync();

      final code = await MigratorCli().run(['migrate', dir, '--dry-run']);

      expect(code, MigratorCli.exitClean);
      expect(inputFile.readAsBytesSync(), before);
    });

    test('--apply rewrites the file in place', () async {
      final dir = stageFixture('simple_class');
      final inputFile = File(p.join(dir, 'input.dart'));

      final code = await MigratorCli().run(['migrate', dir, '--apply']);

      expect(code, MigratorCli.exitClean);
      final expected = File(
        p.join(fixturesDir, 'simple_class', 'expected.dart'),
      ).readAsStringSync();
      expect(inputFile.readAsStringSync().trimRight(), expected.trimRight());
    });

    test('--apply rewrites @ExchangeableObject files in place', () async {
      final dir = stageFixture('exchangeable_object');
      final inputFile = File(p.join(dir, 'input.dart'));

      final code = await MigratorCli().run(['migrate', dir, '--apply']);

      expect(code, MigratorCli.exitClean);
      final expected = File(
        p.join(fixturesDir, 'exchangeable_object', 'expected.dart'),
      ).readAsStringSync();
      expect(inputFile.readAsStringSync().trimRight(), expected.trimRight());
    });

    test('--apply rewrites @ExchangeableEnum files in place', () async {
      final dir = stageFixture('exchangeable_enum');
      final inputFile = File(p.join(dir, 'input.dart'));

      final code = await MigratorCli().run(['migrate', dir, '--apply']);

      expect(code, MigratorCli.exitClean);
      final expected = File(
        p.join(fixturesDir, 'exchangeable_enum', 'expected.dart'),
      ).readAsStringSync();
      expect(inputFile.readAsStringSync().trimRight(), expected.trimRight());
    });

    test('directory without models warns and exits 1 instead of clean',
        () async {
      final dir = stageFixture('simple_class');
      File(p.join(dir, 'input.dart')).deleteSync();
      File(p.join(dir, 'plain.dart')).writeAsStringSync('class Plain {}\n');

      final code = await MigratorCli().run(['migrate', dir]);

      expect(code, MigratorCli.exitManualItems);
    });

    test('--fail-on-manual exits 1 when manual items exist', () async {
      final dir = stageFixture('unfreezed');

      final code = await MigratorCli().run([
        'migrate',
        dir,
        '--apply',
        '--fail-on-manual',
      ]);

      expect(code, MigratorCli.exitManualItems);
      // Unmigratable file stays untouched.
      final expected = File(
        p.join(fixturesDir, 'unfreezed', 'expected.dart'),
      ).readAsStringSync();
      expect(
        File(p.join(dir, 'input.dart')).readAsStringSync().trimRight(),
        expected.trimRight(),
      );
    });

    test('--report writes markdown with manual items and next steps', () async {
      final dir = stageFixture('custom_method');
      final reportFile = p.join(scratch.path, 'REPORT.md');

      final code = await MigratorCli().run([
        'migrate',
        dir,
        '--apply',
        '--report',
        reportFile,
      ]);

      expect(code, MigratorCli.exitClean);
      final report = File(reportFile).readAsStringSync();
      expect(report, contains('Needs manual attention (1)'));
      expect(report, contains('Money.format'));
      expect(report, contains('## Next steps'));
      expect(report, contains('*.freezed.dart'));
    });

    test('dry-run on directory recurses and skips generated files', () async {
      final dir = stageFixture('simple_class');
      // Plant a generated file that must be ignored.
      File(
        p.join(dir, 'ignored.freezed.dart'),
      ).writeAsStringSync('// generated\n');
      File(p.join(dir, 'ignored.g.dart')).writeAsStringSync('// generated\n');

      final code = await MigratorCli().run(['migrate', dir]);
      expect(code, MigratorCli.exitClean);
      expect(
        File(p.join(dir, 'ignored.freezed.dart')).readAsStringSync(),
        '// generated\n',
      );
    });
  });

  group('report model', () {
    test('manual items render file:line and reason', () {
      const item = ManualItem(
        filePath: '/x/y.dart',
        line: 12,
        construct: 'Foo.bar',
        reason: 'custom method',
      );
      expect(item.line, 12);
      expect(item.reason, contains('custom method'));
    });
  });
}
