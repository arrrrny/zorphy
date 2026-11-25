/// IR-native JSON-Pointer resolver for the v3 archetypes (ISSUE-0230,
/// arrrrny/zorphy#230).
///
/// The legacy [JsonPointerGenerator] (`generators/json_pointer_generator.dart`)
/// emits the same `static ZorphyLens<T, Object?>? resolvePath(String pointer)`
/// entry point, but reads the analyzer's `ClassElement`/`ClassMetadata`. The v3
/// production path never builds those, so this emitter is the IR-native twin: it
/// reads the resolved [PolymorphicIr] and emits one resolver per non-generic
/// node — sealed roots and abstract intermediates included, since the issue
/// requires the root surface to resolve too.
///
/// The body is a Dart 3 `switch` expression over the pointer's own segments, so
/// one lookup costs one switch step per segment — O(depth) — with no regex, no
/// `dart:mirrors` and no reflective field lookup, which keeps it valid under AOT
/// (the #193 latency guard). Three cases, in resolution order:
///
/// 1. **Nested** (`/editDraft/price`) — the head segment names a field whose
///    type is another composed class, so the remainder is handed to that type's
///    own `resolvePath` and the two lenses are composed with [ZorphyLens.then].
/// 2. **Visible here** (`/id` on any node) — the field is part of this node's
///    own payload (declared on it or inherited), so the lens reads `root.<field>`
///    directly and writes through `copyWith` (a sealed root dispatches the write
///    to the concrete leaf the receiver actually is).
/// 3. **Subtype-only** (`/version` on the root) — the field exists only on some
///    strict subtype, so the lens dispatches on the RUNTIME subtype and its
///    fallback arm answers `null` (read) / the receiver unchanged (write). That
///    is what makes `Event.resolvePath('/version')` safe on a plain `Event`.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/type_ref.dart';
import '../parser/polymorphic_ir.dart';

/// Emits the v3 `resolvePath` static method for every non-generic node.
final class JsonPointerEmitter {
  /// Creates a pointer emitter over [ir], the whole library graph — a node's
  /// resolver dispatches into its subtypes and nested types, so the emitter
  /// needs every node, not just the one it is emitting.
  const JsonPointerEmitter(this.ir);

  /// The whole resolved library graph.
  final PolymorphicIr ir;

  /// The clean names that will carry a `resolvePath` — the only legal targets
  /// of a nested delegation (`<Type>.resolvePath(remainder)`).
  Set<String> get _resolverNames => {
    for (final node in ir.nodes.values)
      if (node.typeParameters.isEmpty) node.cleanName,
  };

  /// The `resolvePath` static method for every non-generic node, keyed by
  /// `className` (`$Product`) — the shape [PolymorphicClassEmitter]'s
  /// `extraMethods` map takes.
  Map<String, Method> resolvePathMethods() {
    final result = <String, Method>{};
    for (final node in ir.nodes.values) {
      if (node.typeParameters.isNotEmpty) continue;
      // An intent is emitted by `IntentEmitter` and carries no `copyWith`, so a
      // resolver over one would dispatch a write through a missing member.
      if (node.archetype == ArchetypeKind.intent) continue;
      // A node that declares its own `resolvePath` keeps it; emitting the
      // static would be a duplicate member the analyzer rejects.
      if (_declaresOwnResolver(node)) continue;
      result[node.className] = _buildResolvePath(node);
    }
    return result;
  }

  bool _declaresOwnResolver(ZorphyNodeIr node) =>
      node.fields.any((field) => field.name == 'resolvePath');

  // ── Table assembly ────────────────────────────────────────────────

  Method _buildResolvePath(ZorphyNodeIr node) {
    final className = node.cleanName;
    final visible = _visibleFields(node);
    final subtypeOnly = _subtypeOnlyFields(node);
    final nested = visible.entries
        .where((entry) => _nestedTarget(entry.value.type) != null)
        .toList();

    return Method((m) {
      m.name = 'resolvePath';
      m.static = true;
      m.returns = referType('ZorphyLens<$className, Object?>?');
      m.requiredParameters.add(
        Parameter((p) {
          p.name = 'pointer';
          p.type = refer('String');
        }),
      );
      m.docs.add(
        '/// Resolves a JSON Pointer into a [ZorphyLens] over [$className].',
      );
      m.docs.add('///');
      m.docs.add(
        '/// One switch step per segment, so a pointer costs O(depth)',
      );
      m.docs.add('/// — no regex, no mirrors, no reflective lookup.');
      m.docs.add('///');
      m.docs.add('/// A pointer this node does not carry answers `null`.');
      m.body = Code(_body(className, visible, subtypeOnly, nested));
    });
  }

  /// The method body: nested delegation first (a nested pointer carries a second
  /// `/`, so it can never equal a single-segment arm), then one `switch`
  /// expression over the exact pointer.
  String _body(
    String className,
    Map<String, _Field> visible,
    Map<String, _Field> subtypeOnly,
    List<MapEntry<String, _Field>> nested,
  ) {
    final lines = <String>[];

    if (nested.isNotEmpty) {
      lines.add("final separator = pointer.indexOf('/', 1);");
      lines.add('if (separator > 0) {');
      lines.add('final remainder = pointer.substring(separator);');
      for (final entry in nested) {
        final field = entry.value;
        final target = _nestedTarget(field.type)!;
        lines.add("if (pointer.startsWith('/${field.name}/')) {");
        lines.add('final nested = $target.resolvePath(remainder);');
        lines.add('if (nested == null) return null;');
        lines.add(
          'return ZorphyLens<$className, $target>('
          "path: '/${field.name}', "
          'get: (root) => root.${field.name}, '
          'set: (root, value) => ${_rebuild(className, field.name, target, 'value')}, '
          ').then(nested);',
        );
        lines.add('}');
      }
      lines.add('}');
    }

    lines.add('return switch (pointer) {');
    for (final entry in visible.entries) {
      final field = entry.value;
      lines.add(
        "'/${field.name}' => ZorphyLens<$className, Object?>("
        "path: '/${field.name}', "
        'get: (root) => root.${field.name}, '
        'set: (root, value) => '
        '${_rebuild(className, field.name, field.type, 'value as ${field.type}')}),',
      );
    }
    for (final entry in subtypeOnly.entries) {
      final field = entry.value;
      lines.add(
        "'/${field.name}' => ZorphyLens<$className, Object?>("
        "path: '/${field.name}', "
        'get: ${_subtypeRead(className, field)}, '
        'set: ${_subtypeWrite(className, field)}),',
      );
    }
    lines.add('_ => null,');
    lines.add('};');

    return lines.join('\n');
  }

  // ── Get / set expression builders ─────────────────────────────────

  /// The rebuild expression for a field VISIBLE on [className]: a concrete leaf
  /// writes through its own `copyWith`; a sealed node dispatches the write to
  /// the concrete leaf the receiver actually is (every leaf of a visible field
  /// carries it, so the switch is exhaustive and needs no default).
  String _rebuild(
    String className,
    String field,
    String type,
    String valueExpr,
  ) {
    final node = ir.rootFor(className) ?? _nodeByName(className);
    if (node != null && node.isConcreteLeaf) {
      return 'root.copyWith($field: $valueExpr)';
    }
    final leaves = _concreteLeavesBelow(className);
    if (leaves.isEmpty) {
      // No concrete leaf to dispatch to (a childless non-leaf should not exist,
      // but fail closed to a no-op rebuild rather than emit a broken switch).
      return 'root';
    }
    final arms = [
      for (final leaf in leaves)
        '${leaf.cleanName} _node => '
            '_node.copyWith($field: $valueExpr),',
    ];
    return 'switch (root) { ${arms.join(' ')} }';
  }

  /// The read closure for a subtype-only field: dispatch on the runtime subtype,
  /// answering `null` for a receiver that does not carry the field.
  ///
  /// When the field's cases cover EVERY concrete leaf below [className] the
  /// receiver always carries it, so the `_ => null` arm would be unreachable
  /// (`unreachable_switch_case`) and is omitted — the switch stays exhaustive.
  String _subtypeRead(String className, _Field field) {
    final arms = <String>[
      for (final entry in field.subtypes.entries)
        '${entry.key} _node => _node.${field.name},',
    ];
    final fallback = _coversEveryLeaf(className, field) ? '' : ' _ => null';
    return '(root) => switch (root) { ${arms.join(' ')}$fallback }';
  }

  /// The write closure for a subtype-only field: rebuild the subtype that
  /// carries it, answering the receiver unchanged for one that does not.
  ///
  /// The `_ => root` arm is dropped for the same exhaustiveness reason as
  /// [_subtypeRead].
  String _subtypeWrite(String className, _Field field) {
    final arms = <String>[
      for (final entry in field.subtypes.entries)
        '${entry.key} _node => '
            '_node.copyWith(${field.name}: value as ${entry.value}),',
    ];
    final fallback = _coversEveryLeaf(className, field) ? '' : ' _ => root';
    return '(root, value) => switch (root) { ${arms.join(' ')}$fallback }';
  }

  /// Whether [field]'s subtype cases name every concrete leaf below [className],
  /// which makes a `switch (root)` over those cases exhaustive.
  bool _coversEveryLeaf(String className, _Field field) =>
      field.subtypes.length == _concreteLeavesBelow(className).length;

  // ── Field classification ──────────────────────────────────────────

  /// The node's whole visible payload — own fields first, then each ancestor's,
  /// the first declaration of a name winning.
  Map<String, _Field> _visibleFields(ZorphyNodeIr node) {
    final result = <String, _Field>{};
    for (final owner in <ZorphyNodeIr>[node, ...node.superTypes]) {
      for (final field in owner.fields) {
        result.putIfAbsent(
          field.name,
          () => _Field(
            name: field.name,
            type: _concrete(field.isNullable ? '${field.type}?' : field.type),
          ),
        );
      }
    }
    return result;
  }

  /// Fields carried by a STRICT subtype but not visible on this node, keyed by
  /// segment name. Each entry records the concrete leaf clean name -> the field
  /// type AS DECLARED there (a covariant narrowing keeps the leaf's type).
  Map<String, _Field> _subtypeOnlyFields(ZorphyNodeIr node) {
    final visible = _visibleFields(node).keys.toSet();
    final result = <String, _Field>{};
    for (final leaf in _concreteLeavesBelow(node.cleanName)) {
      for (final field in _visibleFields(leaf).entries) {
        if (visible.contains(field.key)) continue;
        final type = field.value.type;
        // A static member cannot name a type parameter, so a field a generic
        // leaf types with its own `T` is not advertised — the segment still
        // resolves through any non-generic declarer (handled by the generic
        // leaf being pruned from the composed library anyway).
        result.putIfAbsent(
          field.key,
          () => _Field(name: field.key, type: type),
        );
        result[field.key]!.subtypes[leaf.cleanName] = type;
      }
    }
    return result;
  }

  /// The concrete leaves strictly below [className], depth-first.
  List<ZorphyNodeIr> _concreteLeavesBelow(String className) {
    final node = ir.rootFor(className) ?? _nodeByName(className);
    if (node == null) return const [];
    final out = <ZorphyNodeIr>[];
    void walk(ZorphyNodeIr current) {
      for (final child in current.directSubTypes) {
        if (child.typeParameters.isNotEmpty) continue;
        if (child.isConcreteLeaf) {
          out.add(child);
        } else {
          walk(child);
        }
      }
    }

    walk(node);
    return out;
  }

  /// The clean name of the composed class a field's type names, when that type
  /// is another node that will carry a `resolvePath` — the nested-delegation
  /// target. `null` for a scalar, a collection, a generic or an unknown type.
  String? _nestedTarget(String type) {
    var base = type;
    if (base.endsWith('?')) base = base.substring(0, base.length - 1);
    // Only a BARE class reference is a nested target: a `List<T>` / `Map<K, V>`
    // is a collection the pointer does not descend into.
    if (base.contains('<') || base.contains(',')) return null;
    base = _concrete(base);
    return _resolverNames.contains(base) ? base : null;
  }

  ZorphyNodeIr? _nodeByName(String cleanName) {
    for (final node in ir.nodes.values) {
      if (node.cleanName == cleanName) return node;
    }
    return null;
  }

  static String _concrete(String type) => type.replaceAll(r'$', '');
}

/// One pointer segment: its name, its declared type on the emitting node, and —
/// for a subtype-only field — the concrete leaf clean name -> declared type.
final class _Field {
  final String name;
  final String type;
  final Map<String, String> subtypes = {};

  _Field({required this.name, required this.type});
}
