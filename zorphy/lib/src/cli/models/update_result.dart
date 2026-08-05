/// Models for the self-update command.
library;

/// Result of checking for a CLI update.
class UpdateCheckResult {
  /// The version currently running (from the _version constant).
  final String currentVersion;

  /// The latest version available on pub.dev.
  final String? latestVersion;

  /// Whether a newer version is available.
  final bool updateAvailable;

  /// Human-readable message describing the result.
  final String message;

  /// HTTP status code from the pub.dev API call, or null if not applicable.
  final int? statusCode;

  const UpdateCheckResult({
    required this.currentVersion,
    this.latestVersion,
    required this.updateAvailable,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() {
    final buf = StringBuffer();
    if (latestVersion == null) {
      buf.writeln('Could not determine latest version.');
    } else {
      buf.writeln('Current version:  $currentVersion');
      buf.writeln('Latest version:   $latestVersion');
      if (updateAvailable) {
        buf.writeln('');
        buf.writeln('A newer version is available!');
      } else {
        buf.writeln('');
        buf.writeln('CLI is up to date.');
      }
    }
    if (message.isNotEmpty && latestVersion == null) {
      buf.writeln(message);
    }
    return buf.toString();
  }
}

/// Result of performing the self-update.
class UpdateResult {
  /// Whether the update succeeded.
  final bool success;

  /// Human-readable message describing the outcome.
  final String message;

  /// The version after the update (if verifiable).
  final String? newVersion;

  /// The exit code of the `dart pub global activate` process.
  final int? exitCode;

  const UpdateResult({
    required this.success,
    required this.message,
    this.newVersion,
    this.exitCode,
  });

  @override
  String toString() {
    final buf = StringBuffer();
    if (success) {
      buf.writeln('Update successful!');
      if (newVersion != null) {
        buf.writeln('New version: $newVersion');
      }
    } else {
      buf.writeln('Update failed.');
      if (exitCode != null) {
        buf.writeln('Exit code: $exitCode');
      }
    }
    buf.writeln(message);
    return buf.toString();
  }
}
