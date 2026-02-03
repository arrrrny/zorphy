// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'complex_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

sealed class $Shape {
  double get area;

  const $Shape._internal();
}

@JsonSerializable(explicitToJson: true)
class Circle implements $$Shape {
  final double area;
  final double radius;

  Circle({required this.area, required this.radius});

  Circle copyWith({double? area, double? radius}) {
    return Circle(area: area ?? this.area, radius: radius ?? this.radius);
  }

  Circle copyWithCircle({double? area, double? radius}) {
    return copyWith(area: area, radius: radius);
  }

  Circle patchWithCircle({CirclePatch? patchInput}) {
    final _patcher = patchInput ?? CirclePatch();
    final _patchMap = _patcher.toPatch();
    return Circle(
      area: _patchMap.containsKey(Circle$.area)
          ? (_patchMap[Circle$.area] is Function)
                ? _patchMap[Circle$.area](this.area)
                : _patchMap[Circle$.area]
          : this.area,
      radius: _patchMap.containsKey(Circle$.radius)
          ? (_patchMap[Circle$.radius] is Function)
                ? _patchMap[Circle$.radius](this.radius)
                : _patchMap[Circle$.radius]
          : this.radius,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Circle && area == other.area && radius == other.radius;
  }

  @override
  int get hashCode {
    return Object.hash(this.area, this.radius);
  }

  @override
  String toString() {
    return 'Circle(' + 'area: ${area}' + ', ' + 'radius: ${radius})';
  }

  /// Creates a [Circle] instance from JSON
  factory Circle.fromJson(Map<String, dynamic> json) => _$CircleFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CircleToJson(this);
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

enum Circle$ { area, radius }

class CirclePatch implements Patch<Circle> {
  final Map<Circle$, dynamic> _patch = {};

  static CirclePatch create([Map<String, dynamic>? diff]) {
    final patch = CirclePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Circle$.values.firstWhere((e) => e.name == key);
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

  static CirclePatch fromPatch(Map<Circle$, dynamic> patch) {
    final _patch = CirclePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Circle$, dynamic> toPatch() => Map.from(_patch);

  Circle applyTo(Circle entity) {
    return entity.patchWithCircle(patchInput: this);
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

  static CirclePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  CirclePatch withArea(double? value) {
    _patch[Circle$.area] = value;
    return this;
  }

  CirclePatch withRadius(double? value) {
    _patch[Circle$.radius] = value;
    return this;
  }
}

extension CircleSerialization on Circle {
  Map<String, dynamic> toJson() => _$CircleToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CircleToJson(this);
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

extension CircleCompareE on Circle {
  Map<String, dynamic> compareToCircle(Circle other) {
    final Map<String, dynamic> diff = {};

    if (area != other.area) {
      diff['area'] = () => other.area;
    }
    if (radius != other.radius) {
      diff['radius'] = () => other.radius;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class Rectangle implements $$Shape {
  final double area;
  final double width;
  final double height;

  Rectangle({required this.area, required this.width, required this.height});

  Rectangle copyWith({double? area, double? width, double? height}) {
    return Rectangle(
      area: area ?? this.area,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  Rectangle copyWithRectangle({double? area, double? width, double? height}) {
    return copyWith(area: area, width: width, height: height);
  }

  Rectangle patchWithRectangle({RectanglePatch? patchInput}) {
    final _patcher = patchInput ?? RectanglePatch();
    final _patchMap = _patcher.toPatch();
    return Rectangle(
      area: _patchMap.containsKey(Rectangle$.area)
          ? (_patchMap[Rectangle$.area] is Function)
                ? _patchMap[Rectangle$.area](this.area)
                : _patchMap[Rectangle$.area]
          : this.area,
      width: _patchMap.containsKey(Rectangle$.width)
          ? (_patchMap[Rectangle$.width] is Function)
                ? _patchMap[Rectangle$.width](this.width)
                : _patchMap[Rectangle$.width]
          : this.width,
      height: _patchMap.containsKey(Rectangle$.height)
          ? (_patchMap[Rectangle$.height] is Function)
                ? _patchMap[Rectangle$.height](this.height)
                : _patchMap[Rectangle$.height]
          : this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rectangle &&
        area == other.area &&
        width == other.width &&
        height == other.height;
  }

  @override
  int get hashCode {
    return Object.hash(this.area, this.width, this.height);
  }

  @override
  String toString() {
    return 'Rectangle(' +
        'area: ${area}' +
        ', ' +
        'width: ${width}' +
        ', ' +
        'height: ${height})';
  }

  /// Creates a [Rectangle] instance from JSON
  factory Rectangle.fromJson(Map<String, dynamic> json) =>
      _$RectangleFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$RectangleToJson(this);
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

enum Rectangle$ { area, width, height }

class RectanglePatch implements Patch<Rectangle> {
  final Map<Rectangle$, dynamic> _patch = {};

  static RectanglePatch create([Map<String, dynamic>? diff]) {
    final patch = RectanglePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = Rectangle$.values.firstWhere((e) => e.name == key);
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

  static RectanglePatch fromPatch(Map<Rectangle$, dynamic> patch) {
    final _patch = RectanglePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<Rectangle$, dynamic> toPatch() => Map.from(_patch);

  Rectangle applyTo(Rectangle entity) {
    return entity.patchWithRectangle(patchInput: this);
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

  static RectanglePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  RectanglePatch withArea(double? value) {
    _patch[Rectangle$.area] = value;
    return this;
  }

  RectanglePatch withWidth(double? value) {
    _patch[Rectangle$.width] = value;
    return this;
  }

  RectanglePatch withHeight(double? value) {
    _patch[Rectangle$.height] = value;
    return this;
  }
}

extension RectangleSerialization on Rectangle {
  Map<String, dynamic> toJson() => _$RectangleToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$RectangleToJson(this);
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

extension RectangleCompareE on Rectangle {
  Map<String, dynamic> compareToRectangle(Rectangle other) {
    final Map<String, dynamic> diff = {};

    if (area != other.area) {
      diff['area'] = () => other.area;
    }
    if (width != other.width) {
      diff['width'] = () => other.width;
    }
    if (height != other.height) {
      diff['height'] = () => other.height;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true)
class TreeNode extends $TreeNode {
  @override
  final String value;
  @override
  final List<TreeNode> children;
  @override
  final TreeNode? parent;

  TreeNode({required this.value, required this.children, this.parent});

  TreeNode copyWith({
    String? value,
    List<TreeNode>? children,
    TreeNode? parent,
  }) {
    return TreeNode(
      value: value ?? this.value,
      children: children ?? this.children,
      parent: parent ?? this.parent,
    );
  }

  TreeNode copyWithTreeNode({
    String? value,
    List<TreeNode>? children,
    TreeNode? parent,
  }) {
    return copyWith(value: value, children: children, parent: parent);
  }

  TreeNode patchWithTreeNode({TreeNodePatch? patchInput}) {
    final _patcher = patchInput ?? TreeNodePatch();
    final _patchMap = _patcher.toPatch();
    return TreeNode(
      value: _patchMap.containsKey(TreeNode$.value)
          ? (_patchMap[TreeNode$.value] is Function)
                ? _patchMap[TreeNode$.value](this.value)
                : _patchMap[TreeNode$.value]
          : this.value,
      children: _patchMap.containsKey(TreeNode$.children)
          ? (_patchMap[TreeNode$.children] is Function)
                ? _patchMap[TreeNode$.children](this.children)
                : _patchMap[TreeNode$.children]
          : this.children,
      parent: _patchMap.containsKey(TreeNode$.parent)
          ? (_patchMap[TreeNode$.parent] is Function)
                ? _patchMap[TreeNode$.parent](this.parent)
                : _patchMap[TreeNode$.parent]
          : this.parent,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TreeNode &&
        value == other.value &&
        children == other.children &&
        parent == other.parent;
  }

  @override
  int get hashCode {
    return Object.hash(this.value, this.children, this.parent);
  }

  @override
  String toString() {
    return 'TreeNode(' +
        'value: ${value}' +
        ', ' +
        'children: ${children}' +
        ', ' +
        'parent: ${parent})';
  }

  /// Creates a [TreeNode] instance from JSON
  factory TreeNode.fromJson(Map<String, dynamic> json) =>
      _$TreeNodeFromJson(json);

  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TreeNodeToJson(this);
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

enum TreeNode$ { value, children, parent }

class TreeNodePatch implements Patch<TreeNode> {
  final Map<TreeNode$, dynamic> _patch = {};

  static TreeNodePatch create([Map<String, dynamic>? diff]) {
    final patch = TreeNodePatch();
    if (diff != null) {
      diff.forEach((key, value) {
        try {
          final enumValue = TreeNode$.values.firstWhere((e) => e.name == key);
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

  static TreeNodePatch fromPatch(Map<TreeNode$, dynamic> patch) {
    final _patch = TreeNodePatch();
    _patch._patch.addAll(patch);
    return _patch;
  }

  Map<TreeNode$, dynamic> toPatch() => Map.from(_patch);

  TreeNode applyTo(TreeNode entity) {
    return entity.patchWithTreeNode(patchInput: this);
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

  static TreeNodePatch fromJson(Map<String, dynamic> json) {
    return create(json);
  }

  TreeNodePatch withValue(String? value) {
    _patch[TreeNode$.value] = value;
    return this;
  }

  TreeNodePatch withChildren(List<TreeNode>? value) {
    _patch[TreeNode$.children] = value;
    return this;
  }

  TreeNodePatch withParent(TreeNode? value) {
    _patch[TreeNode$.parent] = value;
    return this;
  }
}

extension TreeNodeSerialization on TreeNode {
  Map<String, dynamic> toJson() => _$TreeNodeToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TreeNodeToJson(this);
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

extension TreeNodeCompareE on TreeNode {
  Map<String, dynamic> compareToTreeNode(TreeNode other) {
    final Map<String, dynamic> diff = {};

    if (value != other.value) {
      diff['value'] = () => other.value;
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
