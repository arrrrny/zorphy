import 'package:code_builder/code_builder.dart';

import 'src/plugins/plugin_context.dart';

/// Abstract contract for a Zorphy code-generation plugin.
///
/// Plugins inspect and mutate [code_builder] specs (classes, methods,
/// fields) *before* they are emitted. Each plugin declares:
///
/// - [name] -- unique identifier used for ordering and registration.
/// - [decoratorNames] -- which `@Zorphy(decorators: [...])` names
///   this plugin reacts to (used by the orchestrator to decide
///   whether to run the plugin for a given class). Empty set means
///   the plugin runs for every class.
/// - [runBefore] / [runAfter] -- ordering constraints relative to
///   other plugins by [name]. Processed via topological sort.
///
/// The transform hooks ([transformClass], [transformMethod],
/// [transformField]) receive a mutable builder and a [PluginContext],
/// and must return the (possibly replaced) builder.
///
/// ## v2.1 Extension Surface
///
/// The following hooks are planned for v2.1 and are documented here
/// as anchor points. They are not yet called by the orchestrator:
///
/// - `transformExtension` -- mutate [Extension] specs.
/// - `transformConstructor` -- mutate [Constructor] specs.
/// - `transformLibrary` -- mutate the [Library] spec itself.
/// - `onGenerateStart` / `onGenerateEnd` -- lifecycle hooks for
///   side effects (logging, metrics).
abstract class ZorphyPlugin {
  /// Unique name for this plugin (used in ordering and registration).
  String get name;

  /// Decorator names this plugin reacts to.
  ///
  /// Empty set means the plugin runs for **every** class regardless
  /// of decorators. The orchestrator checks this set to decide
  /// whether to invoke the plugin's transform hooks.
  Set<String> get decoratorNames => const {};

  /// Names of plugins that must run **after** this one.
  ///
  /// Declares: "I must run before these plugins."
  Set<String> get runBefore => const {};

  /// Names of plugins that must run **before** this one.
  ///
  /// Declares: "These plugins must run before me."
  Set<String> get runAfter => const {};

  /// Transforms a [Class] spec.
  ///
  /// Receives the mutable [Class] spec and the [PluginContext].
  /// Return the (possibly replaced) class spec.
  /// Return the input unchanged to pass through.
  Spec transformClass(Spec spec, PluginContext context) => spec;

  /// Transforms a [Method] spec.
  ///
  /// Called for each method inside a class being transformed.
  /// Return the (possibly replaced) method spec.
  Spec transformMethod(Spec spec, PluginContext context) => spec;

  /// Transforms a [Field] spec.
  ///
  /// Called for each field inside a class being transformed.
  /// Return the (possibly replaced) field spec.
  Spec transformField(Spec spec, PluginContext context) => spec;
}
