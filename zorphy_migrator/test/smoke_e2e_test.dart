import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zorphy_migrator/src/cli.dart';

/// End-to-end smoke test: a realistic 11-class freezed project (including
/// a union) is migrated, then the output is generated against zorphy 3.0
/// (shared parts) with build_runner + dart analyze.
void main() {
  test(
    'smoke fixture migrates end-to-end and compiles against zorphy 3.0',
    () async {
      final root = Directory.systemTemp.createTempSync('zorphy_smoke');
      addTearDown(() => root.deleteSync(recursive: true));

      final repoRoot = p.normalize(p.join(Directory.current.path, '..'));

      // 1. Stage the freezed source project.
      final libDir = p.join(root.path, 'lib');
      Directory(libDir).createSync(recursive: true);
      File(p.join(libDir, 'models.dart')).writeAsStringSync(
        File(
          p.join(
            Directory.current.path,
            'test',
            'fixtures',
            'smoke',
            'input.dart',
          ),
        ).readAsStringSync(),
      );
      File(p.join(root.path, 'pubspec.yaml')).writeAsStringSync('''
name: smoke_project
# Matches the floor `zorphy` / `zorphy_annotation` declare (>=3.11.0): the
# depth-first stack this fixture generates for only resolves there.
environment:
  sdk: ">=3.11.0 <4.0.0"
dependencies:
  freezed_annotation: ^3.1.0
  zorphy_annotation: ^3.0.0
dev_dependencies:
  zorphy: ^3.0.0
  build_runner: ^2.17.1
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
      expect(migrated, contains('@ZorphyUnion()'));
      expect(migrated, contains('@ZorphyValue()'));
      expect(migrated, contains('@ZorphyEntity(principalKey: #id)'));
      expect(migrated, isNot(contains('ZorphyPreset')));
      expect(migrated, isNot(contains('generateJson')));

      final report = File(p.join(root.path, 'MIGRATION.md')).readAsStringSync();
      expect(report, contains('Converted classes (11)'));
      expect(report, contains('Needs manual attention (0)'));

      // 3. Post-migration step a user would do: swap the import. The zorphy
      //    part directive is not hand-written — the shared-part builder inserts
      //    it — and no `.g.dart` part is needed: the v3 wire codecs are
      //    generated unconditionally.
      final finalized = migrated
          .replaceAll(
            "import 'package:freezed_annotation/freezed_annotation.dart';",
            "import 'package:zorphy_annotation/zorphy_annotation.dart';",
          )
          .replaceAll("part 'input.freezed.dart';", '');
      File(p.join(libDir, 'models.dart')).writeAsStringSync(finalized);

      // 4. Generate with zorphy 3.0 and analyze. `--delete-conflicting-outputs`
      //    is deliberately absent: build_runner 2.17 removed it and only warns,
      //    so it would not delete a stale `.zorphy.dart` if one were there.
      _run('dart', ['run', 'build_runner', 'build'], root.path);
      expect(
        File(p.join(libDir, '_br_', 'models.part.dart')).existsSync(),
        isTrue,
        reason: 'zorphy 3.0 should generate lib/_br_/models.part.dart',
      );
      expect(
        File(p.join(libDir, 'models.zorphy.dart')).existsSync(),
        isFalse,
        reason: 'zorphy 3.0 must not emit a per-file .zorphy.dart',
      );
      expect(
        File(p.join(libDir, 'models.dart')).readAsStringSync(),
        contains("_br_/models.part.dart'"),
        reason: 'build_runner should insert the shared-part directive',
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
