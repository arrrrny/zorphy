import 'package:test/test.dart';
import 'package:zorphy/src/plugins/plugin_registry.dart';
import 'package:zorphy/zorphy_plugin.dart';

/// A plugin with no ordering constraints.
class _NoOpPlugin extends ZorphyPlugin {
  @override
  final String name;
  _NoOpPlugin(this.name);
}

/// Plugin that declares [runBefore].
class _RunBeforePlugin extends ZorphyPlugin {
  @override
  final String name;
  @override
  final Set<String> runBefore;
  _RunBeforePlugin(this.name, this.runBefore);
}

/// Plugin that declares [runAfter].
class _RunAfterPlugin extends ZorphyPlugin {
  @override
  final String name;
  @override
  final Set<String> runAfter;
  _RunAfterPlugin(this.name, this.runAfter);
}

void main() {
  group('Plugin registry ordering', () {
    test('registration order preserved for unordered plugins', () {
      final registry = PluginRegistry();
      registry.register(_NoOpPlugin('a'));
      registry.register(_NoOpPlugin('b'));
      registry.register(_NoOpPlugin('c'));

      final ordered = registry.ordered();
      expect(ordered.map((p) => p.name), equals(['a', 'b', 'c']));
    });

    test('runAfter enforces ordering', () {
      // a must run after b → b before a
      final registry = PluginRegistry();
      registry.register(_RunAfterPlugin('a', {'b'})); // a runs after b
      registry.register(_NoOpPlugin('b'));

      final ordered = registry.ordered();
      expect(ordered.map((p) => p.name), equals(['b', 'a']));
    });

    test('runBefore enforces ordering', () {
      // a must run before b → a before b
      final registry = PluginRegistry();
      registry.register(_RunBeforePlugin('a', {'b'})); // a runs before b
      registry.register(_NoOpPlugin('b'));

      final ordered = registry.ordered();
      expect(ordered.map((p) => p.name), equals(['a', 'b']));
    });

    test('three plugins with chained ordering', () {
      // a → b → c (a before b, b before c)
      final registry = PluginRegistry();
      registry.register(_RunBeforePlugin('a', {'b'}));
      registry.register(_RunBeforePlugin('b', {'c'}));
      registry.register(_NoOpPlugin('c'));

      final ordered = registry.ordered();
      expect(ordered.map((p) => p.name), equals(['a', 'b', 'c']));
    });

    test('unknown names in runBefore/runAfter are treated as no-op', () {
      final registry = PluginRegistry();
      registry.register(_RunAfterPlugin('a', {'nonexistent'}));
      registry.register(_NoOpPlugin('b'));

      // a has a dependency on 'nonexistent' which doesn't exist.
      // It should be treated as no-op, so both emit in registration order.
      final ordered = registry.ordered();
      expect(ordered.map((p) => p.name), equals(['a', 'b']));
    });

    test('cycle tolerance: no crash, registration-order fallback', () {
      // a runs after b, b runs after a → cycle!
      final registry = PluginRegistry();
      registry.register(_RunAfterPlugin('a', {'b'}));
      registry.register(_RunAfterPlugin('b', {'a'}));

      // Should not throw. Both are in a cycle, so they keep
      // registration order.
      final ordered = registry.ordered();
      expect(ordered.map((p) => p.name), equals(['a', 'b']));
    });

    test('replace plugin with same name', () {
      final registry = PluginRegistry();
      registry.register(_NoOpPlugin('x'));
      registry.register(_NoOpPlugin('x'));

      expect(registry.length, 1);
    });

    test('empty registry ordered returns empty list', () {
      final registry = PluginRegistry();
      expect(registry.ordered(), isEmpty);
    });

    test('single plugin returns singleton list', () {
      final registry = PluginRegistry();
      registry.register(_NoOpPlugin('solo'));

      final ordered = registry.ordered();
      expect(ordered.length, 1);
      expect(ordered.first.name, 'solo');
    });

    test('runBefore enforced even when registered after target', () {
      // a must run before b, but a is registered AFTER b
      final registry = PluginRegistry();
      registry.register(_NoOpPlugin('b'));
      registry.register(_RunBeforePlugin('a', {'b'})); // a runs before b

      final ordered = registry.ordered();
      expect(ordered.map((p) => p.name), equals(['a', 'b']));
    });
  });
}
