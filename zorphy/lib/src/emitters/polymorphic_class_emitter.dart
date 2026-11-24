/// Polymorphic class emission (ISSUE-004, #179).
///
/// Emits the expression-level matchers a closed hierarchy needs so callers
/// are not forced into a statement-level `switch`:
///
/// ```dart
/// extension _NotificationWhenE<T> on Notification {
///   T when<T>({
///     required T Function(OrderNotification) orderNotification,
///     required T Function(PriceDropNotification) priceDropNotification,
///   }) => switch (this) {
///     OrderNotification value => orderNotification(value),
///     PriceDropNotification value => priceDropNotification(value),
///   };
///
///   T maybeWhen<T>({
///     T Function(OrderNotification)? orderNotification,
///     T Function(PriceDropNotification)? priceDropNotification,
///     required T Function() orElse,
///   }) { ... }
/// }
/// ```
///
/// Emitted on the ROOT — the only node that knows the whole closed subtype
/// set — and only for a `sealed` root: `sealed` makes `when`'s `switch`
/// exhaustive by construction, which is §5's "compiles with exhaustive Dart 3
/// `switch`" acceptance criterion. A root whose hierarchy is open (another
/// library may add a subtype, #142) cannot host an exhaustive matcher, so it
/// keeps the `isX`/`asX` helpers and gets no `when`.
///
/// `maybeWhen` deliberately uses `if` branches rather than a `switch`: its
/// callbacks are all optional, so there is no exhaustive set to match — the
/// `switch` form would need a default arm that `switch (this)` cannot express
/// without a wildcard.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/spec_mapper.dart';
import '../ast/type_ref.dart';
import '../models/class_metadata.dart';
import '../models/generation_config.dart';
import 'hierarchy_emitter.dart';

/// Emits `when` / `maybeWhen` matchers on a sealed polymorphic root.
final class PolymorphicClassEmitter implements HierarchyEmitter {
  /// Creates a polymorphic class emitter.
  const PolymorphicClassEmitter();

  @override
  bool shouldEmit(ClassMetadata metadata, GenerationConfig config) {
    // Rides the existing property-helper family; no new toggle (#179 §5).
    if (!config.generatePropertyHelpers) return false;
    if (metadata.explicitSubtypes.isEmpty) return false;
    if (!metadata.isSealed) return false;
    // A GENERIC sealed root is withheld. `ClassDeclarationGenerator` emits
    // `implements` without type arguments (`class SliceData<T> implements
    // AsyncSlice`), so a generic subtype implements `AsyncSlice<dynamic>` and
    // no matcher over `AsyncSlice<T>` can be exhaustive — the emitted
    // `switch (this)` fails `dart analyze` with
    // `non_exhaustive_switch_expression` (review finding on
    // polymorphic_class_emitter.dart:184). Withholding `when`/`maybeWhen` is the
    // fail-closed posture this file already takes; a generic hierarchy keeps its
    // `isX`/`asX` helpers. The root cause is the `implements`-drops-type-args
    // defect in `ClassDeclarationGenerator`, which is a separate change.
    if (metadata.generics.isNotEmpty) return false;
    return true;
  }

  @override
  List<Spec> emit(ClassMetadata metadata) {
    final leaves = _leaves(metadata);
    if (leaves == null || leaves.isEmpty) return const [];
    // The matcher's own return TYPE parameter must not shadow a class type
    // parameter: with a class generic `T`, emitting `when<T>` would rebind
    // every `T` inside the extension's `on` clause and the arms would no
    // longer type-check (finding: `SliceData<T>` collapsed to `SliceData`).
    final resultType = _resultTypeParameterName(metadata);

    return [
      Extension((e) {
        e.name = whenExtensionName(metadata.cleanName);
        // The bound rides along too — `mapGenericParameter` keeps
        // `<T extends Comparable<T>>` well-bounded, the same mapping
        // `ClassDeclarationGenerator` uses (review finding on
        // polymorphic_class_emitter.dart:73).
        for (final generic in metadata.generics) {
          e.types.add(mapGenericParameter(generic));
        }
        e.on = referType('${metadata.cleanName}${_genericArgs(metadata)}');
        e.methods.add(_when(leaves, resultType));
        e.methods.add(_maybeWhen(leaves, resultType));
      }),
    ];
  }

  /// A return-type parameter name no class generic already uses.
  ///
  /// `T` stays the name for a non-generic root, which keeps the emitted
  /// `when<T>` identical to the documented shape; a generic root gets the
  /// first free candidate instead.
  static String _resultTypeParameterName(ClassMetadata metadata) {
    final taken = metadata.generics.map((g) => g.name).toSet();
    for (final candidate in const ['T', 'TResult', 'TValue', 'TOut']) {
      if (!taken.contains(candidate)) return candidate;
    }
    return 'TResult';
  }

  /// One entry per declared subtype, in declaration order, or `null` when a
  /// subtype cannot be named inside the root's extension.
  ///
  /// The parameter name is the lower-camel class name (`orderNotification`),
  /// matching the fluent shape the issue's example uses. [leaf.typeName]
  /// carries the subtype's own type arguments (`SliceData<T>`) whenever they
  /// are bound by the root's type parameters — without them, an arm matching
  /// `SliceData` against a `AsyncSlice<T>` receiver is not assignable.
  List<_Leaf>? _leaves(ClassMetadata metadata) {
    final rootGenerics = metadata.generics.map((g) => g.name).toSet();
    final leaves = <_Leaf>[];
    final seen = <String>{};
    for (final subtype in metadata.explicitSubtypes) {
      final className = subtype.interfaceName.replaceAll(r'$', '');
      if (className.isEmpty || !seen.add(className)) continue;

      final subtypeGenerics = subtype.typeParams.map((g) => g.name).toList();
      // A subtype introducing a type parameter the ROOT does not declare
      // cannot be named here — the extension has no way to bind it. Emitting
      // it bare would produce a non-generic arm for a generic type, so the
      // whole matcher is withheld rather than emitted broken.
      if (subtypeGenerics.any((name) => !rootGenerics.contains(name))) {
        return null;
      }
      final typeArgs = subtypeGenerics.isEmpty
          ? ''
          : '<${subtypeGenerics.join(', ')}>';
      leaves.add(
        _Leaf(
          className: className,
          typeName: '$className$typeArgs',
          parameterName: _lowerFirst(className),
        ),
      );
    }
    return leaves;
  }

  /// `ResultType Function(ParameterType)` as a `code_builder` spec.
  ///
  /// Built from [FunctionType] rather than a type STRING: `referType` treats
  /// anything before `<` as a generic head, so the string
  /// `'T Function(SliceData<T>)'` lost its `Function(` prefix and emitted
  /// `required TResult Function(SliceData<T>` — a part that does not parse
  /// (finding: the generic fixture failed with `expected_token` and
  /// `extraneous_modifier`). [parameterType] `null` means a zero-argument
  /// function (`orElse`).
  static Reference _callbackType(
    String returnType,
    String? parameterType, {
    bool isNullable = false,
  }) {
    final signature = parameterType == null
        ? '$returnType Function()'
        : '$returnType Function($parameterType)';
    if (isNullable) {
      // code_builder 4.x ignores `isNullable` on a function type that has
      // parameters, so the `?` goes into the symbol verbatim — the same
      // workaround `referType` applies to its nullable cases.
      return TypeReference((t) => t.symbol = '$signature?');
    }
    return FunctionType((f) {
      f.returnType = referType(returnType);
      if (parameterType != null) {
        f.requiredParameters.add(referType(parameterType));
      }
    });
  }

  /// `T when<T>({required T Function(Leaf) leaf, ...})` as a switch
  /// expression over `this`.
  Method _when(List<_Leaf> leaves, String resultType) => Method((m) {
    m.name = 'when';
    m.types.add(_typeParameter(resultType));
    m.returns = referType(resultType);
    for (final leaf in leaves) {
      m.optionalParameters.add(
        Parameter((p) {
          p.name = leaf.parameterName;
          p.type = _callbackType(resultType, leaf.typeName);
          p.named = true;
          p.required = true;
        }),
      );
    }
    final arms = [
      for (final leaf in leaves)
        '${leaf.typeName} value => ${leaf.parameterName}(value)',
    ];
    // `value` is bound per arm, so each case reads its own value with no
    // shadowing of the callbacks above.
    m.body = Block.of([Code('return switch (this) { ${arms.join(', ')} };')]);
  });

  /// `T maybeWhen<T>({T Function(Leaf)? leaf, ..., required T Function()
  /// orElse})` as guarded branches.
  Method _maybeWhen(List<_Leaf> leaves, String resultType) => Method((m) {
    m.name = 'maybeWhen';
    m.types.add(_typeParameter(resultType));
    m.returns = referType(resultType);
    for (final leaf in leaves) {
      m.optionalParameters.add(
        Parameter((p) {
          p.name = leaf.parameterName;
          p.type = _callbackType(resultType, leaf.typeName, isNullable: true);
          p.named = true;
        }),
      );
    }
    m.optionalParameters.add(
      Parameter((p) {
        p.name = 'orElse';
        p.type = _callbackType(resultType, null);
        p.named = true;
        p.required = true;
      }),
    );

    final lines = <String>['final self = this;'];
    for (final leaf in leaves) {
      lines
        ..add('if (self is ${leaf.typeName}) {')
        ..add('  final callback = ${leaf.parameterName};')
        ..add('  return callback == null ? orElse() : callback(self);')
        ..add('}');
    }
    lines.add('return orElse();');
    m.body = Block.of([Code(lines.join('\n'))]);
  });

  static String _genericArgs(ClassMetadata metadata) =>
      metadata.generics.isEmpty
      ? ''
      : '<${metadata.generics.map((g) => g.name).join(', ')}>';

  static Reference _typeParameter(String name) => refer(name);

  static String _lowerFirst(String value) =>
      value.isEmpty ? value : value[0].toLowerCase() + value.substring(1);
}

/// The extension name holding the matchers for [rootClassName].
///
/// Public so a consumer and the release test can name the extension without
/// re-deriving the convention.
String whenExtensionName(String rootClassName) =>
    '${rootClassName.replaceAll(r'$', '')}WhenE';

/// One subtype the generated matchers accept.
final class _Leaf {
  const _Leaf({
    required this.className,
    required this.typeName,
    required this.parameterName,
  });

  /// Clean class name (`OrderNotification`).
  final String className;

  /// The use-site type inside the matcher (`SliceData<T>`, or the plain
  /// class name for a non-generic subtype).
  final String typeName;

  /// The callback name (`orderNotification`).
  final String parameterName;
}
