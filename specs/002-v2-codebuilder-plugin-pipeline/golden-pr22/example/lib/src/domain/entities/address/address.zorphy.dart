// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'address.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Address {
  final String street;
  final String city;

  Address({required this.street, required this.city});

  Address copyWith({String? street, String? city}) {
    return Address(street: street ?? this.street, city: city ?? this.city);
  }

  Address copyWithAddress({String? street, String? city}) {
    return copyWith(street: street, city: city);
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
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address && street == other.street && city == other.city;
  }

  @override
  int get hashCode {
    return Object.hash(this.street, this.city);
  }

  @override
  String toString() {
    return 'Address(' + 'street: ${street}' + ', ' + 'city: ${city})';
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

enum Address$ { street, city }

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
}

/// Field descriptors for [Address] query construction
abstract final class AddressFields {
  static String _$getstreet(Address e) => e.street;
  static const street = Field<Address, String>('street', _$getstreet);
  static String _$getcity(Address e) => e.city;
  static const city = Field<Address, String>('city', _$getcity);
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
    return diff;
  }
}
