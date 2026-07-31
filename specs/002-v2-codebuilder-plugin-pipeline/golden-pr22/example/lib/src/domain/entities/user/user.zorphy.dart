// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'user.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class User {
  final String id;
  final String name;
  final Address address;

  User({required this.id, required this.name, required this.address});

  User copyWith({String? id, String? name, Address? address}) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
    );
  }

  User copyWithUser({String? id, String? name, Address? address}) {
    return copyWith(id: id, name: name, address: address);
  }

  User patchWithUser({UserPatch? patchInput}) {
    final _patcher = patchInput ?? UserPatch();
    final _patchMap = _patcher.patchMap;
    return User(
      id: _patchMap.containsKey(User$.id)
          ? (_patchMap[User$.id] is Function)
                ? _patchMap[User$.id](this.id)
                : (_patchMap[User$.id] is Patch)
                ? _patchMap[User$.id].applyTo(this.id)
                : _patchMap[User$.id]
          : this.id,
      name: _patchMap.containsKey(User$.name)
          ? (_patchMap[User$.name] is Function)
                ? _patchMap[User$.name](this.name)
                : (_patchMap[User$.name] is Patch)
                ? _patchMap[User$.name].applyTo(this.name)
                : _patchMap[User$.name]
          : this.name,
      address: _patchMap.containsKey(User$.address)
          ? (_patchMap[User$.address] is Function)
                ? _patchMap[User$.address](this.address)
                : (_patchMap[User$.address] is Patch)
                ? _patchMap[User$.address].applyTo(this.address)
                : _patchMap[User$.address]
          : this.address,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        id == other.id &&
        name == other.name &&
        address == other.address;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.name, this.address);
  }

  @override
  String toString() {
    return 'User(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'address: ${address})';
  }

  /// Creates a [User] instance from JSON
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserToJson(this);
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

extension UserPropertyHelpers on User {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

extension UserSerialization on User {
  Map<String, dynamic> toJson() => _$UserToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$UserToJson(this);
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

enum User$ { id, name, address }

class UserPatch extends PatchBase<User, User$> {
  User applyTo(User entity) {
    return entity.patchWithUser(patchInput: this);
  }

  UserPatch withId(String? value) {
    patchMap[User$.id] = value;
    return this;
  }

  UserPatch withName(String? value) {
    patchMap[User$.name] = value;
    return this;
  }

  UserPatch withAddress(Address? value) {
    patchMap[User$.address] = value;
    return this;
  }

  UserPatch withAddressPatch(AddressPatch patch) {
    patchMap[User$.address] = patch;
    return this;
  }

  UserPatch withAddressPatchFunc(AddressPatch Function(AddressPatch) patch) {
    patchMap[User$.address] = (dynamic current) {
      var currentPatch = AddressPatch();
      return patch(currentPatch).applyTo(current as Address);
    };
    return this;
  }
}

/// Field descriptors for [User] query construction
abstract final class UserFields {
  static String _$getid(User e) => e.id;
  static const id = Field<User, String>('id', _$getid);
  static String _$getname(User e) => e.name;
  static const name = Field<User, String>('name', _$getname);
  static Address _$getaddress(User e) => e.address;
  static const address = Field<User, Address>('address', _$getaddress);
}

extension UserCompareE on User {
  Map<String, dynamic> compareToUser(User other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (address != other.address) {
      diff['address'] = () => other.address;
    }
    return diff;
  }
}
