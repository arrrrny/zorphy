// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'cross_file_customer_profile.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class CustomerProfile extends $CustomerProfile {
  @override
  final int? yearOfBirth;
  @override
  final String? occupation;
  @override
  final String? operatingSystem;

  CustomerProfile({
    this.yearOfBirth,
    this.occupation,
    this.operatingSystem,
  });

  CustomerProfile copyWith({
    int? yearOfBirth,
    String? occupation,
    String? operatingSystem,
  }) {
    return CustomerProfile(
      yearOfBirth: yearOfBirth ?? this.yearOfBirth,
      occupation: occupation ?? this.occupation,
      operatingSystem: operatingSystem ?? this.operatingSystem,
    );
  }

  CustomerProfile copyWithCustomerProfile({
    int? yearOfBirth,
    String? occupation,
    String? operatingSystem,
  }) {
    return copyWith(
      yearOfBirth: yearOfBirth,
      occupation: occupation,
      operatingSystem: operatingSystem,
    );
  }

  CustomerProfile patchWithCustomerProfile({
    CustomerProfilePatch? patchInput,
  }) {
    final _patcher = patchInput ?? CustomerProfilePatch();
    final _patchMap = _patcher.toPatch();
    return CustomerProfile(
        yearOfBirth: _patchMap.containsKey(CustomerProfile$.yearOfBirth)
            ? (_patchMap[CustomerProfile$.yearOfBirth] is Function)
                ? _patchMap[CustomerProfile$.yearOfBirth](this.yearOfBirth)
                : _patchMap[CustomerProfile$.yearOfBirth]
            : this.yearOfBirth,
        occupation: _patchMap.containsKey(CustomerProfile$.occupation)
            ? (_patchMap[CustomerProfile$.occupation] is Function)
                ? _patchMap[CustomerProfile$.occupation](this.occupation)
                : _patchMap[CustomerProfile$.occupation]
            : this.occupation,
        operatingSystem: _patchMap.containsKey(CustomerProfile$.operatingSystem)
            ? (_patchMap[CustomerProfile$.operatingSystem] is Function)
                ? _patchMap[CustomerProfile$.operatingSystem](
                    this.operatingSystem)
                : _patchMap[CustomerProfile$.operatingSystem]
            : this.operatingSystem);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerProfile &&
        yearOfBirth == other.yearOfBirth &&
        occupation == other.occupation &&
        operatingSystem == other.operatingSystem;
  }

  @override
  int get hashCode {
    return Object.hash(this.yearOfBirth, this.occupation, this.operatingSystem);
  }

  @override
  String toString() {
    return 'CustomerProfile(' +
        'yearOfBirth: ${yearOfBirth}' +
        ', ' +
        'occupation: ${occupation}' +
        ', ' +
        'operatingSystem: ${operatingSystem})';
  }

  /// Creates a [CustomerProfile] instance from JSON
  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      _$CustomerProfileFromJson(json);
}

enum CustomerProfile$ { yearOfBirth, occupation, operatingSystem }

class CustomerProfilePatch implements Patch<CustomerProfile> {
  final Map<CustomerProfile$, dynamic> _patch = {};

  static CustomerProfilePatch create([Map<String, dynamic>? diff]) {
    final patch = CustomerProfilePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue =
              CustomerProfile$.values.firstWhere((e) => e.name == key);
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static CustomerProfilePatch fromPatch(Map<CustomerProfile$, dynamic> patch) {
    final _patch = CustomerProfilePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<CustomerProfile$, dynamic> toPatch() => Map.from(_patch);

  CustomerProfile applyTo(CustomerProfile entity) {
    return entity.patchWithCustomerProfile(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if (value?.toJsonLean != null) return value.toJsonLean();
    } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static CustomerProfilePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  CustomerProfilePatch withYearOfBirth(int? value) {
    _patch[CustomerProfile$.yearOfBirth] = value;
    return this;
  }

  CustomerProfilePatch withOccupation(String? value) {
    _patch[CustomerProfile$.occupation] = value;
    return this;
  }

  CustomerProfilePatch withOperatingSystem(String? value) {
    _patch[CustomerProfile$.operatingSystem] = value;
    return this;
  }
}

extension CustomerProfileSerialization on CustomerProfile {
  Map<String, dynamic> toJson() => _$CustomerProfileToJson(this);
}

extension CustomerProfileCompareE on CustomerProfile {
  Map<String, dynamic> compareToCustomerProfile(CustomerProfile other) {
    final Map<String, dynamic> diff = {};

    if (yearOfBirth != other.yearOfBirth) {
      diff['yearOfBirth'] = () => other.yearOfBirth;
    }
    if (occupation != other.occupation) {
      diff['occupation'] = () => other.occupation;
    }
    if (operatingSystem != other.operatingSystem) {
      diff['operatingSystem'] = () => other.operatingSystem;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Customer extends $Customer implements $User {
  @override
  final String name;
  @override
  final String email;
  @override
  final CustomerProfile? profile;
  @override
  final List<CustomerProfile> profiles;
  @override
  final Map<String, CustomerProfile> profileHistory;

  Customer({
    required this.name,
    required this.email,
    this.profile,
    required this.profiles,
    required this.profileHistory,
  });

  Customer copyWith({
    String? name,
    String? email,
    CustomerProfile? profile,
    List<CustomerProfile>? profiles,
    Map<String, CustomerProfile>? profileHistory,
  }) {
    return Customer(
      name: name ?? this.name,
      email: email ?? this.email,
      profile: profile ?? this.profile,
      profiles: profiles ?? this.profiles,
      profileHistory: profileHistory ?? this.profileHistory,
    );
  }

  Customer copyWithCustomer({
    String? name,
    String? email,
    CustomerProfile? profile,
    List<CustomerProfile>? profiles,
    Map<String, CustomerProfile>? profileHistory,
  }) {
    return copyWith(
      name: name,
      email: email,
      profile: profile,
      profiles: profiles,
      profileHistory: profileHistory,
    );
  }

  Customer patchWithCustomer({
    CustomerPatch? patchInput,
  }) {
    final _patcher = patchInput ?? CustomerPatch();
    final _patchMap = _patcher.toPatch();
    return Customer(
        name: _patchMap.containsKey(Customer$.name)
            ? (_patchMap[Customer$.name] is Function)
                ? _patchMap[Customer$.name](this.name)
                : _patchMap[Customer$.name]
            : this.name,
        email: _patchMap.containsKey(Customer$.email)
            ? (_patchMap[Customer$.email] is Function)
                ? _patchMap[Customer$.email](this.email)
                : _patchMap[Customer$.email]
            : this.email,
        profile: _patchMap.containsKey(Customer$.profile)
            ? (_patchMap[Customer$.profile] is Function)
                ? _patchMap[Customer$.profile](this.profile)
                : _patchMap[Customer$.profile]
            : this.profile,
        profiles: _patchMap.containsKey(Customer$.profiles)
            ? (_patchMap[Customer$.profiles] is Function)
                ? _patchMap[Customer$.profiles](this.profiles)
                : _patchMap[Customer$.profiles]
            : this.profiles,
        profileHistory: _patchMap.containsKey(Customer$.profileHistory)
            ? (_patchMap[Customer$.profileHistory] is Function)
                ? _patchMap[Customer$.profileHistory](this.profileHistory)
                : _patchMap[Customer$.profileHistory]
            : this.profileHistory);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Customer &&
        name == other.name &&
        email == other.email &&
        profile == other.profile &&
        profiles == other.profiles &&
        profileHistory == other.profileHistory;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.email, this.profile, this.profiles,
        this.profileHistory);
  }

  @override
  String toString() {
    return 'Customer(' +
        'name: ${name}' +
        ', ' +
        'email: ${email}' +
        ', ' +
        'profile: ${profile}' +
        ', ' +
        'profiles: ${profiles}' +
        ', ' +
        'profileHistory: ${profileHistory})';
  }

  /// Creates a [Customer] instance from JSON
  factory Customer.fromJson(Map<String, dynamic> json) =>
      _$CustomerFromJson(json);
}

enum Customer$ { name, email, profile, profiles, profileHistory }

class CustomerPatch implements Patch<Customer> {
  final Map<Customer$, dynamic> _patch = {};

  static CustomerPatch create([Map<String, dynamic>? diff]) {
    final patch = CustomerPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Customer$.values.firstWhere((e) => e.name == key);
          if (value is Function) {
            patch._patch[enumValue] = value();
          } else {
            patch._patch[enumValue] = value;
          }
        } catch (_) {}
      });
    }
    return patch;
  }

  static CustomerPatch fromPatch(Map<Customer$, dynamic> patch) {
    final _patch = CustomerPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Customer$, dynamic> toPatch() => Map.from(_patch);

  Customer applyTo(Customer entity) {
    return entity.patchWithCustomer(patchInput: this);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    _patch.forEach((key, value) {
      if (value != null) {
        if (value is Function) {
          final result = value();
          json[key.name] = _convertToJson(result);
        } else {
          json[key.name] = _convertToJson(value);
        }
      }
    });
    return json;
  }

  dynamic _convertToJson(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toIso8601String();
    if (value is Enum) return value.toString().split('.').last;
    if (value is List) return value.map((e) => _convertToJson(e)).toList();
    if (value is Map)
      return value.map((k, v) => MapEntry(k.toString(), _convertToJson(v)));
    if (value is num || value is bool || value is String) return value;
    try {
      if (value?.toJsonLean != null) return value.toJsonLean();
    } catch (_) {}
    if (value?.toJson != null) return value.toJson();
    return value.toString();
  }

  static CustomerPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  CustomerPatch withName(String? value) {
    _patch[Customer$.name] = value;
    return this;
  }

  CustomerPatch withEmail(String? value) {
    _patch[Customer$.email] = value;
    return this;
  }

  CustomerPatch withProfile(CustomerProfile? value) {
    _patch[Customer$.profile] = value;
    return this;
  }

  CustomerPatch withProfiles(List<CustomerProfile>? value) {
    _patch[Customer$.profiles] = value;
    return this;
  }

  CustomerPatch withProfileHistory(Map<String, CustomerProfile>? value) {
    _patch[Customer$.profileHistory] = value;
    return this;
  }
}

extension CustomerSerialization on Customer {
  Map<String, dynamic> toJson() => _$CustomerToJson(this);
}

extension CustomerCompareE on Customer {
  Map<String, dynamic> compareToCustomer(Customer other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    if (profile != other.profile) {
      diff['profile'] = () => other.profile;
    }
    if (profiles != other.profiles) {
      diff['profiles'] = () => other.profiles;
    }
    if (profileHistory != other.profileHistory) {
      diff['profileHistory'] = () => other.profileHistory;
    }
    return diff;
  }
}
