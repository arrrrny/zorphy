// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'enum_nested_patch_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class OperatingSystem extends $OperatingSystem {
  @override
  final String name;
  @override
  final String version;
  @override
  final bool isActive;

  OperatingSystem({
    required this.name,
    required this.version,
    required this.isActive,
  });

  OperatingSystem copyWith({
    String? name,
    String? version,
    bool? isActive,
  }) {
    return OperatingSystem(
      name: name ?? this.name,
      version: version ?? this.version,
      isActive: isActive ?? this.isActive,
    );
  }

  OperatingSystem copyWithOperatingSystem({
    String? name,
    String? version,
    bool? isActive,
  }) {
    return copyWith(
      name: name,
      version: version,
      isActive: isActive,
    );
  }

  OperatingSystem patchWithOperatingSystem({
    OperatingSystemPatch? patchInput,
  }) {
    final _patcher = patchInput ?? OperatingSystemPatch();
    final _patchMap = _patcher.toPatch();
    return OperatingSystem(
        name: _patchMap.containsKey(OperatingSystem$.name)
            ? (_patchMap[OperatingSystem$.name] is Function)
                ? _patchMap[OperatingSystem$.name](this.name)
                : _patchMap[OperatingSystem$.name]
            : this.name,
        version: _patchMap.containsKey(OperatingSystem$.version)
            ? (_patchMap[OperatingSystem$.version] is Function)
                ? _patchMap[OperatingSystem$.version](this.version)
                : _patchMap[OperatingSystem$.version]
            : this.version,
        isActive: _patchMap.containsKey(OperatingSystem$.isActive)
            ? (_patchMap[OperatingSystem$.isActive] is Function)
                ? _patchMap[OperatingSystem$.isActive](this.isActive)
                : _patchMap[OperatingSystem$.isActive]
            : this.isActive);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OperatingSystem &&
        name == other.name &&
        version == other.version &&
        isActive == other.isActive;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.version, this.isActive);
  }

  @override
  String toString() {
    return 'OperatingSystem(' +
        'name: ${name}' +
        ', ' +
        'version: ${version}' +
        ', ' +
        'isActive: ${isActive})';
  }

  /// Creates a [OperatingSystem] instance from JSON
  factory OperatingSystem.fromJson(Map<String, dynamic> json) =>
      _$OperatingSystemFromJson(json);
}

enum OperatingSystem$ { name, version, isActive }

class OperatingSystemPatch implements Patch<OperatingSystem> {
  final Map<OperatingSystem$, dynamic> _patch = {};

  static OperatingSystemPatch create([Map<String, dynamic>? diff]) {
    final patch = OperatingSystemPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue =
              OperatingSystem$.values.firstWhere((e) => e.name == key);
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

  static OperatingSystemPatch fromPatch(Map<OperatingSystem$, dynamic> patch) {
    final _patch = OperatingSystemPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<OperatingSystem$, dynamic> toPatch() => Map.from(_patch);

  OperatingSystem applyTo(OperatingSystem entity) {
    return entity.patchWithOperatingSystem(patchInput: this);
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

  static OperatingSystemPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  OperatingSystemPatch withName(String? value) {
    _patch[OperatingSystem$.name] = value;
    return this;
  }

  OperatingSystemPatch withVersion(String? value) {
    _patch[OperatingSystem$.version] = value;
    return this;
  }

  OperatingSystemPatch withIsActive(bool? value) {
    _patch[OperatingSystem$.isActive] = value;
    return this;
  }
}

extension OperatingSystemSerialization on OperatingSystem {
  Map<String, dynamic> toJson() => _$OperatingSystemToJson(this);
}

extension OperatingSystemCompareE on OperatingSystem {
  Map<String, dynamic> compareToOperatingSystem(OperatingSystem other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (version != other.version) {
      diff['version'] = () => other.version;
    }
    if (isActive != other.isActive) {
      diff['isActive'] = () => other.isActive;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class DeviceType extends $DeviceType {
  @override
  final String category;
  @override
  final String manufacturer;
  @override
  final double screenSize;

  DeviceType({
    required this.category,
    required this.manufacturer,
    required this.screenSize,
  });

  DeviceType copyWith({
    String? category,
    String? manufacturer,
    double? screenSize,
  }) {
    return DeviceType(
      category: category ?? this.category,
      manufacturer: manufacturer ?? this.manufacturer,
      screenSize: screenSize ?? this.screenSize,
    );
  }

  DeviceType copyWithDeviceType({
    String? category,
    String? manufacturer,
    double? screenSize,
  }) {
    return copyWith(
      category: category,
      manufacturer: manufacturer,
      screenSize: screenSize,
    );
  }

  DeviceType patchWithDeviceType({
    DeviceTypePatch? patchInput,
  }) {
    final _patcher = patchInput ?? DeviceTypePatch();
    final _patchMap = _patcher.toPatch();
    return DeviceType(
        category: _patchMap.containsKey(DeviceType$.category)
            ? (_patchMap[DeviceType$.category] is Function)
                ? _patchMap[DeviceType$.category](this.category)
                : _patchMap[DeviceType$.category]
            : this.category,
        manufacturer: _patchMap.containsKey(DeviceType$.manufacturer)
            ? (_patchMap[DeviceType$.manufacturer] is Function)
                ? _patchMap[DeviceType$.manufacturer](this.manufacturer)
                : _patchMap[DeviceType$.manufacturer]
            : this.manufacturer,
        screenSize: _patchMap.containsKey(DeviceType$.screenSize)
            ? (_patchMap[DeviceType$.screenSize] is Function)
                ? _patchMap[DeviceType$.screenSize](this.screenSize)
                : _patchMap[DeviceType$.screenSize]
            : this.screenSize);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceType &&
        category == other.category &&
        manufacturer == other.manufacturer &&
        screenSize == other.screenSize;
  }

  @override
  int get hashCode {
    return Object.hash(this.category, this.manufacturer, this.screenSize);
  }

  @override
  String toString() {
    return 'DeviceType(' +
        'category: ${category}' +
        ', ' +
        'manufacturer: ${manufacturer}' +
        ', ' +
        'screenSize: ${screenSize})';
  }

  /// Creates a [DeviceType] instance from JSON
  factory DeviceType.fromJson(Map<String, dynamic> json) =>
      _$DeviceTypeFromJson(json);
}

enum DeviceType$ { category, manufacturer, screenSize }

class DeviceTypePatch implements Patch<DeviceType> {
  final Map<DeviceType$, dynamic> _patch = {};

  static DeviceTypePatch create([Map<String, dynamic>? diff]) {
    final patch = DeviceTypePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = DeviceType$.values.firstWhere((e) => e.name == key);
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

  static DeviceTypePatch fromPatch(Map<DeviceType$, dynamic> patch) {
    final _patch = DeviceTypePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<DeviceType$, dynamic> toPatch() => Map.from(_patch);

  DeviceType applyTo(DeviceType entity) {
    return entity.patchWithDeviceType(patchInput: this);
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

  static DeviceTypePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  DeviceTypePatch withCategory(String? value) {
    _patch[DeviceType$.category] = value;
    return this;
  }

  DeviceTypePatch withManufacturer(String? value) {
    _patch[DeviceType$.manufacturer] = value;
    return this;
  }

  DeviceTypePatch withScreenSize(double? value) {
    _patch[DeviceType$.screenSize] = value;
    return this;
  }
}

extension DeviceTypeSerialization on DeviceType {
  Map<String, dynamic> toJson() => _$DeviceTypeToJson(this);
}

extension DeviceTypeCompareE on DeviceType {
  Map<String, dynamic> compareToDeviceType(DeviceType other) {
    final Map<String, dynamic> diff = {};

    if (category != other.category) {
      diff['category'] = () => other.category;
    }
    if (manufacturer != other.manufacturer) {
      diff['manufacturer'] = () => other.manufacturer;
    }
    if (screenSize != other.screenSize) {
      diff['screenSize'] = () => other.screenSize;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Device extends $Device {
  @override
  final String deviceId;
  @override
  final OperatingSystem os;
  @override
  final DeviceType deviceType;
  @override
  final List<OperatingSystem> supportedOS;
  @override
  final Map<String, DeviceType> peripherals;

  Device({
    required this.deviceId,
    required this.os,
    required this.deviceType,
    required this.supportedOS,
    required this.peripherals,
  });

  Device copyWith({
    String? deviceId,
    OperatingSystem? os,
    DeviceType? deviceType,
    List<OperatingSystem>? supportedOS,
    Map<String, DeviceType>? peripherals,
  }) {
    return Device(
      deviceId: deviceId ?? this.deviceId,
      os: os ?? this.os,
      deviceType: deviceType ?? this.deviceType,
      supportedOS: supportedOS ?? this.supportedOS,
      peripherals: peripherals ?? this.peripherals,
    );
  }

  Device copyWithDevice({
    String? deviceId,
    OperatingSystem? os,
    DeviceType? deviceType,
    List<OperatingSystem>? supportedOS,
    Map<String, DeviceType>? peripherals,
  }) {
    return copyWith(
      deviceId: deviceId,
      os: os,
      deviceType: deviceType,
      supportedOS: supportedOS,
      peripherals: peripherals,
    );
  }

  Device patchWithDevice({
    DevicePatch? patchInput,
  }) {
    final _patcher = patchInput ?? DevicePatch();
    final _patchMap = _patcher.toPatch();
    return Device(
        deviceId: _patchMap.containsKey(Device$.deviceId)
            ? (_patchMap[Device$.deviceId] is Function)
                ? _patchMap[Device$.deviceId](this.deviceId)
                : _patchMap[Device$.deviceId]
            : this.deviceId,
        os: _patchMap.containsKey(Device$.os)
            ? (_patchMap[Device$.os] is Function)
                ? _patchMap[Device$.os](this.os)
                : _patchMap[Device$.os]
            : this.os,
        deviceType: _patchMap.containsKey(Device$.deviceType)
            ? (_patchMap[Device$.deviceType] is Function)
                ? _patchMap[Device$.deviceType](this.deviceType)
                : _patchMap[Device$.deviceType]
            : this.deviceType,
        supportedOS: _patchMap.containsKey(Device$.supportedOS)
            ? (_patchMap[Device$.supportedOS] is Function)
                ? _patchMap[Device$.supportedOS](this.supportedOS)
                : _patchMap[Device$.supportedOS]
            : this.supportedOS,
        peripherals: _patchMap.containsKey(Device$.peripherals)
            ? (_patchMap[Device$.peripherals] is Function)
                ? _patchMap[Device$.peripherals](this.peripherals)
                : _patchMap[Device$.peripherals]
            : this.peripherals);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Device &&
        deviceId == other.deviceId &&
        os == other.os &&
        deviceType == other.deviceType &&
        supportedOS == other.supportedOS &&
        peripherals == other.peripherals;
  }

  @override
  int get hashCode {
    return Object.hash(this.deviceId, this.os, this.deviceType,
        this.supportedOS, this.peripherals);
  }

  @override
  String toString() {
    return 'Device(' +
        'deviceId: ${deviceId}' +
        ', ' +
        'os: ${os}' +
        ', ' +
        'deviceType: ${deviceType}' +
        ', ' +
        'supportedOS: ${supportedOS}' +
        ', ' +
        'peripherals: ${peripherals})';
  }

  /// Creates a [Device] instance from JSON
  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);
}

enum Device$ { deviceId, os, deviceType, supportedOS, peripherals }

class DevicePatch implements Patch<Device> {
  final Map<Device$, dynamic> _patch = {};

  static DevicePatch create([Map<String, dynamic>? diff]) {
    final patch = DevicePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Device$.values.firstWhere((e) => e.name == key);
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

  static DevicePatch fromPatch(Map<Device$, dynamic> patch) {
    final _patch = DevicePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Device$, dynamic> toPatch() => Map.from(_patch);

  Device applyTo(Device entity) {
    return entity.patchWithDevice(patchInput: this);
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

  static DevicePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  DevicePatch withDeviceId(String? value) {
    _patch[Device$.deviceId] = value;
    return this;
  }

  DevicePatch withOs(OperatingSystem? value) {
    _patch[Device$.os] = value;
    return this;
  }

  DevicePatch withDeviceType(DeviceType? value) {
    _patch[Device$.deviceType] = value;
    return this;
  }

  DevicePatch withSupportedOS(List<OperatingSystem>? value) {
    _patch[Device$.supportedOS] = value;
    return this;
  }

  DevicePatch withPeripherals(Map<String, DeviceType>? value) {
    _patch[Device$.peripherals] = value;
    return this;
  }
}

extension DeviceSerialization on Device {
  Map<String, dynamic> toJson() => _$DeviceToJson(this);
}

extension DeviceCompareE on Device {
  Map<String, dynamic> compareToDevice(Device other) {
    final Map<String, dynamic> diff = {};

    if (deviceId != other.deviceId) {
      diff['deviceId'] = () => other.deviceId;
    }
    if (os != other.os) {
      diff['os'] = () => other.os;
    }
    if (deviceType != other.deviceType) {
      diff['deviceType'] = () => other.deviceType;
    }
    if (supportedOS != other.supportedOS) {
      diff['supportedOS'] = () => other.supportedOS;
    }
    if (peripherals != other.peripherals) {
      diff['peripherals'] = () => other.peripherals;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class User extends $User {
  @override
  final String name;
  @override
  final String email;
  @override
  final Device primaryDevice;
  @override
  final List<Device> devices;
  @override
  final Map<String, OperatingSystem> preferences;

  User({
    required this.name,
    required this.email,
    required this.primaryDevice,
    required this.devices,
    required this.preferences,
  });

  User copyWith({
    String? name,
    String? email,
    Device? primaryDevice,
    List<Device>? devices,
    Map<String, OperatingSystem>? preferences,
  }) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      primaryDevice: primaryDevice ?? this.primaryDevice,
      devices: devices ?? this.devices,
      preferences: preferences ?? this.preferences,
    );
  }

  User copyWithUser({
    String? name,
    String? email,
    Device? primaryDevice,
    List<Device>? devices,
    Map<String, OperatingSystem>? preferences,
  }) {
    return copyWith(
      name: name,
      email: email,
      primaryDevice: primaryDevice,
      devices: devices,
      preferences: preferences,
    );
  }

  User patchWithUser({
    UserPatch? patchInput,
  }) {
    final _patcher = patchInput ?? UserPatch();
    final _patchMap = _patcher.toPatch();
    return User(
        name: _patchMap.containsKey(User$.name)
            ? (_patchMap[User$.name] is Function)
                ? _patchMap[User$.name](this.name)
                : _patchMap[User$.name]
            : this.name,
        email: _patchMap.containsKey(User$.email)
            ? (_patchMap[User$.email] is Function)
                ? _patchMap[User$.email](this.email)
                : _patchMap[User$.email]
            : this.email,
        primaryDevice: _patchMap.containsKey(User$.primaryDevice)
            ? (_patchMap[User$.primaryDevice] is Function)
                ? _patchMap[User$.primaryDevice](this.primaryDevice)
                : _patchMap[User$.primaryDevice]
            : this.primaryDevice,
        devices: _patchMap.containsKey(User$.devices)
            ? (_patchMap[User$.devices] is Function)
                ? _patchMap[User$.devices](this.devices)
                : _patchMap[User$.devices]
            : this.devices,
        preferences: _patchMap.containsKey(User$.preferences)
            ? (_patchMap[User$.preferences] is Function)
                ? _patchMap[User$.preferences](this.preferences)
                : _patchMap[User$.preferences]
            : this.preferences);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        name == other.name &&
        email == other.email &&
        primaryDevice == other.primaryDevice &&
        devices == other.devices &&
        preferences == other.preferences;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.email, this.primaryDevice, this.devices,
        this.preferences);
  }

  @override
  String toString() {
    return 'User(' +
        'name: ${name}' +
        ', ' +
        'email: ${email}' +
        ', ' +
        'primaryDevice: ${primaryDevice}' +
        ', ' +
        'devices: ${devices}' +
        ', ' +
        'preferences: ${preferences})';
  }

  /// Creates a [User] instance from JSON
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

enum User$ { name, email, primaryDevice, devices, preferences }

class UserPatch implements Patch<User> {
  final Map<User$, dynamic> _patch = {};

  static UserPatch create([Map<String, dynamic>? diff]) {
    final patch = UserPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = User$.values.firstWhere((e) => e.name == key);
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

  static UserPatch fromPatch(Map<User$, dynamic> patch) {
    final _patch = UserPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<User$, dynamic> toPatch() => Map.from(_patch);

  User applyTo(User entity) {
    return entity.patchWithUser(patchInput: this);
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

  static UserPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  UserPatch withName(String? value) {
    _patch[User$.name] = value;
    return this;
  }

  UserPatch withEmail(String? value) {
    _patch[User$.email] = value;
    return this;
  }

  UserPatch withPrimaryDevice(Device? value) {
    _patch[User$.primaryDevice] = value;
    return this;
  }

  UserPatch withDevices(List<Device>? value) {
    _patch[User$.devices] = value;
    return this;
  }

  UserPatch withPreferences(Map<String, OperatingSystem>? value) {
    _patch[User$.preferences] = value;
    return this;
  }
}

extension UserSerialization on User {
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

extension UserCompareE on User {
  Map<String, dynamic> compareToUser(User other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    if (primaryDevice != other.primaryDevice) {
      diff['primaryDevice'] = () => other.primaryDevice;
    }
    if (devices != other.devices) {
      diff['devices'] = () => other.devices;
    }
    if (preferences != other.preferences) {
      diff['preferences'] = () => other.preferences;
    }
    return diff;
  }
}
