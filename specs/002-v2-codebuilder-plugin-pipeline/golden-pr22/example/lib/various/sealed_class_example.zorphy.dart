// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'sealed_class_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

sealed class PaymentMethod {
  String get displayName;
  String get processPayment;

  /// Creates a [PaymentMethod] instance from JSON
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    if (json['__typename'] == "CreditCard") {
      return CreditCard.fromJson(json);
    } else if (json['__typename'] == "PayPal") {
      return PayPal.fromJson(json);
    } else if (json['__typename'] == "BankTransfer") {
      return BankTransfer.fromJson(json);
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
  bool get isBankTransfer => this is BankTransfer;
  BankTransfer? get asBankTransfer =>
      this is BankTransfer ? this as BankTransfer : null;
}

extension PaymentMethodPropertyHelpers on PaymentMethod {
  bool get hasDisplayName => displayName.isNotEmpty;
  bool get noDisplayName => displayName.isEmpty;
  bool get hasProcessPayment => processPayment.isNotEmpty;
  bool get noProcessPayment => processPayment.isEmpty;
}

enum PaymentMethod$ { displayName, processPayment }

/// Field descriptors for [PaymentMethod] query construction
abstract final class PaymentMethodFields {
  static String _$getdisplayName(PaymentMethod e) => e.displayName;
  static const displayName = Field<PaymentMethod, String>(
    'displayName',
    _$getdisplayName,
  );
  static String _$getprocessPayment(PaymentMethod e) => e.processPayment;
  static const processPayment = Field<PaymentMethod, String>(
    'processPayment',
    _$getprocessPayment,
  );
}

extension PaymentMethodCompareE on PaymentMethod {
  Map<String, dynamic> compareToPaymentMethod(PaymentMethod other) {
    final Map<String, dynamic> diff = {};

    if (displayName != other.displayName) {
      diff['displayName'] = () => other.displayName;
    }
    if (processPayment != other.processPayment) {
      diff['processPayment'] = () => other.processPayment;
    }
    return diff;
  }
}

extension PaymentMethodChangeToE on PaymentMethod {
  CreditCard changeToCreditCard({
    required String cardNumber,
    required String expiryDate,
    required String cardHolderName,
    String? displayName,
    String? processPayment,
  }) {
    final _patcher = CreditCardPatch();
    _patcher.withCardNumber(cardNumber);
    _patcher.withExpiryDate(expiryDate);
    _patcher.withCardHolderName(cardHolderName);
    if (displayName != null) {
      _patcher.withDisplayName(displayName);
    }
    if (processPayment != null) {
      _patcher.withProcessPayment(processPayment);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return CreditCard.fromJson(_json);
  }

  PayPal changeToPayPal({
    required String email,
    required String transactionId,
    String? displayName,
    String? processPayment,
  }) {
    final _patcher = PayPalPatch();
    _patcher.withEmail(email);
    _patcher.withTransactionId(transactionId);
    if (displayName != null) {
      _patcher.withDisplayName(displayName);
    }
    if (processPayment != null) {
      _patcher.withProcessPayment(processPayment);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return PayPal.fromJson(_json);
  }

  BankTransfer changeToBankTransfer({
    required String accountNumber,
    required String routingNumber,
    required String bankName,
    String? displayName,
    String? processPayment,
  }) {
    final _patcher = BankTransferPatch();
    _patcher.withAccountNumber(accountNumber);
    _patcher.withRoutingNumber(routingNumber);
    _patcher.withBankName(bankName);
    if (displayName != null) {
      _patcher.withDisplayName(displayName);
    }
    if (processPayment != null) {
      _patcher.withProcessPayment(processPayment);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return BankTransfer.fromJson(_json);
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class CreditCard implements PaymentMethod {
  @override
  final String displayName;
  @override
  final String processPayment;
  final String cardNumber;
  final String expiryDate;
  final String cardHolderName;

  CreditCard({
    required this.displayName,
    required this.processPayment,
    required this.cardNumber,
    required this.expiryDate,
    required this.cardHolderName,
  });

  CreditCard copyWith({
    String? displayName,
    String? processPayment,
    String? cardNumber,
    String? expiryDate,
    String? cardHolderName,
  }) {
    return CreditCard(
      displayName: displayName ?? this.displayName,
      processPayment: processPayment ?? this.processPayment,
      cardNumber: cardNumber ?? this.cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cardHolderName: cardHolderName ?? this.cardHolderName,
    );
  }

  CreditCard copyWithCreditCard({
    String? displayName,
    String? processPayment,
    String? cardNumber,
    String? expiryDate,
    String? cardHolderName,
  }) {
    return copyWith(
      displayName: displayName,
      processPayment: processPayment,
      cardNumber: cardNumber,
      expiryDate: expiryDate,
      cardHolderName: cardHolderName,
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
      processPayment: _patchMap.containsKey(CreditCard$.processPayment)
          ? (_patchMap[CreditCard$.processPayment] is Function)
                ? _patchMap[CreditCard$.processPayment](this.processPayment)
                : (_patchMap[CreditCard$.processPayment] is Patch)
                ? _patchMap[CreditCard$.processPayment].applyTo(
                    this.processPayment,
                  )
                : _patchMap[CreditCard$.processPayment]
          : this.processPayment,
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
      cardHolderName: _patchMap.containsKey(CreditCard$.cardHolderName)
          ? (_patchMap[CreditCard$.cardHolderName] is Function)
                ? _patchMap[CreditCard$.cardHolderName](this.cardHolderName)
                : (_patchMap[CreditCard$.cardHolderName] is Patch)
                ? _patchMap[CreditCard$.cardHolderName].applyTo(
                    this.cardHolderName,
                  )
                : _patchMap[CreditCard$.cardHolderName]
          : this.cardHolderName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditCard &&
        displayName == other.displayName &&
        processPayment == other.processPayment &&
        cardNumber == other.cardNumber &&
        expiryDate == other.expiryDate &&
        cardHolderName == other.cardHolderName;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.displayName,
      this.processPayment,
      this.cardNumber,
      this.expiryDate,
      this.cardHolderName,
    );
  }

  @override
  String toString() {
    return 'CreditCard(' +
        'displayName: ${displayName}' +
        ', ' +
        'processPayment: ${processPayment}' +
        ', ' +
        'cardNumber: ${cardNumber}' +
        ', ' +
        'expiryDate: ${expiryDate}' +
        ', ' +
        'cardHolderName: ${cardHolderName})';
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
  bool get hasProcessPayment => processPayment.isNotEmpty;
  bool get noProcessPayment => processPayment.isEmpty;
  bool get hasCardNumber => cardNumber.isNotEmpty;
  bool get noCardNumber => cardNumber.isEmpty;
  bool get hasExpiryDate => expiryDate.isNotEmpty;
  bool get noExpiryDate => expiryDate.isEmpty;
  bool get hasCardHolderName => cardHolderName.isNotEmpty;
  bool get noCardHolderName => cardHolderName.isEmpty;
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

enum CreditCard$ {
  displayName,
  processPayment,
  cardNumber,
  expiryDate,
  cardHolderName,
}

class CreditCardPatch extends PatchBase<CreditCard, CreditCard$> {
  CreditCard applyTo(CreditCard entity) {
    return entity.patchWithCreditCard(patchInput: this);
  }

  CreditCardPatch withDisplayName(String? value) {
    patchMap[CreditCard$.displayName] = value;
    return this;
  }

  CreditCardPatch withProcessPayment(String? value) {
    patchMap[CreditCard$.processPayment] = value;
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

  CreditCardPatch withCardHolderName(String? value) {
    patchMap[CreditCard$.cardHolderName] = value;
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
  static String _$getprocessPayment(CreditCard e) => e.processPayment;
  static const processPayment = Field<CreditCard, String>(
    'processPayment',
    _$getprocessPayment,
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
  static String _$getcardHolderName(CreditCard e) => e.cardHolderName;
  static const cardHolderName = Field<CreditCard, String>(
    'cardHolderName',
    _$getcardHolderName,
  );
}

extension CreditCardCompareE on CreditCard {
  Map<String, dynamic> compareToCreditCard(CreditCard other) {
    final Map<String, dynamic> diff = {};

    if (displayName != other.displayName) {
      diff['displayName'] = () => other.displayName;
    }
    if (processPayment != other.processPayment) {
      diff['processPayment'] = () => other.processPayment;
    }
    if (cardNumber != other.cardNumber) {
      diff['cardNumber'] = () => other.cardNumber;
    }
    if (expiryDate != other.expiryDate) {
      diff['expiryDate'] = () => other.expiryDate;
    }
    if (cardHolderName != other.cardHolderName) {
      diff['cardHolderName'] = () => other.cardHolderName;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class PayPal implements PaymentMethod {
  @override
  final String displayName;
  @override
  final String processPayment;
  final String email;
  final String transactionId;

  PayPal({
    required this.displayName,
    required this.processPayment,
    required this.email,
    required this.transactionId,
  });

  PayPal copyWith({
    String? displayName,
    String? processPayment,
    String? email,
    String? transactionId,
  }) {
    return PayPal(
      displayName: displayName ?? this.displayName,
      processPayment: processPayment ?? this.processPayment,
      email: email ?? this.email,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  PayPal copyWithPayPal({
    String? displayName,
    String? processPayment,
    String? email,
    String? transactionId,
  }) {
    return copyWith(
      displayName: displayName,
      processPayment: processPayment,
      email: email,
      transactionId: transactionId,
    );
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
      processPayment: _patchMap.containsKey(PayPal$.processPayment)
          ? (_patchMap[PayPal$.processPayment] is Function)
                ? _patchMap[PayPal$.processPayment](this.processPayment)
                : (_patchMap[PayPal$.processPayment] is Patch)
                ? _patchMap[PayPal$.processPayment].applyTo(this.processPayment)
                : _patchMap[PayPal$.processPayment]
          : this.processPayment,
      email: _patchMap.containsKey(PayPal$.email)
          ? (_patchMap[PayPal$.email] is Function)
                ? _patchMap[PayPal$.email](this.email)
                : (_patchMap[PayPal$.email] is Patch)
                ? _patchMap[PayPal$.email].applyTo(this.email)
                : _patchMap[PayPal$.email]
          : this.email,
      transactionId: _patchMap.containsKey(PayPal$.transactionId)
          ? (_patchMap[PayPal$.transactionId] is Function)
                ? _patchMap[PayPal$.transactionId](this.transactionId)
                : (_patchMap[PayPal$.transactionId] is Patch)
                ? _patchMap[PayPal$.transactionId].applyTo(this.transactionId)
                : _patchMap[PayPal$.transactionId]
          : this.transactionId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PayPal &&
        displayName == other.displayName &&
        processPayment == other.processPayment &&
        email == other.email &&
        transactionId == other.transactionId;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.displayName,
      this.processPayment,
      this.email,
      this.transactionId,
    );
  }

  @override
  String toString() {
    return 'PayPal(' +
        'displayName: ${displayName}' +
        ', ' +
        'processPayment: ${processPayment}' +
        ', ' +
        'email: ${email}' +
        ', ' +
        'transactionId: ${transactionId})';
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
  bool get hasProcessPayment => processPayment.isNotEmpty;
  bool get noProcessPayment => processPayment.isEmpty;
  bool get hasEmail => email.isNotEmpty;
  bool get noEmail => email.isEmpty;
  bool get hasTransactionId => transactionId.isNotEmpty;
  bool get noTransactionId => transactionId.isEmpty;
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

enum PayPal$ { displayName, processPayment, email, transactionId }

class PayPalPatch extends PatchBase<PayPal, PayPal$> {
  PayPal applyTo(PayPal entity) {
    return entity.patchWithPayPal(patchInput: this);
  }

  PayPalPatch withDisplayName(String? value) {
    patchMap[PayPal$.displayName] = value;
    return this;
  }

  PayPalPatch withProcessPayment(String? value) {
    patchMap[PayPal$.processPayment] = value;
    return this;
  }

  PayPalPatch withEmail(String? value) {
    patchMap[PayPal$.email] = value;
    return this;
  }

  PayPalPatch withTransactionId(String? value) {
    patchMap[PayPal$.transactionId] = value;
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
  static String _$getprocessPayment(PayPal e) => e.processPayment;
  static const processPayment = Field<PayPal, String>(
    'processPayment',
    _$getprocessPayment,
  );
  static String _$getemail(PayPal e) => e.email;
  static const email = Field<PayPal, String>('email', _$getemail);
  static String _$gettransactionId(PayPal e) => e.transactionId;
  static const transactionId = Field<PayPal, String>(
    'transactionId',
    _$gettransactionId,
  );
}

extension PayPalCompareE on PayPal {
  Map<String, dynamic> compareToPayPal(PayPal other) {
    final Map<String, dynamic> diff = {};

    if (displayName != other.displayName) {
      diff['displayName'] = () => other.displayName;
    }
    if (processPayment != other.processPayment) {
      diff['processPayment'] = () => other.processPayment;
    }
    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    if (transactionId != other.transactionId) {
      diff['transactionId'] = () => other.transactionId;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class BankTransfer implements PaymentMethod {
  @override
  final String displayName;
  @override
  final String processPayment;
  final String accountNumber;
  final String routingNumber;
  final String bankName;

  BankTransfer({
    required this.displayName,
    required this.processPayment,
    required this.accountNumber,
    required this.routingNumber,
    required this.bankName,
  });

  BankTransfer copyWith({
    String? displayName,
    String? processPayment,
    String? accountNumber,
    String? routingNumber,
    String? bankName,
  }) {
    return BankTransfer(
      displayName: displayName ?? this.displayName,
      processPayment: processPayment ?? this.processPayment,
      accountNumber: accountNumber ?? this.accountNumber,
      routingNumber: routingNumber ?? this.routingNumber,
      bankName: bankName ?? this.bankName,
    );
  }

  BankTransfer copyWithBankTransfer({
    String? displayName,
    String? processPayment,
    String? accountNumber,
    String? routingNumber,
    String? bankName,
  }) {
    return copyWith(
      displayName: displayName,
      processPayment: processPayment,
      accountNumber: accountNumber,
      routingNumber: routingNumber,
      bankName: bankName,
    );
  }

  BankTransfer patchWithBankTransfer({BankTransferPatch? patchInput}) {
    final _patcher = patchInput ?? BankTransferPatch();
    final _patchMap = _patcher.patchMap;
    return BankTransfer(
      displayName: _patchMap.containsKey(BankTransfer$.displayName)
          ? (_patchMap[BankTransfer$.displayName] is Function)
                ? _patchMap[BankTransfer$.displayName](this.displayName)
                : (_patchMap[BankTransfer$.displayName] is Patch)
                ? _patchMap[BankTransfer$.displayName].applyTo(this.displayName)
                : _patchMap[BankTransfer$.displayName]
          : this.displayName,
      processPayment: _patchMap.containsKey(BankTransfer$.processPayment)
          ? (_patchMap[BankTransfer$.processPayment] is Function)
                ? _patchMap[BankTransfer$.processPayment](this.processPayment)
                : (_patchMap[BankTransfer$.processPayment] is Patch)
                ? _patchMap[BankTransfer$.processPayment].applyTo(
                    this.processPayment,
                  )
                : _patchMap[BankTransfer$.processPayment]
          : this.processPayment,
      accountNumber: _patchMap.containsKey(BankTransfer$.accountNumber)
          ? (_patchMap[BankTransfer$.accountNumber] is Function)
                ? _patchMap[BankTransfer$.accountNumber](this.accountNumber)
                : (_patchMap[BankTransfer$.accountNumber] is Patch)
                ? _patchMap[BankTransfer$.accountNumber].applyTo(
                    this.accountNumber,
                  )
                : _patchMap[BankTransfer$.accountNumber]
          : this.accountNumber,
      routingNumber: _patchMap.containsKey(BankTransfer$.routingNumber)
          ? (_patchMap[BankTransfer$.routingNumber] is Function)
                ? _patchMap[BankTransfer$.routingNumber](this.routingNumber)
                : (_patchMap[BankTransfer$.routingNumber] is Patch)
                ? _patchMap[BankTransfer$.routingNumber].applyTo(
                    this.routingNumber,
                  )
                : _patchMap[BankTransfer$.routingNumber]
          : this.routingNumber,
      bankName: _patchMap.containsKey(BankTransfer$.bankName)
          ? (_patchMap[BankTransfer$.bankName] is Function)
                ? _patchMap[BankTransfer$.bankName](this.bankName)
                : (_patchMap[BankTransfer$.bankName] is Patch)
                ? _patchMap[BankTransfer$.bankName].applyTo(this.bankName)
                : _patchMap[BankTransfer$.bankName]
          : this.bankName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BankTransfer &&
        displayName == other.displayName &&
        processPayment == other.processPayment &&
        accountNumber == other.accountNumber &&
        routingNumber == other.routingNumber &&
        bankName == other.bankName;
  }

  @override
  int get hashCode {
    return Object.hash(
      this.displayName,
      this.processPayment,
      this.accountNumber,
      this.routingNumber,
      this.bankName,
    );
  }

  @override
  String toString() {
    return 'BankTransfer(' +
        'displayName: ${displayName}' +
        ', ' +
        'processPayment: ${processPayment}' +
        ', ' +
        'accountNumber: ${accountNumber}' +
        ', ' +
        'routingNumber: ${routingNumber}' +
        ', ' +
        'bankName: ${bankName})';
  }

  /// Creates a [BankTransfer] instance from JSON
  factory BankTransfer.fromJson(Map<String, dynamic> json) =>
      _$BankTransferFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BankTransferToJson(this);
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
    final json = _$BankTransferToJson(this);
    json['__typename'] = 'BankTransfer';
    return json;
  }
}

extension BankTransferPropertyHelpers on BankTransfer {
  bool get hasDisplayName => displayName.isNotEmpty;
  bool get noDisplayName => displayName.isEmpty;
  bool get hasProcessPayment => processPayment.isNotEmpty;
  bool get noProcessPayment => processPayment.isEmpty;
  bool get hasAccountNumber => accountNumber.isNotEmpty;
  bool get noAccountNumber => accountNumber.isEmpty;
  bool get hasRoutingNumber => routingNumber.isNotEmpty;
  bool get noRoutingNumber => routingNumber.isEmpty;
  bool get hasBankName => bankName.isNotEmpty;
  bool get noBankName => bankName.isEmpty;
}

extension BankTransferSerialization on BankTransfer {
  Map<String, dynamic> toJson() => _$BankTransferToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$BankTransferToJson(this);
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

enum BankTransfer$ {
  displayName,
  processPayment,
  accountNumber,
  routingNumber,
  bankName,
}

class BankTransferPatch extends PatchBase<BankTransfer, BankTransfer$> {
  BankTransfer applyTo(BankTransfer entity) {
    return entity.patchWithBankTransfer(patchInput: this);
  }

  BankTransferPatch withDisplayName(String? value) {
    patchMap[BankTransfer$.displayName] = value;
    return this;
  }

  BankTransferPatch withProcessPayment(String? value) {
    patchMap[BankTransfer$.processPayment] = value;
    return this;
  }

  BankTransferPatch withAccountNumber(String? value) {
    patchMap[BankTransfer$.accountNumber] = value;
    return this;
  }

  BankTransferPatch withRoutingNumber(String? value) {
    patchMap[BankTransfer$.routingNumber] = value;
    return this;
  }

  BankTransferPatch withBankName(String? value) {
    patchMap[BankTransfer$.bankName] = value;
    return this;
  }
}

/// Field descriptors for [BankTransfer] query construction
abstract final class BankTransferFields {
  static String _$getdisplayName(BankTransfer e) => e.displayName;
  static const displayName = Field<BankTransfer, String>(
    'displayName',
    _$getdisplayName,
  );
  static String _$getprocessPayment(BankTransfer e) => e.processPayment;
  static const processPayment = Field<BankTransfer, String>(
    'processPayment',
    _$getprocessPayment,
  );
  static String _$getaccountNumber(BankTransfer e) => e.accountNumber;
  static const accountNumber = Field<BankTransfer, String>(
    'accountNumber',
    _$getaccountNumber,
  );
  static String _$getroutingNumber(BankTransfer e) => e.routingNumber;
  static const routingNumber = Field<BankTransfer, String>(
    'routingNumber',
    _$getroutingNumber,
  );
  static String _$getbankName(BankTransfer e) => e.bankName;
  static const bankName = Field<BankTransfer, String>(
    'bankName',
    _$getbankName,
  );
}

extension BankTransferCompareE on BankTransfer {
  Map<String, dynamic> compareToBankTransfer(BankTransfer other) {
    final Map<String, dynamic> diff = {};

    if (displayName != other.displayName) {
      diff['displayName'] = () => other.displayName;
    }
    if (processPayment != other.processPayment) {
      diff['processPayment'] = () => other.processPayment;
    }
    if (accountNumber != other.accountNumber) {
      diff['accountNumber'] = () => other.accountNumber;
    }
    if (routingNumber != other.routingNumber) {
      diff['routingNumber'] = () => other.routingNumber;
    }
    if (bankName != other.bankName) {
      diff['bankName'] = () => other.bankName;
    }
    return diff;
  }
}
