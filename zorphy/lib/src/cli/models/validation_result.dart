/// Validation result models for the zorphy validate command.
library;

/// Severity levels for validation findings.
enum ValidationSeverity {
  /// No issues found.
  none,

  /// A suggestion for improvement, not required.
  info,

  /// A potential issue that may cause problems.
  warning,

  /// A definite problem that will cause errors.
  error,
}

/// A single validation finding.
class ValidationFinding {
  /// Human-readable description of the finding.
  final String message;

  /// Severity level.
  final ValidationSeverity severity;

  /// Absolute file path this finding relates to (if applicable).
  final String? filePath;

  /// Line number in the file (if applicable).
  final int? lineNumber;

  /// Suggested fix or remediation step.
  final String? fixSuggestion;

  const ValidationFinding({
    required this.message,
    required this.severity,
    this.filePath,
    this.lineNumber,
    this.fixSuggestion,
  });

  @override
  String toString() {
    final buf = StringBuffer();
    switch (severity) {
      case ValidationSeverity.error:
        buf.write('ERROR  ');
      case ValidationSeverity.warning:
        buf.write('WARN   ');
      case ValidationSeverity.info:
        buf.write('INFO   ');
      case ValidationSeverity.none:
        buf.write('OK     ');
    }
    if (filePath != null) {
      buf.write(filePath!);
      if (lineNumber != null) buf.write(':$lineNumber');
      buf.write('  ');
    }
    buf.writeln(message);
    if (fixSuggestion != null) {
      buf.writeln('       Fix: $fixSuggestion');
    }
    return buf.toString();
  }
}

/// Aggregated result of running all validation checks.
class ValidationResult {
  /// All findings from the validation run.
  final List<ValidationFinding> findings;

  /// The directory that was validated.
  final String validatedDir;

  /// Number of files scanned.
  final int filesScanned;

  const ValidationResult({
    required this.findings,
    required this.validatedDir,
    this.filesScanned = 0,
  });

  int get errorCount =>
      findings.where((f) => f.severity == ValidationSeverity.error).length;

  int get warningCount =>
      findings.where((f) => f.severity == ValidationSeverity.warning).length;

  int get infoCount =>
      findings.where((f) => f.severity == ValidationSeverity.info).length;

  bool get hasErrors => errorCount > 0;

  bool get hasIssues => findings.isNotEmpty;

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln('Zorphy Validation Report');
    buf.writeln('Directory: $validatedDir');
    buf.writeln('Files scanned: $filesScanned');
    buf.writeln('');

    if (findings.isEmpty) {
      buf.writeln('No issues found.');
    } else {
      for (final f in findings) {
        buf.write(f);
      }
      buf.writeln('');
      buf.writeln('Summary: $errorCount error(s), $warningCount warning(s), $infoCount info');
    }
    return buf.toString();
  }
}
