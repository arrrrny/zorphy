// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'json_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Product {
  final String id;
  final String name;
  final double price;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Product copyWithProduct({
    String? id,
    String? name,
    double? price,
    DateTime? createdAt,
  }) {
    return copyWith(id: id, name: name, price: price, createdAt: createdAt);
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
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        id == other.id &&
        name == other.name &&
        price == other.price &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.name, this.price, this.createdAt);
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
        'createdAt: ${createdAt})';
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
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
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

enum Product$ { id, name, price, createdAt }

class ProductPatch extends PatchBase<Product, Product$> {
  Product applyTo(Product entity) {
    return entity.patchWithProduct(patchInput: this);
  }

  ProductPatch withId(String? value) {
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
}

/// Field descriptors for [Product] query construction
abstract final class ProductFields {
  static String _$getid(Product e) => e.id;
  static const id = Field<Product, String>('id', _$getid);
  static String _$getname(Product e) => e.name;
  static const name = Field<Product, String>('name', _$getname);
  static double _$getprice(Product e) => e.price;
  static const price = Field<Product, double>('price', _$getprice);
  static DateTime _$getcreatedAt(Product e) => e.createdAt;
  static const createdAt = Field<Product, DateTime>(
    'createdAt',
    _$getcreatedAt,
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
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Order {
  final String orderId;
  final DateTime orderDate;
  final List<ProductItem> items;
  final double total;

  Order({
    required this.orderId,
    required this.orderDate,
    required this.items,
    required this.total,
  });

  Order copyWith({
    String? orderId,
    DateTime? orderDate,
    List<ProductItem>? items,
    double? total,
  }) {
    return Order(
      orderId: orderId ?? this.orderId,
      orderDate: orderDate ?? this.orderDate,
      items: items ?? this.items,
      total: total ?? this.total,
    );
  }

  Order copyWithOrder({
    String? orderId,
    DateTime? orderDate,
    List<ProductItem>? items,
    double? total,
  }) {
    return copyWith(
      orderId: orderId,
      orderDate: orderDate,
      items: items,
      total: total,
    );
  }

  Order patchWithOrder({OrderPatch? patchInput}) {
    final _patcher = patchInput ?? OrderPatch();
    final _patchMap = _patcher.patchMap;
    return Order(
      orderId: _patchMap.containsKey(Order$.orderId)
          ? (_patchMap[Order$.orderId] is Function)
                ? _patchMap[Order$.orderId](this.orderId)
                : (_patchMap[Order$.orderId] is Patch)
                ? _patchMap[Order$.orderId].applyTo(this.orderId)
                : _patchMap[Order$.orderId]
          : this.orderId,
      orderDate: _patchMap.containsKey(Order$.orderDate)
          ? (_patchMap[Order$.orderDate] is Function)
                ? _patchMap[Order$.orderDate](this.orderDate)
                : (_patchMap[Order$.orderDate] is Patch)
                ? _patchMap[Order$.orderDate].applyTo(this.orderDate)
                : _patchMap[Order$.orderDate]
          : this.orderDate,
      items: _patchMap.containsKey(Order$.items)
          ? (_patchMap[Order$.items] is Function)
                ? _patchMap[Order$.items](this.items)
                : (_patchMap[Order$.items] is Patch)
                ? _patchMap[Order$.items].applyTo(this.items)
                : _patchMap[Order$.items]
          : this.items,
      total: _patchMap.containsKey(Order$.total)
          ? (_patchMap[Order$.total] is Function)
                ? _patchMap[Order$.total](this.total)
                : (_patchMap[Order$.total] is Patch)
                ? _patchMap[Order$.total].applyTo(this.total)
                : _patchMap[Order$.total]
          : this.total,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order &&
        orderId == other.orderId &&
        orderDate == other.orderDate &&
        items == other.items &&
        total == other.total;
  }

  @override
  int get hashCode {
    return Object.hash(this.orderId, this.orderDate, this.items, this.total);
  }

  @override
  String toString() {
    return 'Order(' +
        'orderId: ${orderId}' +
        ', ' +
        'orderDate: ${orderDate}' +
        ', ' +
        'items: ${items}' +
        ', ' +
        'total: ${total})';
  }

  /// Creates a [Order] instance from JSON
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$OrderToJson(this);
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

extension OrderPropertyHelpers on Order {
  bool get hasOrderId => orderId.isNotEmpty;
  bool get noOrderId => orderId.isEmpty;
  bool get hasItems => items.isNotEmpty;
  bool get noItems => items.isEmpty;
}

extension OrderSerialization on Order {
  Map<String, dynamic> toJson() => _$OrderToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$OrderToJson(this);
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

enum Order$ { orderId, orderDate, items, total }

class OrderPatch extends PatchBase<Order, Order$> {
  Order applyTo(Order entity) {
    return entity.patchWithOrder(patchInput: this);
  }

  OrderPatch withOrderId(String? value) {
    patchMap[Order$.orderId] = value;
    return this;
  }

  OrderPatch withOrderDate(DateTime? value) {
    patchMap[Order$.orderDate] = value;
    return this;
  }

  OrderPatch withItems(List<ProductItem>? value) {
    patchMap[Order$.items] = value;
    return this;
  }

  OrderPatch withTotal(double? value) {
    patchMap[Order$.total] = value;
    return this;
  }
}

/// Field descriptors for [Order] query construction
abstract final class OrderFields {
  static String _$getorderId(Order e) => e.orderId;
  static const orderId = Field<Order, String>('orderId', _$getorderId);
  static DateTime _$getorderDate(Order e) => e.orderDate;
  static const orderDate = Field<Order, DateTime>('orderDate', _$getorderDate);
  static List<ProductItem> _$getitems(Order e) => e.items;
  static const items = Field<Order, List<ProductItem>>('items', _$getitems);
  static double _$gettotal(Order e) => e.total;
  static const total = Field<Order, double>('total', _$gettotal);
}

extension OrderCompareE on Order {
  Map<String, dynamic> compareToOrder(Order other) {
    final Map<String, dynamic> diff = {};

    if (orderId != other.orderId) {
      diff['orderId'] = () => other.orderId;
    }
    if (orderDate != other.orderDate) {
      diff['orderDate'] = () => other.orderDate;
    }
    if (items != other.items) {
      diff['items'] = () => other.items;
    }
    if (total != other.total) {
      diff['total'] = () => other.total;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class ProductItem {
  final String productId;
  final String name;
  final int quantity;
  final double unitPrice;

  ProductItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  ProductItem copyWith({
    String? productId,
    String? name,
    int? quantity,
    double? unitPrice,
  }) {
    return ProductItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  ProductItem copyWithProductItem({
    String? productId,
    String? name,
    int? quantity,
    double? unitPrice,
  }) {
    return copyWith(
      productId: productId,
      name: name,
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  ProductItem patchWithProductItem({ProductItemPatch? patchInput}) {
    final _patcher = patchInput ?? ProductItemPatch();
    final _patchMap = _patcher.patchMap;
    return ProductItem(
      productId: _patchMap.containsKey(ProductItem$.productId)
          ? (_patchMap[ProductItem$.productId] is Function)
                ? _patchMap[ProductItem$.productId](this.productId)
                : (_patchMap[ProductItem$.productId] is Patch)
                ? _patchMap[ProductItem$.productId].applyTo(this.productId)
                : _patchMap[ProductItem$.productId]
          : this.productId,
      name: _patchMap.containsKey(ProductItem$.name)
          ? (_patchMap[ProductItem$.name] is Function)
                ? _patchMap[ProductItem$.name](this.name)
                : (_patchMap[ProductItem$.name] is Patch)
                ? _patchMap[ProductItem$.name].applyTo(this.name)
                : _patchMap[ProductItem$.name]
          : this.name,
      quantity: _patchMap.containsKey(ProductItem$.quantity)
          ? (_patchMap[ProductItem$.quantity] is Function)
                ? _patchMap[ProductItem$.quantity](this.quantity)
                : (_patchMap[ProductItem$.quantity] is Patch)
                ? _patchMap[ProductItem$.quantity].applyTo(this.quantity)
                : _patchMap[ProductItem$.quantity]
          : this.quantity,
      unitPrice: _patchMap.containsKey(ProductItem$.unitPrice)
          ? (_patchMap[ProductItem$.unitPrice] is Function)
                ? _patchMap[ProductItem$.unitPrice](this.unitPrice)
                : (_patchMap[ProductItem$.unitPrice] is Patch)
                ? _patchMap[ProductItem$.unitPrice].applyTo(this.unitPrice)
                : _patchMap[ProductItem$.unitPrice]
          : this.unitPrice,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductItem &&
        productId == other.productId &&
        name == other.name &&
        quantity == other.quantity &&
        unitPrice == other.unitPrice;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.productId,
      this.name,
      this.quantity,
      this.unitPrice,
    );
  }

  @override
  String toString() {
    return 'ProductItem(' +
        'productId: ${productId}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'quantity: ${quantity}' +
        ', ' +
        'unitPrice: ${unitPrice})';
  }

  /// Creates a [ProductItem] instance from JSON
  factory ProductItem.fromJson(Map<String, dynamic> json) =>
      _$ProductItemFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ProductItemToJson(this);
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

extension ProductItemPropertyHelpers on ProductItem {
  bool get hasProductId => productId.isNotEmpty;
  bool get noProductId => productId.isEmpty;
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

extension ProductItemSerialization on ProductItem {
  Map<String, dynamic> toJson() => _$ProductItemToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ProductItemToJson(this);
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

enum ProductItem$ { productId, name, quantity, unitPrice }

class ProductItemPatch extends PatchBase<ProductItem, ProductItem$> {
  ProductItem applyTo(ProductItem entity) {
    return entity.patchWithProductItem(patchInput: this);
  }

  ProductItemPatch withProductId(String? value) {
    patchMap[ProductItem$.productId] = value;
    return this;
  }

  ProductItemPatch withName(String? value) {
    patchMap[ProductItem$.name] = value;
    return this;
  }

  ProductItemPatch withQuantity(int? value) {
    patchMap[ProductItem$.quantity] = value;
    return this;
  }

  ProductItemPatch withUnitPrice(double? value) {
    patchMap[ProductItem$.unitPrice] = value;
    return this;
  }
}

/// Field descriptors for [ProductItem] query construction
abstract final class ProductItemFields {
  static String _$getproductId(ProductItem e) => e.productId;
  static const productId = Field<ProductItem, String>(
    'productId',
    _$getproductId,
  );
  static String _$getname(ProductItem e) => e.name;
  static const name = Field<ProductItem, String>('name', _$getname);
  static int _$getquantity(ProductItem e) => e.quantity;
  static const quantity = Field<ProductItem, int>('quantity', _$getquantity);
  static double _$getunitPrice(ProductItem e) => e.unitPrice;
  static const unitPrice = Field<ProductItem, double>(
    'unitPrice',
    _$getunitPrice,
  );
}

extension ProductItemCompareE on ProductItem {
  Map<String, dynamic> compareToProductItem(ProductItem other) {
    final Map<String, dynamic> diff = {};

    if (productId != other.productId) {
      diff['productId'] = () => other.productId;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (quantity != other.quantity) {
      diff['quantity'] = () => other.quantity;
    }
    if (unitPrice != other.unitPrice) {
      diff['unitPrice'] = () => other.unitPrice;
    }
    return diff;
  }
}
