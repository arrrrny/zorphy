// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'withPatch_morphy_types_advanced.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true)
class CustomerProfile extends $CustomerProfile {
  @override
  final String name;
  @override
  final int age;

  CustomerProfile({required this.name, required this.age});

  CustomerProfile copyWith({String? name, int? age}) {
    return CustomerProfile(name: name ?? this.name, age: age ?? this.age);
  }

  CustomerProfile copyWithCustomerProfile({String? name, int? age}) {
    return copyWith(name: name, age: age);
  }

  CustomerProfile patchWithCustomerProfile({CustomerProfilePatch? patchInput}) {
    final _patcher = patchInput ?? CustomerProfilePatch();
    final _patchMap = _patcher.toPatch();
    return CustomerProfile(
      name: _patchMap.containsKey(CustomerProfile$.name)
          ? (_patchMap[CustomerProfile$.name] is Function)
                ? _patchMap[CustomerProfile$.name](this.name)
                : _patchMap[CustomerProfile$.name]
          : this.name,
      age: _patchMap.containsKey(CustomerProfile$.age)
          ? (_patchMap[CustomerProfile$.age] is Function)
                ? _patchMap[CustomerProfile$.age](this.age)
                : _patchMap[CustomerProfile$.age]
          : this.age,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerProfile && name == other.name && age == other.age;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.age);
  }

  @override
  String toString() {
    return 'CustomerProfile(' + 'name: ${name}' + ', ' + 'age: ${age})';
  }

  /// Creates a [CustomerProfile] instance from JSON
  factory CustomerProfile.fromJson(Map<String, dynamic> json) =>
      _$CustomerProfileFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CustomerProfileToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum CustomerProfile$ { name, age }

class CustomerProfilePatch implements Patch<CustomerProfile> {
  final Map<CustomerProfile$, dynamic> _patch = {};

  static CustomerProfilePatch create([Map<String, dynamic>? diff]) {
    final patch = CustomerProfilePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = CustomerProfile$.values.firstWhere(
            (e) => e.name == key,
          );
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

  CustomerProfilePatch withName(String? value) {
    _patch[CustomerProfile$.name] = value;
    return this;
  }

  CustomerProfilePatch withAge(int? value) {
    _patch[CustomerProfile$.age] = value;
    return this;
  }
}

extension CustomerProfileSerialization on CustomerProfile {
  Map<String, dynamic> toJson() => _$CustomerProfileToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CustomerProfileToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension CustomerProfileCompareE on CustomerProfile {
  Map<String, dynamic> compareToCustomerProfile(CustomerProfile other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (age != other.age) {
      diff['age'] = () => other.age;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Entity extends $Entity {
  @override
  final String? code;
  @override
  final String? name;
  @override
  final String? id;

  Entity({this.code, this.name, this.id});

  Entity copyWith({String? code, String? name, String? id}) {
    return Entity(
      code: code ?? this.code,
      name: name ?? this.name,
      id: id ?? this.id,
    );
  }

  Entity copyWithEntity({String? code, String? name, String? id}) {
    return copyWith(code: code, name: name, id: id);
  }

  Entity patchWithEntity({EntityPatch? patchInput}) {
    final _patcher = patchInput ?? EntityPatch();
    final _patchMap = _patcher.toPatch();
    return Entity(
      code: _patchMap.containsKey(Entity$.code)
          ? (_patchMap[Entity$.code] is Function)
                ? _patchMap[Entity$.code](this.code)
                : _patchMap[Entity$.code]
          : this.code,
      name: _patchMap.containsKey(Entity$.name)
          ? (_patchMap[Entity$.name] is Function)
                ? _patchMap[Entity$.name](this.name)
                : _patchMap[Entity$.name]
          : this.name,
      id: _patchMap.containsKey(Entity$.id)
          ? (_patchMap[Entity$.id] is Function)
                ? _patchMap[Entity$.id](this.id)
                : _patchMap[Entity$.id]
          : this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Entity &&
        code == other.code &&
        name == other.name &&
        id == other.id;
  }

  @override
  int get hashCode {
    return Object.hash(this.code, this.name, this.id);
  }

  @override
  String toString() {
    return 'Entity(' +
        'code: ${code}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'id: ${id})';
  }

  /// Creates a [Entity] instance from JSON
  factory Entity.fromJson(Map<String, dynamic> json) => _$EntityFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$EntityToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum Entity$ { code, name, id }

class EntityPatch implements Patch<Entity> {
  final Map<Entity$, dynamic> _patch = {};

  static EntityPatch create([Map<String, dynamic>? diff]) {
    final patch = EntityPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Entity$.values.firstWhere((e) => e.name == key);
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

  static EntityPatch fromPatch(Map<Entity$, dynamic> patch) {
    final _patch = EntityPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Entity$, dynamic> toPatch() => Map.from(_patch);

  Entity applyTo(Entity entity) {
    return entity.patchWithEntity(patchInput: this);
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

  static EntityPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  EntityPatch withCode(String? value) {
    _patch[Entity$.code] = value;
    return this;
  }

  EntityPatch withName(String? value) {
    _patch[Entity$.name] = value;
    return this;
  }

  EntityPatch withId(String? value) {
    _patch[Entity$.id] = value;
    return this;
  }
}

extension EntitySerialization on Entity {
  Map<String, dynamic> toJson() => _$EntityToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$EntityToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension EntityCompareE on Entity {
  Map<String, dynamic> compareToEntity(Entity other) {
    final Map<String, dynamic> diff = {};

    if (code != other.code) {
      diff['code'] = () => other.code;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Participant extends $$Participant implements Entity {
  @override
  final String? code;
  @override
  final String? name;
  @override
  final String? id;

  Participant({this.code, this.name, this.id});

  Participant copyWith({String? code, String? name, String? id}) {
    return Participant(
      code: code ?? this.code,
      name: name ?? this.name,
      id: id ?? this.id,
    );
  }

  Participant copyWithParticipant({String? code, String? name, String? id}) {
    return copyWith(code: code, name: name, id: id);
  }

  Participant patchWithParticipant({ParticipantPatch? patchInput}) {
    final _patcher = patchInput ?? ParticipantPatch();
    final _patchMap = _patcher.toPatch();
    return Participant(
      code: _patchMap.containsKey(Participant$.code)
          ? (_patchMap[Participant$.code] is Function)
                ? _patchMap[Participant$.code](this.code)
                : _patchMap[Participant$.code]
          : this.code,
      name: _patchMap.containsKey(Participant$.name)
          ? (_patchMap[Participant$.name] is Function)
                ? _patchMap[Participant$.name](this.name)
                : _patchMap[Participant$.name]
          : this.name,
      id: _patchMap.containsKey(Participant$.id)
          ? (_patchMap[Participant$.id] is Function)
                ? _patchMap[Participant$.id](this.id)
                : _patchMap[Participant$.id]
          : this.id,
    );
  }

  Participant copyWithEntity({String? code, String? name, String? id}) {
    return copyWith(code: code, name: name, id: id);
  }

  Participant patchWithEntity({EntityPatch? patchInput}) {
    final _patcher = patchInput ?? EntityPatch();
    final _patchMap = _patcher.toPatch();
    return Participant(
      code: _patchMap.containsKey(Entity$.code)
          ? (_patchMap[Entity$.code] is Function)
                ? _patchMap[Entity$.code](this.code)
                : _patchMap[Entity$.code]
          : this.code,
      name: _patchMap.containsKey(Entity$.name)
          ? (_patchMap[Entity$.name] is Function)
                ? _patchMap[Entity$.name](this.name)
                : _patchMap[Entity$.name]
          : this.name,
      id: _patchMap.containsKey(Entity$.id)
          ? (_patchMap[Entity$.id] is Function)
                ? _patchMap[Entity$.id](this.id)
                : _patchMap[Entity$.id]
          : this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Participant &&
        code == other.code &&
        name == other.name &&
        id == other.id;
  }

  @override
  int get hashCode {
    return Object.hash(this.code, this.name, this.id);
  }

  @override
  String toString() {
    return 'Participant(' +
        'code: ${code}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'id: ${id})';
  }

  /// Creates a [Participant] instance from JSON
  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ParticipantToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum Participant$ { code, name, id }

class ParticipantPatch implements Patch<Participant> {
  final Map<Participant$, dynamic> _patch = {};

  static ParticipantPatch create([Map<String, dynamic>? diff]) {
    final patch = ParticipantPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Participant$.values.firstWhere(
            (e) => e.name == key,
          );
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

  static ParticipantPatch fromPatch(Map<Participant$, dynamic> patch) {
    final _patch = ParticipantPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Participant$, dynamic> toPatch() => Map.from(_patch);

  Participant applyTo(Participant entity) {
    return entity.patchWithParticipant(patchInput: this);
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

  static ParticipantPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ParticipantPatch withCode(String? value) {
    _patch[Participant$.code] = value;
    return this;
  }

  ParticipantPatch withName(String? value) {
    _patch[Participant$.name] = value;
    return this;
  }

  ParticipantPatch withId(String? value) {
    _patch[Participant$.id] = value;
    return this;
  }
}

extension ParticipantSerialization on Participant {
  Map<String, dynamic> toJson() => _$ParticipantToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ParticipantToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension ParticipantCompareE on Participant {
  Map<String, dynamic> compareToParticipant(Participant other) {
    final Map<String, dynamic> diff = {};

    if (code != other.code) {
      diff['code'] = () => other.code;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Actor implements $$Participant {
  final String? code;
  final String? name;
  final String? id;

  Actor({this.code, this.name, this.id});

  Actor copyWith({String? code, String? name, String? id}) {
    return Actor(
      code: code ?? this.code,
      name: name ?? this.name,
      id: id ?? this.id,
    );
  }

  Actor copyWithActor({String? code, String? name, String? id}) {
    return copyWith(code: code, name: name, id: id);
  }

  Actor patchWithActor({ActorPatch? patchInput}) {
    final _patcher = patchInput ?? ActorPatch();
    final _patchMap = _patcher.toPatch();
    return Actor(
      code: _patchMap.containsKey(Actor$.code)
          ? (_patchMap[Actor$.code] is Function)
                ? _patchMap[Actor$.code](this.code)
                : _patchMap[Actor$.code]
          : this.code,
      name: _patchMap.containsKey(Actor$.name)
          ? (_patchMap[Actor$.name] is Function)
                ? _patchMap[Actor$.name](this.name)
                : _patchMap[Actor$.name]
          : this.name,
      id: _patchMap.containsKey(Actor$.id)
          ? (_patchMap[Actor$.id] is Function)
                ? _patchMap[Actor$.id](this.id)
                : _patchMap[Actor$.id]
          : this.id,
    );
  }

  Actor copyWithEntity({String? code, String? name, String? id}) {
    return copyWith(code: code, name: name, id: id);
  }

  Actor patchWithEntity({EntityPatch? patchInput}) {
    final _patcher = patchInput ?? EntityPatch();
    final _patchMap = _patcher.toPatch();
    return Actor(
      code: _patchMap.containsKey(Entity$.code)
          ? (_patchMap[Entity$.code] is Function)
                ? _patchMap[Entity$.code](this.code)
                : _patchMap[Entity$.code]
          : this.code,
      name: _patchMap.containsKey(Entity$.name)
          ? (_patchMap[Entity$.name] is Function)
                ? _patchMap[Entity$.name](this.name)
                : _patchMap[Entity$.name]
          : this.name,
      id: _patchMap.containsKey(Entity$.id)
          ? (_patchMap[Entity$.id] is Function)
                ? _patchMap[Entity$.id](this.id)
                : _patchMap[Entity$.id]
          : this.id,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Actor &&
        code == other.code &&
        name == other.name &&
        id == other.id;
  }

  @override
  int get hashCode {
    return Object.hash(this.code, this.name, this.id);
  }

  @override
  String toString() {
    return 'Actor(' +
        'code: ${code}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'id: ${id})';
  }

  /// Creates a [Actor] instance from JSON
  factory Actor.fromJson(Map<String, dynamic> json) => _$ActorFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ActorToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum Actor$ { code, name, id }

class ActorPatch implements Patch<Actor> {
  final Map<Actor$, dynamic> _patch = {};

  static ActorPatch create([Map<String, dynamic>? diff]) {
    final patch = ActorPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Actor$.values.firstWhere((e) => e.name == key);
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

  static ActorPatch fromPatch(Map<Actor$, dynamic> patch) {
    final _patch = ActorPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Actor$, dynamic> toPatch() => Map.from(_patch);

  Actor applyTo(Actor entity) {
    return entity.patchWithActor(patchInput: this);
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

  static ActorPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  ActorPatch withCode(String? value) {
    _patch[Actor$.code] = value;
    return this;
  }

  ActorPatch withName(String? value) {
    _patch[Actor$.name] = value;
    return this;
  }

  ActorPatch withId(String? value) {
    _patch[Actor$.id] = value;
    return this;
  }
}

extension ActorSerialization on Actor {
  Map<String, dynamic> toJson() => _$ActorToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$ActorToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension ActorCompareE on Actor {
  Map<String, dynamic> compareToActor(Actor other) {
    final Map<String, dynamic> diff = {};

    if (code != other.code) {
      diff['code'] = () => other.code;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class AdvancedUser implements $$Participant {
  final String? code;
  final String? name;
  final String? id;
  final String email;

  AdvancedUser({this.code, this.name, this.id, required this.email});

  AdvancedUser copyWith({
    String? code,
    String? name,
    String? id,
    String? email,
  }) {
    return AdvancedUser(
      code: code ?? this.code,
      name: name ?? this.name,
      id: id ?? this.id,
      email: email ?? this.email,
    );
  }

  AdvancedUser copyWithAdvancedUser({
    String? code,
    String? name,
    String? id,
    String? email,
  }) {
    return copyWith(code: code, name: name, id: id, email: email);
  }

  AdvancedUser patchWithAdvancedUser({AdvancedUserPatch? patchInput}) {
    final _patcher = patchInput ?? AdvancedUserPatch();
    final _patchMap = _patcher.toPatch();
    return AdvancedUser(
      code: _patchMap.containsKey(AdvancedUser$.code)
          ? (_patchMap[AdvancedUser$.code] is Function)
                ? _patchMap[AdvancedUser$.code](this.code)
                : _patchMap[AdvancedUser$.code]
          : this.code,
      name: _patchMap.containsKey(AdvancedUser$.name)
          ? (_patchMap[AdvancedUser$.name] is Function)
                ? _patchMap[AdvancedUser$.name](this.name)
                : _patchMap[AdvancedUser$.name]
          : this.name,
      id: _patchMap.containsKey(AdvancedUser$.id)
          ? (_patchMap[AdvancedUser$.id] is Function)
                ? _patchMap[AdvancedUser$.id](this.id)
                : _patchMap[AdvancedUser$.id]
          : this.id,
      email: _patchMap.containsKey(AdvancedUser$.email)
          ? (_patchMap[AdvancedUser$.email] is Function)
                ? _patchMap[AdvancedUser$.email](this.email)
                : _patchMap[AdvancedUser$.email]
          : this.email,
    );
  }

  AdvancedUser copyWithEntity({String? code, String? name, String? id}) {
    return copyWith(code: code, name: name, id: id);
  }

  AdvancedUser patchWithEntity({EntityPatch? patchInput}) {
    final _patcher = patchInput ?? EntityPatch();
    final _patchMap = _patcher.toPatch();
    return AdvancedUser(
      code: _patchMap.containsKey(Entity$.code)
          ? (_patchMap[Entity$.code] is Function)
                ? _patchMap[Entity$.code](this.code)
                : _patchMap[Entity$.code]
          : this.code,
      name: _patchMap.containsKey(Entity$.name)
          ? (_patchMap[Entity$.name] is Function)
                ? _patchMap[Entity$.name](this.name)
                : _patchMap[Entity$.name]
          : this.name,
      id: _patchMap.containsKey(Entity$.id)
          ? (_patchMap[Entity$.id] is Function)
                ? _patchMap[Entity$.id](this.id)
                : _patchMap[Entity$.id]
          : this.id,
      email: this.email,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvancedUser &&
        code == other.code &&
        name == other.name &&
        id == other.id &&
        email == other.email;
  }

  @override
  int get hashCode {
    return Object.hash(this.code, this.name, this.id, this.email);
  }

  @override
  String toString() {
    return 'AdvancedUser(' +
        'code: ${code}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'email: ${email})';
  }

  /// Creates a [AdvancedUser] instance from JSON
  factory AdvancedUser.fromJson(Map<String, dynamic> json) {
    if (json['_className_'] == null) {
      return _$AdvancedUserFromJson(json);
    }
    if (json['_className_'] == "AdvancedCustomer") {
      return AdvancedCustomer.fromJson(json);
    } else if (json['_className_'] == "Gamer") {
      return Gamer.fromJson(json);
    } else if (json['_className_'] == "AdvancedUser") {
      return _$AdvancedUserFromJson(json);
    }
    throw UnsupportedError(
      "The _className_ '${json['_className_']}' is not supported by the AdvancedUser.fromJson constructor.",
    );
  }

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AdvancedUserToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum AdvancedUser$ { code, name, id, email }

class AdvancedUserPatch implements Patch<AdvancedUser> {
  final Map<AdvancedUser$, dynamic> _patch = {};

  static AdvancedUserPatch create([Map<String, dynamic>? diff]) {
    final patch = AdvancedUserPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = AdvancedUser$.values.firstWhere(
            (e) => e.name == key,
          );
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

  static AdvancedUserPatch fromPatch(Map<AdvancedUser$, dynamic> patch) {
    final _patch = AdvancedUserPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<AdvancedUser$, dynamic> toPatch() => Map.from(_patch);

  AdvancedUser applyTo(AdvancedUser entity) {
    return entity.patchWithAdvancedUser(patchInput: this);
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

  static AdvancedUserPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  AdvancedUserPatch withCode(String? value) {
    _patch[AdvancedUser$.code] = value;
    return this;
  }

  AdvancedUserPatch withName(String? value) {
    _patch[AdvancedUser$.name] = value;
    return this;
  }

  AdvancedUserPatch withId(String? value) {
    _patch[AdvancedUser$.id] = value;
    return this;
  }

  AdvancedUserPatch withEmail(String? value) {
    _patch[AdvancedUser$.email] = value;
    return this;
  }
}

extension AdvancedUserSerialization on AdvancedUser {
  Map<String, dynamic> toJson() => _$AdvancedUserToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AdvancedUserToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension AdvancedUserCompareE on AdvancedUser {
  Map<String, dynamic> compareToAdvancedUser(AdvancedUser other) {
    final Map<String, dynamic> diff = {};

    if (code != other.code) {
      diff['code'] = () => other.code;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    return diff;
  }
}

extension AdvancedUserChangeToE on AdvancedUser {
  AdvancedCustomer changeToAdvancedCustomer({
    CustomerProfile? profile,
    String? code,
    String? name,
    String? id,
  }) {
    final _patcher = AdvancedCustomerPatch();
    if (profile != null) {
      _patcher.withProfile(profile);
    }
    if (code != null) {
      _patcher.withCode(code);
    }
    if (name != null) {
      _patcher.withName(name);
    }
    if (id != null) {
      _patcher.withId(id);
    }
    final _patchMap = _patcher.toPatch();
    return AdvancedCustomer(
      profile: _patchMap.containsKey(AdvancedCustomer$.profile)
          ? (_patchMap[AdvancedCustomer$.profile] is Function)
                ? _patchMap[AdvancedCustomer$.profile](profile)
                : _patchMap[AdvancedCustomer$.profile]
          : profile,
      email: _patchMap.containsKey(AdvancedCustomer$.email)
          ? (_patchMap[AdvancedCustomer$.email] is Function)
                ? _patchMap[AdvancedCustomer$.email](email)
                : _patchMap[AdvancedCustomer$.email]
          : email,
      code: _patchMap.containsKey(AdvancedCustomer$.code)
          ? (_patchMap[AdvancedCustomer$.code] is Function)
                ? _patchMap[AdvancedCustomer$.code](code)
                : _patchMap[AdvancedCustomer$.code]
          : code,
      name: _patchMap.containsKey(AdvancedCustomer$.name)
          ? (_patchMap[AdvancedCustomer$.name] is Function)
                ? _patchMap[AdvancedCustomer$.name](name)
                : _patchMap[AdvancedCustomer$.name]
          : name,
      id: _patchMap.containsKey(AdvancedCustomer$.id)
          ? (_patchMap[AdvancedCustomer$.id] is Function)
                ? _patchMap[AdvancedCustomer$.id](id)
                : _patchMap[AdvancedCustomer$.id]
          : id,
    );
  }

  Gamer changeToGamer({
    List<String>? games,
    String? code,
    String? name,
    String? id,
  }) {
    final _patcher = GamerPatch();
    if (games != null) {
      _patcher.withGames(games);
    }
    if (code != null) {
      _patcher.withCode(code);
    }
    if (name != null) {
      _patcher.withName(name);
    }
    if (id != null) {
      _patcher.withId(id);
    }
    final _patchMap = _patcher.toPatch();
    return Gamer(
      games: _patchMap.containsKey(Gamer$.games)
          ? (_patchMap[Gamer$.games] is Function)
                ? _patchMap[Gamer$.games](games)
                : _patchMap[Gamer$.games]
          : games,
      email: _patchMap.containsKey(Gamer$.email)
          ? (_patchMap[Gamer$.email] is Function)
                ? _patchMap[Gamer$.email](email)
                : _patchMap[Gamer$.email]
          : email,
      code: _patchMap.containsKey(Gamer$.code)
          ? (_patchMap[Gamer$.code] is Function)
                ? _patchMap[Gamer$.code](code)
                : _patchMap[Gamer$.code]
          : code,
      name: _patchMap.containsKey(Gamer$.name)
          ? (_patchMap[Gamer$.name] is Function)
                ? _patchMap[Gamer$.name](name)
                : _patchMap[Gamer$.name]
          : name,
      id: _patchMap.containsKey(Gamer$.id)
          ? (_patchMap[Gamer$.id] is Function)
                ? _patchMap[Gamer$.id](id)
                : _patchMap[Gamer$.id]
          : id,
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Gamer implements $$Participant {
  final String email;
  final String? code;
  final String? name;
  final String? id;
  final List<String>? games;

  Gamer({required this.email, this.code, this.name, this.id, this.games});

  Gamer copyWith({
    String? email,
    String? code,
    String? name,
    String? id,
    List<String>? games,
  }) {
    return Gamer(
      email: email ?? this.email,
      code: code ?? this.code,
      name: name ?? this.name,
      id: id ?? this.id,
      games: games ?? this.games,
    );
  }

  Gamer copyWithGamer({
    String? email,
    String? code,
    String? name,
    String? id,
    List<String>? games,
  }) {
    return copyWith(email: email, code: code, name: name, id: id, games: games);
  }

  Gamer patchWithGamer({GamerPatch? patchInput}) {
    final _patcher = patchInput ?? GamerPatch();
    final _patchMap = _patcher.toPatch();
    return Gamer(
      email: _patchMap.containsKey(Gamer$.email)
          ? (_patchMap[Gamer$.email] is Function)
                ? _patchMap[Gamer$.email](this.email)
                : _patchMap[Gamer$.email]
          : this.email,
      code: _patchMap.containsKey(Gamer$.code)
          ? (_patchMap[Gamer$.code] is Function)
                ? _patchMap[Gamer$.code](this.code)
                : _patchMap[Gamer$.code]
          : this.code,
      name: _patchMap.containsKey(Gamer$.name)
          ? (_patchMap[Gamer$.name] is Function)
                ? _patchMap[Gamer$.name](this.name)
                : _patchMap[Gamer$.name]
          : this.name,
      id: _patchMap.containsKey(Gamer$.id)
          ? (_patchMap[Gamer$.id] is Function)
                ? _patchMap[Gamer$.id](this.id)
                : _patchMap[Gamer$.id]
          : this.id,
      games: _patchMap.containsKey(Gamer$.games)
          ? (_patchMap[Gamer$.games] is Function)
                ? _patchMap[Gamer$.games](this.games)
                : _patchMap[Gamer$.games]
          : this.games,
    );
  }

  Gamer copyWithAdvancedUser({String? email}) {
    return copyWith(email: email);
  }

  Gamer copyWithEntity({String? code, String? name, String? id}) {
    return copyWith(code: code, name: name, id: id);
  }

  Gamer patchWithAdvancedUser({AdvancedUserPatch? patchInput}) {
    final _patcher = patchInput ?? AdvancedUserPatch();
    final _patchMap = _patcher.toPatch();
    return Gamer(
      email: _patchMap.containsKey(AdvancedUser$.email)
          ? (_patchMap[AdvancedUser$.email] is Function)
                ? _patchMap[AdvancedUser$.email](this.email)
                : _patchMap[AdvancedUser$.email]
          : this.email,
      code: this.code,
      name: this.name,
      id: this.id,
      games: this.games,
    );
  }

  Gamer patchWithEntity({EntityPatch? patchInput}) {
    final _patcher = patchInput ?? EntityPatch();
    final _patchMap = _patcher.toPatch();
    return Gamer(
      email: this.email,
      code: _patchMap.containsKey(Entity$.code)
          ? (_patchMap[Entity$.code] is Function)
                ? _patchMap[Entity$.code](this.code)
                : _patchMap[Entity$.code]
          : this.code,
      name: _patchMap.containsKey(Entity$.name)
          ? (_patchMap[Entity$.name] is Function)
                ? _patchMap[Entity$.name](this.name)
                : _patchMap[Entity$.name]
          : this.name,
      id: _patchMap.containsKey(Entity$.id)
          ? (_patchMap[Entity$.id] is Function)
                ? _patchMap[Entity$.id](this.id)
                : _patchMap[Entity$.id]
          : this.id,
      games: this.games,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Gamer &&
        email == other.email &&
        code == other.code &&
        name == other.name &&
        id == other.id &&
        games == other.games;
  }

  @override
  int get hashCode {
    return Object.hash(this.email, this.code, this.name, this.id, this.games);
  }

  @override
  String toString() {
    return 'Gamer(' +
        'email: ${email}' +
        ', ' +
        'code: ${code}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'games: ${games})';
  }

  /// Creates a [Gamer] instance from JSON
  factory Gamer.fromJson(Map<String, dynamic> json) => _$GamerFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$GamerToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum Gamer$ { email, code, name, id, games }

class GamerPatch implements Patch<Gamer> {
  final Map<Gamer$, dynamic> _patch = {};

  static GamerPatch create([Map<String, dynamic>? diff]) {
    final patch = GamerPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Gamer$.values.firstWhere((e) => e.name == key);
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

  static GamerPatch fromPatch(Map<Gamer$, dynamic> patch) {
    final _patch = GamerPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Gamer$, dynamic> toPatch() => Map.from(_patch);

  Gamer applyTo(Gamer entity) {
    return entity.patchWithGamer(patchInput: this);
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

  static GamerPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  GamerPatch withEmail(String? value) {
    _patch[Gamer$.email] = value;
    return this;
  }

  GamerPatch withCode(String? value) {
    _patch[Gamer$.code] = value;
    return this;
  }

  GamerPatch withName(String? value) {
    _patch[Gamer$.name] = value;
    return this;
  }

  GamerPatch withId(String? value) {
    _patch[Gamer$.id] = value;
    return this;
  }

  GamerPatch withGames(List<String>? value) {
    _patch[Gamer$.games] = value;
    return this;
  }
}

extension GamerSerialization on Gamer {
  Map<String, dynamic> toJson() => _$GamerToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$GamerToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension GamerCompareE on Gamer {
  Map<String, dynamic> compareToGamer(Gamer other) {
    final Map<String, dynamic> diff = {};

    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    if (code != other.code) {
      diff['code'] = () => other.code;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (games != other.games) {
      diff['games'] = () => other.games;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class AdvancedCustomer implements $$Participant {
  final String email;
  final String? code;
  final String? name;
  final String? id;
  final CustomerProfile? profile;

  AdvancedCustomer({
    required this.email,
    this.code,
    this.name,
    this.id,
    this.profile,
  });

  AdvancedCustomer copyWith({
    String? email,
    String? code,
    String? name,
    String? id,
    CustomerProfile? profile,
  }) {
    return AdvancedCustomer(
      email: email ?? this.email,
      code: code ?? this.code,
      name: name ?? this.name,
      id: id ?? this.id,
      profile: profile ?? this.profile,
    );
  }

  AdvancedCustomer copyWithAdvancedCustomer({
    String? email,
    String? code,
    String? name,
    String? id,
    CustomerProfile? profile,
  }) {
    return copyWith(
      email: email,
      code: code,
      name: name,
      id: id,
      profile: profile,
    );
  }

  AdvancedCustomer patchWithAdvancedCustomer({
    AdvancedCustomerPatch? patchInput,
  }) {
    final _patcher = patchInput ?? AdvancedCustomerPatch();
    final _patchMap = _patcher.toPatch();
    return AdvancedCustomer(
      email: _patchMap.containsKey(AdvancedCustomer$.email)
          ? (_patchMap[AdvancedCustomer$.email] is Function)
                ? _patchMap[AdvancedCustomer$.email](this.email)
                : _patchMap[AdvancedCustomer$.email]
          : this.email,
      code: _patchMap.containsKey(AdvancedCustomer$.code)
          ? (_patchMap[AdvancedCustomer$.code] is Function)
                ? _patchMap[AdvancedCustomer$.code](this.code)
                : _patchMap[AdvancedCustomer$.code]
          : this.code,
      name: _patchMap.containsKey(AdvancedCustomer$.name)
          ? (_patchMap[AdvancedCustomer$.name] is Function)
                ? _patchMap[AdvancedCustomer$.name](this.name)
                : _patchMap[AdvancedCustomer$.name]
          : this.name,
      id: _patchMap.containsKey(AdvancedCustomer$.id)
          ? (_patchMap[AdvancedCustomer$.id] is Function)
                ? _patchMap[AdvancedCustomer$.id](this.id)
                : _patchMap[AdvancedCustomer$.id]
          : this.id,
      profile: _patchMap.containsKey(AdvancedCustomer$.profile)
          ? (_patchMap[AdvancedCustomer$.profile] is Function)
                ? _patchMap[AdvancedCustomer$.profile](this.profile)
                : _patchMap[AdvancedCustomer$.profile]
          : this.profile,
    );
  }

  AdvancedCustomer copyWithAdvancedUser({String? email}) {
    return copyWith(email: email);
  }

  AdvancedCustomer copyWithEntity({String? code, String? name, String? id}) {
    return copyWith(code: code, name: name, id: id);
  }

  AdvancedCustomer patchWithAdvancedUser({AdvancedUserPatch? patchInput}) {
    final _patcher = patchInput ?? AdvancedUserPatch();
    final _patchMap = _patcher.toPatch();
    return AdvancedCustomer(
      email: _patchMap.containsKey(AdvancedUser$.email)
          ? (_patchMap[AdvancedUser$.email] is Function)
                ? _patchMap[AdvancedUser$.email](this.email)
                : _patchMap[AdvancedUser$.email]
          : this.email,
      code: this.code,
      name: this.name,
      id: this.id,
      profile: this.profile,
    );
  }

  AdvancedCustomer patchWithEntity({EntityPatch? patchInput}) {
    final _patcher = patchInput ?? EntityPatch();
    final _patchMap = _patcher.toPatch();
    return AdvancedCustomer(
      email: this.email,
      code: _patchMap.containsKey(Entity$.code)
          ? (_patchMap[Entity$.code] is Function)
                ? _patchMap[Entity$.code](this.code)
                : _patchMap[Entity$.code]
          : this.code,
      name: _patchMap.containsKey(Entity$.name)
          ? (_patchMap[Entity$.name] is Function)
                ? _patchMap[Entity$.name](this.name)
                : _patchMap[Entity$.name]
          : this.name,
      id: _patchMap.containsKey(Entity$.id)
          ? (_patchMap[Entity$.id] is Function)
                ? _patchMap[Entity$.id](this.id)
                : _patchMap[Entity$.id]
          : this.id,
      profile: this.profile,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdvancedCustomer &&
        email == other.email &&
        code == other.code &&
        name == other.name &&
        id == other.id &&
        profile == other.profile;
  }

  @override
  int get hashCode {
    return Object.hash(this.email, this.code, this.name, this.id, this.profile);
  }

  @override
  String toString() {
    return 'AdvancedCustomer(' +
        'email: ${email}' +
        ', ' +
        'code: ${code}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'id: ${id}' +
        ', ' +
        'profile: ${profile})';
  }

  /// Creates a [AdvancedCustomer] instance from JSON
  factory AdvancedCustomer.fromJson(Map<String, dynamic> json) =>
      _$AdvancedCustomerFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AdvancedCustomerToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

enum AdvancedCustomer$ { email, code, name, id, profile }

class AdvancedCustomerPatch implements Patch<AdvancedCustomer> {
  final Map<AdvancedCustomer$, dynamic> _patch = {};

  static AdvancedCustomerPatch create([Map<String, dynamic>? diff]) {
    final patch = AdvancedCustomerPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = AdvancedCustomer$.values.firstWhere(
            (e) => e.name == key,
          );
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

  static AdvancedCustomerPatch fromPatch(
    Map<AdvancedCustomer$, dynamic> patch,
  ) {
    final _patch = AdvancedCustomerPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<AdvancedCustomer$, dynamic> toPatch() => Map.from(_patch);

  AdvancedCustomer applyTo(AdvancedCustomer entity) {
    return entity.patchWithAdvancedCustomer(patchInput: this);
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

  static AdvancedCustomerPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  AdvancedCustomerPatch withEmail(String? value) {
    _patch[AdvancedCustomer$.email] = value;
    return this;
  }

  AdvancedCustomerPatch withCode(String? value) {
    _patch[AdvancedCustomer$.code] = value;
    return this;
  }

  AdvancedCustomerPatch withName(String? value) {
    _patch[AdvancedCustomer$.name] = value;
    return this;
  }

  AdvancedCustomerPatch withId(String? value) {
    _patch[AdvancedCustomer$.id] = value;
    return this;
  }

  AdvancedCustomerPatch withProfile(CustomerProfile? value) {
    _patch[AdvancedCustomer$.profile] = value;
    return this;
  }
}

extension AdvancedCustomerSerialization on AdvancedCustomer {
  Map<String, dynamic> toJson() => _$AdvancedCustomerToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$AdvancedCustomerToJson(this);
    return _sanitizeJson(data);
  }

  dynamic _sanitizeJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      json.remove('_className_');
      return json..forEach((key, value) {
        json[key] = _sanitizeJson(value);
      });
    } else if (json is List) {
      return json.map((e) => _sanitizeJson(e)).toList();
    }
    return json;
  }
}

extension AdvancedCustomerCompareE on AdvancedCustomer {
  Map<String, dynamic> compareToAdvancedCustomer(AdvancedCustomer other) {
    final Map<String, dynamic> diff = {};

    if (email != other.email) {
      diff['email'] = () => other.email;
    }
    if (code != other.code) {
      diff['code'] = () => other.code;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (profile != other.profile) {
      diff['profile'] = () => other.profile;
    }
    return diff;
  }
}
