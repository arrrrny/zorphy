import 'dart:io';
import 'package:test/test.dart';
import 'package:zorphy/zorphy_cli.dart';

void main() {
  group('ProjectValidator', () {
    late Directory tempDir;
    late String tempPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('zorphy_test_');
      tempPath = tempDir.path;
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('reports error when pubspec.yaml is missing', () {
      final validator = ProjectValidator(projectDir: tempPath);
      final result = validator.validate();

      expect(result.hasErrors, isTrue);
      expect(
        result.findings.any(
          (f) => f.message.contains('pubspec.yaml not found'),
        ),
        isTrue,
      );
    });

    test('reports error when zorphy not in dependencies', () async {
      await File('$tempPath/pubspec.yaml').writeAsString('''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  some_other: ^1.0.0
''');

      final validator = ProjectValidator(projectDir: tempPath);
      final result = validator.validate();

      expect(result.hasErrors, isTrue);
      expect(
        result.findings.any(
          (f) => f.message.contains("'zorphy' not found in dependencies"),
        ),
        isTrue,
      );
    });

    test('passes pub check when zorphy is in dependencies', () async {
      await File('$tempPath/pubspec.yaml').writeAsString('''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  zorphy: ^2.0.0
  zorphy_annotation: ^2.0.0
dev_dependencies:
  build_runner: ^2.0.0
''');

      final validator = ProjectValidator(projectDir: tempPath);
      final result = validator.validate();

      expect(
        result.findings.any(
          (f) => f.message.contains("'zorphy' not found in dependencies"),
        ),
        isFalse,
      );
      expect(
        result.findings.any(
          (f) => f.message.contains("'zorphy_annotation' not found"),
        ),
        isFalse,
      );
    });

    test('detects annotated file with missing generated files', () async {
      await File('$tempPath/pubspec.yaml').writeAsString('''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  zorphy: ^2.0.0
  zorphy_annotation: ^2.0.0
dev_dependencies:
  build_runner: ^2.0.0
''');

      final libDir = Directory('$tempPath/lib')..createSync(recursive: true);
      await File('${libDir.path}/user.dart').writeAsString('''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'user.zorphy.dart';
part 'user.g.dart';

@Zorphy()
abstract class \$User {}
''');

      final validator = ProjectValidator(projectDir: tempPath);
      final result = validator.validate();

      expect(result.filesScanned, equals(1));
      final missingFindings = result.findings.where(
        (f) => f.message.contains('does not exist'),
      );
      expect(missingFindings.length, equals(2));
    });

    test('detects missing part directives', () async {
      await File('$tempPath/pubspec.yaml').writeAsString('''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  zorphy: ^2.0.0
  zorphy_annotation: ^2.0.0
''');

      final libDir = Directory('$tempPath/lib')..createSync(recursive: true);
      await File('${libDir.path}/product.dart').writeAsString('''
import 'package:zorphy_annotation/zorphy_annotation.dart';

@Zorphy()
abstract class \$Product {}
''');

      final validator = ProjectValidator(projectDir: tempPath);
      final result = validator.validate();

      expect(
        result.findings.any(
          (f) => f.message.contains('Missing part directive'),
        ),
        isTrue,
      );
    });

    test(
      'no findings when project is valid with all generated files',
      () async {
        await File('$tempPath/pubspec.yaml').writeAsString('''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  zorphy: ^2.0.0
  zorphy_annotation: ^2.0.0
dev_dependencies:
  build_runner: ^2.0.0
''');

        final libDir = Directory('$tempPath/lib')..createSync(recursive: true);
        final libPath = libDir.path;

        final source = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'order.zorphy.dart';
part 'order.g.dart';

@Zorphy()
abstract class \$Order {}
''';
        File('$libPath/order.dart')
          ..createSync()
          ..writeAsStringSync(source);

        File('$libPath/order.zorphy.dart').createSync();
        File('$libPath/order.g.dart').createSync();

        final validator = ProjectValidator(projectDir: tempPath);
        final result = validator.validate();

        expect(result.errorCount, equals(0));
        expect(result.findings, isEmpty);
      },
    );

    test('warns when source is newer than generated file', () async {
      await File('$tempPath/pubspec.yaml').writeAsString('''
name: test_project
environment:
  sdk: '>=3.0.0 <4.0.0'
dependencies:
  zorphy: ^2.0.0
  zorphy_annotation: ^2.0.0
dev_dependencies:
  build_runner: ^2.0.0
''');

      final libDir = Directory('$tempPath/lib')..createSync(recursive: true);
      final libPath = libDir.path;

      // Create generated files first
      File('$libPath/item.zorphy.dart').createSync();
      File('$libPath/item.g.dart').createSync();

      // Wait to ensure different filesystem timestamps (1s minimum for ext4)
      await Future.delayed(const Duration(seconds: 2));

      // Create source file after generated files (newer)
      final source = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'item.zorphy.dart';
part 'item.g.dart';

@Zorphy()
abstract class \$Item {}
''';
      File('$libPath/item.dart')
        ..createSync()
        ..writeAsStringSync(source);

      final validator = ProjectValidator(projectDir: tempPath);
      final result = validator.validate();

      final staleFindings = result.findings.where(
        (f) =>
            f.severity == ValidationSeverity.warning &&
            f.message.contains('stale'),
      );
      expect(staleFindings.length, equals(2));
    });

    test('ValidationResult.toString() formats correctly', () {
      final result = ValidationResult(
        findings: [
          ValidationFinding(
            message: 'test error',
            severity: ValidationSeverity.error,
            filePath: '/some/file.dart',
          ),
          ValidationFinding(
            message: 'test warning',
            severity: ValidationSeverity.warning,
          ),
        ],
        validatedDir: '/tmp/test',
        filesScanned: 5,
      );

      final output = result.toString();
      expect(output.contains('Zorphy Validation Report'), isTrue);
      expect(output.contains('1 error(s)'), isTrue);
      expect(output.contains('1 warning(s)'), isTrue);
      expect(output.contains('test error'), isTrue);
      expect(output.contains('test warning'), isTrue);
    });
  });
}
