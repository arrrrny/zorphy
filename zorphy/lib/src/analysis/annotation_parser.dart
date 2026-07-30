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
}

/// Options extracted from a @Zorphy/@Zorphy2 annotation.
///
/// Every feature flag is nullable: `null` means "inherit from [preset]".
/// Resolution to final non-nullable values happens exclusively in
/// `GenerationConfig.fromAnnotationOptions`.
class AnnotationOptions {
  final ZorphyPreset? preset;
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

  /// Creates a typed options object from annotation values.
  const AnnotationOptions({
    this.preset,
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
  });
}
