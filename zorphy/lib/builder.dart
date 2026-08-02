import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/zorphy_generator.dart';

/// Creates the build_runner builder for Zorphy code generation.
///
/// **Note:** The `plugins` builder option is currently reserved for
/// future use (v2.1+). URI-based plugin loading is not yet implemented.
/// For now, plugins must be registered programmatically by passing a
/// pre-populated [PluginRegistry] to [ZorphyGenerator].
///
/// Example `build.yaml` (future feature):
/// ```yaml
/// targets:
///   $default:
///     builders:
///       zorphy:
///         options:
///           plugins:
///             - package:my_plugin/my_plugin.dart
/// ```
///
/// When no `plugins` option is present, behavior is byte-identical
/// to the pre-plugin pipeline (zero regressions).
Builder zorphyBuilder(BuilderOptions options) {
  final pluginUris = _extractPluginUris(options);
  return PartBuilder(
    [ZorphyGenerator(pluginUris: pluginUris)],
    '.zorphy.dart',
    header: '''
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint
''',
  );
}

/// Extracts the `plugins` list from builder options.
///
/// Returns an empty list if the key is missing, not a [List],
/// or contains non-[String] entries (which are silently skipped).
List<String> _extractPluginUris(BuilderOptions options) {
  final raw = options.config['plugins'];
  if (raw is! List) return const [];
  return raw.whereType<String>().toList();
}
