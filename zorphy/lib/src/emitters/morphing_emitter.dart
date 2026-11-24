/// Sibling morphing emission (ISSUE-004, #179).
///
/// When two subtypes share a `$Parent`, moving an instance from one to the
/// other must not restate the inherited fields:
///
/// ```dart
/// extension OrderNotificationMorphing on OrderNotification {
///   PriceDropNotification changeToPriceDropNotification({
///     required String productId,
///     required double oldPrice,
///     required double newPrice,
///     DateTime? createdAt,
///     DateTime? readAt,
///   }) => PriceDropNotification(
///     id: id,
///     createdAt: createdAt ?? this.createdAt,
///     readAt: readAt ?? this.readAt,
///     productId: productId,
///     oldPrice: oldPrice,
///     newPrice: newPrice,
///   );
/// }
/// ```
///
/// Inherited fields are copied off `this`; only the target's own fields are
/// asked for. Each method is an [Extension] on the SOURCE subtype, and Dart
/// resolves a member against the most specific `on` clause, so two siblings
/// hand each other their own implementation without ambiguity.
///
/// Deliberately independent of `ChangeToExtensionGenerator` — the #159/#161
/// JSON round-trip — which is withheld unless every class in the hierarchy
/// generates JSON. Sibling morphing constructs the target directly, so it
/// works on the default preset where JSON is off.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/spec_mapper.dart';
import '../ast/type_ref.dart';
import '../analysis/class_analyzer.dart';
import '../common/NameType.dart';
import '../common/classes.dart';
import '../helpers.dart' as helpers;
import '../models/class_metadata.dart';
import '../models/generation_config.dart';
import 'hierarchy_emitter.dart';

/// Emits one `changeTo<Target>()` method per sibling subtype.
final class MorphingEmitter implements HierarchyEmitter {
  /// Creates a sibling-morphing emitter.
  const MorphingEmitter();

  @override
  bool shouldEmit(ClassMetadata metadata, GenerationConfig config) {
    // Rides the existing changeTo feature family; no new toggle (#179 §5).
    if (!config.generateChangeTo) return false;
    // The base declares the closed set; a subtype inherits it. Morphing is
    // emitted on the SUBTYPE side only — the base has no sibling to become.
    if (metadata.explicitSubtypes.isNotEmpty) return false;
    if (metadata.polymorphicSubtypes.isEmpty) return false;
    // Name-collision gate: `ChangeToExtensionGenerator` emits the SAME
    // `changeTo<Target>` method names (as a JSON round-trip) on the base
    // whenever the whole hierarchy has a JSON surface. Two `changeTo<Target>`
    // extensions on the same source class make the call ambiguous
    // (`ambiguous_extension_member_access`) — so when the JSON generator already
    // covers this hierarchy, sibling morphing stands down (review finding on
    // morphing_emitter.dart:170).
    if (_jsonChangeToCovers(metadata, config)) return false;
    return true;
  }

  /// Whether `ChangeToExtensionGenerator` already emits a `changeTo<Target>`
  /// extension for [metadata]'s hierarchy — i.e. the JSON round-trip surface
  /// exists, so the direct-construction morphing below would collide by name.
  ///
  /// The JSON generator runs on the BASE (a class that declares subtypes) and
  /// covers it exactly when `generateJson` is on and every declared subtype
  /// generates JSON (`ChangeToExtensionGenerator._jsonSurfaceExists`); a `sealed`
  /// base needs no extra base case. This subtype stands down when its hierarchy's
  /// base would emit that extension, which is the same predicate evaluated from
  /// the subtype's inherited view.
  bool _jsonChangeToCovers(ClassMetadata metadata, GenerationConfig config) {
    if (!config.generateJson) return false;
    // The source must itself be a JSON subtype of the base — the base's
    // `changeTo<Target>` is emitted on the base and inherited by every subtype,
    // so a source that does not generate JSON is not covered by it.
    if (!metadata.isInParentExplicitSubtypes) return false;
    // Every sibling the base's switch dispatches to must generate JSON too, or
    // the base's `_jsonSurfaceExists` fails and no JSON `changeTo` is emitted.
    for (final sibling in metadata.polymorphicSubtypes) {
      final element = metadata.allAnnotatedClasses[sibling.interfaceName];
      if (element == null) return false;
      if (!ClassAnalyzer.generatesJson(element)) return false;
    }
    return true;
  }

  @override
  List<Spec> emit(ClassMetadata metadata) {
    final siblings = _siblings(metadata);
    if (siblings.isEmpty) return const [];

    final methods = <Method>[];
    for (final sibling in siblings) {
      final method = _morphingMethod(metadata: metadata, target: sibling);
      if (method != null) methods.add(method);
    }
    if (methods.isEmpty) return const [];

    return [
      Extension((e) {
        e.name = siblingMorphingExtensionName(metadata.cleanName);
        // A generic hierarchy must carry its type parameters onto the
        // extension: without them `SliceData<T>` collapses to `SliceData` and
        // the body's `T` is undefined (finding: `changeToSliceData({required
        // T value})` in a non-generic extension). The bound rides along too —
        // `mapGenericParameter` keeps `<T extends Comparable<T>>` well-bounded,
        // the same mapping `ClassDeclarationGenerator` uses.
        for (final generic in metadata.generics) {
          e.types.add(mapGenericParameter(generic));
        }
        e.on = referType('${metadata.cleanName}${genericArgs(metadata)}');
        e.methods.addAll(methods);
      }),
    ];
  }

  /// Every declared subtype of the hierarchy [metadata] belongs to, minus
  /// itself.
  ///
  /// `polymorphicSubtypes` is `explicitSubtypes` on the base and the
  /// inherited closed set on every subtype ([ClassAnalyzer] resolves it), so
  /// both halves of a hierarchy read the same sibling list without the
  /// emitter walking supertypes again.
  List<Interface> _siblings(ClassMetadata metadata) {
    final ownName = metadata.cleanName;
    return [
      for (final subtype in metadata.polymorphicSubtypes)
        if (subtype.interfaceName.replaceAll(r'$', '') != ownName) subtype,
    ];
  }

  /// Builds the `changeTo<Target>` method, or `null` when no compilable body
  /// exists.
  ///
  /// A non-nullable target field the source cannot supply is a reason to skip
  /// the method rather than emit a body that does not analyze — the same
  /// fail-closed posture `ChangeToExtensionGenerator` takes for its JSON
  /// surface (#159).
  Method? _morphingMethod({
    required ClassMetadata metadata,
    required Interface target,
  }) {
    final targetClassName = target.interfaceName.replaceAll(r'$', '');
    final targetTypeName = '$targetClassName${genericArgs(metadata)}';
    final sourceFieldsByName = {for (final f in metadata.allFields) f.name: f};
    final targetFields = _distinctTypedFields(target);

    final parameters = <Parameter>[];
    final arguments = <String, Expression>{};

    for (final field in targetFields) {
      final name = field.name;
      final type = helpers.replaceDollarTypesWithConcrete(field.type ?? '');
      // A `T?` field is nullable; `dynamic` is NOT — it is required unless the
      // source supplies it (review finding on morphing_emitter.dart:167). The
      // `?? this.x` fallback below is value-level and only fires for a `T?`.
      final isOptional = _isNullable(type);
      final rawSourceType = sourceFieldsByName[name]?.type;
      final sourceType = rawSourceType == null
          ? null
          : helpers.replaceDollarTypesWithConcrete(rawSourceType);

      // A field shared with the target only flows across when its TYPE agrees.
      // Two siblings under one root may type the same segment differently
      // (`String payload` vs `$Draft payload`), and copying by NAME alone
      // emitted `DraftNode(payload: payload)` — a `String` handed to a `Draft`
      // parameter (`argument_type_not_assignable`, seen on the sibling_nested
      // fixture once MorphingEmitter met a covariant sibling pair). Such a
      // field is not shared: it is asked for as the target's own field.
      if (sourceType != null && _typesAgree(sourceType, type)) {
        // A shared `$Parent` field: copy it across, never asked for twice.
        //
        //  - target NON-nullable, source nullable: the receiver may have no
        //    value, so the caller must supply one (required parameter).
        //  - target NULLABLE: an optional parameter overrides, and an unset
        //    one keeps the receiver's value — that is the
        //    `createdAt ?? this.createdAt` shape §2 documents.
        //  - both non-nullable: copy verbatim, no parameter at all; the
        //    receiver already holds a value the target accepts.
        final sourceIsNullable = _isNullable(sourceType);
        if (!isOptional && sourceIsNullable) {
          // The target demands a value the receiver may not have.
          parameters.add(_parameter(name, type, required: true));
          arguments[name] = refer(name);
        } else if (isOptional) {
          parameters.add(_parameter(name, type));
          arguments[name] = refer(name)
              .ifNullThen(refer('this').property(name));
        } else {
          arguments[name] = refer(name);
        }
        continue;
      }

      // The target's own field: the caller supplies it. `dynamic` is required
      // (no `?`), so `required: !isOptional` asks the caller for it.
      parameters.add(_parameter(name, type, required: !isOptional));
      arguments[name] = refer(name);
    }

    // Last word: every non-nullable target field must have an argument,
    // otherwise the emitted constructor call cannot compile. Only a `T?` field
    // is nullable — `dynamic` is required (review finding on
    // morphing_emitter.dart:167), so a `dynamic` target field the source does
    // not supply withholds the method rather than emitting a call that omits a
    // required argument.
    for (final field in targetFields) {
      if (arguments.containsKey(field.name)) continue;
      final type = helpers.replaceDollarTypesWithConcrete(field.type ?? '');
      if (_isNullable(type)) continue;
      return null;
    }

    return Method((m) {
      m.name = 'changeTo$targetClassName';
      m.returns = referType(targetTypeName);
      m.optionalParameters.addAll(parameters);
      m.body = Block.of([
        referType(targetTypeName).newInstance([], arguments).returned.statement,
      ]);
    });
  }

  /// Whether a source field's type can be handed to the target's parameter.
  ///
  /// `$`-stripping already happened on both sides, so this compares the
  /// emitted spellings. A trailing `?` is ignored: a nullable source is
  /// already handled by the required-parameter branch above, and
  /// `createdAt ?? this.createdAt` passes a non-null value on the optional
  /// path — so `T?` and `T` agree, while `String` and `Draft` never do.
  static bool _typesAgree(String sourceType, String targetType) {
    String bare(String type) =>
        type.trim().endsWith('?')
        ? type.trim().substring(0, type.trim().length - 1).trim()
        : type.trim();
    return bare(sourceType) == bare(targetType);
  }

  /// [target]'s fields that carry a usable type, first occurrence winning so
  /// a field repeated by the interface list is not emitted twice.
  List<NameType> _distinctTypedFields(Interface target) {
    final seen = <String>{};
    return [
      for (final field in target.fields)
        if (field.type != null && field.type!.isNotEmpty)
          if (seen.add(field.name)) field,
    ];
  }

  /// `<T, U>` for a generic [metadata], or `''` for a non-generic one.
  static String genericArgs(ClassMetadata metadata) => metadata.generics.isEmpty
      ? ''
      : '<${metadata.generics.map((g) => g.name).join(', ')}>';

  /// Whether [type] is a `T?` nullable — the "the caller MAY omit it" test.
  ///
  /// `dynamic` is deliberately NOT nullable here: it accepts `null` as a value
  /// but is not a `T?` optional, so a `dynamic` target field is required unless
  /// the source supplies it (review finding on morphing_emitter.dart:167). The
  /// fail-closed guard below keys requiredness off this same test, so a `dynamic`
  /// target field the source does not supply withholds the method rather than
  /// emitting a constructor call that omits a required argument.
  static bool _isNullable(String type) => type.endsWith('?');

  static Parameter _parameter(
    String name,
    String type, {
    bool required = false,
  }) => Parameter((p) {
    p.name = name;
    p.type = referType(type);
    p.named = true;
    p.required = required;
  });
}

/// The extension name holding the morphing methods for [sourceClassName].
///
/// Public so a consumer and the golden test can name the extension without
/// re-deriving the convention.
String siblingMorphingExtensionName(String sourceClassName) =>
    '${sourceClassName.replaceAll(r'$', '')}Morphing';
