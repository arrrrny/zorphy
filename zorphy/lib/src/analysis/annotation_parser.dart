import 'package:source_gen/source_gen.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

/// Parses @Zorphy/@Zorphy2 annotation options.
///
/// This is the ONLY place annotation values are read — generators must
/// never touch [ConstantReader] directly. All feature flags are read via
/// `peek()` so an unset flag stays `null` (= inherit from preset).
class AnnotationParser {
  /// Parse annotation and return typed options with nullable feature flags.
  static AnnotationOptions parse(ConstantReader annotation) {
    return AnnotationOptions(
      preset: _readPreset(annotation),
      kind: _readKind(annotation),
      autoId: annotation.peek('autoId')?.boolValue,
      generateJson: annotation.peek('generateJson')?.boolValue,
      explicitToJson: annotation.peek('explicitToJson')?.boolValue,
      generateCopyWith: annotation.peek('generateCopyWith')?.boolValue,
      generateCopyWithFn: annotation.peek('generateCopyWithFn')?.boolValue,
      generateCompareTo: annotation.peek('generateCompareTo')?.boolValue,
      generatePatch: annotation.peek('generatePatch')?.boolValue,
      generateFilter: annotation.peek('generateFilter')?.boolValue,
      generatePropertyHelpers: annotation
          .peek('generatePropertyHelpers')
          ?.boolValue,
      generateEqualsToString: annotation
          .peek('generateEqualsToString')
          ?.boolValue,
      generateChangeTo: annotation.peek('generateChangeTo')?.boolValue,
      hidePublicConstructor: annotation
          .peek('hidePublicConstructor')
          ?.boolValue,
      nonSealed: annotation.peek('nonSealed')?.boolValue,
      typeKey: annotation.peek('typeKey')?.stringValue,
      subtypeWireValue: annotation.peek('subtypeWireValue')?.stringValue,
    );
  }

  static ZorphyPreset? _readPreset(ConstantReader annotation) {
    final presetObj = annotation.peek('preset');
    if (presetObj == null || presetObj.isNull) return null;
    final index = presetObj.objectValue.getField('index')?.toIntValue();
    if (index == null || index < 0 || index >= ZorphyPreset.values.length) {
      return null;
    }
    return ZorphyPreset.values[index];
  }

  /// Reads the `kind` annotation argument (`@Zorphy(kind: ...)`). Both the
  /// explicit form and the `@ZValueObject` const alias (a `Zorphy(kind:
  /// ZorphyKind.valueObject)` instance) resolve to the same enum value via
  /// the const's `index` field.
  static ZorphyKind? _readKind(ConstantReader annotation) {
    final kindObj = annotation.peek('kind');
    if (kindObj == null || kindObj.isNull) return null;
    final index = kindObj.objectValue.getField('index')?.toIntValue();
    if (index == null || index < 0 || index >= ZorphyKind.values.length) {
      return null;
    }
    return ZorphyKind.values[index];
  }
}

/// Options extracted from a @Zorphy/@Zorphy2 annotation.
///
/// Every feature flag is nullable: `null` means "inherit from [preset]".
/// Resolution to final non-nullable values happens exclusively in
/// `GenerationConfig.fromAnnotationOptions`.
class AnnotationOptions {
  final ZorphyPreset? preset;
  final ZorphyKind? kind;
  final bool? autoId;
  final bool? generateJson;
  final bool? explicitToJson;
  final bool? generateCopyWith;
  final bool? generateCopyWithFn;
  final bool? generateCompareTo;
  final bool? generatePatch;
  final bool? generateFilter;
  final bool? generatePropertyHelpers;
  final bool? generateEqualsToString;
  final bool? generateChangeTo;
  final bool? hidePublicConstructor;
  final bool? nonSealed;
  final String? typeKey;
  final String? subtypeWireValue;

  /// Creates a typed options object from annotation values.
  const AnnotationOptions({
    this.preset,
    this.kind,
    this.autoId,
    this.generateJson,
    this.explicitToJson,
    this.generateCopyWith,
    this.generateCopyWithFn,
    this.generateCompareTo,
    this.generatePatch,
    this.generateFilter,
    this.generatePropertyHelpers,
    this.generateEqualsToString,
    this.generateChangeTo,
    this.hidePublicConstructor,
    this.nonSealed,
    this.typeKey,
    this.subtypeWireValue,
  });
}
