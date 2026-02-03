import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

void main() {
  test('Zorphy annotation should be importable', () {
    // Just verify that we can reference the annotation
    expect(zorphy, isNotNull);
    expect(Zorphy, isNotNull);
  });

  test('Zorphy annotation has expected properties', () {
    const annotation = Zorphy(
      generateJson: true,
      explicitSubTypes: null,
      explicitToJson: false,
      generateCompareTo: false,
      generateCopyWithFn: true,
    );
    
    expect(annotation.generateJson, isTrue);
    expect(annotation.explicitSubTypes, isNull);
    expect(annotation.explicitToJson, isFalse);
    expect(annotation.generateCompareTo, isFalse);
    expect(annotation.generateCopyWithFn, isTrue);
  });
}