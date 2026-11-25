/// Sibling morphing emission for the v3 pipeline (issue #231).
///
/// When two concrete siblings share a root, moving an instance from one to
/// the other must not restate the shared fields:
///
/// ```dart
/// extension ReadyMorphing on Ready {
///   Loading changeToLoading() => Loading();
/// }
///
/// extension LoadingMorphing on Loading {
///   Ready changeToReady({required String value}) =>
///       Ready(value: value);
/// }
/// ```
///
/// The rules, straight from the issue:
///
/// - shared fields are copied BY REFERENCE — the body passes `this.field`
///   verbatim, so a `DateTime`, a collection or the entity `principalKey`
///   survive the morph with `identical` (the acceptance gate);
/// - only target-owned fields the source cannot supply are asked for, and a
///   nullable target field the source does share takes an optional override
///   that falls back to the receiver's value;
/// - a field shared by NAME but not by TYPE is not shared: it is asked for
///   typed as the target declares it, the same rule the legacy emitter
///   learned from a covariant sibling pair that emitted a `String` into a
///   `Draft` parameter;
/// - a method whose target has a field no argument can reach is withheld
///   rather than emitted with a body that cannot compile.
///
/// One extension per concrete source, one `changeTo<Target>` method per
/// other concrete target of the same hierarchy — both directions get their
/// own method. Generics ride along: the extension declares the source's type
/// parameters (bounds included) and the target constructor call binds them
/// positionally, which is what makes `SliceData<T>.changeToSliceLoading()`
/// return a `SliceLoading<T>` (issue #231 §3).
///
/// The emitted surface is UNCONDITIONAL (issue #231 §4): no `generateChangeTo`
/// toggle, no property-helper toggle — the composer composes it for every
/// hierarchy it composes at all. It is also independent of the legacy JSON
/// round-trip `ChangeToExtensionGenerator`: the v3 pipeline never emits that
/// generator, so the two can never collide on one class.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/type_ref.dart';
import '../parser/polymorphic_ir.dart';
import 'emitter.dart';
import 'polymorphic_class_emitter.dart';

/// Emits the `changeTo<Sibling>` extensions of one hierarchy.
final class PolymorphicMorphingEmitter {
  /// The shared emission pipeline (`code_builder` -> `dart_style`).
  static final ZorphyEmitter _emitter = ZorphyEmitter();

  /// Creates the morphing emitter.
  const PolymorphicMorphingEmitter();

  /// Emits every source extension of the hierarchy under [root] as one
  /// formatted fragment, or an empty string when the hierarchy has fewer
  /// than two emittable concrete leaves — a single leaf has no sibling to
  /// become.
  ///
  /// [fields] is keyed by a node's `className`, matching
  /// [ZorphyNodeIr.className] — the same map the class emitter takes.
  String emit({
    required ZorphyNodeIr root,
    required Map<String, List<PolymorphicField>> fields,
  }) {
    final leaves = PolymorphicClassEmitter.emittableLeaves(root);
    if (leaves.length < 2) return '';

    final extensions = <Extension>[];
    for (final source in leaves) {
      final sourcePayload = _payload(source, fields);
      final methods = <Method>[];
      for (final target in leaves) {
        if (target.className == source.className) continue;
        final method = _morph(
          source: source,
          sourcePayload: sourcePayload,
          target: target,
          fields: fields,
        );
        if (method != null) methods.add(method);
      }
      if (methods.isEmpty) continue;
      extensions.add(
        Extension((e) {
          e.name = extensionName(source.cleanName);
          for (final parameter in source.typeParameters) {
            e.types.add(
              PolymorphicClassEmitter.genericParameterSpec(parameter),
            );
          }
          e.on = referType(
            '${source.cleanName}${PolymorphicClassEmitter.typeArgumentList(source)}',
          );
          e.methods.addAll(methods);
        }),
      );
    }
    if (extensions.isEmpty) return '';
    return _emitter.emitSpecs(extensions);
  }

  /// The extension name holding the morphing methods for [sourceClassName].
  ///
  /// Public so a test (and a consumer scanning the composed part) can name
  /// the extension without re-deriving the convention.
  static String extensionName(String sourceClassName) =>
      '${sourceClassName.replaceAll(r'$', '')}Morphing';

  /// Builds the `changeTo<Target>` method, or `null` when no compilable body
  /// exists.
  Method? _morph({
    required ZorphyNodeIr source,
    required Map<String, PolymorphicField> sourcePayload,
    required ZorphyNodeIr target,
    required Map<String, List<PolymorphicField>> fields,
  }) {
    // The target's type arguments bind the SOURCE's type parameters
    // positionally, so the arities must agree. A generic target under a
    // source of a different arity cannot be constructed here — withhold the
    // method, the same fail-closed posture the matcher takes for its arms.
    final targetIsGeneric = target.typeParameters.isNotEmpty;
    if (targetIsGeneric &&
        target.typeParameters.length != source.typeParameters.length) {
      return null;
    }
    final targetName = target.cleanName;
    final targetType = targetIsGeneric
        ? '$targetName<${PolymorphicClassEmitter.bareParameterNames(source.typeParameters).join(', ')}>'
        : targetName;

    final parameters = <Parameter>[];
    final arguments = <String>[];

    for (final field in _payload(target, fields).values) {
      final name = field.name;
      final sourceField = sourcePayload[name];
      final shared =
          sourceField != null &&
          _bareType(sourceField.type) == _bareType(field.type);

      if (shared && !field.isNullable && !sourceField.isNullable) {
        // A shared `$Parent` field, non-nullable on both sides: copy it off
        // the receiver verbatim. This is the reference-preservation path —
        // the argument resolves to `this.<name>`, never a clone.
        arguments.add('$name: $name');
        continue;
      }
      if (shared && field.isNullable) {
        // A nullable target field: an optional override, and an unset one
        // keeps the receiver's value.
        parameters.add(_parameter(field, required: false));
        arguments.add('$name: $name ?? this.$name');
        continue;
      }
      // Either target-owned, or shared by name but typed differently (a
      // covariant sibling pair): the caller supplies it as the target
      // declares it.
      parameters.add(_parameter(field, required: !field.isNullable));
      arguments.add('$name: $name');
    }

    // Last word: every target field must have an argument, or the
    // constructor call does not compile. The loop above always adds one —
    // this guard exists for the reader, and to keep a future parameter
    // policy from emitting silently broken bodies.
    if (arguments.length != _payload(target, fields).length) return null;

    return Method((m) {
      m.name = 'changeTo$targetName';
      m.returns = referType(targetType);
      m.optionalParameters.addAll(parameters);
      // `fromTrusted`, not an unnamed constructor call: a concrete leaf
      // declares `fromTrusted` and — when it has fields — nothing else, so
      // `Ready(...)` would not compile. A field-less leaf carries an unnamed
      // const constructor too, but one canonical form keeps every body
      // uniform.
      m.body = Code('return $targetType.fromTrusted(${arguments.join(', ')});');
    });
  }

  /// The full payload of [node] — own fields first, then each ancestor's,
  /// nearest first, the first declaration of a name winning — keyed by name.
  Map<String, PolymorphicField> _payload(
    ZorphyNodeIr node,
    Map<String, List<PolymorphicField>> fields,
  ) {
    final payload = <String, PolymorphicField>{};
    for (final owner in <ZorphyNodeIr>[node, ...node.superTypes]) {
      for (final field
          in fields[owner.className] ?? const <PolymorphicField>[]) {
        payload.putIfAbsent(field.name, () => field);
      }
    }
    return payload;
  }

  /// The declared type stripped to its comparable spelling: the `$` prefixes
  /// lowered and a trailing `?` dropped. Nullability never blocks sharing —
  /// the parameter branches above handle it — only a different bare type
  /// does.
  static String _bareType(String type) {
    final lowered = type.replaceAll(r'$', '').trim();
    return lowered.endsWith('?')
        ? lowered.substring(0, lowered.length - 1)
        : lowered;
  }

  static Parameter _parameter(
    PolymorphicField field, {
    required bool required,
  }) => Parameter((p) {
    p.name = field.name;
    p.type = referType(field.emittedType);
    p.named = true;
    p.required = required;
  });
}
