// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'static_method_test.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class Category {
  final String id;
  final String name;
  final String? description;

  Category({required this.id, required this.name, this.description});

  Category copyWith({String? id, String? name, String? description}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  Category copyWithCategory({String? id, String? name, String? description}) {
    return copyWith(id: id, name: name, description: description);
  }

  factory Category.undefined() => $Category.undefined();

  factory Category.create({
    required String id,
    required String name,
    String? description,
  }) => $Category.create(id: id, name: name, description: description);

  factory Category.createWithName(String name) =>
      $Category.createWithName(name);

  Category patchWithCategory({CategoryPatch? patchInput}) {
    final _patcher = patchInput ?? CategoryPatch();
    final _patchMap = _patcher.patchMap;
    return Category(
      id: _patchMap.containsKey(Category$.id)
          ? (_patchMap[Category$.id] is Function)
                ? _patchMap[Category$.id](this.id)
                : (_patchMap[Category$.id] is Patch)
                ? _patchMap[Category$.id].applyTo(this.id)
                : _patchMap[Category$.id]
          : this.id,
      name: _patchMap.containsKey(Category$.name)
          ? (_patchMap[Category$.name] is Function)
                ? _patchMap[Category$.name](this.name)
                : (_patchMap[Category$.name] is Patch)
                ? _patchMap[Category$.name].applyTo(this.name)
                : _patchMap[Category$.name]
          : this.name,
      description: _patchMap.containsKey(Category$.description)
          ? (_patchMap[Category$.description] is Function)
                ? _patchMap[Category$.description](this.description)
                : (_patchMap[Category$.description] is Patch)
                ? _patchMap[Category$.description].applyTo(this.description)
                : _patchMap[Category$.description]
          : this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        id == other.id &&
        name == other.name &&
        description == other.description;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.name, this.description);
  }

  @override
  String toString() {
    return 'Category(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'description: ${description})';
  }

  /// Creates a [Category] instance from JSON
  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CategoryToJson(this);
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

extension CategoryPropertyHelpers on Category {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  bool get hasDescription => description?.isNotEmpty == true;
  bool get noDescription => description?.isEmpty ?? true;
  String get descriptionRequired =>
      description ?? (throw StateError('description is required but was null'));
}

extension CategorySerialization on Category {
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CategoryToJson(this);
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

enum Category$ { id, name, description }

class CategoryPatch extends PatchBase<Category, Category$> {
  Category applyTo(Category entity) {
    return entity.patchWithCategory(patchInput: this);
  }

  CategoryPatch withId(String? value) {
    patchMap[Category$.id] = value;
    return this;
  }

  CategoryPatch withName(String? value) {
    patchMap[Category$.name] = value;
    return this;
  }

  CategoryPatch withDescription(String? value) {
    patchMap[Category$.description] = value;
    return this;
  }
}

/// Field descriptors for [Category] query construction
abstract final class CategoryFields {
  static String _$getid(Category e) => e.id;
  static const id = Field<Category, String>('id', _$getid);
  static String _$getname(Category e) => e.name;
  static const name = Field<Category, String>('name', _$getname);
  static String? _$getdescription(Category e) => e.description;
  static const description = Field<Category, String?>(
    'description',
    _$getdescription,
  );
}

extension CategoryCompareE on Category {
  Map<String, dynamic> compareToCategory(Category other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (description != other.description) {
      diff['description'] = () => other.description;
    }
    return diff;
  }
}
