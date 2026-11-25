/// Exhaustive `when` / `maybeWhen` matchers for a v3 union root (issue #231).
///
/// The consumer reproduction:
///
/// ```dart
/// const Loading().when(
///   loading: () => ...,
///   ready: (ready) => ...,
/// );
/// ```
///
/// emitted as
///
/// ```dart
/// extension AsyncStatusWhenE on AsyncStatus {
///   T when<T>({
///     required T Function(Loading) loading,
///     required T Function(Ready) ready,
///   }) => switch (this) {
///     Loading value => loading(value),
///     Ready value => ready(value),
///   };
///
///   T maybeWhen<T>({
///     T Function(Loading)? loading,
///     T Function(Ready)? ready,
///     required T Function() orElse,
///   }) { ... }
/// }
/// ```
///
/// The extension lives on the ROOT — the only node that knows the whole closed
/// variant set — and the switch is exhaustive by construction: the root is
/// `sealed`, every variant is a `final` class in the same library (the shared
/// part), and every concrete variant the class emitter produced has an arm. A
/// variant the class emitter had to prune (a type-parameter arity it cannot
/// name its parent with, issue #231) removes that guarantee, so the whole
/// matcher is withheld rather than emitted non-exhaustive.
///
/// Matchers are a UNION surface only (`@ZorphyUnion` lowers to
/// [ArchetypeKind.value] with `isUnion`): an entity hierarchy already has the
/// patch/mock family and a state hierarchy the sealed switch statement, and
/// the issue scopes this contract to unions. `maybeWhen` deliberately uses
/// `if` branches rather than a `switch` — its callbacks are all optional, so
/// there is no exhaustive set to match.
///
/// The emitted surface is UNCONDITIONAL (issue #231 §4): no `generate*`
/// toggle gates it — the v3 composer composes it for every union root it
/// composes at all.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/type_ref.dart';
import '../parser/polymorphic_ir.dart';
import 'emitter.dart';
import 'polymorphic_class_emitter.dart';

/// One variant the matcher's callbacks accept.
final class _Arm {
  /// Clean class name (`Loading`).
  final String className;

  /// The use-site type inside the matcher (`SliceData<T>` for a variant whose
  /// type parameters are all bound by the root's).
  final String typeName;

  /// The callback name (`loading`) — lower-camel of the class name.
  final String parameterName;

  const _Arm({
    required this.className,
    required this.typeName,
    required this.parameterName,
  });
}

/// Emits the `when` / `maybeWhen` extension of one union root.
final class PolymorphicMatcherEmitter {
  /// The shared emission pipeline (`code_builder` -> `dart_style`).
  static final ZorphyEmitter _emitter = ZorphyEmitter();

  /// Creates the matcher emitter.
  const PolymorphicMatcherEmitter();

  /// Emits the extension for [root] as one formatted fragment, or an empty
  /// string when the root carries no matcher surface: a non-union root, a
  /// root with no variants, or a hierarchy whose variant set cannot be armed
  /// exhaustively.
  ///
  /// [fields] is keyed by a node's `className`, matching
  /// [ZorphyNodeIr.className] — the same map the class emitter takes. The
  /// fields themselves are unused here (matchers only name types), but the
  /// parameter keeps every composer caller uniform.
  String emit({
    required ZorphyNodeIr root,
    required Map<String, List<PolymorphicField>> fields,
  }) {
    if (!root.isUnion) return '';
    // A root with no variants is its own concrete leaf — nothing to match on.
    if (root.isConcreteLeaf) return '';

    final arms = _arms(root);
    if (arms == null || arms.isEmpty) return '';

    final resultType = _resultTypeParameterName(root);
    final extension = Extension((e) {
      e.name = extensionName(root.cleanName);
      for (final parameter in root.typeParameters) {
        e.types.add(PolymorphicClassEmitter.genericParameterSpec(parameter));
      }
      e.on = referType(
        '${root.cleanName}${PolymorphicClassEmitter.typeArgumentList(root)}',
      );
      e.methods.add(_when(arms, resultType));
      e.methods.add(_maybeWhen(arms, resultType));
    });
    return _emitter.emitSpecs([extension]);
  }

  /// The extension name holding the matchers for [rootClassName].
  ///
  /// Public so a test (and a consumer scanning the composed part) can name the
  /// extension without re-deriving the convention.
  static String extensionName(String rootClassName) =>
      '${rootClassName.replaceAll(r'$', '')}WhenE';

  /// One arm per emittable concrete variant, depth-first in declaration
  /// order — or `null` when the variant set cannot be armed exhaustively.
  ///
  /// Two refusals, both fail-closed:
  /// - a variant the class emitter pruned (it cannot name its parent's type
  ///   arguments, [PolymorphicClassEmitter.isEmittableChild]) would leave the
  ///   switch non-exhaustive — `non_exhaustive_switch_expression` in the
  ///   consumer;
  /// - a variant with a type parameter the ROOT does not declare cannot be
  ///   named inside the extension — the extension has no way to bind it.
  List<_Arm>? _arms(ZorphyNodeIr root) {
    final rootParameters = PolymorphicClassEmitter.bareParameterNames(
      root.typeParameters,
    ).toSet();
    final arms = <_Arm>[];
    final seen = <String>{};

    bool walk(ZorphyNodeIr node) {
      if (node.isConcreteLeaf) {
        final className = node.cleanName;
        if (!seen.add(className)) return true;
        final parameterNames = PolymorphicClassEmitter.bareParameterNames(
          node.typeParameters,
        );
        if (parameterNames.any((name) => !rootParameters.contains(name))) {
          return false;
        }
        arms.add(
          _Arm(
            className: className,
            typeName:
                '$className${PolymorphicClassEmitter.typeArgumentList(node)}',
            parameterName: _lowerFirst(className),
          ),
        );
        return true;
      }
      for (final child in node.directSubTypes) {
        if (!PolymorphicClassEmitter.isEmittableChild(child, node)) {
          // The class emitter emits no class for this child, so no arm can
          // cover it — the switch would not be exhaustive.
          return false;
        }
        if (!walk(child)) return false;
      }
      return true;
    }

    return walk(root) ? arms : null;
  }

  /// A return-type parameter name no variant type parameter already uses.
  ///
  /// `T` stays the name for a non-generic root, which keeps the emitted
  /// `when<T>` identical to the documented shape; a generic root gets the
  /// first free candidate instead — reusing a variant's `T` would rebind it
  /// inside the extension and the arms would no longer type-check.
  static String _resultTypeParameterName(ZorphyNodeIr root) {
    final taken = <String>{
      ...PolymorphicClassEmitter.bareParameterNames(root.typeParameters),
      for (final node in root.directSubTypes)
        ...PolymorphicClassEmitter.bareParameterNames(node.typeParameters),
    };
    for (final candidate in const ['T', 'TResult', 'TValue', 'TOut']) {
      if (!taken.contains(candidate)) return candidate;
    }
    return 'TResult';
  }

  /// `ResultType Function(ParameterType)` as a `code_builder` spec.
  ///
  /// Built from [FunctionType] rather than a type STRING: `referType` treats
  /// anything before `<` as a generic head, so the string
  /// `'T Function(SliceData<T>)'` lost its `Function(` prefix and emitted
  /// `required TResult Function(SliceData<T>` — a part that does not parse
  /// (the same finding the legacy matcher emitter recorded). [parameterType]
  /// `null` means a zero-argument function (`orElse`).
  static Reference _callbackType(String returnType, String? parameterType) {
    if (parameterType == null) {
      return FunctionType((f) {
        f.returnType = referType(returnType);
      });
    }
    return FunctionType((f) {
      f.returnType = referType(returnType);
      f.requiredParameters.add(referType(parameterType));
    });
  }

  /// The nullable callback spelling. code_builder 4.x ignores `isNullable` on
  /// a function type that has parameters, so the `?` goes into the symbol
  /// verbatim — the same workaround `referType` applies to its nullable
  /// cases.
  static Reference _nullableCallbackType(
    String returnType,
    String? parameterType,
  ) {
    final signature = parameterType == null
        ? '$returnType Function()'
        : '$returnType Function($parameterType)';
    return TypeReference((t) => t.symbol = '$signature?');
  }

  /// `T when<T>({required T Function(Leaf) leaf, ...})` as a switch
  /// expression over `this`.
  Method _when(List<_Arm> arms, String resultType) => Method((m) {
    m.name = 'when';
    m.types.add(refer(resultType));
    m.returns = refer(resultType);
    for (final arm in arms) {
      m.optionalParameters.add(
        Parameter((p) {
          p.name = arm.parameterName;
          p.type = _callbackType(resultType, arm.typeName);
          p.named = true;
          p.required = true;
        }),
      );
    }
    final patterns = [
      for (final arm in arms)
        '${arm.typeName} value => ${arm.parameterName}(value)',
    ];
    // `value` is bound per arm, so each case reads its own value with no
    // shadowing of the callbacks above.
    m.body = Block.of([
      Code('return switch (this) { ${patterns.join(', ')} };'),
    ]);
  });

  /// `T maybeWhen<T>({T Function(Leaf)? leaf, ..., required T Function()
  /// orElse})` as guarded branches.
  Method _maybeWhen(List<_Arm> arms, String resultType) => Method((m) {
    m.name = 'maybeWhen';
    m.types.add(refer(resultType));
    m.returns = refer(resultType);
    for (final arm in arms) {
      m.optionalParameters.add(
        Parameter((p) {
          p.name = arm.parameterName;
          p.type = _nullableCallbackType(resultType, arm.typeName);
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
    for (final arm in arms) {
      lines
        ..add('if (self is ${arm.typeName}) {')
        ..add('  final callback = ${arm.parameterName};')
        ..add('  return callback == null ? orElse() : callback(self);')
        ..add('}');
    }
    lines.add('return orElse();');
    m.body = Block.of([Code(lines.join('\n'))]);
  });

  static String _lowerFirst(String value) =>
      value.isEmpty ? value : value[0].toLowerCase() + value.substring(1);
}
