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

import '../ast/type_ref.dart';
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
    return metadata.polymorphicSubtypes.isNotEmpty;
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
        // T value})` in a non-generic extension).
        for (final generic in metadata.generics) {
          e.types.add(refer(generic.name));
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
  List<dynamic> _siblings(ClassMetadata metadata) {
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
    required dynamic target,
  }) {
    final targetClassName = target.interfaceName.replaceAll(r'$', '');
    final targetTypeName = '$targetClassName${genericArgs(metadata)}';
    final sourceFieldsByName = {for (final f in metadata.allFields) f.name: f};
    final targetFields = _distinctTypedFields(target);

    final parameters = <Parameter>[];
    final arguments = <String, Expression>{};

    for (final field in targetFields) {
      final name = field.name as String;
      final type = helpers.replaceDollarTypesWithConcrete(field.type as String);
      final isNullable = _isNullable(type);
      final sourceType = sourceFieldsByName[name]?.type;

      if (sourceType != null) {
        // A shared `$Parent` field: copy it across, never asked for twice.
        //
        //  - target NON-nullable, source nullable: the receiver may have no
        //    value, so the caller must supply one (required parameter).
        //  - target NULLABLE: an optional parameter overrides, and an unset
        //    one keeps the receiver's value — that is the
        //    `createdAt ?? this.createdAt` shape §2 documents.
        //  - both non-nullable: copy verbatim, no parameter at all; the
        //    receiver already holds a value the target accepts.
        final sourceIsNullable = _isNullable(
          helpers.replaceDollarTypesWithConcrete(sourceType),
        );
        if (!isNullable && sourceIsNullable) {
          // The target demands a value the receiver may not have.
          parameters.add(_parameter(name, type, required: true));
          arguments[name] = refer(name);
        } else if (isNullable) {
          parameters.add(_parameter(name, type));
          arguments[name] = refer(
            name,
          ).ifNullThen(refer('this').property(name));
        } else {
          arguments[name] = refer(name);
        }
        continue;
      }

      // The target's own field: the caller supplies it.
      parameters.add(_parameter(name, type, required: !isNullable));
      arguments[name] = refer(name);
    }

    // Last word: every non-nullable target field must have an argument,
    // otherwise the emitted constructor call cannot compile.
    for (final field in targetFields) {
      if (arguments.containsKey(field.name)) continue;
      final type = helpers.replaceDollarTypesWithConcrete(field.type as String);
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

  /// [target]'s fields that carry a usable type, first occurrence winning so
  /// a field repeated by the interface list is not emitted twice.
  List<dynamic> _distinctTypedFields(dynamic target) {
    final seen = <String>{};
    return [
      for (final field in target.fields)
        if (field.type != null && (field.type as String).isNotEmpty)
          if (seen.add(field.name as String)) field,
    ];
  }

  /// `<T, U>` for a generic [metadata], or `''` for a non-generic one.
  static String genericArgs(ClassMetadata metadata) => metadata.generics.isEmpty
      ? ''
      : '<${metadata.generics.map((g) => g.name).join(', ')}>';

  static bool _isNullable(String type) =>
      type.endsWith('?') ||
      type == 'dynamic' ||
      type.startsWith('dynamic<') ||
      type.startsWith('dynamic ');

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
