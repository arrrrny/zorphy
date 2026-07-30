import 'package:test/test.dart';
import 'package:zorphy/src/analysis/annotation_parser.dart';
import 'package:zorphy/src/models/generation_config.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

GenerationConfig _resolve(AnnotationOptions options) =>
    GenerationConfig.fromAnnotationOptions(
      options,
      outputExtension: '.zorphy.dart',
      factoryMethods: const [],
      ownFields: const {},
    );

void main() {
  group('GenerationConfig preset resolution', () {
    test('standard preset reproduces v1.9.0 defaults', () {
      final config = _resolve(
        const AnnotationOptions(preset: ZorphyPreset.standard),
      );

      expect(config.generateCopyWith, isTrue);
      expect(config.generateEqualsToString, isTrue);
      expect(config.generateJson, isFalse); // opt-in in every preset
      expect(config.generatePropertyHelpers, isTrue);
      expect(config.generatePatch, isTrue);
      expect(config.generateFilter, isTrue);
      expect(config.generateCompareTo, isTrue);
      expect(config.generateChangeTo, isTrue);
      expect(config.generateCopyWithFn, isFalse);
    });

    test('no options at all behaves like standard (byte-compat)', () {
      final config = _resolve(const AnnotationOptions());
      final standard = _resolve(
        const AnnotationOptions(preset: ZorphyPreset.standard),
      );

      expect(config.generateCopyWith, standard.generateCopyWith);
      expect(config.generateEqualsToString, standard.generateEqualsToString);
      expect(config.generatePropertyHelpers, standard.generatePropertyHelpers);
      expect(config.generatePatch, standard.generatePatch);
      expect(config.generateFilter, standard.generateFilter);
      expect(config.generateCompareTo, standard.generateCompareTo);
      expect(config.generateChangeTo, standard.generateChangeTo);
      expect(config.generateCopyWithFn, standard.generateCopyWithFn);
      expect(config.generateJson, standard.generateJson);
    });

    test('lean preset emits only copyWith + equals/toString', () {
      final config = _resolve(
        const AnnotationOptions(preset: ZorphyPreset.lean),
      );

      expect(config.generateCopyWith, isTrue);
      expect(config.generateEqualsToString, isTrue);
      expect(config.generatePropertyHelpers, isFalse);
      expect(config.generatePatch, isFalse);
      expect(config.generateFilter, isFalse);
      expect(config.generateCompareTo, isFalse);
      expect(config.generateChangeTo, isFalse);
      expect(config.generateCopyWithFn, isFalse);
      expect(config.generateJson, isFalse);
    });

    test('full preset adds copyWithFn on top of standard', () {
      final config = _resolve(
        const AnnotationOptions(preset: ZorphyPreset.full),
      );

      expect(config.generateCopyWithFn, isTrue);
      expect(config.generatePatch, isTrue);
      expect(config.generateFilter, isTrue);
      expect(config.generateCompareTo, isTrue);
    });

    test('explicit flag overrides preset (lean + generatePatch)', () {
      final config = _resolve(
        const AnnotationOptions(
          preset: ZorphyPreset.lean,
          generatePatch: true,
        ),
      );

      expect(config.generatePatch, isTrue);
      // everything else stays lean
      expect(config.generateFilter, isFalse);
      expect(config.generateCompareTo, isFalse);
      expect(config.generatePropertyHelpers, isFalse);
    });

    test('explicit false overrides preset (standard - generateFilter)', () {
      final config = _resolve(
        const AnnotationOptions(
          preset: ZorphyPreset.standard,
          generateFilter: false,
        ),
      );

      expect(config.generateFilter, isFalse);
      expect(config.generatePatch, isTrue);
    });

    test('generateJson is never preset-forced, always explicit', () {
      for (final preset in ZorphyPreset.values) {
        final config = _resolve(AnnotationOptions(preset: preset));
        expect(config.generateJson, isFalse, reason: 'preset $preset');
      }
      final withJson = _resolve(
        const AnnotationOptions(
          preset: ZorphyPreset.lean,
          generateJson: true,
        ),
      );
      expect(withJson.generateJson, isTrue);
    });
  });
}
