/// Example demonstrating how to write and register a Zorphy plugin.
///
/// This file defines a no-op plugin (`LoggingPlugin`) that logs every
/// class it transforms. It compiles with `dart analyze` and shows the
/// registration pattern you would use in your own projects.
///
/// To activate this plugin, add it to your `build.yaml`:
///
/// ```yaml
/// targets:
///   $default:
///     builders:
///       zorphy:zorphy:
///         options:
///           plugins:
///             - package:your_package/your_plugin.dart
/// ```

import 'package:code_builder/code_builder.dart';
import 'package:zorphy/zorphy_plugin.dart';

/// A minimal no-op plugin that demonstrates the ZorphyPlugin contract.
///
/// This plugin:
/// - Runs for every class (empty [decoratorNames] = universal)
/// - Logs the class name via [PluginContext.diagnostic]
/// - Does not mutate any specs (passes them through unchanged)
class LoggingPlugin extends ZorphyPlugin {
  @override
  String get name => 'logging';

  @override
  Set<String> get decoratorNames => const {};

  @override
  Spec transformClass(Spec spec, PluginContext context) {
    if (spec is Class) {
      context.diagnostic('LoggingPlugin: transforming ${spec.name}');
    }
    return spec; // no-op: return unchanged
  }

  @override
  Spec transformMethod(Spec spec, PluginContext context) => spec;

  @override
  Spec transformField(Spec spec, PluginContext context) => spec;
}

/// A plugin that adds a `generatedAt` timestamp field to every class.
///
/// Demonstrates:
/// - Adding a field via [transformClass]
/// - Using spec.rebuild to preserve all class properties
class TimestampPlugin extends ZorphyPlugin {
  @override
  String get name => 'timestamp';

  /// This plugin must run after 'logging' (if both are registered).
  @override
  Set<String> get runAfter => const {'logging'};

  @override
  Spec transformClass(Spec spec, PluginContext context) {
    if (spec is! Class) return spec;

    // Rebuild the class with an additional field.
    return spec.rebuild(
      (c) => c
        ..fields.add(
          Field((f) {
            f.name = 'generatedAt';
            f.type = refer('DateTime');
            f.modifier = FieldModifier.final$;
          }),
        ),
    );
  }

  @override
  Spec transformMethod(Spec spec, PluginContext context) => spec;

  @override
  Spec transformField(Spec spec, PluginContext context) => spec;
}

/// Programmatic registration example.
///
/// When using the builder system, plugins are resolved from
/// `build.yaml` options automatically. For programmatic use
/// (e.g. in tests or custom build pipelines), instantiate the
/// registry directly:
///
/// ```dart
/// import 'package:zorphy/zorphy_plugin.dart';
///
/// final registry = PluginRegistry();
/// registry.register(LoggingPlugin());
/// registry.register(TimestampPlugin());
///
/// // Plugins execute in topological order:
/// // 'logging' runs first, then 'timestamp'.
/// final ordered = registry.ordered();
/// print(ordered.map((p) => p.name).toList()); // [logging, timestamp]
/// ```
