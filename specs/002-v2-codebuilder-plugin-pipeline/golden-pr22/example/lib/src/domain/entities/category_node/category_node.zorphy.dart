// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'category_node.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

@JsonSerializable(explicitToJson: true, checked: true)
class CategoryNode {
  final String id;
  final String name;
  final List<CategoryNode>? children;
  final CategoryNode? parent;

  CategoryNode({
    required this.id,
    required this.name,
    this.children,
    this.parent,
  });

  CategoryNode copyWith({
    String? id,
    String? name,
    List<CategoryNode>? children,
    CategoryNode? parent,
  }) {
    return CategoryNode(
      id: id ?? this.id,
      name: name ?? this.name,
      children: children ?? this.children,
      parent: parent ?? this.parent,
    );
  }

  CategoryNode copyWithCategoryNode({
    String? id,
    String? name,
    List<CategoryNode>? children,
    CategoryNode? parent,
  }) {
    return copyWith(id: id, name: name, children: children, parent: parent);
  }

  CategoryNode patchWithCategoryNode({CategoryNodePatch? patchInput}) {
    final _patcher = patchInput ?? CategoryNodePatch();
    final _patchMap = _patcher.patchMap;
    return CategoryNode(
      id: _patchMap.containsKey(CategoryNode$.id)
          ? (_patchMap[CategoryNode$.id] is Function)
                ? _patchMap[CategoryNode$.id](this.id)
                : (_patchMap[CategoryNode$.id] is Patch)
                ? _patchMap[CategoryNode$.id].applyTo(this.id)
                : _patchMap[CategoryNode$.id]
          : this.id,
      name: _patchMap.containsKey(CategoryNode$.name)
          ? (_patchMap[CategoryNode$.name] is Function)
                ? _patchMap[CategoryNode$.name](this.name)
                : (_patchMap[CategoryNode$.name] is Patch)
                ? _patchMap[CategoryNode$.name].applyTo(this.name)
                : _patchMap[CategoryNode$.name]
          : this.name,
      children: _patchMap.containsKey(CategoryNode$.children)
          ? (_patchMap[CategoryNode$.children] is Function)
                ? _patchMap[CategoryNode$.children](this.children)
                : (_patchMap[CategoryNode$.children] is Patch)
                ? _patchMap[CategoryNode$.children].applyTo(this.children)
                : _patchMap[CategoryNode$.children]
          : this.children,
      parent: _patchMap.containsKey(CategoryNode$.parent)
          ? (_patchMap[CategoryNode$.parent] is Function)
                ? _patchMap[CategoryNode$.parent](this.parent)
                : (_patchMap[CategoryNode$.parent] is Patch)
                ? _patchMap[CategoryNode$.parent].applyTo(this.parent)
                : _patchMap[CategoryNode$.parent]
          : this.parent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryNode &&
        id == other.id &&
        name == other.name &&
        children == other.children &&
        parent == other.parent;
  }

  @override
  int get hashCode {
    return Object.hash(this.id, this.name, this.children, this.parent);
  }

  @override
  String toString() {
    return 'CategoryNode(' +
        'id: ${id}' +
        ', ' +
        'name: ${name}' +
        ', ' +
        'children: ${children}' +
        ', ' +
        'parent: ${parent})';
  }

  /// Creates a [CategoryNode] instance from JSON
  factory CategoryNode.fromJson(Map<String, dynamic> json) =>
      _$CategoryNodeFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CategoryNodeToJson(this);
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

extension CategoryNodePropertyHelpers on CategoryNode {
  bool get hasId => id.isNotEmpty;
  bool get noId => id.isEmpty;
  bool get hasName => name.isNotEmpty;
  bool get noName => name.isEmpty;
  List<CategoryNode> get childrenRequired =>
      children ?? (throw StateError('children is required but was null'));
  bool get hasChildren => children?.isNotEmpty ?? false;
  bool get noChildren => children?.isEmpty ?? true;
  bool get hasParent => parent != null;
  bool get noParent => parent == null;
  CategoryNode get parentRequired =>
      parent ?? (throw StateError('parent is required but was null'));
}

extension CategoryNodeSerialization on CategoryNode {
  Map<String, dynamic> toJson() => _$CategoryNodeToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CategoryNodeToJson(this);
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

enum CategoryNode$ { id, name, children, parent }

class CategoryNodePatch extends PatchBase<CategoryNode, CategoryNode$> {
  CategoryNode applyTo(CategoryNode entity) {
    return entity.patchWithCategoryNode(patchInput: this);
  }

  CategoryNodePatch withId(String? value) {
    patchMap[CategoryNode$.id] = value;
    return this;
  }

  CategoryNodePatch withName(String? value) {
    patchMap[CategoryNode$.name] = value;
    return this;
  }

  CategoryNodePatch withChildren(List<CategoryNode>? value) {
    patchMap[CategoryNode$.children] = value;
    return this;
  }

  CategoryNodePatch updateChildrenAt(
    int index,
    CategoryNodePatch Function(CategoryNodePatch) patch,
  ) {
    patchMap[CategoryNode$.children] = (List<dynamic> list) {
      var updatedList = List.from(list);
      if (index >= 0 && index < updatedList.length) {
        updatedList[index] = patch(
          CategoryNodePatch(),
        ).applyTo(updatedList[index] as CategoryNode);
      }
      return updatedList;
    };
    return this;
  }

  CategoryNodePatch withParent(CategoryNode? value) {
    patchMap[CategoryNode$.parent] = value;
    return this;
  }

  CategoryNodePatch withParentPatch(CategoryNodePatch patch) {
    patchMap[CategoryNode$.parent] = patch;
    return this;
  }

  CategoryNodePatch withParentPatchFunc(
    CategoryNodePatch Function(CategoryNodePatch) patch,
  ) {
    patchMap[CategoryNode$.parent] = (dynamic current) {
      var currentPatch = CategoryNodePatch();
      return patch(currentPatch).applyTo(current as CategoryNode);
    };
    return this;
  }
}

/// Field descriptors for [CategoryNode] query construction
abstract final class CategoryNodeFields {
  static String _$getid(CategoryNode e) => e.id;
  static const id = Field<CategoryNode, String>('id', _$getid);
  static String _$getname(CategoryNode e) => e.name;
  static const name = Field<CategoryNode, String>('name', _$getname);
  static List<CategoryNode>? _$getchildren(CategoryNode e) => e.children;
  static const children = Field<CategoryNode, List<CategoryNode>?>(
    'children',
    _$getchildren,
  );
  static CategoryNode? _$getparent(CategoryNode e) => e.parent;
  static const parent = Field<CategoryNode, CategoryNode?>(
    'parent',
    _$getparent,
  );
}

extension CategoryNodeCompareE on CategoryNode {
  Map<String, dynamic> compareToCategoryNode(CategoryNode other) {
    final Map<String, dynamic> diff = {};

    if (id != other.id) {
      diff['id'] = () => other.id;
    }
    if (name != other.name) {
      diff['name'] = () => other.name;
    }
    if (children != other.children) {
      diff['children'] = () => other.children;
    }
    if (parent != other.parent) {
      diff['parent'] = () => other.parent;
    }
    return diff;
  }
}
