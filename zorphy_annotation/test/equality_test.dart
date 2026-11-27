import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy.dart';

void main() {
  group('zorphyCollectionEquals', () {
    test('identity and scalar equality are preserved', () {
      final scalar = Object();
      expect(zorphyCollectionEquals(scalar, scalar), isTrue);
      expect(zorphyCollectionEquals('same', 'same'), isTrue);
      expect(zorphyCollectionEquals('same', 'different'), isFalse);
    });

    test('lists compare by ordered element equality', () {
      expect(zorphyCollectionEquals([1, 2], [1, 2]), isTrue);
      expect(zorphyCollectionEquals([1, 2], [2, 1]), isFalse);
      expect(zorphyCollectionEquals([1], [1, 2]), isFalse);
    });

    test('sets compare without iteration-order dependence', () {
      expect(zorphyCollectionEquals({1, 2}, {2, 1}), isTrue);
      expect(zorphyCollectionEquals({1, 2}, {1, 3}), isFalse);
    });

    test('maps compare keys and values', () {
      expect(zorphyCollectionEquals({'a': 1}, {'a': 1}), isTrue);
      expect(zorphyCollectionEquals({'a': 1}, {'a': 2}), isFalse);
      expect(zorphyCollectionEquals({'a': 1}, {'b': 1}), isFalse);
    });

    test('nested collections keep shallow identity semantics', () {
      expect(
        zorphyCollectionEquals(
          [
            [1],
          ],
          [
            [1],
          ],
        ),
        isFalse,
      );
    });
  });

  group('zorphyCollectionHash', () {
    test('equal lists have equal ordered hashes', () {
      expect(zorphyCollectionHash([1, 2]), zorphyCollectionHash([1, 2]));
      expect(zorphyCollectionHash([1, 2]), isNot(zorphyCollectionHash([2, 1])));
    });

    test('equal sets and maps hash independently of iteration order', () {
      expect(zorphyCollectionHash({1, 2}), zorphyCollectionHash({2, 1}));
      expect(
        zorphyCollectionHash({'a': 1, 'b': 2}),
        zorphyCollectionHash({'b': 2, 'a': 1}),
      );
    });

    test('scalars retain their hashCode', () {
      expect(zorphyCollectionHash('value'), 'value'.hashCode);
    });
  });
}
