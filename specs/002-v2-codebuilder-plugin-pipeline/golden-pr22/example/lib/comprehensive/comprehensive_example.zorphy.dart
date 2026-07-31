// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'comprehensive_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class User {
  final String name;
  final int age;
  final String? email;

  User({required this.name, required this.age, this.email});

  User copyWith({String? name, int? age, String? email}) {
    return User(
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
    );
  }

  User copyWithUser({String? name, int? age, String? email}) {
    return copyWith(name: name, age: age, email: email);
  }

  User patchWithUser({UserPatch? patchInput}) {
    final _patcher = patchInput ?? UserPatch();
    final _patchMap = _patcher.patchMap;
    return User(
      name: _patchMap.containsKey(User$.name)
          ? (_patchMap[User$.name] is Function)
                ? _patchMap[User$.name](this.name)
                : (_patchMap[User$.name] is Patch)
                ? _patchMap[User$.name].applyTo(this.name)
                : _patchMap[User$.name]
          : this.name,
      age: _patchMap.containsKey(User$.age)
          ? (_patchMap[User$.age] is Function)
                ? _patchMap[User$.age](this.age)
                : (_patchMap[User$.age] is Patch)
                ? _patchMap[User$.age].applyTo(this.age)
                : _patchMap[User$.age]
          : this.age,
      email: _patchMap.containsKey(User$.email)
          ? (_patchMap[User$.email] is Function)
                ? _patchMap[User$.email](this.email)
                : (_patchMap[User$.email] is Patch)
                ? _patchMap[User$.email].applyTo(this.email)
                : _patchMap[User$.email]
          : this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        name == other.name &&
        age == other.age &&
        email == other.email;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.age, this.email);
  }

  @override
  String toString() {
    return 'User(' +
        'name: ${name}' +
        ', ' +
        'age: ${age}' +
        ', ' +
        'email: ${email})';
  }
}

extension UserPropertyHelpers on User {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasEmail => email?.isNotEmpty == true;
  bool get noEmail => email?.isEmpty ?? true;
  String get emailRequired =>
      email ?? (throw StateError('email is required but was null'));
}

enum User$ { name, age, email }

class UserPatch extends PatchBase<User, User$> {
  User applyTo(User entity) {
    return entity.patchWithUser(patchInput: this);
  }

  UserPatch withName(String? value) {
    patchMap[User$.name] = value;
    return this;
  }

  UserPatch withAge(int? value) {
    patchMap[User$.age] = value;
    return this;
  }

  UserPatch withEmail(String? value) {
    patchMap[User$.email] = value;
    return this;
  }
}

/// Field descriptors for [User] query construction
abstract final class UserFields {
  static String _$getname(User e) => e.name;
  static const name = Field<User, String>('name', _$getname);
  static int _$getage(User e) => e.age;
  static const age = Field<User, int>('age', _$getage);
  static String? _$getemail(User e) => e.email;
  static const email = Field<User, String?>('email', _$getemail);
}

extension UserCompareE on User {
  Map<String, dynamic> compareToUser(User other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Product {
  final String id;
  final String name;
  final double price;
  final bool inStock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.inStock,
  });

  Product copyWith({String? id, String? name, double? price, bool? inStock}) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      inStock: inStock ?? this.inStock,
    );
  }

  Product copyWithProduct({
    String? id,
    String? name,
    double? price,
    bool? inStock,
  }) {
    return copyWith(id: id, name: name, price: price, inStock: inStock);
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
      inStock: _patchMap.containsKey(Product$.inStock)
          ? (_patchMap[Product$.inStock] is Function)
                ? _patchMap[Product$.inStock](this.inStock)
                : (_patchMap[Product$.inStock] is Patch)
                ? _patchMap[Product$.inStock].applyTo(this.inStock)
                : _patchMap[Product$.inStock]
          : this.inStock,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product &&
        id == other.id &&
        name == other.name &&
        price == other.price &&
        inStock == other.inStock;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.name, this.price, this.inStock);
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
        'inStock: ${inStock})';
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

enum Product$ { id, name, price, inStock }

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

  ProductPatch withInStock(bool? value) {
    patchMap[Product$.inStock] = value;
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
  static bool _$getinStock(Product e) => e.inStock;
  static const inStock = Field<Product, bool>('inStock', _$getinStock);
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
    if (inStock != other.inStock) {
      diff['inStock'] = () => other.inStock;
    }
    return diff;
  }
}

sealed class PaymentMethod {
  String get displayName;

  /// Creates a [PaymentMethod] instance from JSON
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    if (json['__typename'] == "CreditCard") {
      return CreditCard.fromJson(json);
    } else if (json['__typename'] == "PayPal") {
      return PayPal.fromJson(json);
    }
    throw UnsupportedError(
      "The __typename '${json['__typename']}' is not supported by the $className.fromJson constructor.",
    );
  }
}

extension PaymentMethodPolymorphicE on PaymentMethod {
  bool get isCreditCard => this is CreditCard;
  CreditCard? get asCreditCard =>
      this is CreditCard ? this as CreditCard : null;
  bool get isPayPal => this is PayPal;
  PayPal? get asPayPal => this is PayPal ? this as PayPal : null;
}

extension PaymentMethodPropertyHelpers on PaymentMethod {
  bool get hasDisplayName => displayName.isNotEmpty;
  bool get noDisplayName => displayName.isEmpty;
}

enum PaymentMethod$ { displayName }

/// Field descriptors for [PaymentMethod] query construction
abstract final class PaymentMethodFields {
  static String _$getdisplayName(PaymentMethod e) => e.displayName;
  static const displayName = Field<PaymentMethod, String>(
    'displayName',
    _$getdisplayName,
  );
}

extension PaymentMethodCompareE on PaymentMethod {
  Map<String, dynamic> compareToPaymentMethod(PaymentMethod other) {
    final Map<String, dynamic> diff = {};

    if (displayName != other.displayName) {
      diff['displayName'] = () => other.displayName;
    }
    return diff;
  }
}

extension PaymentMethodChangeToE on PaymentMethod {
  CreditCard changeToCreditCard({
    required String cardNumber,
    required String expiryDate,
    String? displayName,
  }) {
    final _patcher = CreditCardPatch();
    _patcher.withCardNumber(cardNumber);
    _patcher.withExpiryDate(expiryDate);
    if (displayName != null) {
      _patcher.withDisplayName(displayName);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return CreditCard.fromJson(_json);
  }

  PayPal changeToPayPal({required String email, String? displayName}) {
    final _patcher = PayPalPatch();
    _patcher.withEmail(email);
    if (displayName != null) {
      _patcher.withDisplayName(displayName);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return PayPal.fromJson(_json);
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class CreditCard implements PaymentMethod {
  @override
  final String displayName;
  final String cardNumber;
  final String expiryDate;

  CreditCard({
    required this.displayName,
    required this.cardNumber,
    required this.expiryDate,
  });

  CreditCard copyWith({
    String? displayName,
    String? cardNumber,
    String? expiryDate,
  }) {
    return CreditCard(
      displayName: displayName ?? this.displayName,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  CreditCard copyWithCreditCard({
    String? displayName,
    String? cardNumber,
    String? expiryDate,
  }) {
    return copyWith(
      displayName: displayName,
      cardNumber: cardNumber,
      expiryDate: expiryDate,
    );
  }

  CreditCard patchWithCreditCard({CreditCardPatch? patchInput}) {
    final _patcher = patchInput ?? CreditCardPatch();
    final _patchMap = _patcher.patchMap;
    return CreditCard(
      displayName: _patchMap.containsKey(CreditCard$.displayName)
          ? (_patchMap[CreditCard$.displayName] is Function)
                ? _patchMap[CreditCard$.displayName](this.displayName)
                : (_patchMap[CreditCard$.displayName] is Patch)
                ? _patchMap[CreditCard$.displayName].applyTo(this.displayName)
                : _patchMap[CreditCard$.displayName]
          : this.displayName,
      cardNumber: _patchMap.containsKey(CreditCard$.cardNumber)
          ? (_patchMap[CreditCard$.cardNumber] is Function)
                ? _patchMap[CreditCard$.cardNumber](this.cardNumber)
                : (_patchMap[CreditCard$.cardNumber] is Patch)
                ? _patchMap[CreditCard$.cardNumber].applyTo(this.cardNumber)
                : _patchMap[CreditCard$.cardNumber]
          : this.cardNumber,
      expiryDate: _patchMap.containsKey(CreditCard$.expiryDate)
          ? (_patchMap[CreditCard$.expiryDate] is Function)
                ? _patchMap[CreditCard$.expiryDate](this.expiryDate)
                : (_patchMap[CreditCard$.expiryDate] is Patch)
                ? _patchMap[CreditCard$.expiryDate].applyTo(this.expiryDate)
                : _patchMap[CreditCard$.expiryDate]
          : this.expiryDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCard &&
        displayName == other.displayName &&
        cardNumber == other.cardNumber &&
        expiryDate == other.expiryDate;
  }

  @override
  int get hashCode {
    return Object.hash(this.displayName, this.cardNumber, this.expiryDate);
  }

  @override
  String toString() {
    return 'CreditCard(' +
        'displayName: ${displayName}' +
        ', ' +
        'cardNumber: ${cardNumber}' +
        ', ' +
        'expiryDate: ${expiryDate})';
  }

  /// Creates a [CreditCard] instance from JSON
  factory CreditCard.fromJson(Map<String, dynamic> json) =>
      _$CreditCardFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CreditCardToJson(this);
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

  Map<String, dynamic> toJson() {
    final json = _$CreditCardToJson(this);
    json['__typename'] = 'CreditCard';
    return json;
  }
}

extension CreditCardPropertyHelpers on CreditCard {
  bool get hasDisplayName => displayName.isNotEmpty;
  bool get noDisplayName => displayName.isEmpty;
  bool get hasCardNumber => cardNumber.isNotEmpty;
  bool get noCardNumber => cardNumber.isEmpty;
  bool get hasExpiryDate => expiryDate.isNotEmpty;
  bool get noExpiryDate => expiryDate.isEmpty;
}

extension CreditCardSerialization on CreditCard {
  Map<String, dynamic> toJson() => _$CreditCardToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CreditCardToJson(this);
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

enum CreditCard$ { displayName, cardNumber, expiryDate }

class CreditCardPatch extends PatchBase<CreditCard, CreditCard$> {
  CreditCard applyTo(CreditCard entity) {
    return entity.patchWithCreditCard(patchInput: this);
  }

  CreditCardPatch withDisplayName(String? value) {
    patchMap[CreditCard$.displayName] = value;
    return this;
  }

  CreditCardPatch withCardNumber(String? value) {
    patchMap[CreditCard$.cardNumber] = value;
    return this;
  }

  CreditCardPatch withExpiryDate(String? value) {
    patchMap[CreditCard$.expiryDate] = value;
    return this;
  }
}

/// Field descriptors for [CreditCard] query construction
abstract final class CreditCardFields {
  static String _$getdisplayName(CreditCard e) => e.displayName;
  static const displayName = Field<CreditCard, String>(
    'displayName',
    _$getdisplayName,
  );
  static String _$getcardNumber(CreditCard e) => e.cardNumber;
  static const cardNumber = Field<CreditCard, String>(
    'cardNumber',
    _$getcardNumber,
  );
  static String _$getexpiryDate(CreditCard e) => e.expiryDate;
  static const expiryDate = Field<CreditCard, String>(
    'expiryDate',
    _$getexpiryDate,
  );
}

extension CreditCardCompareE on CreditCard {
  Map<String, dynamic> compareToCreditCard(CreditCard other) {
    final Map<String, dynamic> diff = {};

    if (displayName != other.displayName) {
      diff['displayName'] = () => other.displayName;
    }
    if (cardNumber != other.cardNumber) {
      diff['cardNumber'] = () => other.cardNumber;
    }
    if (expiryDate != other.expiryDate) {
      diff['expiryDate'] = () => other.expiryDate;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class PayPal implements PaymentMethod {
  @override
  final String displayName;
  final String email;

  PayPal({required this.displayName, required this.email});

  PayPal copyWith({String? displayName, String? email}) {
    return PayPal(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
    );
  }

  PayPal copyWithPayPal({String? displayName, String? email}) {
    return copyWith(displayName: displayName, email: email);
  }

  PayPal patchWithPayPal({PayPalPatch? patchInput}) {
    final _patcher = patchInput ?? PayPalPatch();
    final _patchMap = _patcher.patchMap;
    return PayPal(
      displayName: _patchMap.containsKey(PayPal$.displayName)
          ? (_patchMap[PayPal$.displayName] is Function)
                ? _patchMap[PayPal$.displayName](this.displayName)
                : (_patchMap[PayPal$.displayName] is Patch)
                ? _patchMap[PayPal$.displayName].applyTo(this.displayName)
                : _patchMap[PayPal$.displayName]
          : this.displayName,
      email: _patchMap.containsKey(PayPal$.email)
          ? (_patchMap[PayPal$.email] is Function)
                ? _patchMap[PayPal$.email](this.email)
                : (_patchMap[PayPal$.email] is Patch)
                ? _patchMap[PayPal$.email].applyTo(this.email)
                : _patchMap[PayPal$.email]
          : this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayPal &&
        displayName == other.displayName &&
        email == other.email;
  }

  @override
  int get hashCode {
    return Object.hash(this.displayName, this.email);
  }

  @override
  String toString() {
    return 'PayPal(' +
        'displayName: ${displayName}' +
        ', ' +
        'email: ${email})';
  }

  /// Creates a [PayPal] instance from JSON
  factory PayPal.fromJson(Map<String, dynamic> json) => _$PayPalFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PayPalToJson(this);
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

  Map<String, dynamic> toJson() {
    final json = _$PayPalToJson(this);
    json['__typename'] = 'PayPal';
    return json;
  }
}

extension PayPalPropertyHelpers on PayPal {
  bool get hasDisplayName => displayName.isNotEmpty;
  bool get noDisplayName => displayName.isEmpty;
  bool get hasEmail => email.isNotEmpty;
  bool get noEmail => email.isEmpty;
}

extension PayPalSerialization on PayPal {
  Map<String, dynamic> toJson() => _$PayPalToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PayPalToJson(this);
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

enum PayPal$ { displayName, email }

class PayPalPatch extends PatchBase<PayPal, PayPal$> {
  PayPal applyTo(PayPal entity) {
    return entity.patchWithPayPal(patchInput: this);
  }

  PayPalPatch withDisplayName(String? value) {
    patchMap[PayPal$.displayName] = value;
    return this;
  }

  PayPalPatch withEmail(String? value) {
    patchMap[PayPal$.email] = value;
    return this;
  }
}

/// Field descriptors for [PayPal] query construction
abstract final class PayPalFields {
  static String _$getdisplayName(PayPal e) => e.displayName;
  static const displayName = Field<PayPal, String>(
    'displayName',
    _$getdisplayName,
  );
  static String _$getemail(PayPal e) => e.email;
  static const email = Field<PayPal, String>('email', _$getemail);
}

extension PayPalCompareE on PayPal {
  Map<String, dynamic> compareToPayPal(PayPal other) {
    final Map<String, dynamic> diff = {};

    if (displayName != other.displayName) {
      diff['displayName'] = () => other.displayName;
    }
    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Account {
  final String username;
  final UserStatus status;
  final DateTime createdAt;

  Account({
    required this.username,
    required this.status,
    required this.createdAt,
  });

  Account copyWith({
    String? username,
    UserStatus? status,
    DateTime? createdAt,
  }) {
    return Account(
      username: username ?? this.username,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Account copyWithAccount({
    String? username,
    UserStatus? status,
    DateTime? createdAt,
  }) {
    return copyWith(username: username, status: status, createdAt: createdAt);
  }

  Account patchWithAccount({AccountPatch? patchInput}) {
    final _patcher = patchInput ?? AccountPatch();
    final _patchMap = _patcher.patchMap;
    return Account(
      username: _patchMap.containsKey(Account$.username)
          ? (_patchMap[Account$.username] is Function)
                ? _patchMap[Account$.username](this.username)
                : (_patchMap[Account$.username] is Patch)
                ? _patchMap[Account$.username].applyTo(this.username)
                : _patchMap[Account$.username]
          : this.username,
      status: _patchMap.containsKey(Account$.status)
          ? (_patchMap[Account$.status] is Function)
                ? _patchMap[Account$.status](this.status)
                : (_patchMap[Account$.status] is Patch)
                ? _patchMap[Account$.status].applyTo(this.status)
                : _patchMap[Account$.status]
          : this.status,
      createdAt: _patchMap.containsKey(Account$.createdAt)
          ? (_patchMap[Account$.createdAt] is Function)
                ? _patchMap[Account$.createdAt](this.createdAt)
                : (_patchMap[Account$.createdAt] is Patch)
                ? _patchMap[Account$.createdAt].applyTo(this.createdAt)
                : _patchMap[Account$.createdAt]
          : this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Account &&
        username == other.username &&
        status == other.status &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(this.username, this.status, this.createdAt);
  }

  @override
  String toString() {
    return 'Account(' +
        'username: ${username}' +
        ', ' +
        'status: ${status}' +
        ', ' +
        'createdAt: ${createdAt})';
  }

  /// Creates a [Account] instance from JSON
  factory Account.fromJson(Map<String, dynamic> json) =>
      _$AccountFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AccountToJson(this);
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

extension AccountPropertyHelpers on Account {
  bool get hasUsername => username.isNotEmpty;
  bool get noUsername => username.isEmpty;
  bool get isStatusActive => status == UserStatus.active;
  bool get isStatusInactive => status == UserStatus.inactive;
  bool get isStatusSuspended => status == UserStatus.suspended;
  bool get isStatusPending => status == UserStatus.pending;
}

extension AccountSerialization on Account {
  Map<String, dynamic> toJson() => _$AccountToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AccountToJson(this);
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

enum Account$ { username, status, createdAt }

class AccountPatch extends PatchBase<Account, Account$> {
  Account applyTo(Account entity) {
    return entity.patchWithAccount(patchInput: this);
  }

  AccountPatch withUsername(String? value) {
    patchMap[Account$.username] = value;
    return this;
  }

  AccountPatch withStatus(UserStatus? value) {
    patchMap[Account$.status] = value;
    return this;
  }

  AccountPatch withCreatedAt(DateTime? value) {
    patchMap[Account$.createdAt] = value;
    return this;
  }
}

/// Field descriptors for [Account] query construction
abstract final class AccountFields {
  static String _$getusername(Account e) => e.username;
  static const username = Field<Account, String>('username', _$getusername);
  static UserStatus _$getstatus(Account e) => e.status;
  static const status = Field<Account, UserStatus>('status', _$getstatus);
  static DateTime _$getcreatedAt(Account e) => e.createdAt;
  static const createdAt = Field<Account, DateTime>(
    'createdAt',
    _$getcreatedAt,
  );
}

extension AccountCompareE on Account {
  Map<String, dynamic> compareToAccount(Account other) {
    final Map<String, dynamic> diff = {};

    if (username != other.username) {
      diff['username'] = () => other.username;
    }
    if (status != other.status) {
      diff['status'] = () => other.status;
    }
    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    return diff;
  }
}

class Counter {
  final int value;
  final String label;

  Counter({required this.value, required this.label});

  Counter.copyWith({int? value, String? label})
    : value =
          value ??
          (() {
            throw ArgumentError("value is required");
          })(),
      label =
          label ??
          (() {
            throw ArgumentError("label is required");
          })();

  Counter copyWith({int? value, String? label}) {
    return Counter(value: value ?? this.value, label: label ?? this.label);
  }

  Counter copyWithCounter({int? value, String? label}) {
    return copyWith(value: value, label: label);
  }

  Counter copyWithFn({
    int Function(int)? value,
    String Function(String)? label,
  }) {
    return Counter(
      value: value != null ? value(this.value) : this.value,
      label: label != null ? label(this.label) : this.label,
    );
  }

  Counter patchWithCounter({CounterPatch? patchInput}) {
    final _patcher = patchInput ?? CounterPatch();
    final _patchMap = _patcher.patchMap;
    return Counter(
      value: _patchMap.containsKey(Counter$.value)
          ? (_patchMap[Counter$.value] is Function)
                ? _patchMap[Counter$.value](this.value)
                : (_patchMap[Counter$.value] is Patch)
                ? _patchMap[Counter$.value].applyTo(this.value)
                : _patchMap[Counter$.value]
          : this.value,
      label: _patchMap.containsKey(Counter$.label)
          ? (_patchMap[Counter$.label] is Function)
                ? _patchMap[Counter$.label](this.label)
                : (_patchMap[Counter$.label] is Patch)
                ? _patchMap[Counter$.label].applyTo(this.label)
                : _patchMap[Counter$.label]
          : this.label,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Counter && value == other.value && label == other.label;
  }

  @override
  int get hashCode {
    return Object.hash(this.value, this.label);
  }

  @override
  String toString() {
    return 'Counter(' + 'value: ${value}' + ', ' + 'label: ${label})';
  }
}

extension CounterPropertyHelpers on Counter {
  bool get hasLabel => label.isNotEmpty;
  bool get noLabel => label.isEmpty;
}

enum Counter$ { value, label }

class CounterPatch extends PatchBase<Counter, Counter$> {
  Counter applyTo(Counter entity) {
    return entity.patchWithCounter(patchInput: this);
  }

  CounterPatch withValue(int? value) {
    patchMap[Counter$.value] = value;
    return this;
  }

  CounterPatch withLabel(String? value) {
    patchMap[Counter$.label] = value;
    return this;
  }
}

/// Field descriptors for [Counter] query construction
abstract final class CounterFields {
  static int _$getvalue(Counter e) => e.value;
  static const value = Field<Counter, int>('value', _$getvalue);
  static String _$getlabel(Counter e) => e.label;
  static const label = Field<Counter, String>('label', _$getlabel);
}

extension CounterCompareE on Counter {
  Map<String, dynamic> compareToCounter(Counter other) {
    final Map<String, dynamic> diff = {};

    if (value != other.value) {
      diff['value'] = () => other.value;
    }
    if (label != other.label) {
      diff['label'] = () => other.label;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Address {
  final String street;
  final String city;
  final String country;
  final String postalCode;

  Address({
    required this.street,
    required this.city,
    required this.country,
    required this.postalCode,
  });

  Address copyWith({
    String? street,
    String? city,
    String? country,
    String? postalCode,
  }) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  Address copyWithAddress({
    String? street,
    String? city,
    String? country,
    String? postalCode,
  }) {
    return copyWith(
      street: street,
      city: city,
      country: country,
      postalCode: postalCode,
    );
  }

  Address patchWithAddress({AddressPatch? patchInput}) {
    final _patcher = patchInput ?? AddressPatch();
    final _patchMap = _patcher.patchMap;
    return Address(
      street: _patchMap.containsKey(Address$.street)
          ? (_patchMap[Address$.street] is Function)
                ? _patchMap[Address$.street](this.street)
                : (_patchMap[Address$.street] is Patch)
                ? _patchMap[Address$.street].applyTo(this.street)
                : _patchMap[Address$.street]
          : this.street,
      city: _patchMap.containsKey(Address$.city)
          ? (_patchMap[Address$.city] is Function)
                ? _patchMap[Address$.city](this.city)
                : (_patchMap[Address$.city] is Patch)
                ? _patchMap[Address$.city].applyTo(this.city)
                : _patchMap[Address$.city]
          : this.city,
      country: _patchMap.containsKey(Address$.country)
          ? (_patchMap[Address$.country] is Function)
                ? _patchMap[Address$.country](this.country)
                : (_patchMap[Address$.country] is Patch)
                ? _patchMap[Address$.country].applyTo(this.country)
                : _patchMap[Address$.country]
          : this.country,
      postalCode: _patchMap.containsKey(Address$.postalCode)
          ? (_patchMap[Address$.postalCode] is Function)
                ? _patchMap[Address$.postalCode](this.postalCode)
                : (_patchMap[Address$.postalCode] is Patch)
                ? _patchMap[Address$.postalCode].applyTo(this.postalCode)
                : _patchMap[Address$.postalCode]
          : this.postalCode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        street == other.street &&
        city == other.city &&
        country == other.country &&
        postalCode == other.postalCode;
  }

  @override
  int get hashCode {
    return Object.hash(this.street, this.city, this.country, this.postalCode);
  }

  @override
  String toString() {
    return 'Address(' +
        'street: ${street}' +
        ', ' +
        'city: ${city}' +
        ', ' +
        'country: ${country}' +
        ', ' +
        'postalCode: ${postalCode})';
  }

  /// Creates a [Address] instance from JSON
  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AddressToJson(this);
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

extension AddressPropertyHelpers on Address {
  bool get hasStreet => street.isNotEmpty;
  bool get noStreet => street.isEmpty;
  bool get hasCity => city.isNotEmpty;
  bool get noCity => city.isEmpty;
  bool get hasCountry => country.isNotEmpty;
  bool get noCountry => country.isEmpty;
  bool get hasPostalCode => postalCode.isNotEmpty;
  bool get noPostalCode => postalCode.isEmpty;
}

extension AddressSerialization on Address {
  Map<String, dynamic> toJson() => _$AddressToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AddressToJson(this);
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

enum Address$ { street, city, country, postalCode }

class AddressPatch extends PatchBase<Address, Address$> {
  Address applyTo(Address entity) {
    return entity.patchWithAddress(patchInput: this);
  }

  AddressPatch withStreet(String? value) {
    patchMap[Address$.street] = value;
    return this;
  }

  AddressPatch withCity(String? value) {
    patchMap[Address$.city] = value;
    return this;
  }

  AddressPatch withCountry(String? value) {
    patchMap[Address$.country] = value;
    return this;
  }

  AddressPatch withPostalCode(String? value) {
    patchMap[Address$.postalCode] = value;
    return this;
  }
}

/// Field descriptors for [Address] query construction
abstract final class AddressFields {
  static String _$getstreet(Address e) => e.street;
  static const street = Field<Address, String>('street', _$getstreet);
  static String _$getcity(Address e) => e.city;
  static const city = Field<Address, String>('city', _$getcity);
  static String _$getcountry(Address e) => e.country;
  static const country = Field<Address, String>('country', _$getcountry);
  static String _$getpostalCode(Address e) => e.postalCode;
  static const postalCode = Field<Address, String>(
    'postalCode',
    _$getpostalCode,
  );
}

extension AddressCompareE on Address {
  Map<String, dynamic> compareToAddress(Address other) {
    final Map<String, dynamic> diff = {};

    if (street != other.street) {
      diff['street'] = () => other.street;
    }
    if (city != other.city) {
      diff['city'] = () => other.city;
    }
    if (country != other.country) {
      diff['country'] = () => other.country;
    }
    if (postalCode != other.postalCode) {
      diff['postalCode'] = () => other.postalCode;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class PersonWithAddress {
  final String name;
  final Address address;
  final String? phone;

  PersonWithAddress({required this.name, required this.address, this.phone});

  PersonWithAddress copyWith({String? name, Address? address, String? phone}) {
    return PersonWithAddress(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }

  PersonWithAddress copyWithPersonWithAddress({
    String? name,
    Address? address,
    String? phone,
  }) {
    return copyWith(name: name, address: address, phone: phone);
  }

  PersonWithAddress patchWithPersonWithAddress({
    PersonWithAddressPatch? patchInput,
  }) {
    final _patcher = patchInput ?? PersonWithAddressPatch();
    final _patchMap = _patcher.patchMap;
    return PersonWithAddress(
      name: _patchMap.containsKey(PersonWithAddress$.name)
          ? (_patchMap[PersonWithAddress$.name] is Function)
                ? _patchMap[PersonWithAddress$.name](this.name)
                : (_patchMap[PersonWithAddress$.name] is Patch)
                ? _patchMap[PersonWithAddress$.name].applyTo(this.name)
                : _patchMap[PersonWithAddress$.name]
          : this.name,
      address: _patchMap.containsKey(PersonWithAddress$.address)
          ? (_patchMap[PersonWithAddress$.address] is Function)
                ? _patchMap[PersonWithAddress$.address](this.address)
                : (_patchMap[PersonWithAddress$.address] is Patch)
                ? _patchMap[PersonWithAddress$.address].applyTo(this.address)
                : _patchMap[PersonWithAddress$.address]
          : this.address,
      phone: _patchMap.containsKey(PersonWithAddress$.phone)
          ? (_patchMap[PersonWithAddress$.phone] is Function)
                ? _patchMap[PersonWithAddress$.phone](this.phone)
                : (_patchMap[PersonWithAddress$.phone] is Patch)
                ? _patchMap[PersonWithAddress$.phone].applyTo(this.phone)
                : _patchMap[PersonWithAddress$.phone]
          : this.phone,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonWithAddress &&
        name == other.name &&
        address == other.address &&
        phone == other.phone;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.address, this.phone);
  }

  @override
  String toString() {
    return 'PersonWithAddress(' +
        'name: ${name}' +
        ', ' +
        'address: ${address}' +
        ', ' +
        'phone: ${phone})';
  }

  /// Creates a [PersonWithAddress] instance from JSON
  factory PersonWithAddress.fromJson(Map<String, dynamic> json) =>
      _$PersonWithAddressFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PersonWithAddressToJson(this);
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

extension PersonWithAddressPropertyHelpers on PersonWithAddress {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasPhone => phone?.isNotEmpty == true;
  bool get noPhone => phone?.isEmpty ?? true;
  String get phoneRequired =>
      phone ?? (throw StateError('phone is required but was null'));
}

extension PersonWithAddressSerialization on PersonWithAddress {
  Map<String, dynamic> toJson() => _$PersonWithAddressToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PersonWithAddressToJson(this);
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

enum PersonWithAddress$ { name, address, phone }

class PersonWithAddressPatch
    extends PatchBase<PersonWithAddress, PersonWithAddress$> {
  PersonWithAddress applyTo(PersonWithAddress entity) {
    return entity.patchWithPersonWithAddress(patchInput: this);
  }

  PersonWithAddressPatch withName(String? value) {
    patchMap[PersonWithAddress$.name] = value;
    return this;
  }

  PersonWithAddressPatch withAddress(Address? value) {
    patchMap[PersonWithAddress$.address] = value;
    return this;
  }

  PersonWithAddressPatch withAddressPatch(AddressPatch patch) {
    patchMap[PersonWithAddress$.address] = patch;
    return this;
  }

  PersonWithAddressPatch withAddressPatchFunc(
    AddressPatch Function(AddressPatch) patch,
  ) {
    patchMap[PersonWithAddress$.address] = (dynamic current) {
      var currentPatch = AddressPatch();
      return patch(currentPatch).applyTo(current as Address);
    };
    return this;
  }

  PersonWithAddressPatch withPhone(String? value) {
    patchMap[PersonWithAddress$.phone] = value;
    return this;
  }
}

/// Field descriptors for [PersonWithAddress] query construction
abstract final class PersonWithAddressFields {
  static String _$getname(PersonWithAddress e) => e.name;
  static const name = Field<PersonWithAddress, String>('name', _$getname);
  static Address _$getaddress(PersonWithAddress e) => e.address;
  static const address = Field<PersonWithAddress, Address>(
    'address',
    _$getaddress,
  );
  static String? _$getphone(PersonWithAddress e) => e.phone;
  static const phone = Field<PersonWithAddress, String?>('phone', _$getphone);
}

extension PersonWithAddressCompareE on PersonWithAddress {
  Map<String, dynamic> compareToPersonWithAddress(PersonWithAddress other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (address != other.address) {
      diff['address'] = () => other.address;
    }
    if (phone != other.phone) {
      diff['phone'] = () => other.phone;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class CategoryNode {
  final String id;
  final String name;
  final List<CategoryNode>? children;
  final CategoryNode? parent;

  CategoryNode({
    required this.id,
    required this.name,
    this.children,
    this.parent,
  });

  CategoryNode copyWith({
    String? id,
    String? name,
    List<CategoryNode>? children,
    CategoryNode? parent,
  }) {
    return CategoryNode(
      id: id ?? this.id,
      name: name ?? this.name,
      children: children ?? this.children,
      parent: parent ?? this.parent,
    );
  }

  CategoryNode copyWithCategoryNode({
    String? id,
    String? name,
    List<CategoryNode>? children,
    CategoryNode? parent,
  }) {
    return copyWith(id: id, name: name, children: children, parent: parent);
  }

  CategoryNode patchWithCategoryNode({CategoryNodePatch? patchInput}) {
    final _patcher = patchInput ?? CategoryNodePatch();
    final _patchMap = _patcher.patchMap;
    return CategoryNode(
      id: _patchMap.containsKey(CategoryNode$.id)
          ? (_patchMap[CategoryNode$.id] is Function)
                ? _patchMap[CategoryNode$.id](this.id)
                : (_patchMap[CategoryNode$.id] is Patch)
                ? _patchMap[CategoryNode$.id].applyTo(this.id)
                : _patchMap[CategoryNode$.id]
          : this.id,
      name: _patchMap.containsKey(CategoryNode$.name)
          ? (_patchMap[CategoryNode$.name] is Function)
                ? _patchMap[CategoryNode$.name](this.name)
                : (_patchMap[CategoryNode$.name] is Patch)
                ? _patchMap[CategoryNode$.name].applyTo(this.name)
                : _patchMap[CategoryNode$.name]
          : this.name,
      children: _patchMap.containsKey(CategoryNode$.children)
          ? (_patchMap[CategoryNode$.children] is Function)
                ? _patchMap[CategoryNode$.children](this.children)
                : (_patchMap[CategoryNode$.children] is Patch)
                ? _patchMap[CategoryNode$.children].applyTo(this.children)
                : _patchMap[CategoryNode$.children]
          : this.children,
      parent: _patchMap.containsKey(CategoryNode$.parent)
          ? (_patchMap[CategoryNode$.parent] is Function)
                ? _patchMap[CategoryNode$.parent](this.parent)
                : (_patchMap[CategoryNode$.parent] is Patch)
                ? _patchMap[CategoryNode$.parent].applyTo(this.parent)
                : _patchMap[CategoryNode$.parent]
          : this.parent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryNode &&
        id == other.id &&
        name == other.name &&
        children == other.children &&
        parent == other.parent;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.name, this.children, this.parent);
  }

  @override
  String toString() {
    return 'CategoryNode(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'children: ${children}' +
        ', ' +
        'parent: ${parent})';
  }

  /// Creates a [CategoryNode] instance from JSON
  factory CategoryNode.fromJson(Map<String, dynamic> json) =>
      _$CategoryNodeFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CategoryNodeToJson(this);
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

extension CategoryNodePropertyHelpers on CategoryNode {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  List<CategoryNode> get childrenRequired =>
      children ?? (throw StateError('children is required but was null'));
  bool get hasChildren => children?.isNotEmpty ?? false;
  bool get noChildren => children?.isEmpty ?? true;
  bool get hasParent => parent != null;
  bool get noParent => parent == null;
  CategoryNode get parentRequired =>
      parent ?? (throw StateError('parent is required but was null'));
}

extension CategoryNodeSerialization on CategoryNode {
  Map<String, dynamic> toJson() => _$CategoryNodeToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CategoryNodeToJson(this);
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

enum CategoryNode$ { id, name, children, parent }

class CategoryNodePatch extends PatchBase<CategoryNode, CategoryNode$> {
  CategoryNode applyTo(CategoryNode entity) {
    return entity.patchWithCategoryNode(patchInput: this);
  }

  CategoryNodePatch withId(String? value) {
    patchMap[CategoryNode$.id] = value;
    return this;
  }

  CategoryNodePatch withName(String? value) {
    patchMap[CategoryNode$.name] = value;
    return this;
  }

  CategoryNodePatch withChildren(List<CategoryNode>? value) {
    patchMap[CategoryNode$.children] = value;
    return this;
  }

  CategoryNodePatch updateChildrenAt(
    int index,
    CategoryNodePatch Function(CategoryNodePatch) patch,
  ) {
    patchMap[CategoryNode$.children] = (List<dynamic> list) {
      var updatedList = List<CategoryNode>.from(list);
      if (index >= 0 && index < updatedList.length) {
        updatedList[index] = patch(
          CategoryNodePatch(),
        ).applyTo(updatedList[index] as CategoryNode);
      }
      return updatedList;
    };
    return this;
  }

  CategoryNodePatch withParent(CategoryNode? value) {
    patchMap[CategoryNode$.parent] = value;
    return this;
  }

  CategoryNodePatch withParentPatch(CategoryNodePatch patch) {
    patchMap[CategoryNode$.parent] = patch;
    return this;
  }

  CategoryNodePatch withParentPatchFunc(
    CategoryNodePatch Function(CategoryNodePatch) patch,
  ) {
    patchMap[CategoryNode$.parent] = (dynamic current) {
      var currentPatch = CategoryNodePatch();
      return patch(currentPatch).applyTo(current as CategoryNode);
    };
    return this;
  }
}

/// Field descriptors for [CategoryNode] query construction
abstract final class CategoryNodeFields {
  static String _$getid(CategoryNode e) => e.id;
  static const id = Field<CategoryNode, String>('id', _$getid);
  static String _$getname(CategoryNode e) => e.name;
  static const name = Field<CategoryNode, String>('name', _$getname);
  static List<CategoryNode>? _$getchildren(CategoryNode e) => e.children;
  static const children = Field<CategoryNode, List<CategoryNode>?>(
    'children',
    _$getchildren,
  );
  static CategoryNode? _$getparent(CategoryNode e) => e.parent;
  static const parent = Field<CategoryNode, CategoryNode?>(
    'parent',
    _$getparent,
  );
}

extension CategoryNodeCompareE on CategoryNode {
  Map<String, dynamic> compareToCategoryNode(CategoryNode other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (children != other.children) {
      diff['children'] = () => other.children;
    }
    if (parent != other.parent) {
      diff['parent'] = () => other.parent;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Timestamped {
  final DateTime createdAt;
  final DateTime? updatedAt;

  Timestamped({required this.createdAt, this.updatedAt});

  Timestamped copyWith({DateTime? createdAt, DateTime? updatedAt}) {
    return Timestamped(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Timestamped copyWithTimestamped({DateTime? createdAt, DateTime? updatedAt}) {
    return copyWith(createdAt: createdAt, updatedAt: updatedAt);
  }

  Timestamped patchWithTimestamped({TimestampedPatch? patchInput}) {
    final _patcher = patchInput ?? TimestampedPatch();
    final _patchMap = _patcher.patchMap;
    return Timestamped(
      createdAt: _patchMap.containsKey(Timestamped$.createdAt)
          ? (_patchMap[Timestamped$.createdAt] is Function)
                ? _patchMap[Timestamped$.createdAt](this.createdAt)
                : (_patchMap[Timestamped$.createdAt] is Patch)
                ? _patchMap[Timestamped$.createdAt].applyTo(this.createdAt)
                : _patchMap[Timestamped$.createdAt]
          : this.createdAt,
      updatedAt: _patchMap.containsKey(Timestamped$.updatedAt)
          ? (_patchMap[Timestamped$.updatedAt] is Function)
                ? _patchMap[Timestamped$.updatedAt](this.updatedAt)
                : (_patchMap[Timestamped$.updatedAt] is Patch)
                ? _patchMap[Timestamped$.updatedAt].applyTo(this.updatedAt)
                : _patchMap[Timestamped$.updatedAt]
          : this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Timestamped &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(this.createdAt, this.updatedAt);
  }

  @override
  String toString() {
    return 'Timestamped(' +
        'createdAt: ${createdAt}' +
        ', ' +
        'updatedAt: ${updatedAt})';
  }

  /// Creates a [Timestamped] instance from JSON
  factory Timestamped.fromJson(Map<String, dynamic> json) =>
      _$TimestampedFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TimestampedToJson(this);
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

extension TimestampedPropertyHelpers on Timestamped {
  bool get hasUpdatedAt => updatedAt != null;
  bool get noUpdatedAt => updatedAt == null;
  DateTime get updatedAtRequired =>
      updatedAt ?? (throw StateError('updatedAt is required but was null'));
}

extension TimestampedSerialization on Timestamped {
  Map<String, dynamic> toJson() => _$TimestampedToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TimestampedToJson(this);
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

enum Timestamped$ { createdAt, updatedAt }

class TimestampedPatch extends PatchBase<Timestamped, Timestamped$> {
  Timestamped applyTo(Timestamped entity) {
    return entity.patchWithTimestamped(patchInput: this);
  }

  TimestampedPatch withCreatedAt(DateTime? value) {
    patchMap[Timestamped$.createdAt] = value;
    return this;
  }

  TimestampedPatch withUpdatedAt(DateTime? value) {
    patchMap[Timestamped$.updatedAt] = value;
    return this;
  }
}

/// Field descriptors for [Timestamped] query construction
abstract final class TimestampedFields {
  static DateTime _$getcreatedAt(Timestamped e) => e.createdAt;
  static const createdAt = Field<Timestamped, DateTime>(
    'createdAt',
    _$getcreatedAt,
  );
  static DateTime? _$getupdatedAt(Timestamped e) => e.updatedAt;
  static const updatedAt = Field<Timestamped, DateTime?>(
    'updatedAt',
    _$getupdatedAt,
  );
}

extension TimestampedCompareE on Timestamped {
  Map<String, dynamic> compareToTimestamped(Timestamped other) {
    final Map<String, dynamic> diff = {};

    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (updatedAt != other.updatedAt) {
      diff['updatedAt'] = () => other.updatedAt;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Identified {
  final String id;

  Identified({required this.id});

  Identified copyWith({String? id}) {
    return Identified(id: id ?? this.id);
  }

  Identified copyWithIdentified({String? id}) {
    return copyWith(id: id);
  }

  Identified patchWithIdentified({IdentifiedPatch? patchInput}) {
    final _patcher = patchInput ?? IdentifiedPatch();
    final _patchMap = _patcher.patchMap;
    return Identified(
      id: _patchMap.containsKey(Identified$.id)
          ? (_patchMap[Identified$.id] is Function)
                ? _patchMap[Identified$.id](this.id)
                : (_patchMap[Identified$.id] is Patch)
                ? _patchMap[Identified$.id].applyTo(this.id)
                : _patchMap[Identified$.id]
          : this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Identified && id == other.id;
  }

  @override
  int get hashCode {
    return Object.hash(id, 0);
  }

  @override
  String toString() {
    return 'Identified(' + 'id: ${id})';
  }

  /// Creates a [Identified] instance from JSON
  factory Identified.fromJson(Map<String, dynamic> json) =>
      _$IdentifiedFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$IdentifiedToJson(this);
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

extension IdentifiedPropertyHelpers on Identified {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
}

extension IdentifiedSerialization on Identified {
  Map<String, dynamic> toJson() => _$IdentifiedToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$IdentifiedToJson(this);
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

enum Identified$ { id }

class IdentifiedPatch extends PatchBase<Identified, Identified$> {
  Identified applyTo(Identified entity) {
    return entity.patchWithIdentified(patchInput: this);
  }

  IdentifiedPatch withId(String? value) {
    patchMap[Identified$.id] = value;
    return this;
  }
}

/// Field descriptors for [Identified] query construction
abstract final class IdentifiedFields {
  static String _$getid(Identified e) => e.id;
  static const id = Field<Identified, String>('id', _$getid);
}

extension IdentifiedCompareE on Identified {
  Map<String, dynamic> compareToIdentified(Identified other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Post extends Timestamped implements Identified {
  @override
  final String id;
  final String title;
  final String content;
  final String authorId;

  Post({
    required DateTime createdAt,
    DateTime? updatedAt,
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
  }) : super(createdAt: createdAt, updatedAt: updatedAt);

  Post copyWith({
    DateTime? createdAt,
    DateTime? updatedAt,
    String? id,
    String? title,
    String? content,
    String? authorId,
  }) {
    return Post(
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
    );
  }

  Post copyWithPost({
    DateTime? createdAt,
    DateTime? updatedAt,
    String? id,
    String? title,
    String? content,
    String? authorId,
  }) {
    return copyWith(
      createdAt: createdAt,
      updatedAt: updatedAt,
      id: id,
      title: title,
      content: content,
      authorId: authorId,
    );
  }

  Post copyWithTimestamped({DateTime? createdAt, DateTime? updatedAt}) {
    return copyWith(createdAt: createdAt, updatedAt: updatedAt);
  }

  Post copyWithIdentified({String? id}) {
    return copyWith(id: id);
  }

  Post patchWithPost({PostPatch? patchInput}) {
    final _patcher = patchInput ?? PostPatch();
    final _patchMap = _patcher.patchMap;
    return Post(
      createdAt: _patchMap.containsKey(Post$.createdAt)
          ? (_patchMap[Post$.createdAt] is Function)
                ? _patchMap[Post$.createdAt](this.createdAt)
                : (_patchMap[Post$.createdAt] is Patch)
                ? _patchMap[Post$.createdAt].applyTo(this.createdAt)
                : _patchMap[Post$.createdAt]
          : this.createdAt,
      updatedAt: _patchMap.containsKey(Post$.updatedAt)
          ? (_patchMap[Post$.updatedAt] is Function)
                ? _patchMap[Post$.updatedAt](this.updatedAt)
                : (_patchMap[Post$.updatedAt] is Patch)
                ? _patchMap[Post$.updatedAt].applyTo(this.updatedAt)
                : _patchMap[Post$.updatedAt]
          : this.updatedAt,
      id: _patchMap.containsKey(Post$.id)
          ? (_patchMap[Post$.id] is Function)
                ? _patchMap[Post$.id](this.id)
                : (_patchMap[Post$.id] is Patch)
                ? _patchMap[Post$.id].applyTo(this.id)
                : _patchMap[Post$.id]
          : this.id,
      title: _patchMap.containsKey(Post$.title)
          ? (_patchMap[Post$.title] is Function)
                ? _patchMap[Post$.title](this.title)
                : (_patchMap[Post$.title] is Patch)
                ? _patchMap[Post$.title].applyTo(this.title)
                : _patchMap[Post$.title]
          : this.title,
      content: _patchMap.containsKey(Post$.content)
          ? (_patchMap[Post$.content] is Function)
                ? _patchMap[Post$.content](this.content)
                : (_patchMap[Post$.content] is Patch)
                ? _patchMap[Post$.content].applyTo(this.content)
                : _patchMap[Post$.content]
          : this.content,
      authorId: _patchMap.containsKey(Post$.authorId)
          ? (_patchMap[Post$.authorId] is Function)
                ? _patchMap[Post$.authorId](this.authorId)
                : (_patchMap[Post$.authorId] is Patch)
                ? _patchMap[Post$.authorId].applyTo(this.authorId)
                : _patchMap[Post$.authorId]
          : this.authorId,
    );
  }

  Post patchWithTimestamped({TimestampedPatch? patchInput}) {
    final _patcher = patchInput ?? TimestampedPatch();
    final _patchMap = _patcher.patchMap;
    return Post(
      createdAt: _patchMap.containsKey(Timestamped$.createdAt)
          ? (_patchMap[Timestamped$.createdAt] is Function)
                ? _patchMap[Timestamped$.createdAt](this.createdAt)
                : (_patchMap[Timestamped$.createdAt] is Patch)
                ? _patchMap[Timestamped$.createdAt].applyTo(this.createdAt)
                : _patchMap[Timestamped$.createdAt]
          : this.createdAt,
      updatedAt: _patchMap.containsKey(Timestamped$.updatedAt)
          ? (_patchMap[Timestamped$.updatedAt] is Function)
                ? _patchMap[Timestamped$.updatedAt](this.updatedAt)
                : (_patchMap[Timestamped$.updatedAt] is Patch)
                ? _patchMap[Timestamped$.updatedAt].applyTo(this.updatedAt)
                : _patchMap[Timestamped$.updatedAt]
          : this.updatedAt,
      id: this.id,
      title: this.title,
      content: this.content,
      authorId: this.authorId,
    );
  }

  Post patchWithIdentified({IdentifiedPatch? patchInput}) {
    final _patcher = patchInput ?? IdentifiedPatch();
    final _patchMap = _patcher.patchMap;
    return Post(
      createdAt: this.createdAt,
      updatedAt: this.updatedAt,
      id: _patchMap.containsKey(Identified$.id)
          ? (_patchMap[Identified$.id] is Function)
                ? _patchMap[Identified$.id](this.id)
                : (_patchMap[Identified$.id] is Patch)
                ? _patchMap[Identified$.id].applyTo(this.id)
                : _patchMap[Identified$.id]
          : this.id,
      title: this.title,
      content: this.content,
      authorId: this.authorId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        id == other.id &&
        title == other.title &&
        content == other.content &&
        authorId == other.authorId;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.createdAt,
      this.updatedAt,
      this.id,
      this.title,
      this.content,
      this.authorId,
    );
  }

  @override
  String toString() {
    return 'Post(' +
        'createdAt: ${createdAt}' +
        ', ' +
        'updatedAt: ${updatedAt}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'title: ${title}' +
        ', ' +
        'content: ${content}' +
        ', ' +
        'authorId: ${authorId})';
  }

  /// Creates a [Post] instance from JSON
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PostToJson(this);
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

extension PostPropertyHelpers on Post {
  bool get hasTitle => title.isNotEmpty;
  bool get noTitle => title.isEmpty;
  bool get hasContent => content.isNotEmpty;
  bool get noContent => content.isEmpty;
  bool get hasAuthorId => authorId.isNotEmpty;
  bool get noAuthorId => authorId.isEmpty;
}

extension PostSerialization on Post {
  Map<String, dynamic> toJson() => _$PostToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$PostToJson(this);
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

enum Post$ { createdAt, updatedAt, id, title, content, authorId }

class PostPatch extends PatchBase<Post, Post$> {
  Post applyTo(Post entity) {
    return entity.patchWithPost(patchInput: this);
  }

  PostPatch withCreatedAt(DateTime? value) {
    patchMap[Post$.createdAt] = value;
    return this;
  }

  PostPatch withUpdatedAt(DateTime? value) {
    patchMap[Post$.updatedAt] = value;
    return this;
  }

  PostPatch withId(String? value) {
    patchMap[Post$.id] = value;
    return this;
  }

  PostPatch withTitle(String? value) {
    patchMap[Post$.title] = value;
    return this;
  }

  PostPatch withContent(String? value) {
    patchMap[Post$.content] = value;
    return this;
  }

  PostPatch withAuthorId(String? value) {
    patchMap[Post$.authorId] = value;
    return this;
  }
}

/// Field descriptors for [Post] query construction
abstract final class PostFields {
  static DateTime _$getcreatedAt(Post e) => e.createdAt;
  static const createdAt = Field<Post, DateTime>('createdAt', _$getcreatedAt);
  static DateTime? _$getupdatedAt(Post e) => e.updatedAt;
  static const updatedAt = Field<Post, DateTime?>('updatedAt', _$getupdatedAt);
  static String _$getid(Post e) => e.id;
  static const id = Field<Post, String>('id', _$getid);
  static String _$gettitle(Post e) => e.title;
  static const title = Field<Post, String>('title', _$gettitle);
  static String _$getcontent(Post e) => e.content;
  static const content = Field<Post, String>('content', _$getcontent);
  static String _$getauthorId(Post e) => e.authorId;
  static const authorId = Field<Post, String>('authorId', _$getauthorId);
}

extension PostCompareE on Post {
  Map<String, dynamic> compareToPost(Post other) {
    final Map<String, dynamic> diff = {};

    if (createdAt != other.createdAt) {
      diff['createdAt'] = () => other.createdAt;
    }
    if (updatedAt != other.updatedAt) {
      diff['updatedAt'] = () => other.updatedAt;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (content != other.content) {
      diff['content'] = () => other.content;
    }
    if (authorId != other.authorId) {
      diff['authorId'] = () => other.authorId;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Document {
  final String title;
  final String content;
  final int version;
  final List<String> tags;

  Document({
    required this.title,
    required this.content,
    required this.version,
    required this.tags,
  });

  Document copyWith({
    String? title,
    String? content,
    int? version,
    List<String>? tags,
  }) {
    return Document(
      title: title ?? this.title,
      content: content ?? this.content,
      version: version ?? this.version,
      tags: tags ?? this.tags,
    );
  }

  Document copyWithDocument({
    String? title,
    String? content,
    int? version,
    List<String>? tags,
  }) {
    return copyWith(
      title: title,
      content: content,
      version: version,
      tags: tags,
    );
  }

  Document patchWithDocument({DocumentPatch? patchInput}) {
    final _patcher = patchInput ?? DocumentPatch();
    final _patchMap = _patcher.patchMap;
    return Document(
      title: _patchMap.containsKey(Document$.title)
          ? (_patchMap[Document$.title] is Function)
                ? _patchMap[Document$.title](this.title)
                : (_patchMap[Document$.title] is Patch)
                ? _patchMap[Document$.title].applyTo(this.title)
                : _patchMap[Document$.title]
          : this.title,
      content: _patchMap.containsKey(Document$.content)
          ? (_patchMap[Document$.content] is Function)
                ? _patchMap[Document$.content](this.content)
                : (_patchMap[Document$.content] is Patch)
                ? _patchMap[Document$.content].applyTo(this.content)
                : _patchMap[Document$.content]
          : this.content,
      version: _patchMap.containsKey(Document$.version)
          ? (_patchMap[Document$.version] is Function)
                ? _patchMap[Document$.version](this.version)
                : (_patchMap[Document$.version] is Patch)
                ? _patchMap[Document$.version].applyTo(this.version)
                : _patchMap[Document$.version]
          : this.version,
      tags: _patchMap.containsKey(Document$.tags)
          ? (_patchMap[Document$.tags] is Function)
                ? _patchMap[Document$.tags](this.tags)
                : (_patchMap[Document$.tags] is Patch)
                ? _patchMap[Document$.tags].applyTo(this.tags)
                : _patchMap[Document$.tags]
          : this.tags,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Document &&
        title == other.title &&
        content == other.content &&
        version == other.version &&
        tags == other.tags;
  }

  @override
  int get hashCode {
    return Object.hash(this.title, this.content, this.version, this.tags);
  }

  @override
  String toString() {
    return 'Document(' +
        'title: ${title}' +
        ', ' +
        'content: ${content}' +
        ', ' +
        'version: ${version}' +
        ', ' +
        'tags: ${tags})';
  }

  /// Creates a [Document] instance from JSON
  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$DocumentToJson(this);
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

extension DocumentPropertyHelpers on Document {
  bool get hasTitle => title.isNotEmpty;
  bool get noTitle => title.isEmpty;
  bool get hasContent => content.isNotEmpty;
  bool get noContent => content.isEmpty;
  bool get hasTags => tags.isNotEmpty;
  bool get noTags => tags.isEmpty;
}

extension DocumentSerialization on Document {
  Map<String, dynamic> toJson() => _$DocumentToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$DocumentToJson(this);
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

enum Document$ { title, content, version, tags }

class DocumentPatch extends PatchBase<Document, Document$> {
  Document applyTo(Document entity) {
    return entity.patchWithDocument(patchInput: this);
  }

  DocumentPatch withTitle(String? value) {
    patchMap[Document$.title] = value;
    return this;
  }

  DocumentPatch withContent(String? value) {
    patchMap[Document$.content] = value;
    return this;
  }

  DocumentPatch withVersion(int? value) {
    patchMap[Document$.version] = value;
    return this;
  }

  DocumentPatch withTags(List<String>? value) {
    patchMap[Document$.tags] = value;
    return this;
  }
}

/// Field descriptors for [Document] query construction
abstract final class DocumentFields {
  static String _$gettitle(Document e) => e.title;
  static const title = Field<Document, String>('title', _$gettitle);
  static String _$getcontent(Document e) => e.content;
  static const content = Field<Document, String>('content', _$getcontent);
  static int _$getversion(Document e) => e.version;
  static const version = Field<Document, int>('version', _$getversion);
  static List<String> _$gettags(Document e) => e.tags;
  static const tags = Field<Document, List<String>>('tags', _$gettags);
}

extension DocumentCompareE on Document {
  Map<String, dynamic> compareToDocument(Document other) {
    final Map<String, dynamic> diff = {};

    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (content != other.content) {
      diff['content'] = () => other.content;
    }
    if (version != other.version) {
      diff['version'] = () => other.version;
    }
    if (tags != other.tags) {
      diff['tags'] = () => other.tags;
    }
    return diff;
  }
}

class Result<T> {
  final bool success;
  final T? data;
  final String? errorMessage;

  Result({required this.success, this.data, this.errorMessage});

  Result copyWith({bool? success, T? data, String? errorMessage}) {
    return Result(
      success: success ?? this.success,
      data: data ?? this.data,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Result copyWithResult({bool? success, T? data, String? errorMessage}) {
    return copyWith(success: success, data: data, errorMessage: errorMessage);
  }

  Result patchWithResult({ResultPatch? patchInput}) {
    final _patcher = patchInput ?? ResultPatch();
    final _patchMap = _patcher.patchMap;
    return Result(
      success: _patchMap.containsKey(Result$.success)
          ? (_patchMap[Result$.success] is Function)
                ? _patchMap[Result$.success](this.success)
                : (_patchMap[Result$.success] is Patch)
                ? _patchMap[Result$.success].applyTo(this.success)
                : _patchMap[Result$.success]
          : this.success,
      data: _patchMap.containsKey(Result$.data)
          ? (_patchMap[Result$.data] is Function)
                ? _patchMap[Result$.data](this.data)
                : (_patchMap[Result$.data] is Patch)
                ? _patchMap[Result$.data].applyTo(this.data)
                : _patchMap[Result$.data]
          : this.data,
      errorMessage: _patchMap.containsKey(Result$.errorMessage)
          ? (_patchMap[Result$.errorMessage] is Function)
                ? _patchMap[Result$.errorMessage](this.errorMessage)
                : (_patchMap[Result$.errorMessage] is Patch)
                ? _patchMap[Result$.errorMessage].applyTo(this.errorMessage)
                : _patchMap[Result$.errorMessage]
          : this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Result &&
        success == other.success &&
        data == other.data &&
        errorMessage == other.errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(this.success, this.data, this.errorMessage);
  }

  @override
  String toString() {
    return 'Result(' +
        'success: ${success}' +
        ', ' +
        'data: ${data}' +
        ', ' +
        'errorMessage: ${errorMessage})';
  }
}

extension ResultPropertyHelpers<T> on Result<T> {
  bool get hasData => data != null;
  bool get noData => data == null;
  T get dataRequired =>
      data ?? (throw StateError('data is required but was null'));
  bool get hasErrorMessage => errorMessage?.isNotEmpty == true;
  bool get noErrorMessage => errorMessage?.isEmpty ?? true;
  String get errorMessageRequired =>
      errorMessage ??
      (throw StateError('errorMessage is required but was null'));
}

enum Result$ { success, data, errorMessage }

class ResultPatch extends PatchBase<Result, Result$> {
  Result applyTo(Result entity) {
    return entity.patchWithResult(patchInput: this);
  }

  ResultPatch withSuccess(bool? value) {
    patchMap[Result$.success] = value;
    return this;
  }

  ResultPatch withData(dynamic value) {
    patchMap[Result$.data] = value;
    return this;
  }

  ResultPatch withErrorMessage(String? value) {
    patchMap[Result$.errorMessage] = value;
    return this;
  }
}

/// Field descriptors for [Result] query construction
abstract final class ResultFields {
  static bool _$getsuccess<T>(Result<T> e) => e.success;
  static Field<Result<T>, bool> success<T>() =>
      Field<Result<T>, bool>('success', _$getsuccess<T>);
  static T? _$getdata<T>(Result<T> e) => e.data;
  static Field<Result<T>, T?> data<T>() =>
      Field<Result<T>, T?>('data', _$getdata<T>);
  static String? _$geterrorMessage<T>(Result<T> e) => e.errorMessage;
  static Field<Result<T>, String?> errorMessage<T>() =>
      Field<Result<T>, String?>('errorMessage', _$geterrorMessage<T>);
}

extension ResultCompareE on Result {
  Map<String, dynamic> compareToResult(Result other) {
    final Map<String, dynamic> diff = {};

    if (success != other.success) {
      diff['success'] = () => other.success;
    }
    if (data != other.data) {
      diff['data'] = () => other.data;
    }
    if (errorMessage != other.errorMessage) {
      diff['errorMessage'] = () => other.errorMessage;
    }
    return diff;
  }
}

@JsonSerializable(
  explicitToJson: true,
  checked: true,
  genericArgumentFactories: true,
)
class ListResponse<T> {
  final int total;
  final List<T> items;
  final int page;
  final int pageSize;

  ListResponse({
    required this.total,
    required this.items,
    required this.page,
    required this.pageSize,
  });

  ListResponse copyWith({
    int? total,
    List<T>? items,
    int? page,
    int? pageSize,
  }) {
    return ListResponse(
      total: total ?? this.total,
      items: items ?? this.items,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  ListResponse copyWithListResponse({
    int? total,
    List<T>? items,
    int? page,
    int? pageSize,
  }) {
    return copyWith(total: total, items: items, page: page, pageSize: pageSize);
  }

  ListResponse patchWithListResponse({ListResponsePatch? patchInput}) {
    final _patcher = patchInput ?? ListResponsePatch();
    final _patchMap = _patcher.patchMap;
    return ListResponse(
      total: _patchMap.containsKey(ListResponse$.total)
          ? (_patchMap[ListResponse$.total] is Function)
                ? _patchMap[ListResponse$.total](this.total)
                : (_patchMap[ListResponse$.total] is Patch)
                ? _patchMap[ListResponse$.total].applyTo(this.total)
                : _patchMap[ListResponse$.total]
          : this.total,
      items: _patchMap.containsKey(ListResponse$.items)
          ? (_patchMap[ListResponse$.items] is Function)
                ? _patchMap[ListResponse$.items](this.items)
                : (_patchMap[ListResponse$.items] is Patch)
                ? _patchMap[ListResponse$.items].applyTo(this.items)
                : _patchMap[ListResponse$.items]
          : this.items,
      page: _patchMap.containsKey(ListResponse$.page)
          ? (_patchMap[ListResponse$.page] is Function)
                ? _patchMap[ListResponse$.page](this.page)
                : (_patchMap[ListResponse$.page] is Patch)
                ? _patchMap[ListResponse$.page].applyTo(this.page)
                : _patchMap[ListResponse$.page]
          : this.page,
      pageSize: _patchMap.containsKey(ListResponse$.pageSize)
          ? (_patchMap[ListResponse$.pageSize] is Function)
                ? _patchMap[ListResponse$.pageSize](this.pageSize)
                : (_patchMap[ListResponse$.pageSize] is Patch)
                ? _patchMap[ListResponse$.pageSize].applyTo(this.pageSize)
                : _patchMap[ListResponse$.pageSize]
          : this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListResponse &&
        total == other.total &&
        items == other.items &&
        page == other.page &&
        pageSize == other.pageSize;
  }

  @override
  int get hashCode {
    return Object.hash(this.total, this.items, this.page, this.pageSize);
  }

  @override
  String toString() {
    return 'ListResponse(' +
        'total: ${total}' +
        ', ' +
        'items: ${items}' +
        ', ' +
        'page: ${page}' +
        ', ' +
        'pageSize: ${pageSize})';
  }

  /// Creates a [ListResponse] instance from JSON
  factory ListResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ListResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$ListResponseToJson(this, toJsonT);
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

extension ListResponsePropertyHelpers<T> on ListResponse<T> {
  bool get hasItems => items.isNotEmpty;
  bool get noItems => items.isEmpty;
}

extension ListResponseSerialization<T> on ListResponse<T> {
  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ListResponseToJson(this, toJsonT);
  Map<String, dynamic> toJsonLean(Object? Function(T value) toJsonT) {
    final Map<String, dynamic> data = _$ListResponseToJson(this, toJsonT);
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

enum ListResponse$ { total, items, page, pageSize }

class ListResponsePatch extends PatchBase<ListResponse, ListResponse$> {
  ListResponse applyTo(ListResponse entity) {
    return entity.patchWithListResponse(patchInput: this);
  }

  ListResponsePatch withTotal(int? value) {
    patchMap[ListResponse$.total] = value;
    return this;
  }

  ListResponsePatch withItems(dynamic value) {
    patchMap[ListResponse$.items] = value;
    return this;
  }

  ListResponsePatch withPage(int? value) {
    patchMap[ListResponse$.page] = value;
    return this;
  }

  ListResponsePatch withPageSize(int? value) {
    patchMap[ListResponse$.pageSize] = value;
    return this;
  }
}

/// Field descriptors for [ListResponse] query construction
abstract final class ListResponseFields {
  static int _$gettotal<T>(ListResponse<T> e) => e.total;
  static Field<ListResponse<T>, int> total<T>() =>
      Field<ListResponse<T>, int>('total', _$gettotal<T>);
  static List<T> _$getitems<T>(ListResponse<T> e) => e.items;
  static Field<ListResponse<T>, List<T>> items<T>() =>
      Field<ListResponse<T>, List<T>>('items', _$getitems<T>);
  static int _$getpage<T>(ListResponse<T> e) => e.page;
  static Field<ListResponse<T>, int> page<T>() =>
      Field<ListResponse<T>, int>('page', _$getpage<T>);
  static int _$getpageSize<T>(ListResponse<T> e) => e.pageSize;
  static Field<ListResponse<T>, int> pageSize<T>() =>
      Field<ListResponse<T>, int>('pageSize', _$getpageSize<T>);
}

extension ListResponseCompareE on ListResponse {
  Map<String, dynamic> compareToListResponse(ListResponse other) {
    final Map<String, dynamic> diff = {};

    if (total != other.total) {
      diff['total'] = () => other.total;
    }
    if (items != other.items) {
      diff['items'] = () => other.items;
    }
    if (page != other.page) {
      diff['page'] = () => other.page;
    }
    if (pageSize != other.pageSize) {
      diff['pageSize'] = () => other.pageSize;
    }
    return diff;
  }
}

sealed class Shape {
  String get name;
}

extension ShapePolymorphicE on Shape {
  bool get isCircle => this is Circle;
  Circle? get asCircle => this is Circle ? this as Circle : null;
  bool get isRectangle => this is Rectangle;
  Rectangle? get asRectangle => this is Rectangle ? this as Rectangle : null;
}

extension ShapePropertyHelpers on Shape {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

enum Shape$ { name }

/// Field descriptors for [Shape] query construction
abstract final class ShapeFields {
  static String _$getname(Shape e) => e.name;
  static const name = Field<Shape, String>('name', _$getname);
}

extension ShapeCompareE on Shape {
  Map<String, dynamic> compareToShape(Shape other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    return diff;
  }
}

extension ShapeChangeToE on Shape {
  Circle changeToCircle({required double radius, String? name}) {
    final _patcher = CirclePatch();
    _patcher.withRadius(radius);
    if (name != null) {
      _patcher.withName(name);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return Circle.fromJson(_json);
  }

  Rectangle changeToRectangle({
    required double width,
    required double height,
    String? name,
  }) {
    final _patcher = RectanglePatch();
    _patcher.withWidth(width);
    _patcher.withHeight(height);
    if (name != null) {
      _patcher.withName(name);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return Rectangle.fromJson(_json);
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Circle implements Shape {
  @override
  final String name;
  final double radius;

  Circle({required this.name, required this.radius});

  Circle copyWith({String? name, double? radius}) {
    return Circle(name: name ?? this.name, radius: radius ?? this.radius);
  }

  Circle copyWithCircle({String? name, double? radius}) {
    return copyWith(name: name, radius: radius);
  }

  Circle patchWithCircle({CirclePatch? patchInput}) {
    final _patcher = patchInput ?? CirclePatch();
    final _patchMap = _patcher.patchMap;
    return Circle(
      name: _patchMap.containsKey(Circle$.name)
          ? (_patchMap[Circle$.name] is Function)
                ? _patchMap[Circle$.name](this.name)
                : (_patchMap[Circle$.name] is Patch)
                ? _patchMap[Circle$.name].applyTo(this.name)
                : _patchMap[Circle$.name]
          : this.name,
      radius: _patchMap.containsKey(Circle$.radius)
          ? (_patchMap[Circle$.radius] is Function)
                ? _patchMap[Circle$.radius](this.radius)
                : (_patchMap[Circle$.radius] is Patch)
                ? _patchMap[Circle$.radius].applyTo(this.radius)
                : _patchMap[Circle$.radius]
          : this.radius,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Circle && name == other.name && radius == other.radius;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.radius);
  }

  @override
  String toString() {
    return 'Circle(' + 'name: ${name}' + ', ' + 'radius: ${radius})';
  }

  /// Creates a [Circle] instance from JSON
  factory Circle.fromJson(Map<String, dynamic> json) => _$CircleFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CircleToJson(this);
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

  Map<String, dynamic> toJson() {
    final json = _$CircleToJson(this);
    json['__typename'] = 'Circle';
    return json;
  }
}

extension CirclePropertyHelpers on Circle {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

extension CircleSerialization on Circle {
  Map<String, dynamic> toJson() => _$CircleToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CircleToJson(this);
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

enum Circle$ { name, radius }

class CirclePatch extends PatchBase<Circle, Circle$> {
  Circle applyTo(Circle entity) {
    return entity.patchWithCircle(patchInput: this);
  }

  CirclePatch withName(String? value) {
    patchMap[Circle$.name] = value;
    return this;
  }

  CirclePatch withRadius(double? value) {
    patchMap[Circle$.radius] = value;
    return this;
  }
}

/// Field descriptors for [Circle] query construction
abstract final class CircleFields {
  static String _$getname(Circle e) => e.name;
  static const name = Field<Circle, String>('name', _$getname);
  static double _$getradius(Circle e) => e.radius;
  static const radius = Field<Circle, double>('radius', _$getradius);
}

extension CircleCompareE on Circle {
  Map<String, dynamic> compareToCircle(Circle other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (radius != other.radius) {
      diff['radius'] = () => other.radius;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Rectangle implements Shape {
  @override
  final String name;
  final double width;
  final double height;

  Rectangle({required this.name, required this.width, required this.height});

  Rectangle copyWith({String? name, double? width, double? height}) {
    return Rectangle(
      name: name ?? this.name,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Rectangle copyWithRectangle({String? name, double? width, double? height}) {
    return copyWith(name: name, width: width, height: height);
  }

  Rectangle patchWithRectangle({RectanglePatch? patchInput}) {
    final _patcher = patchInput ?? RectanglePatch();
    final _patchMap = _patcher.patchMap;
    return Rectangle(
      name: _patchMap.containsKey(Rectangle$.name)
          ? (_patchMap[Rectangle$.name] is Function)
                ? _patchMap[Rectangle$.name](this.name)
                : (_patchMap[Rectangle$.name] is Patch)
                ? _patchMap[Rectangle$.name].applyTo(this.name)
                : _patchMap[Rectangle$.name]
          : this.name,
      width: _patchMap.containsKey(Rectangle$.width)
          ? (_patchMap[Rectangle$.width] is Function)
                ? _patchMap[Rectangle$.width](this.width)
                : (_patchMap[Rectangle$.width] is Patch)
                ? _patchMap[Rectangle$.width].applyTo(this.width)
                : _patchMap[Rectangle$.width]
          : this.width,
      height: _patchMap.containsKey(Rectangle$.height)
          ? (_patchMap[Rectangle$.height] is Function)
                ? _patchMap[Rectangle$.height](this.height)
                : (_patchMap[Rectangle$.height] is Patch)
                ? _patchMap[Rectangle$.height].applyTo(this.height)
                : _patchMap[Rectangle$.height]
          : this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rectangle &&
        name == other.name &&
        width == other.width &&
        height == other.height;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.width, this.height);
  }

  @override
  String toString() {
    return 'Rectangle(' +
        'name: ${name}' +
        ', ' +
        'width: ${width}' +
        ', ' +
        'height: ${height})';
  }

  /// Creates a [Rectangle] instance from JSON
  factory Rectangle.fromJson(Map<String, dynamic> json) =>
      _$RectangleFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$RectangleToJson(this);
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

  Map<String, dynamic> toJson() {
    final json = _$RectangleToJson(this);
    json['__typename'] = 'Rectangle';
    return json;
  }
}

extension RectanglePropertyHelpers on Rectangle {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

extension RectangleSerialization on Rectangle {
  Map<String, dynamic> toJson() => _$RectangleToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$RectangleToJson(this);
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

enum Rectangle$ { name, width, height }

class RectanglePatch extends PatchBase<Rectangle, Rectangle$> {
  Rectangle applyTo(Rectangle entity) {
    return entity.patchWithRectangle(patchInput: this);
  }

  RectanglePatch withName(String? value) {
    patchMap[Rectangle$.name] = value;
    return this;
  }

  RectanglePatch withWidth(double? value) {
    patchMap[Rectangle$.width] = value;
    return this;
  }

  RectanglePatch withHeight(double? value) {
    patchMap[Rectangle$.height] = value;
    return this;
  }
}

/// Field descriptors for [Rectangle] query construction
abstract final class RectangleFields {
  static String _$getname(Rectangle e) => e.name;
  static const name = Field<Rectangle, String>('name', _$getname);
  static double _$getwidth(Rectangle e) => e.width;
  static const width = Field<Rectangle, double>('width', _$getwidth);
  static double _$getheight(Rectangle e) => e.height;
  static const height = Field<Rectangle, double>('height', _$getheight);
}

extension RectangleCompareE on Rectangle {
  Map<String, dynamic> compareToRectangle(Rectangle other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (width != other.width) {
      diff['width'] = () => other.width;
    }
    if (height != other.height) {
      diff['height'] = () => other.height;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Color {
  final int red;
  final int green;
  final int blue;

  const Color({required this.red, required this.green, required this.blue});

  Color copyWith({int? red, int? green, int? blue}) {
    return Color(
      red: red ?? this.red,
      green: green ?? this.green,
      blue: blue ?? this.blue,
    );
  }

  Color copyWithColor({int? red, int? green, int? blue}) {
    return copyWith(red: red, green: green, blue: blue);
  }

  Color patchWithColor({ColorPatch? patchInput}) {
    final _patcher = patchInput ?? ColorPatch();
    final _patchMap = _patcher.patchMap;
    return Color(
      red: _patchMap.containsKey(Color$.red)
          ? (_patchMap[Color$.red] is Function)
                ? _patchMap[Color$.red](this.red)
                : (_patchMap[Color$.red] is Patch)
                ? _patchMap[Color$.red].applyTo(this.red)
                : _patchMap[Color$.red]
          : this.red,
      green: _patchMap.containsKey(Color$.green)
          ? (_patchMap[Color$.green] is Function)
                ? _patchMap[Color$.green](this.green)
                : (_patchMap[Color$.green] is Patch)
                ? _patchMap[Color$.green].applyTo(this.green)
                : _patchMap[Color$.green]
          : this.green,
      blue: _patchMap.containsKey(Color$.blue)
          ? (_patchMap[Color$.blue] is Function)
                ? _patchMap[Color$.blue](this.blue)
                : (_patchMap[Color$.blue] is Patch)
                ? _patchMap[Color$.blue].applyTo(this.blue)
                : _patchMap[Color$.blue]
          : this.blue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Color &&
        red == other.red &&
        green == other.green &&
        blue == other.blue;
  }

  @override
  int get hashCode {
    return Object.hash(this.red, this.green, this.blue);
  }

  @override
  String toString() {
    return 'Color(' +
        'red: ${red}' +
        ', ' +
        'green: ${green}' +
        ', ' +
        'blue: ${blue})';
  }

  /// Creates a [Color] instance from JSON
  factory Color.fromJson(Map<String, dynamic> json) => _$ColorFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ColorToJson(this);
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

extension ColorPropertyHelpers on Color {}

extension ColorSerialization on Color {
  Map<String, dynamic> toJson() => _$ColorToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ColorToJson(this);
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

enum Color$ { red, green, blue }

class ColorPatch extends PatchBase<Color, Color$> {
  Color applyTo(Color entity) {
    return entity.patchWithColor(patchInput: this);
  }

  ColorPatch withRed(int? value) {
    patchMap[Color$.red] = value;
    return this;
  }

  ColorPatch withGreen(int? value) {
    patchMap[Color$.green] = value;
    return this;
  }

  ColorPatch withBlue(int? value) {
    patchMap[Color$.blue] = value;
    return this;
  }
}

/// Field descriptors for [Color] query construction
abstract final class ColorFields {
  static int _$getred(Color e) => e.red;
  static const red = Field<Color, int>('red', _$getred);
  static int _$getgreen(Color e) => e.green;
  static const green = Field<Color, int>('green', _$getgreen);
  static int _$getblue(Color e) => e.blue;
  static const blue = Field<Color, int>('blue', _$getblue);
}

extension ColorCompareE on Color {
  Map<String, dynamic> compareToColor(Color other) {
    final Map<String, dynamic> diff = {};

    if (red != other.red) {
      diff['red'] = () => other.red;
    }
    if (green != other.green) {
      diff['green'] = () => other.green;
    }
    if (blue != other.blue) {
      diff['blue'] = () => other.blue;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class StartupOptions {
  final Duration? timeout;
  final bool? forceRefresh;
  final String? locale;

  const StartupOptions({this.timeout, this.forceRefresh, this.locale});

  StartupOptions copyWith({
    Duration? timeout,
    bool? forceRefresh,
    String? locale,
  }) {
    return StartupOptions(
      timeout: timeout ?? this.timeout,
      forceRefresh: forceRefresh ?? this.forceRefresh,
      locale: locale ?? this.locale,
    );
  }

  StartupOptions copyWithStartupOptions({
    Duration? timeout,
    bool? forceRefresh,
    String? locale,
  }) {
    return copyWith(
      timeout: timeout,
      forceRefresh: forceRefresh,
      locale: locale,
    );
  }

  StartupOptions patchWithStartupOptions({StartupOptionsPatch? patchInput}) {
    final _patcher = patchInput ?? StartupOptionsPatch();
    final _patchMap = _patcher.patchMap;
    return StartupOptions(
      timeout: _patchMap.containsKey(StartupOptions$.timeout)
          ? (_patchMap[StartupOptions$.timeout] is Function)
                ? _patchMap[StartupOptions$.timeout](this.timeout)
                : (_patchMap[StartupOptions$.timeout] is Patch)
                ? _patchMap[StartupOptions$.timeout].applyTo(this.timeout)
                : _patchMap[StartupOptions$.timeout]
          : this.timeout,
      forceRefresh: _patchMap.containsKey(StartupOptions$.forceRefresh)
          ? (_patchMap[StartupOptions$.forceRefresh] is Function)
                ? _patchMap[StartupOptions$.forceRefresh](this.forceRefresh)
                : (_patchMap[StartupOptions$.forceRefresh] is Patch)
                ? _patchMap[StartupOptions$.forceRefresh].applyTo(
                    this.forceRefresh,
                  )
                : _patchMap[StartupOptions$.forceRefresh]
          : this.forceRefresh,
      locale: _patchMap.containsKey(StartupOptions$.locale)
          ? (_patchMap[StartupOptions$.locale] is Function)
                ? _patchMap[StartupOptions$.locale](this.locale)
                : (_patchMap[StartupOptions$.locale] is Patch)
                ? _patchMap[StartupOptions$.locale].applyTo(this.locale)
                : _patchMap[StartupOptions$.locale]
          : this.locale,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StartupOptions &&
        timeout == other.timeout &&
        forceRefresh == other.forceRefresh &&
        locale == other.locale;
  }

  @override
  int get hashCode {
    return Object.hash(this.timeout, this.forceRefresh, this.locale);
  }

  @override
  String toString() {
    return 'StartupOptions(' +
        'timeout: ${timeout}' +
        ', ' +
        'forceRefresh: ${forceRefresh}' +
        ', ' +
        'locale: ${locale})';
  }

  /// Creates a [StartupOptions] instance from JSON
  factory StartupOptions.fromJson(Map<String, dynamic> json) =>
      _$StartupOptionsFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$StartupOptionsToJson(this);
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

extension StartupOptionsPropertyHelpers on StartupOptions {
  bool get hasTimeout => timeout != null;
  bool get noTimeout => timeout == null;
  Duration get timeoutRequired =>
      timeout ?? (throw StateError('timeout is required but was null'));
  bool get hasForceRefresh => forceRefresh != null;
  bool get noForceRefresh => forceRefresh == null;
  bool get forceRefreshRequired =>
      forceRefresh ??
      (throw StateError('forceRefresh is required but was null'));
  bool get hasLocale => locale?.isNotEmpty == true;
  bool get noLocale => locale?.isEmpty ?? true;
  String get localeRequired =>
      locale ?? (throw StateError('locale is required but was null'));
}

extension StartupOptionsSerialization on StartupOptions {
  Map<String, dynamic> toJson() => _$StartupOptionsToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$StartupOptionsToJson(this);
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

enum StartupOptions$ { timeout, forceRefresh, locale }

class StartupOptionsPatch extends PatchBase<StartupOptions, StartupOptions$> {
  StartupOptions applyTo(StartupOptions entity) {
    return entity.patchWithStartupOptions(patchInput: this);
  }

  StartupOptionsPatch withTimeout(Duration? value) {
    patchMap[StartupOptions$.timeout] = value;
    return this;
  }

  StartupOptionsPatch withForceRefresh(bool? value) {
    patchMap[StartupOptions$.forceRefresh] = value;
    return this;
  }

  StartupOptionsPatch withLocale(String? value) {
    patchMap[StartupOptions$.locale] = value;
    return this;
  }
}

/// Field descriptors for [StartupOptions] query construction
abstract final class StartupOptionsFields {
  static Duration? _$gettimeout(StartupOptions e) => e.timeout;
  static const timeout = Field<StartupOptions, Duration?>(
    'timeout',
    _$gettimeout,
  );
  static bool? _$getforceRefresh(StartupOptions e) => e.forceRefresh;
  static const forceRefresh = Field<StartupOptions, bool?>(
    'forceRefresh',
    _$getforceRefresh,
  );
  static String? _$getlocale(StartupOptions e) => e.locale;
  static const locale = Field<StartupOptions, String?>('locale', _$getlocale);
}

extension StartupOptionsCompareE on StartupOptions {
  Map<String, dynamic> compareToStartupOptions(StartupOptions other) {
    final Map<String, dynamic> diff = {};

    if (timeout != other.timeout) {
      diff['timeout'] = () => other.timeout;
    }
    if (forceRefresh != other.forceRefresh) {
      diff['forceRefresh'] = () => other.forceRefresh;
    }
    if (locale != other.locale) {
      diff['locale'] = () => other.locale;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Employee {
  final String id;
  final String name;
  final String? title;
  final String? department;

  Employee({required this.id, required this.name, this.title, this.department});

  Employee copyWith({
    String? id,
    String? name,
    String? title,
    String? department,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      department: department ?? this.department,
    );
  }

  Employee copyWithEmployee({
    String? id,
    String? name,
    String? title,
    String? department,
  }) {
    return copyWith(id: id, name: name, title: title, department: department);
  }

  Employee patchWithEmployee({EmployeePatch? patchInput}) {
    final _patcher = patchInput ?? EmployeePatch();
    final _patchMap = _patcher.patchMap;
    return Employee(
      id: _patchMap.containsKey(Employee$.id)
          ? (_patchMap[Employee$.id] is Function)
                ? _patchMap[Employee$.id](this.id)
                : (_patchMap[Employee$.id] is Patch)
                ? _patchMap[Employee$.id].applyTo(this.id)
                : _patchMap[Employee$.id]
          : this.id,
      name: _patchMap.containsKey(Employee$.name)
          ? (_patchMap[Employee$.name] is Function)
                ? _patchMap[Employee$.name](this.name)
                : (_patchMap[Employee$.name] is Patch)
                ? _patchMap[Employee$.name].applyTo(this.name)
                : _patchMap[Employee$.name]
          : this.name,
      title: _patchMap.containsKey(Employee$.title)
          ? (_patchMap[Employee$.title] is Function)
                ? _patchMap[Employee$.title](this.title)
                : (_patchMap[Employee$.title] is Patch)
                ? _patchMap[Employee$.title].applyTo(this.title)
                : _patchMap[Employee$.title]
          : this.title,
      department: _patchMap.containsKey(Employee$.department)
          ? (_patchMap[Employee$.department] is Function)
                ? _patchMap[Employee$.department](this.department)
                : (_patchMap[Employee$.department] is Patch)
                ? _patchMap[Employee$.department].applyTo(this.department)
                : _patchMap[Employee$.department]
          : this.department,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Employee &&
        id == other.id &&
        name == other.name &&
        title == other.title &&
        department == other.department;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.name, this.title, this.department);
  }

  @override
  String toString() {
    return 'Employee(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'title: ${title}' +
        ', ' +
        'department: ${department})';
  }

  /// Creates a [Employee] instance from JSON
  factory Employee.fromJson(Map<String, dynamic> json) =>
      _$EmployeeFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$EmployeeToJson(this);
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

extension EmployeePropertyHelpers on Employee {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasTitle => title?.isNotEmpty == true;
  bool get noTitle => title?.isEmpty ?? true;
  String get titleRequired =>
      title ?? (throw StateError('title is required but was null'));
  bool get hasDepartment => department?.isNotEmpty == true;
  bool get noDepartment => department?.isEmpty ?? true;
  String get departmentRequired =>
      department ?? (throw StateError('department is required but was null'));
}

extension EmployeeSerialization on Employee {
  Map<String, dynamic> toJson() => _$EmployeeToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$EmployeeToJson(this);
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

enum Employee$ { id, name, title, department }

class EmployeePatch extends PatchBase<Employee, Employee$> {
  Employee applyTo(Employee entity) {
    return entity.patchWithEmployee(patchInput: this);
  }

  EmployeePatch withId(String? value) {
    patchMap[Employee$.id] = value;
    return this;
  }

  EmployeePatch withName(String? value) {
    patchMap[Employee$.name] = value;
    return this;
  }

  EmployeePatch withTitle(String? value) {
    patchMap[Employee$.title] = value;
    return this;
  }

  EmployeePatch withDepartment(String? value) {
    patchMap[Employee$.department] = value;
    return this;
  }
}

/// Field descriptors for [Employee] query construction
abstract final class EmployeeFields {
  static String _$getid(Employee e) => e.id;
  static const id = Field<Employee, String>('id', _$getid);
  static String _$getname(Employee e) => e.name;
  static const name = Field<Employee, String>('name', _$getname);
  static String? _$gettitle(Employee e) => e.title;
  static const title = Field<Employee, String?>('title', _$gettitle);
  static String? _$getdepartment(Employee e) => e.department;
  static const department = Field<Employee, String?>(
    'department',
    _$getdepartment,
  );
}

extension EmployeeCompareE on Employee {
  Map<String, dynamic> compareToEmployee(Employee other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (title != other.title) {
      diff['title'] = () => other.title;
    }
    if (department != other.department) {
      diff['department'] = () => other.department;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Company {
  final String name;
  final String industry;
  final List<String> locations;
  final List<Employee> employees;

  Company({
    required this.name,
    required this.industry,
    required this.locations,
    required this.employees,
  });

  Company copyWith({
    String? name,
    String? industry,
    List<String>? locations,
    List<Employee>? employees,
  }) {
    return Company(
      name: name ?? this.name,
      industry: industry ?? this.industry,
      locations: locations ?? this.locations,
      employees: employees ?? this.employees,
    );
  }

  Company copyWithCompany({
    String? name,
    String? industry,
    List<String>? locations,
    List<Employee>? employees,
  }) {
    return copyWith(
      name: name,
      industry: industry,
      locations: locations,
      employees: employees,
    );
  }

  Company patchWithCompany({CompanyPatch? patchInput}) {
    final _patcher = patchInput ?? CompanyPatch();
    final _patchMap = _patcher.patchMap;
    return Company(
      name: _patchMap.containsKey(Company$.name)
          ? (_patchMap[Company$.name] is Function)
                ? _patchMap[Company$.name](this.name)
                : (_patchMap[Company$.name] is Patch)
                ? _patchMap[Company$.name].applyTo(this.name)
                : _patchMap[Company$.name]
          : this.name,
      industry: _patchMap.containsKey(Company$.industry)
          ? (_patchMap[Company$.industry] is Function)
                ? _patchMap[Company$.industry](this.industry)
                : (_patchMap[Company$.industry] is Patch)
                ? _patchMap[Company$.industry].applyTo(this.industry)
                : _patchMap[Company$.industry]
          : this.industry,
      locations: _patchMap.containsKey(Company$.locations)
          ? (_patchMap[Company$.locations] is Function)
                ? _patchMap[Company$.locations](this.locations)
                : (_patchMap[Company$.locations] is Patch)
                ? _patchMap[Company$.locations].applyTo(this.locations)
                : _patchMap[Company$.locations]
          : this.locations,
      employees: _patchMap.containsKey(Company$.employees)
          ? (_patchMap[Company$.employees] is Function)
                ? _patchMap[Company$.employees](this.employees)
                : (_patchMap[Company$.employees] is Patch)
                ? _patchMap[Company$.employees].applyTo(this.employees)
                : _patchMap[Company$.employees]
          : this.employees,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Company &&
        name == other.name &&
        industry == other.industry &&
        locations == other.locations &&
        employees == other.employees;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.name,
      this.industry,
      this.locations,
      this.employees,
    );
  }

  @override
  String toString() {
    return 'Company(' +
        'name: ${name}' +
        ', ' +
        'industry: ${industry}' +
        ', ' +
        'locations: ${locations}' +
        ', ' +
        'employees: ${employees})';
  }

  /// Creates a [Company] instance from JSON
  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CompanyToJson(this);
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

extension CompanyPropertyHelpers on Company {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasIndustry => industry.isNotEmpty;
  bool get noIndustry => industry.isEmpty;
  bool get hasLocations => locations.isNotEmpty;
  bool get noLocations => locations.isEmpty;
  bool get hasEmployees => employees.isNotEmpty;
  bool get noEmployees => employees.isEmpty;
}

extension CompanySerialization on Company {
  Map<String, dynamic> toJson() => _$CompanyToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CompanyToJson(this);
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

enum Company$ { name, industry, locations, employees }

class CompanyPatch extends PatchBase<Company, Company$> {
  Company applyTo(Company entity) {
    return entity.patchWithCompany(patchInput: this);
  }

  CompanyPatch withName(String? value) {
    patchMap[Company$.name] = value;
    return this;
  }

  CompanyPatch withIndustry(String? value) {
    patchMap[Company$.industry] = value;
    return this;
  }

  CompanyPatch withLocations(List<String>? value) {
    patchMap[Company$.locations] = value;
    return this;
  }

  CompanyPatch withEmployees(List<Employee>? value) {
    patchMap[Company$.employees] = value;
    return this;
  }

  CompanyPatch updateEmployeesAt(
    int index,
    EmployeePatch Function(EmployeePatch) patch,
  ) {
    patchMap[Company$.employees] = (List<dynamic> list) {
      var updatedList = List<Employee>.from(list);
      if (index >= 0 && index < updatedList.length) {
        updatedList[index] = patch(
          EmployeePatch(),
        ).applyTo(updatedList[index] as Employee);
      }
      return updatedList;
    };
    return this;
  }
}

/// Field descriptors for [Company] query construction
abstract final class CompanyFields {
  static String _$getname(Company e) => e.name;
  static const name = Field<Company, String>('name', _$getname);
  static String _$getindustry(Company e) => e.industry;
  static const industry = Field<Company, String>('industry', _$getindustry);
  static List<String> _$getlocations(Company e) => e.locations;
  static const locations = Field<Company, List<String>>(
    'locations',
    _$getlocations,
  );
  static List<Employee> _$getemployees(Company e) => e.employees;
  static const employees = Field<Company, List<Employee>>(
    'employees',
    _$getemployees,
  );
}

extension CompanyCompareE on Company {
  Map<String, dynamic> compareToCompany(Company other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (industry != other.industry) {
      diff['industry'] = () => other.industry;
    }
    if (locations != other.locations) {
      diff['locations'] = () => other.locations;
    }
    if (employees != other.employees) {
      diff['employees'] = () => other.employees;
    }
    return diff;
  }
}
