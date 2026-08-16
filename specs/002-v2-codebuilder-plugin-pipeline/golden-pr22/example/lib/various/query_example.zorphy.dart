// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'query_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Product {
  final int id;
  final String name;
  final double price;
  final DateTime createdAt;
  final bool isAvailable;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.createdAt,
    required this.isAvailable,
  });

  Product copyWith({
    int? id,
    String? name,
    double? price,
    DateTime? createdAt,
    bool? isAvailable,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Product copyWithProduct({
    int? id,
    String? name,
    double? price,
    DateTime? createdAt,
    bool? isAvailable,
  }) {
    return copyWith(
      id: id,
      name: name,
      price: price,
      createdAt: createdAt,
      isAvailable: isAvailable,
    );
  }

  Product patchWithProduct({ProductPatch? patchInput}) {
    final _patcher = patchInput ?? ProductPatch();
    final _patchMap = _patcher.patchMap;
    return Product(
      id: _patchMap.containsKey(Product$.id)
          ? (_patchMap[Product$.id] is Function)
                ? _patchMap[Product$.id](this.id)
                : (_patchMap[Product$.id] is Patch)
                ? _patchMap[Product$.id].applyTo(this.id)
                : _patchMap[Product$.id]
          : this.id,
      name: _patchMap.containsKey(Product$.name)
          ? (_patchMap[Product$.name] is Function)
                ? _patchMap[Product$.name](this.name)
                : (_patchMap[Product$.name] is Patch)
                ? _patchMap[Product$.name].applyTo(this.name)
                : _patchMap[Product$.name]
          : this.name,
      price: _patchMap.containsKey(Product$.price)
          ? (_patchMap[Product$.price] is Function)
                ? _patchMap[Product$.price](this.price)
                : (_patchMap[Product$.price] is Patch)
                ? _patchMap[Product$.price].applyTo(this.price)
                : _patchMap[Product$.price]
          : this.price,
      createdAt: _patchMap.containsKey(Product$.createdAt)
          ? (_patchMap[Product$.createdAt] is Function)
                ? _patchMap[Product$.createdAt](this.createdAt)
                : (_patchMap[Product$.createdAt] is Patch)
                ? _patchMap[Product$.createdAt].applyTo(this.createdAt)
                : _patchMap[Product$.createdAt]
          : this.createdAt,
      isAvailable: _patchMap.containsKey(Product$.isAvailable)
          ? (_patchMap[Product$.isAvailable] is Function)
                ? _patchMap[Product$.isAvailable](this.isAvailable)
                : (_patchMap[Product$.isAvailable] is Patch)
                ? _patchMap[Product$.isAvailable].applyTo(this.isAvailable)
                : _patchMap[Product$.isAvailable]
          : this.isAvailable,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        id == other.id &&
        name == other.name &&
        price == other.price &&
        createdAt == other.createdAt &&
        isAvailable == other.isAvailable;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.id,
      this.name,
      this.price,
      this.createdAt,
      this.isAvailable,
    );
  }

  @override
  String toString() {
    return 'Product(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'price: ${price}' +
        ', ' +
        'createdAt: ${createdAt}' +
        ', ' +
        'isAvailable: ${isAvailable})';
  }

  /// Creates a [Product] instance from JSON
  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ProductToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension ProductPropertyHelpers on Product {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

extension ProductSerialization on Product {
  Map<String, dynamic> toJson() => _$ProductToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ProductToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('__typename');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum Product$ { id, name, price, createdAt, isAvailable }

class ProductPatch extends PatchBase<Product, Product$> {
  Product applyTo(Product entity) {
    return entity.patchWithProduct(patchInput: this);
  }

  ProductPatch withId(int? value) {
    patchMap[Product$.id] = value;
    return this;
  }

  ProductPatch withName(String? value) {
    patchMap[Product$.name] = value;
    return this;
  }

  ProductPatch withPrice(double? value) {
    patchMap[Product$.price] = value;
    return this;
  }

  ProductPatch withCreatedAt(DateTime? value) {
    patchMap[Product$.createdAt] = value;
    return this;
  }

  ProductPatch withIsAvailable(bool? value) {
    patchMap[Product$.isAvailable] = value;
    return this;
  }
}

/// Field descriptors for [Product] query construction
abstract final class ProductFields {
  static int _$getid(Product e) => e.id;
  static const id = Field<Product, int>('id', _$getid);
  static String _$getname(Product e) => e.name;
  static const name = Field<Product, String>('name', _$getname);
  static double _$getprice(Product e) => e.price;
  static const price = Field<Product, double>('price', _$getprice);
  static DateTime _$getcreatedAt(Product e) => e.createdAt;
  static const createdAt = Field<Product, DateTime>(
    'createdAt',
    _$getcreatedAt,
  );
  static bool _$getisAvailable(Product e) => e.isAvailable;
  static const isAvailable = Field<Product, bool>(
    'isAvailable',
    _$getisAvailable,
  );
}

extension ProductCompareE on Product {
  Map<String, dynamic> compareToProduct(Product other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (price != other.price) {
      diff['price'] = () => other.price;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (isAvailable != other.isAvailable) {
      diff['isAvailable'] = () => other.isAvailable;
    }
    return diff;
  }
}
