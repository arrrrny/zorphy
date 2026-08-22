import 'package:code_builder/code_builder.dart';

import '../common/NameType.dart';
import '../models/class_metadata.dart';
import 'base_generator.dart';

/// Generates the value-comparison surface for `autoId: true` entities
/// (issue #127, proposal #2).
///
/// For every `@Zorphy(autoId: true)` concrete class, the generator emits
/// a NEW `valueEquals(other)` method on the concrete class. When JSON
/// generation is also enabled (`generateJson: true`), it ALSO emits
/// `toJsonValue()`. They do NOT replace the identity-equality
/// `operator ==` / `hashCode` (which stay the default and include the
/// autoId field). The two methods give consumers a value-comparison
/// surface without forcing them to hand-roll string keys:
///
///   * `bool valueEquals(Object other)` — `true` iff `other` is the
///     same concrete type AND every field EXCEPT the autoId field
///     (`id`) is equal to this instance's. Always emitted for
///     `autoId: true` entities.
///   * `Map<String, dynamic> toJsonValue()` — the full `toJson()`
///     output with the autoId field (`id`) key removed. Stable across
///     two instances with the same field values, so it can be used as
///     a deduplication / Set / Map key. Emitted only when
///     `generateJson: true` (since it calls `_$XToJson(this)`).
///
/// The autoId field is identified by the literal Dart name `id` — the
/// same convention used by the constructor parameter the
/// `ClassDeclarationGenerator` adds for `autoId: true` entities. To
/// drop a renamed id, use `equalityExcludes: ['userId']` instead.
///
/// Identity equality (the default `==`/`hashCode`) is preserved —
/// this generator emits NEW methods only. No existing code that
/// depends on the default `==`/`hashCode`/`toJsonLean()` behavior is
/// affected. `valueEquals` and `toJsonValue` are additive surfaces
/// for consumers that need value comparison.
///
/// Honors `GenerationConfig.equalityExcludes` (issue #127, proposal
/// #1): any field listed there is ALSO dropped from `valueEquals()`
/// and `toJsonValue()`. The autoId `id` is always dropped by these
/// methods regardless of `equalityExcludes`.
class ValueEqualityGenerator extends ConcreteClassGenerator {
  ValueEqualityGenerator();

  /// The literal Dart field name that `autoId: true` minted uuid
  /// occupies. Matched against `NameTypeClassComment.name` when
  /// filtering the comparison surface.
  static const String autoIdFieldName = 'id';

  @override
  bool shouldGenerate(GenerationContext context) {
    return !context.metadata.isAbstract && context.config.autoId;
  }

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final metadata = context.metadata;
    final className = metadata.cleanName;
    final excluded = <String>{
      autoIdFieldName,
      ...context.config.equalityExcludes,
    };
    final valueFields = metadata.allFields
        .where((f) => !excluded.contains(f.name))
        .toList();

    final specs = <Spec>[_buildValueEquals(valueFields, className)];

    // toJsonValue() depends on the json_serializable-generated
    // `_$XToJson(this)` helper, so only emit it when JSON generation
    // is enabled for this class.
    if (context.config.generateJson) {
      specs.add(_buildToJsonValue(metadata, className, excluded));
    }
    return specs;
  }

  // ── valueEquals ──────────────────────────────────────────────────

  Method _buildValueEquals(
    List<NameTypeClassComment> fields,
    String className,
  ) {
    final body = <String>[];
    body.add('if (identical(this, other)) return true;');

    if (fields.isEmpty) {
      body.add('return other is $className;');
    } else {
      final fieldChecks = fields
          .map((f) => '${f.name} == other.${f.name}')
          .join(' &&\n    ');
      body.add('return other is $className &&\n    $fieldChecks;');
    }

    return Method((m) {
      // No `@override` — this is a NEW method, not inherited from Object.
      m.name = 'valueEquals';
      m.returns = refer('bool');
      m.docs.add('/// Value equality that ignores the auto-generated `id`');
      m.docs.add('/// field (and any other field listed in');
      m.docs.add('/// `@Zorphy(equalityExcludes: ...)`). See issue #127.');
      m.requiredParameters.add(Parameter((p) {
        p.name = 'other';
        p.type = refer('Object');
      }));
      m.body = Code(body.join('\n'));
    });
  }

  // ── toJsonValue ──────────────────────────────────────────────────

  Method _buildToJsonValue(
    ClassMetadata metadata,
    String className,
    Set<String> excluded,
  ) {
    // Compute the JSON key for each excluded Dart field name. The
    // json_serializable output uses the @JsonKey(name: ...) alias when
    // set, otherwise the Dart field name. The `id` field typically has
    // no alias, so its JSON key is just `'id'`.
    final excludedJsonKeys = <String>{};
    for (final f in metadata.allFields) {
      if (!excluded.contains(f.name)) continue;
      final jsonKey = f.jsonKeyInfo?.name ?? f.name;
      excludedJsonKeys.add(jsonKey);
    }

    final body = <String>[];
    if (metadata.generics.isEmpty) {
      body.add(
        'final Map<String, dynamic> data = _\$$className'
        'ToJson(this);',
      );
    } else {
      final toJsonArgs =
          metadata.generics.map((g) => 'toJson${g.name}').join(', ');
      body.add(
        'final Map<String, dynamic> data = _\$$className'
        'ToJson(this, $toJsonArgs);',
      );
    }
    for (final key in excludedJsonKeys) {
      // Escape the JSON key the same way json_generator does for the
      // literal embedded in the generated source.
      final escaped = _escapeDartStringLiteral(key);
      body.add("data.remove('$escaped');");
    }
    body.add('return data;');

    return Method((m) {
      // No `@override` — this is a NEW method, not inherited from Object.
      m.name = 'toJsonValue';
      m.returns = refer('Map<String, dynamic>');
      m.docs.add('/// The full `toJson()` output with the auto-generated');
      m.docs.add('/// `id` field (and any other field listed in');
      m.docs.add('/// `@Zorphy(equalityExcludes: ...)` ) removed. Use this');
      m.docs.add('/// as a stable dedup / Set / Map key for `autoId`');
      m.docs.add('/// entities. See issue #127.');
      if (metadata.generics.isNotEmpty) {
        for (final g in metadata.generics) {
          m.requiredParameters.add(Parameter((p) {
            p.name = 'toJson${g.name}';
            p.type = refer('Object? Function(${g.name} value)');
          }));
        }
      }
      m.body = Code(body.join('\n'));
    });
  }
}

// ── small local escape helper ─────────────────────────────────────
// The json_generator.dart file has the same `_escapeDartStringLiteral`
// helper at top level (not exported). We re-declare it here so this
// generator is self-contained — the two helpers must stay byte-identical.
String _escapeDartStringLiteral(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('"', '\\"')
      .replaceAll('\$', '\\\$')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}
