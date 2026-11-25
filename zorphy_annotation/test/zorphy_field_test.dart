import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

// Hand-written mirror of what the generator emits for a two-field entity
// (`id: String`, `price: double`) — issue #247.
final class Product {
  final String id;
  final double price;
  final String? note;

  const Product(this.id, this.price, [this.note]);

  Product copyWith({String? id, double? price, Object? note = _unset}) =>
      Product(
        id ?? this.id,
        price ?? this.price,
        identical(note, _unset) ? this.note : note as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && other.id == id && other.price == price;

  @override
  int get hashCode => Object.hash(id, price);
}

const _unset = Object();

final class ProductFields {
  const ProductFields();

  static const id = ZorphyField<Product, String>(
    name: 'id',
    jsonKey: 'id',
    pointer: '/id',
    get: _getId,
    set: _setId,
  );

  static const price = ZorphyField<Product, double>(
    name: 'price',
    jsonKey: 'price',
    pointer: '/price',
    get: _getPrice,
    set: _setPrice,
  );

  static const note = ZorphyField<Product, String?>(
    name: 'note',
    jsonKey: 'note',
    pointer: '/note',
    get: _getNote,
    set: _setNote,
  );

  static const List<ZorphyField<Product, Object?>> all = [id, price, note];

  static String _getId(Product instance) => instance.id;
  static Product _setId(Product instance, String value) =>
      instance.copyWith(id: value);

  static double _getPrice(Product instance) => instance.price;
  static Product _setPrice(Product instance, double value) =>
      instance.copyWith(price: value);

  static String? _getNote(Product instance) => instance.note;
  static Product _setNote(Product instance, Object? value) =>
      instance.copyWith(note: value);
}

void main() {
  const p = Product('p1', 9.99);
  const expensive = Product('p2', 149.0, 'gift');

  group('ZorphyField get/set', () {
    test('get reads the field', () {
      expect(ProductFields.id.get(p), 'p1');
      expect(ProductFields.price.get(p), 9.99);
      expect(ProductFields.note.get(expensive), 'gift');
    });

    test('set returns a new root with only that field replaced', () {
      final updated = ProductFields.price.set(p, 49.9);
      expect(updated.price, 49.9);
      expect(updated.id, 'p1');
      // Immutability: the original root is untouched.
      expect(p.price, 9.99);
    });

    test('set clears a nullable field with null', () {
      final cleared = ProductFields.note.set(expensive, null);
      expect(cleared.note, isNull);
      expect(cleared.id, 'p2');
    });

    test('lens bridge reuses the lens layer', () {
      final lens = ProductFields.price.lens;
      expect(lens, isA<ZorphyLens<Product, double>>());
      expect(lens.path, '/price');
      expect(lens.get(p), 9.99);
      expect(lens.set(p, 1.5).price, 1.5);
    });
  });

  group('ZorphyField equality predicates', () {
    test('equals / notEquals', () {
      expect(ProductFields.id.equals('p1').matches(p), isTrue);
      expect(ProductFields.id.equals('p2').matches(p), isFalse);
      expect(ProductFields.id.notEquals('p2').matches(p), isTrue);
    });

    test('isIn', () {
      final f = ProductFields.id.isIn(['p1', 'p3']);
      expect(f.matches(p), isTrue);
      expect(f.matches(expensive), isFalse);
    });

    test('isNull / isNotNull', () {
      expect(ProductFields.note.isNull().matches(p), isTrue);
      expect(ProductFields.note.isNull().matches(expensive), isFalse);
      expect(ProductFields.note.isNotNull().matches(expensive), isTrue);
    });
  });

  group('comparable extension', () {
    test('lessThan / lessThanOrEqual / greaterThan / greaterThanOrEqual', () {
      expect(ProductFields.price.lessThan(100).matches(p), isTrue);
      expect(ProductFields.price.lessThan(100).matches(expensive), isFalse);
      expect(ProductFields.price.lessThanOrEqual(9.99).matches(p), isTrue);
      expect(ProductFields.price.greaterThan(100).matches(expensive), isTrue);
      expect(
        ProductFields.price.greaterThanOrEqual(149.0).matches(expensive),
        isTrue,
      );
    });
  });

  group('string extension', () {
    test('contains is case sensitive by default', () {
      expect(ProductFields.id.contains('p').matches(p), isTrue);
      expect(ProductFields.id.contains('P').matches(p), isFalse);
      expect(
        ProductFields.id.contains('P', caseSensitive: false).matches(p),
        isTrue,
      );
    });

    test('startsWith', () {
      expect(ProductFields.id.startsWith('p1').matches(p), isTrue);
      expect(ProductFields.id.startsWith('p2').matches(p), isFalse);
    });
  });

  group('ZorphySort', () {
    test('asc / desc build the sort', () {
      expect(ProductFields.price.asc().descending, isFalse);
      expect(ProductFields.price.desc().descending, isTrue);
    });

    test('compare orders by the field', () {
      const a = Product('a', 1.0);
      const b = Product('b', 2.0);
      expect(ProductFields.price.asc().compare(a, b), isNegative);
      expect(ProductFields.price.desc().compare(a, b), isPositive);
      expect(ProductFields.id.asc().compare(a, b), isNegative);
    });

    test('nulls sort last in either direction', () {
      const withNull = Product('c', 3.0, null);
      const withNote = Product('d', 0.5, 'x');
      expect(ProductFields.note.asc().compare(withNull, withNote), isPositive);
      expect(ProductFields.note.desc().compare(withNull, withNote), isPositive);
    });
  });

  group('wire round-trips', () {
    test('filter toWire / fromWire preserves matching', () {
      const fields = ProductFields.all;
      final original = ProductFields.price
          .lessThan(100)
          .and(ProductFields.id.startsWith('p'));
      final restored = ZorphyFilter.fromWire<Product>(
        original.toWire(),
        (pointer) => fields.byPointer(pointer),
      );
      expect(restored.matches(p), isTrue);
      expect(restored.matches(expensive), isFalse);
    });

    test('every operator survives a wire round-trip', () {
      const fields = ProductFields.all;
      final filters = <ZorphyFilter<Product>>[
        ProductFields.id.equals('p1'),
        ProductFields.id.notEquals('p1'),
        ProductFields.id.isIn(['p1', 'p9']),
        ProductFields.note.isNull(),
        ProductFields.note.isNotNull(),
        ProductFields.price.lessThan(100),
        ProductFields.price.lessThanOrEqual(9.99),
        ProductFields.price.greaterThan(100),
        ProductFields.price.greaterThanOrEqual(9.99),
        ProductFields.id.contains('1'),
        ProductFields.id.startsWith('p'),
        ProductFields.price.greaterThan(0).or(ProductFields.id.equals('zzz')),
        ProductFields.id.equals('p1').not(),
        ProductFields.price
            .greaterThan(0)
            .and(ProductFields.id.equals('p1').not()),
      ];
      for (final original in filters) {
        final restored = ZorphyFilter.fromWire<Product>(
          original.toWire(),
          (pointer) => fields.byPointer(pointer),
        );
        expect(
          restored.matches(p),
          original.matches(p),
          reason: '${original.toWire()} mismatches on $p after round-trip',
        );
        expect(
          restored.matches(expensive),
          original.matches(expensive),
          reason: '${original.toWire()} mismatches on $expensive',
        );
      }
    });

    test('sort toWire / fromWire preserves ordering', () {
      const fields = ProductFields.all;
      const items = [Product('a', 2.0), Product('b', 1.0), Product('c', 3.0)];
      for (final sort in [
        ProductFields.price.asc(),
        ProductFields.price.desc(),
      ]) {
        final restored = ZorphySort.fromWire<Product>(
          sort.toWire(),
          (pointer) => fields.byPointer(pointer),
        );
        expect(
          restored.sort(items).map((p) => p.id).toList(),
          sort.sort(items).map((p) => p.id).toList(),
        );
        expect(restored.descending, sort.descending);
      }
    });

    test('fromWire throws a FormatException on an unknown pointer or op', () {
      expect(
        () => ZorphyFilter.fromWire<Product>(const {
          'field': '/nope',
          'op': 'eq',
          'value': 1,
        }, (pointer) => ProductFields.all.byPointer(pointer)),
        throwsFormatException,
      );
      expect(
        () => ZorphyFilter.fromWire<Product>(const {
          'field': '/id',
          'op': 'wat',
          'value': 1,
        }, (pointer) => ProductFields.all.byPointer(pointer)),
        throwsFormatException,
      );
    });
  });
}
