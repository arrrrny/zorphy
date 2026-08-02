/// Example demonstrating how to write and register a Zorphy plugin.
///
/// This file defines a no-op plugin (`LoggingPlugin`) that logs every
/// class it transforms and adds an import. It compiles with
/// `dart analyze` and shows the registration pattern you would use
/// in your own projects.
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
///             - example/lib/plugin_example.dart
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

/// A plugin that adds a `createdAt` timestamp field to every class.
///
/// Demonstrates:
/// - Adding a field via [transformClass]
/// - Adding an import via [PluginContext.addImport]
class TimestampPlugin extends ZorphyPlugin {
  @override
  String get name => 'timestamp';

  /// This plugin must run after 'logging' (if both are registered).
  @override
  Set<String> get runAfter => const {'logging'};

  @override
  Spec transformClass(Spec spec, PluginContext context) {
    if (spec is! Class) return spec;

    // Add the import needed for the field type.
    context.addImport('package:zorphy_example/timestamp.dart');

    // Rebuild the class with an additional field.
    return Class((c) {
      c.name = spec.name;
      c.abstract = spec.abstract;
      c.sealed = spec.sealed;
      c.extend = spec.extend;
      c.types.addAll(spec.types);
      c.implements.addAll(spec.implements);
      c.mixins.addAll(spec.mixins);
      c.annotations.addAll(spec.annotations);
      c.docs.addAll(spec.docs);
      c.fields.addAll(spec.fields);
      c.methods.addAll(spec.methods);
      c.constructors.addAll(spec.constructors);
      c.fields.add(
        Field((f) {
          f.name = 'generatedAt';
          f.type = refer('DateTime');
          f.modifier = FieldModifier.final$;
        }),
      );
    });
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
/// import 'package:zorphy/src/plugins/plugin_registry.dart';
///
/// final registry = PluginRegistry();
/// registry.register(LoggingPlugin());
/// registry.register(TimestampPlugin());
///
/// // Plugins execute in topological order:
/// // 'logging' runs first, then 'timestamp'.
/// final ordered = registry.ordered();
/// print(ordered.map((p) => p.name)); // [logging, timestamp]
/// ```
