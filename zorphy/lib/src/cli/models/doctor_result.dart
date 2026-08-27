/// Result models for the zorphy doctor command.
library;

/// Overall health status after running doctor.
enum DoctorHealth {
  /// No issues — all generated files are clean.
  healthy,

  /// Some warnings (e.g. InvalidType remnants) but regeneration succeeded.
  warnings,

  /// Regeneration failed or critical problems remain.
  unhealthy,
}

/// Aggregated result of the doctor command.
class DoctorResult {
  /// Files that were (or would be) deleted.
  final List<String> deletedFiles;

  /// Number of .zorphy.dart files regenerated after build_runner.
  final int regeneratedCount;

  /// Files still containing 'InvalidType' after regeneration.
  final List<String> remainingInvalidTypeFiles;

  /// Whether this was a dry-run (no actual deletion or regeneration).
  final bool dryRun;

  /// The project directory that was doctored.
  final String projectDir;

  /// Output from the build_runner process (stdout).
  final String buildOutput;

  /// Exit code of the build_runner process, or null if not run.
  final int? buildExitCode;

  const DoctorResult({
    this.deletedFiles = const [],
    this.regeneratedCount = 0,
    this.remainingInvalidTypeFiles = const [],
    this.dryRun = false,
    required this.projectDir,
    this.buildOutput = '',
    this.buildExitCode,
  });

  /// Number of files deleted.
  int get deletedCount => deletedFiles.length;

  /// Whether any InvalidType occurrences remain.
  bool get hasInvalidType => remainingInvalidTypeFiles.isNotEmpty;

  /// Overall health assessment.
  DoctorHealth get health {
    if (buildExitCode != null && buildExitCode != 0) {
      return DoctorHealth.unhealthy;
    }
    if (hasInvalidType) {
      return DoctorHealth.warnings;
    }
    return DoctorHealth.healthy;
  }

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln('Zorphy Doctor Report');
    buf.writeln('Directory: $projectDir');
    if (dryRun) {
      buf.writeln('Mode: dry-run (no changes made)');
    }
    buf.writeln('');

    buf.writeln('Deleted $deletedCount stale .zorphy.dart file(s)');
    if (deletedFiles.isNotEmpty) {
      for (final f in deletedFiles) {
        buf.writeln('  - $f');
      }
    }
    buf.writeln('');

    if (dryRun) {
      buf.writeln(
        'Would run: dart run build_runner build --delete-conflicting-outputs',
      );
    } else {
      buf.writeln(
        'Build runner exited with code ${buildExitCode ?? "not run"}',
      );
      buf.writeln('Regenerated $regeneratedCount .zorphy.dart file(s)');
    }
    buf.writeln('');

    if (hasInvalidType) {
      buf.writeln(
        'WARNING: InvalidType still found in ${remainingInvalidTypeFiles.length} file(s):',
      );
      for (final f in remainingInvalidTypeFiles) {
        buf.writeln('  - $f');
      }
      buf.writeln('');
    }

    switch (health) {
      case DoctorHealth.healthy:
        buf.writeln('Project health: healthy');
      case DoctorHealth.warnings:
        buf.writeln('Project health: warnings (InvalidType remnants)');
      case DoctorHealth.unhealthy:
        buf.writeln('Project health: unhealthy (build_runner failed)');
    }

    return buf.toString();
  }

  /// JSON-serializable map for --json output.
  Map<String, dynamic> toJson() {
    return {
      'projectDir': projectDir,
      'dryRun': dryRun,
      'deletedCount': deletedCount,
      'deletedFiles': deletedFiles,
      'regeneratedCount': regeneratedCount,
      'remainingInvalidTypeFiles': remainingInvalidTypeFiles,
      'health': health.name,
      'buildExitCode': buildExitCode,
    };
  }
}
