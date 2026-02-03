// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'ex44_a_copy_super_to_sub_generic_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class Super extends $Super {
  @override
  final String id;

  Super({
    required this.id,
  });

  Super copyWith({
    String? id,
  }) {
    return Super(
      id: id ?? this.id,
    );
  }

  Super copyWithSuper({
    String? id,
  }) {
    return copyWith(
      id: id,
    );
  }

  Super patchWithSuper({
    SuperPatch? patchInput,
  }) {
    final _patcher = patchInput ?? SuperPatch();
    final _patchMap = _patcher.toPatch();
    return Super(
        id: _patchMap.containsKey(Super$.id)
            ? (_patchMap[Super$.id] is Function)
                ? _patchMap[Super$.id](this.id)
                : _patchMap[Super$.id]
            : this.id);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Super && id == other.id;
  }

  @override
  int get hashCode {
    return Object.hash(id, 0);
  }

  @override
  String toString() {
    return 'Super(' + 'id: ${id})';
  }
}

enum Super$ { id }

class SuperPatch implements Patch<Super> {
  final Map<Super$, dynamic> _patch = {};

  static SuperPatch create([Map<String, dynamic>? diff]) {
    final patch = SuperPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Super$.values.firstWhere((e) => e.name == key);
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

  static SuperPatch fromPatch(Map<Super$, dynamic> patch) {
    final _patch = SuperPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Super$, dynamic> toPatch() => Map.from(_patch);

  Super applyTo(Super entity) {
    return entity.patchWithSuper(patchInput: this);
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

  static SuperPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  SuperPatch withId(String? value) {
    _patch[Super$.id] = value;
    return this;
  }
}

extension SuperCompareE on Super {
  Map<String, dynamic> compareToSuper(Super other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    return diff;
  }
}

extension SuperChangeToE on Super {
  Sub changeToSub({required String description, required T code}) {
    final _patcher = SubPatch();
    _patcher.withDescription(description);
    _patcher.withCode(code);
    final _patchMap = _patcher.toPatch();
    return Sub(
        description: _patchMap[Sub$.description],
        code: _patchMap[Sub$.code],
        id: _patchMap.containsKey(Sub$.id)
            ? (_patchMap[Sub$.id] is Function)
                ? _patchMap[Sub$.id](this.id)
                : _patchMap[Sub$.id]
            : this.id);
  }
}

class Sub<T> extends $Sub implements $Super {
  @override
  final String id;
  @override
  final String description;
  @override
  final T code;

  Sub({
    required this.id,
    required this.description,
    required this.code,
  });

  Sub copyWith({
    String? id,
    String? description,
    T? code,
  }) {
    return Sub(
      id: id ?? this.id,
      description: description ?? this.description,
      code: code ?? this.code,
    );
  }

  Sub copyWithSub({
    String? id,
    String? description,
    T? code,
  }) {
    return copyWith(
      id: id,
      description: description,
      code: code,
    );
  }

  Sub patchWithSub({
    SubPatch? patchInput,
  }) {
    final _patcher = patchInput ?? SubPatch();
    final _patchMap = _patcher.toPatch();
    return Sub(
        id: _patchMap.containsKey(Sub$.id)
            ? (_patchMap[Sub$.id] is Function)
                ? _patchMap[Sub$.id](this.id)
                : _patchMap[Sub$.id]
            : this.id,
        description: _patchMap.containsKey(Sub$.description)
            ? (_patchMap[Sub$.description] is Function)
                ? _patchMap[Sub$.description](this.description)
                : _patchMap[Sub$.description]
            : this.description,
        code: _patchMap.containsKey(Sub$.code)
            ? (_patchMap[Sub$.code] is Function)
                ? _patchMap[Sub$.code](this.code)
                : _patchMap[Sub$.code]
            : this.code);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Sub &&
        id == other.id &&
        description == other.description &&
        code == other.code;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.description, this.code);
  }

  @override
  String toString() {
    return 'Sub(' +
        'id: ${id}' +
        ', ' +
        'description: ${description}' +
        ', ' +
        'code: ${code})';
  }
}

enum Sub$ { id, description, code }

class SubPatch implements Patch<Sub> {
  final Map<Sub$, dynamic> _patch = {};

  static SubPatch create([Map<String, dynamic>? diff]) {
    final patch = SubPatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Sub$.values.firstWhere((e) => e.name == key);
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

  static SubPatch fromPatch(Map<Sub$, dynamic> patch) {
    final _patch = SubPatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Sub$, dynamic> toPatch() => Map.from(_patch);

  Sub applyTo(Sub entity) {
    return entity.patchWithSub(patchInput: this);
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

  static SubPatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  SubPatch withId(String? value) {
    _patch[Sub$.id] = value;
    return this;
  }

  SubPatch withDescription(String? value) {
    _patch[Sub$.description] = value;
    return this;
  }

  SubPatch withCode(dynamic value) {
    _patch[Sub$.code] = value;
    return this;
  }
}

extension SubCompareE on Sub {
  Map<String, dynamic> compareToSub(Sub other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (description != other.description) {
      diff['description'] = () => other.description;
    }
    if (code != other.code) {
      diff['code'] = () => other.code;
    }
    return diff;
  }
}
