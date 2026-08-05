/// Doctor service for zorphy.
///
/// Scans a Dart project for stale .zorphy.dart generated part files,
/// optionally deletes them, runs build_runner for clean regeneration,
/// and reports on project health (including InvalidType remnants).
///
/// Designed with injectable dependencies (file system, process runner)
/// for testability without heavyweight mocking.
library;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/doctor_result.dart';

/// Functional type for listing .zorphy.dart files recursively.
/// Returns absolute paths of all matching files.
typedef FindGeneratedFilesFunction = List<String> Function(
  String projectDir, {
  List<String> sourceDirs,
});

/// Functional type for deleting a single file.
/// Returns true if the file was successfully deleted.
typedef DeleteFileFunction = bool Function(String path);

/// Functional type for running a subprocess (named differently to
/// avoid export collision with version_checker's RunProcessFunction).
typedef DoctorProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> args, {
  String? workingDirectory,
});

/// Functional type for reading a file's content.
typedef ReadFileFunction = String Function(String path);

/// Service that performs the "doctor" workflow:
/// 1. Scan for *.zorphy.dart files
/// 2. Delete them (or preview with dry-run)
/// 3. Run build_runner for clean regeneration
/// 4. Report counts and InvalidType occurrences
class DoctorService {
  /// Root directory of the project.
  final String projectDir;

  /// Source directories to scan (relative to projectDir).
  final List<String> sourceDirs;

  /// Overrideable file finder for testing.
  final FindGeneratedFilesFunction? findFiles;

  /// Overrideable file deleter for testing.
  final DeleteFileFunction? deleteFile;

  /// Overrideable process runner for testing.
  final DoctorProcessRunner? processRunner;

  /// Overrideable file reader for testing.
  final ReadFileFunction? readFile;

  DoctorService({
    required this.projectDir,
    List<String>? sourceDirs,
    this.findFiles,
    this.deleteFile,
    this.processRunner,
    this.readFile,
  }) : sourceDirs = sourceDirs ?? const ['lib'];

  /// Run the full doctor workflow.
  ///
  /// If [dryRun] is true, scans and reports but does not delete or regenerate.
  Future<DoctorResult> run({bool dryRun = false}) async {
    final dirs = sourceDirs;

    // Step 1: Find all .zorphy.dart files
    final generatedFiles =
        _doFindFiles(projectDir, sourceDirs: dirs);

    // Step 2: Delete files (unless dry-run)
    final deletedFiles = <String>[];
    if (dryRun) {
      deletedFiles.addAll(generatedFiles);
    } else {
      for (final filePath in generatedFiles) {
        if (_doDeleteFile(filePath)) {
          deletedFiles.add(filePath);
        }
      }
    }

    // Step 3: Run build_runner (unless dry-run)
    var buildOutput = '';
    int? buildExitCode;
    if (!dryRun) {
      final result = await _doRunProcess(
        'dart',
        ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        workingDirectory: projectDir,
      );
      buildOutput = '${result.stdout}\n${result.stderr}';
      buildExitCode = result.exitCode;
    }

    // Step 4: Count regenerated files and check for InvalidType
    int regeneratedCount = 0;
    final remainingInvalidTypeFiles = <String>[];

    final filesAfterBuild =
        _doFindFiles(projectDir, sourceDirs: dirs);

    if (!dryRun) {
      // Count files that exist now but weren't in the original set
      // (or simply count all current .zorphy.dart files as regenerated)
      regeneratedCount = filesAfterBuild.length;

      // Scan for InvalidType in the regenerated files
      for (final filePath in filesAfterBuild) {
        try {
          final content = _doReadFile(filePath);
          if (content.contains('InvalidType')) {
            remainingInvalidTypeFiles.add(filePath);
          }
        } catch (_) {
          // If we can't read a file, skip it
        }
      }
    }

    return DoctorResult(
      deletedFiles: deletedFiles,
      regeneratedCount: regeneratedCount,
      remainingInvalidTypeFiles: remainingInvalidTypeFiles,
      dryRun: dryRun,
      projectDir: projectDir,
      buildOutput: buildOutput,
      buildExitCode: buildExitCode,
    );
  }

  /// Find all .zorphy.dart files in the project.
  List<String> _doFindFiles(
    String dir, {
    List<String> sourceDirs = const ['lib'],
  }) {
    if (findFiles != null) {
      return findFiles!(dir, sourceDirs: sourceDirs);
    }

    final results = <String>[];
    for (final sourceDir in sourceDirs) {
      final absDir = p.join(dir, sourceDir);
      final dirEntity = Directory(absDir);
      if (!dirEntity.existsSync()) continue;

      for (final entity
          in dirEntity.listSync(recursive: true, followLinks: false)) {
        if (entity is File && entity.path.endsWith('.zorphy.dart')) {
          results.add(entity.path);
        }
      }
    }
    return results;
  }

  /// Delete a single file. Returns true on success.
  bool _doDeleteFile(String path) {
    if (deleteFile != null) {
      return deleteFile!(path);
    }
    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Run a subprocess.
  Future<ProcessResult> _doRunProcess(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async {
    if (processRunner != null) {
      return processRunner!(executable, args,
          workingDirectory: workingDirectory);
    }

    return Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
  }

  /// Read file content as string.
  String _doReadFile(String path) {
    if (readFile != null) {
      return readFile!(path);
    }
    return File(path).readAsStringSync();
  }
}
