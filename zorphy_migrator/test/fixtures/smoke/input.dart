import 'package:freezed_annotation/freezed_annotation.dart';

part 'input.freezed.dart';

@freezed
class Product with _$Product {
  const factory Product({
    required String id,
    required String title,
    String? description,
    @Default(0.0) double price,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}

@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    int? sortOrder,
  }) = _Category;
}

@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required String productId,
    @Default(1) int quantity,
  }) = _CartItem;
}

@freezed
class Cart with _$Cart {
  const factory Cart({
    required String id,
    required List<CartItem> items,
    @Default(false) bool checkedOut,
  }) = _Cart;
}

@freezed
class Address with _$Address {
  const factory Address({
    required String street,
    required String city,
    String? state,
    @JsonKey(name: 'zip') String? zipCode,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}

@freezed
class Customer with _$Customer {
  const factory Customer({
    required String id,
    required String name,
    Address? shippingAddress,
  }) = _Customer;

  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required String customerId,
    @Default([]) List<String> itemIds,
  }) = _Order;
}

@freezed
class PaymentMethod with _$PaymentMethod {
  const factory PaymentMethod.card({
    required String last4,
    required String brand,
  }) = CardPayment;

  const factory PaymentMethod.cash() = CashPayment;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);
}

@freezed
class Shipment with _$Shipment {
  const factory Shipment({
    required String id,
    String? trackingNumber,
    @Default('pending') String status,
  }) = _Shipment;
}

@freezed
class Review with _$Review {
  const factory Review({
    required String productId,
    required int rating,
    String? comment,
  }) = _Review;
}

@freezed
class Coupon with _$Coupon {
  const factory Coupon({
    required String code,
    @Default(0) int percentOff,
  }) = _Coupon;
}
