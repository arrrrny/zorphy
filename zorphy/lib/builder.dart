import 'package:build/build.dart';

import 'src/shared_part_builder.dart';

/// Creates the build_runner builder for Zorphy code generation.
///
/// Since zorphy 3.0.0 this returns a shared-part builder: one
/// `<library>.zorphy.part` per library via [BuildStep.librarySourceSink]
/// instead of one `.zorphy.dart` per annotated class. Falls back to a
/// standalone part file when the sink is unavailable.
///
/// **Note:** The `plugins` builder option is currently reserved for
/// future use (v2.1+). URI-based plugin loading is not yet implemented.
/// For now, plugins must be registered programmatically by passing a
/// pre-populated [PluginRegistry] to [ZorphyGenerator].
///
/// Example `build.yaml`:
/// ```yaml
/// targets:
///   $default:
///     builders:
///       zorphy:
///         options:
///           plugins:
///             - package:my_plugin/my_plugin.dart
///           dry_run: false
///           force: false
/// ```
Builder zorphyBuilder(BuilderOptions options) =>
    zorphySharedPartBuilder(options);
