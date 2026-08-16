import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../analysis/annotation_parser.dart';
import '../factory_method.dart';

/// Generation features that presets can toggle.
enum ZorphyFeature {
  generateCopyWith,
  generateCopyWithFn,
  generateCompareTo,
  generatePatch,
  generateFilter,
  generatePropertyHelpers,
  generateEqualsToString,
  generateChangeTo,
}

/// Preset semantics (pre-decided; `standard` reproduces v1.9.0 output
/// byte-for-byte):
///
/// | Feature                | lean | standard | full |
/// |------------------------|------|----------|------|
/// | copyWith               |  ✓   |    ✓     |  ✓   |
/// | == / hashCode/toString |  ✓   |    ✓     |  ✓   |
/// | property helpers       |  ✗   |    ✓     |  ✓   |
/// | patch                  |  ✗   |    ✓     |  ✓   |
/// | filter                 |  ✗   |    ✓     |  ✓   |
/// | compareTo              |  ✗   |    ✓     |  ✓   |
/// | changeTo               |  ✗   |    ✓     |  ✓   |
/// | copyWithFn             |  ✗   |    ✗     |  ✓   |
///
/// `generateJson` stays opt-in in every preset.
const Map<ZorphyPreset, Map<ZorphyFeature, bool>> kZorphyPresetTable = {
  ZorphyPreset.lean: {
    ZorphyFeature.generateCopyWith: true,
    ZorphyFeature.generateCopyWithFn: false,
    ZorphyFeature.generateCompareTo: false,
    ZorphyFeature.generatePatch: false,
    ZorphyFeature.generateFilter: false,
    ZorphyFeature.generatePropertyHelpers: false,
    ZorphyFeature.generateEqualsToString: true,
    ZorphyFeature.generateChangeTo: false,
  },
  ZorphyPreset.standard: {
    ZorphyFeature.generateCopyWith: true,
    ZorphyFeature.generateCopyWithFn: false,
    ZorphyFeature.generateCompareTo: true,
    ZorphyFeature.generatePatch: true,
    ZorphyFeature.generateFilter: true,
    ZorphyFeature.generatePropertyHelpers: true,
    ZorphyFeature.generateEqualsToString: true,
    ZorphyFeature.generateChangeTo: true,
  },
  ZorphyPreset.full: {
    ZorphyFeature.generateCopyWith: true,
    ZorphyFeature.generateCopyWithFn: true,
    ZorphyFeature.generateCompareTo: true,
    ZorphyFeature.generatePatch: true,
    ZorphyFeature.generateFilter: true,
    ZorphyFeature.generatePropertyHelpers: true,
    ZorphyFeature.generateEqualsToString: true,
    ZorphyFeature.generateChangeTo: true,
  },
};

/// Configuration for code generation.
///
/// All feature flags are final, non-nullable booleans after preset+override
/// resolution. This is the ONLY place flags are resolved — generators read
/// this config and never the annotation directly.
class GenerationConfig {
  /// Output file extension (.zorphy.dart or .zorphy2.dart)
  final String outputExtension;

  /// The preset the flags were resolved against.
  final ZorphyPreset preset;

  /// The semantic kind of the annotated class (entity / valueObject).
  final ZorphyKind kind;

  /// Whether the class owns an auto-generated uuid `id` field.
  final bool autoId;

  /// Whether to generate JSON serialization methods
  final bool generateJson;

  /// Whether to generate toJson with explicit parameter
  final bool explicitToJson;

  /// Whether to generate copyWith methods
  final bool generateCopyWith;

  /// Whether to generate function-based copyWith methods
  final bool generateCopyWithFn;

  /// Whether to generate compareTo methods
  final bool generateCompareTo;

  /// Whether to generate patch methods and patch classes
  final bool generatePatch;

  /// Whether to hide the public constructor
  final bool hidePublicConstructor;

  /// Whether to generate filter field descriptors
  final bool generateFilter;

  /// Whether to generate semantic property helpers
  final bool generatePropertyHelpers;

  /// Whether to generate ==, hashCode and toString
  final bool generateEqualsToString;

  /// Whether to generate changeTo conversion extensions
  final bool generateChangeTo;

  /// Whether the class is abstract (not sealed) when prefixed with $$
  final bool nonSealed;

  /// Custom JSON key for polymorphic type dispatch.
  /// When null, `'__typename'` is used.
  final String? typeKey;

  /// Factory methods for the class
  final List<FactoryMethodInfo> factoryMethods;

  /// Field names defined directly on this class (not inherited)
  final Set<String> ownFields;

  /// Creates a generation configuration with explicit options.
  const GenerationConfig({
    required this.outputExtension,
    required this.preset,
    required this.kind,
    required this.autoId,
    required this.generateJson,
    required this.explicitToJson,
    required this.generateCopyWith,
    required this.generateCopyWithFn,
    required this.generateCompareTo,
    required this.generatePatch,
    required this.hidePublicConstructor,
    required this.generateFilter,
    required this.generatePropertyHelpers,
    required this.generateEqualsToString,
    required this.generateChangeTo,
    required this.nonSealed,
    this.typeKey,
    required this.factoryMethods,
    required this.ownFields,
  });

  static bool _resolve(
    ZorphyPreset preset,
    ZorphyFeature feature,
    bool? override,
  ) {
    return override ?? kZorphyPresetTable[preset]![feature]!;
  }

  /// Resolves parsed annotation options against the preset table.
  ///
  /// This is the single resolution point for all feature flags:
  /// a non-null flag overrides the preset; a null flag inherits it.
  factory GenerationConfig.fromAnnotationOptions(
    AnnotationOptions options, {
    required String outputExtension,
    required List<FactoryMethodInfo> factoryMethods,
    required Set<String> ownFields,
  }) {
    final preset = options.preset ?? ZorphyPreset.standard;
    return GenerationConfig(
      outputExtension: outputExtension,
      preset: preset,
      kind: options.kind ?? ZorphyKind.entity,
      autoId: options.autoId ?? false,
      // JSON is opt-in in every preset: never preset-forced.
      generateJson: options.generateJson ?? false,
      explicitToJson: options.explicitToJson ?? true,
      generateCopyWith: _resolve(
        preset,
        ZorphyFeature.generateCopyWith,
        options.generateCopyWith,
      ),
      generateCopyWithFn: _resolve(
        preset,
        ZorphyFeature.generateCopyWithFn,
        options.generateCopyWithFn,
      ),
      generateCompareTo: _resolve(
        preset,
        ZorphyFeature.generateCompareTo,
        options.generateCompareTo,
      ),
      generatePatch: _resolve(
        preset,
        ZorphyFeature.generatePatch,
        options.generatePatch,
      ),
      generateFilter: _resolve(
        preset,
        ZorphyFeature.generateFilter,
        options.generateFilter,
      ),
      generatePropertyHelpers: _resolve(
        preset,
        ZorphyFeature.generatePropertyHelpers,
        options.generatePropertyHelpers,
      ),
      generateEqualsToString: _resolve(
        preset,
        ZorphyFeature.generateEqualsToString,
        options.generateEqualsToString,
      ),
      generateChangeTo: _resolve(
        preset,
        ZorphyFeature.generateChangeTo,
        options.generateChangeTo,
      ),
      hidePublicConstructor: options.hidePublicConstructor ?? false,
      nonSealed: options.nonSealed ?? false,
      typeKey: options.typeKey,
      factoryMethods: factoryMethods,
      ownFields: ownFields,
    );
  }

  /// Create config for standard zorphy builder.
  ///
  /// Deprecated shim for legacy call sites — builds standard-preset
  /// resolution with explicit overrides. Prefer
  /// [GenerationConfig.fromAnnotationOptions].
  factory GenerationConfig.zorphy({
    required bool generateJson,
    required bool explicitToJson,
    required bool generateCopyWithFn,
    required bool generateCompareTo,
    required bool generatePatch,
    required bool hidePublicConstructor,
    required bool generateFilter,
    required List<FactoryMethodInfo> factoryMethods,
    required Set<String> ownFields,
  }) {
    return GenerationConfig.fromAnnotationOptions(
      AnnotationOptions(
        preset: ZorphyPreset.standard,
        generateJson: generateJson,
        explicitToJson: explicitToJson,
        generateCopyWithFn: generateCopyWithFn,
        generateCompareTo: generateCompareTo,
        generatePatch: generatePatch,
        generateFilter: generateFilter,
        hidePublicConstructor: hidePublicConstructor,
      ),
      outputExtension: '.zorphy.dart',
      factoryMethods: factoryMethods,
      ownFields: ownFields,
    );
  }

  /// Create config for zorphy2 builder (deprecated alias output).
  factory GenerationConfig.zorphy2() {
    return GenerationConfig.fromAnnotationOptions(
      const AnnotationOptions(
        preset: ZorphyPreset.standard,
        generateJson: true,
        explicitToJson: true,
      ),
      outputExtension: '.zorphy2.dart',
      factoryMethods: const [],
      ownFields: const {},
    );
  }

  /// Create config for testing with override values.
  const GenerationConfig.test({
    this.outputExtension = '.zorphy.dart',
    this.preset = ZorphyPreset.standard,
    this.kind = ZorphyKind.entity,
    this.autoId = false,
    this.generateJson = true,
    this.explicitToJson = true,
    this.generateCopyWith = true,
    this.generateCopyWithFn = false,
    this.generateCompareTo = true,
    this.generatePatch = true,
    this.hidePublicConstructor = false,
    this.generateFilter = true,
    this.generatePropertyHelpers = true,
    this.generateEqualsToString = true,
    this.generateChangeTo = true,
    this.nonSealed = false,
    this.typeKey = null,
    this.factoryMethods = const [],
    this.ownFields = const {},
  });
}
