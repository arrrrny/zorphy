import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zorphy_migrator/src/cli.dart';

/// End-to-end smoke test: a realistic 11-class freezed project (including
/// a union) is migrated, then the output is compiled against zorphy 2.0
/// with build_runner + dart analyze.
void main() {
  test(
    'smoke fixture migrates end-to-end and compiles against zorphy 2.0',
    () async {
      final root = Directory.systemTemp.createTempSync('zorphy_smoke');
      addTearDown(() => root.deleteSync(recursive: true));

      final repoRoot = p.normalize(
        p.join(Directory.current.path, '..'),
      );

      // 1. Stage the freezed source project.
      final libDir = p.join(root.path, 'lib');
      Directory(libDir).createSync(recursive: true);
      File(p.join(libDir, 'models.dart')).writeAsStringSync(
        File(
          p.join(Directory.current.path, 'test', 'fixtures', 'smoke',
              'input.dart'),
        ).readAsStringSync(),
      );
      File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: smoke_project
environment:
  sdk: ">=3.8.0 <4.0.0"
dependencies:
  freezed_annotation: ^3.1.0
  zorphy_annotation: ^2.0.0
dev_dependencies:
  zorphy: ^2.0.0
  build_runner: ^2.15.2
  json_serializable: ^6.14.0
  json_annotation: ^4.12.0
dependency_overrides:
  zorphy_annotation:
    path: ${p.join(repoRoot, 'zorphy_annotation')}
  zorphy:
    path: ${p.join(repoRoot, 'zorphy')}
''');
      _run('dart', ['pub', 'get'], root.path);

      // 2. Migrate.
      final code = await MigratorCli().run([
        'migrate',
        libDir,
        '--apply',
        '--report',
        p.join(root.path, 'MIGRATION.md'),
        '--fail-on-manual',
      ]);
      expect(code, MigratorCli.exitClean);

      final migrated = File(p.join(libDir, 'models.dart')).readAsStringSync();
      expect(migrated, isNot(contains('@freezed')));
      expect(migrated, contains('abstract class \$\$PaymentMethod'));
      expect(migrated, contains('implements \$\$PaymentMethod'));
      expect(migrated, contains('ZorphyPreset.lean'));
      expect(migrated, contains('generateJson: true'));

      final report = File(
        p.join(root.path, 'MIGRATION.md'),
      ).readAsStringSync();
      expect(report, contains('Converted classes (11)'));
      expect(report, contains('Needs manual attention (0)'));

      // 3. Post-migration steps a user would do: swap the import, fix the
      //    part directives, drop the freezed dep.
      final finalized = migrated
          .replaceAll(
            "import 'package:freezed_annotation/freezed_annotation.dart';",
            "import 'package:zorphy_annotation/zorphy_annotation.dart';",
          )
          .replaceAll("part 'input.freezed.dart';", "part 'models.zorphy.dart';\npart 'models.g.dart';");
      File(p.join(libDir, 'models.dart')).writeAsStringSync(finalized);

      // 4. Generate with zorphy 2.0 and analyze.
      _run(
        'dart',
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        root.path,
      );
      expect(
        File(p.join(libDir, 'models.zorphy.dart')).existsSync(),
        isTrue,
        reason: 'zorphy 2.0 should generate models.zorphy.dart',
      );
      _run('dart', ['analyze'], root.path);
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

void _run(String exe, List<String> args, String cwd) {
  final result = Process.runSync(exe, args, workingDirectory: cwd);
  if (result.exitCode != 0) {
    fail(
      '$exe ${args.join(' ')} failed (${result.exitCode}):\n'
      '${result.stdout}\n${result.stderr}',
    );
  }
}
