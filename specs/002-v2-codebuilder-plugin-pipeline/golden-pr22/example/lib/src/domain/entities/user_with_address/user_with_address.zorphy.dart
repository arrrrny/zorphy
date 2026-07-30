// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'user_with_address.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class UserWithAddress {
  final String name;
  final Address address;
  final String? phone;

  UserWithAddress({required this.name, required this.address, this.phone});

  UserWithAddress copyWith({String? name, Address? address, String? phone}) {
    return UserWithAddress(
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
    );
  }

  UserWithAddress copyWithUserWithAddress({
    String? name,
    Address? address,
    String? phone,
  }) {
    return copyWith(name: name, address: address, phone: phone);
  }

  UserWithAddress patchWithUserWithAddress({UserWithAddressPatch? patchInput}) {
    final _patcher = patchInput ?? UserWithAddressPatch();
    final _patchMap = _patcher.patchMap;
    return UserWithAddress(
      name: _patchMap.containsKey(UserWithAddress$.name)
          ? (_patchMap[UserWithAddress$.name] is Function)
                ? _patchMap[UserWithAddress$.name](this.name)
                : (_patchMap[UserWithAddress$.name] is Patch)
                ? _patchMap[UserWithAddress$.name].applyTo(this.name)
                : _patchMap[UserWithAddress$.name]
          : this.name,
      address: _patchMap.containsKey(UserWithAddress$.address)
          ? (_patchMap[UserWithAddress$.address] is Function)
                ? _patchMap[UserWithAddress$.address](this.address)
                : (_patchMap[UserWithAddress$.address] is Patch)
                ? _patchMap[UserWithAddress$.address].applyTo(this.address)
                : _patchMap[UserWithAddress$.address]
          : this.address,
      phone: _patchMap.containsKey(UserWithAddress$.phone)
          ? (_patchMap[UserWithAddress$.phone] is Function)
                ? _patchMap[UserWithAddress$.phone](this.phone)
                : (_patchMap[UserWithAddress$.phone] is Patch)
                ? _patchMap[UserWithAddress$.phone].applyTo(this.phone)
                : _patchMap[UserWithAddress$.phone]
          : this.phone,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserWithAddress &&
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
    return 'UserWithAddress(' +
        'name: ${name}' +
        ', ' +
        'address: ${address}' +
        ', ' +
        'phone: ${phone})';
  }

  /// Creates a [UserWithAddress] instance from JSON
  factory UserWithAddress.fromJson(Map<String, dynamic> json) =>
      _$UserWithAddressFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserWithAddressToJson(this);
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

extension UserWithAddressPropertyHelpers on UserWithAddress {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasPhone => phone?.isNotEmpty == true;
  bool get noPhone => phone?.isEmpty ?? true;
  String get phoneRequired =>
      phone ?? (throw StateError('phone is required but was null'));
}

extension UserWithAddressSerialization on UserWithAddress {
  Map<String, dynamic> toJson() => _$UserWithAddressToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserWithAddressToJson(this);
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

enum UserWithAddress$ { name, address, phone }

class UserWithAddressPatch
    extends PatchBase<UserWithAddress, UserWithAddress$> {
  UserWithAddress applyTo(UserWithAddress entity) {
    return entity.patchWithUserWithAddress(patchInput: this);
  }

  UserWithAddressPatch withName(String? value) {
    patchMap[UserWithAddress$.name] = value;
    return this;
  }

  UserWithAddressPatch withAddress(Address? value) {
    patchMap[UserWithAddress$.address] = value;
    return this;
  }

  UserWithAddressPatch withAddressPatch(AddressPatch patch) {
    patchMap[UserWithAddress$.address] = patch;
    return this;
  }

  UserWithAddressPatch withAddressPatchFunc(
    AddressPatch Function(AddressPatch) patch,
  ) {
    patchMap[UserWithAddress$.address] = (dynamic current) {
      var currentPatch = AddressPatch();
      return patch(currentPatch).applyTo(current as Address);
    };
    return this;
  }

  UserWithAddressPatch withPhone(String? value) {
    patchMap[UserWithAddress$.phone] = value;
    return this;
  }
}

/// Field descriptors for [UserWithAddress] query construction
abstract final class UserWithAddressFields {
  static String _$getname(UserWithAddress e) => e.name;
  static const name = Field<UserWithAddress, String>('name', _$getname);
  static Address _$getaddress(UserWithAddress e) => e.address;
  static const address = Field<UserWithAddress, Address>(
    'address',
    _$getaddress,
  );
  static String? _$getphone(UserWithAddress e) => e.phone;
  static const phone = Field<UserWithAddress, String?>('phone', _$getphone);
}

extension UserWithAddressCompareE on UserWithAddress {
  Map<String, dynamic> compareToUserWithAddress(UserWithAddress other) {
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
