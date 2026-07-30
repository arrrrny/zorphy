// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'filter_non_generic_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

class SimpleFilterEntity {
  final String name;
  final int count;
  final bool isActive;

  SimpleFilterEntity({
    required this.name,
    required this.count,
    required this.isActive,
  });

  SimpleFilterEntity copyWith({String? name, int? count, bool? isActive}) {
    return SimpleFilterEntity(
      name: name ?? this.name,
      count: count ?? this.count,
      isActive: isActive ?? this.isActive,
    );
  }

  SimpleFilterEntity copyWithSimpleFilterEntity({
    String? name,
    int? count,
    bool? isActive,
  }) {
    return copyWith(name: name, count: count, isActive: isActive);
  }

  SimpleFilterEntity patchWithSimpleFilterEntity({
    SimpleFilterEntityPatch? patchInput,
  }) {
    final _patcher = patchInput ?? SimpleFilterEntityPatch();
    final _patchMap = _patcher.patchMap;
    return SimpleFilterEntity(
      name: _patchMap.containsKey(SimpleFilterEntity$.name)
          ? (_patchMap[SimpleFilterEntity$.name] is Function)
                ? _patchMap[SimpleFilterEntity$.name](this.name)
                : (_patchMap[SimpleFilterEntity$.name] is Patch)
                ? _patchMap[SimpleFilterEntity$.name].applyTo(this.name)
                : _patchMap[SimpleFilterEntity$.name]
          : this.name,
      count: _patchMap.containsKey(SimpleFilterEntity$.count)
          ? (_patchMap[SimpleFilterEntity$.count] is Function)
                ? _patchMap[SimpleFilterEntity$.count](this.count)
                : (_patchMap[SimpleFilterEntity$.count] is Patch)
                ? _patchMap[SimpleFilterEntity$.count].applyTo(this.count)
                : _patchMap[SimpleFilterEntity$.count]
          : this.count,
      isActive: _patchMap.containsKey(SimpleFilterEntity$.isActive)
          ? (_patchMap[SimpleFilterEntity$.isActive] is Function)
                ? _patchMap[SimpleFilterEntity$.isActive](this.isActive)
                : (_patchMap[SimpleFilterEntity$.isActive] is Patch)
                ? _patchMap[SimpleFilterEntity$.isActive].applyTo(this.isActive)
                : _patchMap[SimpleFilterEntity$.isActive]
          : this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimpleFilterEntity &&
        name == other.name &&
        count == other.count &&
        isActive == other.isActive;
  }

  @override
  int get hashCode {
    return Object.hash(this.name, this.count, this.isActive);
  }

  @override
  String toString() {
    return 'SimpleFilterEntity(' +
        'name: ${name}' +
        ', ' +
        'count: ${count}' +
        ', ' +
        'isActive: ${isActive})';
  }
}

extension SimpleFilterEntityPropertyHelpers on SimpleFilterEntity {
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
}

enum SimpleFilterEntity$ { name, count, isActive }

class SimpleFilterEntityPatch
    extends PatchBase<SimpleFilterEntity, SimpleFilterEntity$> {
  SimpleFilterEntity applyTo(SimpleFilterEntity entity) {
    return entity.patchWithSimpleFilterEntity(patchInput: this);
  }

  SimpleFilterEntityPatch withName(String? value) {
    patchMap[SimpleFilterEntity$.name] = value;
    return this;
  }

  SimpleFilterEntityPatch withCount(int? value) {
    patchMap[SimpleFilterEntity$.count] = value;
    return this;
  }

  SimpleFilterEntityPatch withIsActive(bool? value) {
    patchMap[SimpleFilterEntity$.isActive] = value;
    return this;
  }
}

/// Field descriptors for [SimpleFilterEntity] query construction
abstract final class SimpleFilterEntityFields {
  static String _$getname(SimpleFilterEntity e) => e.name;
  static const name = Field<SimpleFilterEntity, String>('name', _$getname);
  static int _$getcount(SimpleFilterEntity e) => e.count;
  static const count = Field<SimpleFilterEntity, int>('count', _$getcount);
  static bool _$getisActive(SimpleFilterEntity e) => e.isActive;
  static const isActive = Field<SimpleFilterEntity, bool>(
    'isActive',
    _$getisActive,
  );
}

extension SimpleFilterEntityCompareE on SimpleFilterEntity {
  Map<String, dynamic> compareToSimpleFilterEntity(SimpleFilterEntity other) {
    final Map<String, dynamic> diff = {};

    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (count != other.count) {
      diff['count'] = () => other.count;
    }
    if (isActive != other.isActive) {
      diff['isActive'] = () => other.isActive;
    }
    return diff;
  }
}
