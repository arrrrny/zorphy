import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:zorphy/zorphy_cli.dart';

void main() {
  group('DoctorService', () {
    late Directory tempDir;
    late String tempPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('zorphy_doctor_test_');
      tempPath = tempDir.path;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('dry-run finds .zorphy.dart files without deleting', () async {
      final libDir = Directory('$tempPath/lib')..createSync(recursive: true);
      File('${libDir.path}/user.zorphy.dart').createSync();
      File('${libDir.path}/product.zorphy.dart').createSync();
      File('${libDir.path}/other.txt').createSync();

      final service = DoctorService(projectDir: tempPath);
      final result = await service.run(dryRun: true);

      expect(result.dryRun, isTrue);
      expect(result.deletedCount, equals(2));
      expect(result.deletedFiles, containsAll([
        '${libDir.path}/user.zorphy.dart',
        '${libDir.path}/product.zorphy.dart',
      ]));
      expect(result.regeneratedCount, equals(0));
      expect(result.buildExitCode, isNull);

      // Files should still exist
      expect(File('${libDir.path}/user.zorphy.dart').existsSync(), isTrue);
      expect(File('${libDir.path}/product.zorphy.dart').existsSync(), isTrue);
    });

    test('dry-run with --json produces valid JSON', () async {
      final libDir = Directory('$tempPath/lib')..createSync(recursive: true);
      File('${libDir.path}/user.zorphy.dart').createSync();

      final service = DoctorService(projectDir: tempPath);
      final result = await service.run(dryRun: true);

      final json = jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;
      expect(json['dryRun'], isTrue);
      expect(json['deletedCount'], equals(1));
      expect(json['health'], equals('healthy'));
    });

    test('deletes .zorphy.dart files and runs build_runner', () async {
      final libDir = Directory('$tempPath/lib')..createSync(recursive: true);
      File('${libDir.path}/user.zorphy.dart').createSync();

      var processCalled = false;
      String? receivedWorkingDir;

      final service = DoctorService(
        projectDir: tempPath,
        processRunner: (executable, args, {workingDirectory}) async {
          processCalled = true;
          receivedWorkingDir = workingDirectory;
          expect(executable, equals('dart'));
          expect(args, containsAll([
            'run',
            'build_runner',
            'build',
            '--delete-conflicting-outputs',
          ]));
          return ProcessResult(0, 0, 'Build succeeded', '');
        },
      );

      final result = await service.run(dryRun: false);

      expect(result.dryRun, isFalse);
      expect(result.deletedCount, equals(1));
      expect(processCalled, isTrue);
      expect(receivedWorkingDir, equals(tempPath));
      expect(result.buildExitCode, equals(0));
      expect(result.health, equals(DoctorHealth.healthy));

      // File should be deleted
      expect(File('${libDir.path}/user.zorphy.dart').existsSync(), isFalse);
    });

    test('detects InvalidType in regenerated files', () async {
      final libDir = Directory('$tempPath/lib')..createSync(recursive: true);
      File('${libDir.path}/user.zorphy.dart').createSync();

      final service = DoctorService(
        projectDir: tempPath,
        processRunner: (executable, args, {workingDirectory}) async {
          // Simulate build_runner recreating the file with InvalidType
          File('${libDir.path}/user.zorphy.dart')
            ..createSync()
            ..writeAsStringSync(
              'class User { InvalidType? field; }',
            );
          return ProcessResult(0, 0, 'Build succeeded', '');
        },
      );

      final result = await service.run(dryRun: false);

      expect(result.regeneratedCount, equals(1));
      expect(result.hasInvalidType, isTrue);
      expect(result.remainingInvalidTypeFiles.length, equals(1));
      expect(result.health, equals(DoctorHealth.warnings));
    });

    test('reports unhealthy when build_runner fails', () async {
      final libDir = Directory('$tempPath/lib')..createSync(recursive: true);
      File('${libDir.path}/user.zorphy.dart').createSync();

      final service = DoctorService(
        projectDir: tempPath,
        processRunner: (executable, args, {workingDirectory}) async {
          return ProcessResult(1, 1, '', 'Build failed');
        },
      );

      final result = await service.run(dryRun: false);

      expect(result.buildExitCode, equals(1));
      expect(result.health, equals(DoctorHealth.unhealthy));
    });

    test('scans multiple source directories', () async {
      Directory('$tempPath/lib').createSync(recursive: true);
      Directory('$tempPath/test').createSync(recursive: true);
      File('$tempPath/lib/user.zorphy.dart').createSync();
      File('$tempPath/test/widget.zorphy.dart').createSync();

      final service = DoctorService(
        projectDir: tempPath,
        sourceDirs: ['lib', 'test'],
      );
      final result = await service.run(dryRun: true);

      expect(result.deletedCount, equals(2));
    });

    test('handles empty project with no generated files', () async {
      Directory('$tempPath/lib').createSync(recursive: true);

      final service = DoctorService(projectDir: tempPath);
      final result = await service.run(dryRun: true);

      expect(result.deletedCount, equals(0));
      expect(result.health, equals(DoctorHealth.healthy));
    });

    test('handles missing source directories gracefully', () async {
      final service = DoctorService(
        projectDir: tempPath,
        sourceDirs: ['lib', 'nonexistent'],
      );
      final result = await service.run(dryRun: true);

      expect(result.deletedCount, equals(0));
    });
  });

  group('DoctorResult', () {
    test('toString formats healthy result correctly', () {
      final result = DoctorResult(
        projectDir: '/tmp/test',
        deletedFiles: ['/tmp/test/lib/a.zorphy.dart'],
        regeneratedCount: 1,
        buildExitCode: 0,
      );

      final output = result.toString();
      expect(output, contains('Zorphy Doctor Report'));
      expect(output, contains('Deleted 1 stale .zorphy.dart file(s)'));
      expect(output, contains('Regenerated 1 .zorphy.dart file(s)'));
      expect(output, contains('Project health: healthy'));
    });

    test('toString formats dry-run result correctly', () {
      final result = DoctorResult(
        projectDir: '/tmp/test',
        deletedFiles: ['/tmp/test/lib/a.zorphy.dart'],
        dryRun: true,
      );

      final output = result.toString();
      expect(output, contains('dry-run (no changes made)'));
      expect(output,
          contains('Would run: dart run build_runner build --delete-conflicting-outputs'));
    });

    test('toString formats warnings result correctly', () {
      final result = DoctorResult(
        projectDir: '/tmp/test',
        regeneratedCount: 2,
        remainingInvalidTypeFiles: ['/tmp/test/lib/a.zorphy.dart'],
        buildExitCode: 0,
      );

      final output = result.toString();
      expect(output, contains('WARNING: InvalidType still found'));
      expect(output, contains('Project health: warnings'));
    });

    test('toString formats unhealthy result correctly', () {
      final result = DoctorResult(
        projectDir: '/tmp/test',
        buildExitCode: 1,
      );

      final output = result.toString();
      expect(output, contains('Project health: unhealthy'));
    });

    test('toJson contains all fields', () {
      final result = DoctorResult(
        projectDir: '/tmp/test',
        deletedFiles: ['a.dart', 'b.dart'],
        regeneratedCount: 2,
        remainingInvalidTypeFiles: ['a.dart'],
        dryRun: true,
        buildExitCode: 0,
      );

      final json = result.toJson();
      expect(json['projectDir'], equals('/tmp/test'));
      expect(json['dryRun'], isTrue);
      expect(json['deletedCount'], equals(2));
      expect(json['regeneratedCount'], equals(2));
      expect(json['health'], equals('warnings'));
      expect(json['buildExitCode'], equals(0));
    });

    test('health is healthy when no issues', () {
      final result = DoctorResult(
        projectDir: '/tmp',
        buildExitCode: 0,
      );
      expect(result.health, equals(DoctorHealth.healthy));
    });

    test('health is warnings when InvalidType remains', () {
      final result = DoctorResult(
        projectDir: '/tmp',
        buildExitCode: 0,
        remainingInvalidTypeFiles: ['a.dart'],
      );
      expect(result.health, equals(DoctorHealth.warnings));
    });

    test('health is unhealthy when build fails', () {
      final result = DoctorResult(
        projectDir: '/tmp',
        buildExitCode: 1,
      );
      expect(result.health, equals(DoctorHealth.unhealthy));
    });
  });
}
