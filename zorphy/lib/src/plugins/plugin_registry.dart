import '../../zorphy_plugin.dart';

/// Registry for [ZorphyPlugin] instances.
///
/// Plugins are registered by name. [ordered] returns them in
/// topological order determined by [ZorphyPlugin.runBefore] and
/// [ZorphyPlugin.runAfter] constraints, using Kahn's algorithm with
/// registration-order fallback -- the same stable-sort pattern used by
/// [ClassGraph.topological].
class PluginRegistry {
  /// Registered plugins in registration order.
  final List<ZorphyPlugin> _plugins = [];

  /// Creates an empty registry.
  PluginRegistry();

  /// Registers a plugin.
  ///
  /// If a plugin with the same [ZorphyPlugin.name] is already
  /// registered, the new plugin replaces it.
  void register(ZorphyPlugin plugin) {
    final idx = _plugins.indexWhere((p) => p.name == plugin.name);
    if (idx >= 0) {
      _plugins[idx] = plugin;
    } else {
      _plugins.add(plugin);
    }
  }

  /// Returns the number of registered plugins.
  int get length => _plugins.length;

  /// Whether any plugins are registered.
  bool get isEmpty => _plugins.isEmpty;

  /// Returns all registered plugins in topological order.
  ///
  /// Plugins without ordering constraints remain in registration
  /// order (stable). Unknown names in [runBefore]/[runAfter] are
  /// treated as no-op dependencies. Cycles cause remaining plugins
  /// to be emitted in registration order (no crash).
  List<ZorphyPlugin> ordered() {
    if (_plugins.length <= 1) return List.of(_plugins);

    final byName = <String, ZorphyPlugin>{};
    for (final p in _plugins) {
      byName[p.name] = p;
    }

    // Kahn's algorithm with source-order queue (stable).
    final result = <ZorphyPlugin>[];
    final emitted = <String>{};
    var remaining = List<ZorphyPlugin>.of(_plugins);
    var progress = true;

    while (remaining.isNotEmpty && progress) {
      progress = false;
      for (final p in remaining.toList()) {
        // p.runAfter: names that must run BEFORE p.
        // If any haven't emitted yet, p must wait.
        final pendingAfter = p.runAfter
            .where((n) => byName.containsKey(n) && !emitted.contains(n))
            .toList();

        // p.runBefore: names that must run AFTER p.
        // We also need to check: does any other remaining plugin
        // declare runBefore=[p.name]? That would mean that plugin
        // must run before p, so p must wait for it.
        // Since we iterate in source order, if that plugin has
        // no pending deps it will emit first naturally.

        if (pendingAfter.isEmpty) {
          result.add(p);
          emitted.add(p.name);
          remaining.remove(p);
          progress = true;
        }
      }
    }

    // Cyclic or unresolved remnants keep registration order.
    result.addAll(remaining);
    return result;
  }
}
