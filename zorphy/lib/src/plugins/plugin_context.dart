import 'package:code_builder/code_builder.dart';

import '../models/class_metadata.dart';
import '../models/generation_config.dart';

/// Context provided to each plugin during the transform pass.
///
/// Accumulates imports and diagnostics across all plugins for a
/// single class generation. After the plugin pass finishes, the
/// orchestrator folds accumulated imports into the [Library] directives.
class PluginContext {
  /// Metadata for the class being transformed.
  final ClassMetadata metadata;

  /// Generation configuration (preset, flags).
  final GenerationConfig config;

  /// Accumulated import directives to add to the output library.
  final List<Directive> _imports = [];

  /// Accumulated diagnostic messages.
  final List<PluginDiagnostic> _diagnostics = [];

  /// Creates a plugin context for the given class generation.
  PluginContext({required this.metadata, required this.config});

  /// Adds an import directive to the output library.
  ///
  /// [uri] is the import URI (e.g. 'package:my_plugin/my_plugin.dart').
  /// [asName] is an optional `as` prefix.
  /// [showNames] and [hideNames] control combinator visibility.
  void addImport(
    String uri, {
    String? asName,
    List<String>? showNames,
    List<String>? hideNames,
  }) {
    _imports.add(
      Directive.import(
        uri,
        as: asName,
        show: showNames ?? const [],
        hide: hideNames ?? const [],
      ),
    );
  }

  /// Records a diagnostic message.
  ///
  /// [level] indicates severity. [message] is the human-readable text.
  /// Diagnostics are collected and can be surfaced after the plugin pass.
  void diagnostic(
    String message, {
    PluginDiagnosticLevel level = PluginDiagnosticLevel.info,
  }) {
    _diagnostics.add(PluginDiagnostic(message: message, level: level));
  }

  /// The accumulated import directives (read by the orchestrator).
  List<Directive> get imports => List.unmodifiable(_imports);

  /// The accumulated diagnostics (read by the orchestrator).
  List<PluginDiagnostic> get diagnostics => List.unmodifiable(_diagnostics);
}

/// Severity level for a plugin diagnostic.
enum PluginDiagnosticLevel {
  /// Informational message.
  info,

  /// A potential issue that may warrant attention.
  warning,

  /// A problem that prevents correct code generation.
  error,
}

/// A single diagnostic produced by a plugin.
class PluginDiagnostic {
  /// Human-readable diagnostic message.
  final String message;

  /// Severity level.
  final PluginDiagnosticLevel level;

  /// Creates a diagnostic with the given [message] and [level].
  const PluginDiagnostic({required this.message, required this.level});
}
