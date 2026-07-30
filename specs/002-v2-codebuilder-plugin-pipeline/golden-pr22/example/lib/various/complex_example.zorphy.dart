// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'complex_example.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

sealed class Shape {
  double get area;

  Shape();
}

extension ShapePropertyHelpers on Shape {}

enum Shape$ { area }

/// Field descriptors for [Shape] query construction
abstract final class ShapeFields {
  static double _$getarea(Shape e) => e.area;
  static const area = Field<Shape, double>('area', _$getarea);
}

extension ShapeCompareE on Shape {
  Map<String, dynamic> compareToShape(Shape other) {
    final Map<String, dynamic> diff = {};

    if (area != other.area) {
      diff['area'] = () => other.area;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Circle implements Shape {
  @override
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
    final _patchMap = _patcher.patchMap;
    return Circle(
      area: _patchMap.containsKey(Circle$.area)
          ? (_patchMap[Circle$.area] is Function)
                ? _patchMap[Circle$.area](this.area)
                : (_patchMap[Circle$.area] is Patch)
                ? _patchMap[Circle$.area].applyTo(this.area)
                : _patchMap[Circle$.area]
          : this.area,
      radius: _patchMap.containsKey(Circle$.radius)
          ? (_patchMap[Circle$.radius] is Function)
                ? _patchMap[Circle$.radius](this.radius)
                : (_patchMap[Circle$.radius] is Patch)
                ? _patchMap[Circle$.radius].applyTo(this.radius)
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

extension CirclePropertyHelpers on Circle {}

extension CircleSerialization on Circle {
  Map<String, dynamic> toJson() => _$CircleToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$CircleToJson(this);
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

enum Circle$ { area, radius }

class CirclePatch extends PatchBase<Circle, Circle$> {
  Circle applyTo(Circle entity) {
    return entity.patchWithCircle(patchInput: this);
  }

  CirclePatch withArea(double? value) {
    patchMap[Circle$.area] = value;
    return this;
  }

  CirclePatch withRadius(double? value) {
    patchMap[Circle$.radius] = value;
    return this;
  }
}

/// Field descriptors for [Circle] query construction
abstract final class CircleFields {
  static double _$getarea(Circle e) => e.area;
  static const area = Field<Circle, double>('area', _$getarea);
  static double _$getradius(Circle e) => e.radius;
  static const radius = Field<Circle, double>('radius', _$getradius);
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

@JsonSerializable(explicitToJson: true, checked: true)
class Rectangle implements Shape {
  @override
  final double area;
  @JsonKey(defaultValue: 1.0)
  final double width;
  @JsonKey(defaultValue: 1.0)
  final double height;

  Rectangle({required this.area, double? width, double? height})
    : this.width = width ?? 1.0,
      this.height = height ?? 1.0;

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
    final _patchMap = _patcher.patchMap;
    return Rectangle(
      area: _patchMap.containsKey(Rectangle$.area)
          ? (_patchMap[Rectangle$.area] is Function)
                ? _patchMap[Rectangle$.area](this.area)
                : (_patchMap[Rectangle$.area] is Patch)
                ? _patchMap[Rectangle$.area].applyTo(this.area)
                : _patchMap[Rectangle$.area]
          : this.area,
      width: _patchMap.containsKey(Rectangle$.width)
          ? (_patchMap[Rectangle$.width] is Function)
                ? _patchMap[Rectangle$.width](this.width)
                : (_patchMap[Rectangle$.width] is Patch)
                ? _patchMap[Rectangle$.width].applyTo(this.width)
                : _patchMap[Rectangle$.width]
          : this.width,
      height: _patchMap.containsKey(Rectangle$.height)
          ? (_patchMap[Rectangle$.height] is Function)
                ? _patchMap[Rectangle$.height](this.height)
                : (_patchMap[Rectangle$.height] is Patch)
                ? _patchMap[Rectangle$.height].applyTo(this.height)
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

extension RectanglePropertyHelpers on Rectangle {}

extension RectangleSerialization on Rectangle {
  Map<String, dynamic> toJson() => _$RectangleToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$RectangleToJson(this);
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

enum Rectangle$ { area, width, height }

class RectanglePatch extends PatchBase<Rectangle, Rectangle$> {
  Rectangle applyTo(Rectangle entity) {
    return entity.patchWithRectangle(patchInput: this);
  }

  RectanglePatch withArea(double? value) {
    patchMap[Rectangle$.area] = value;
    return this;
  }

  RectanglePatch withWidth(double? value) {
    patchMap[Rectangle$.width] = value;
    return this;
  }

  RectanglePatch withHeight(double? value) {
    patchMap[Rectangle$.height] = value;
    return this;
  }
}

/// Field descriptors for [Rectangle] query construction
abstract final class RectangleFields {
  static double _$getarea(Rectangle e) => e.area;
  static const area = Field<Rectangle, double>('area', _$getarea);
  static double _$getwidth(Rectangle e) => e.width;
  static const width = Field<Rectangle, double>('width', _$getwidth);
  static double _$getheight(Rectangle e) => e.height;
  static const height = Field<Rectangle, double>('height', _$getheight);
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

@JsonSerializable(explicitToJson: true, checked: true)
class TreeNode {
  @JsonKey(defaultValue: "root")
  final String value;
  @JsonKey(defaultValue: const [])
  final List<TreeNode>? children;
  final Duration timeout;
  final TreeNode? parent;

  TreeNode({
    String? value,
    List<TreeNode>? children,
    required this.timeout,
    this.parent,
  }) : this.value = value ?? "root",
       this.children = children ?? const [];

  TreeNode copyWith({
    String? value,
    List<TreeNode>? children,
    Duration? timeout,
    TreeNode? parent,
  }) {
    return TreeNode(
      value: value ?? this.value,
      children: children ?? this.children,
      timeout: timeout ?? this.timeout,
      parent: parent ?? this.parent,
    );
  }

  TreeNode copyWithTreeNode({
    String? value,
    List<TreeNode>? children,
    Duration? timeout,
    TreeNode? parent,
  }) {
    return copyWith(
      value: value,
      children: children,
      timeout: timeout,
      parent: parent,
    );
  }

  TreeNode patchWithTreeNode({TreeNodePatch? patchInput}) {
    final _patcher = patchInput ?? TreeNodePatch();
    final _patchMap = _patcher.patchMap;
    return TreeNode(
      value: _patchMap.containsKey(TreeNode$.value)
          ? (_patchMap[TreeNode$.value] is Function)
                ? _patchMap[TreeNode$.value](this.value)
                : (_patchMap[TreeNode$.value] is Patch)
                ? _patchMap[TreeNode$.value].applyTo(this.value)
                : _patchMap[TreeNode$.value]
          : this.value,
      children: _patchMap.containsKey(TreeNode$.children)
          ? (_patchMap[TreeNode$.children] is Function)
                ? _patchMap[TreeNode$.children](this.children)
                : (_patchMap[TreeNode$.children] is Patch)
                ? _patchMap[TreeNode$.children].applyTo(this.children)
                : _patchMap[TreeNode$.children]
          : this.children,
      timeout: _patchMap.containsKey(TreeNode$.timeout)
          ? (_patchMap[TreeNode$.timeout] is Function)
                ? _patchMap[TreeNode$.timeout](this.timeout)
                : (_patchMap[TreeNode$.timeout] is Patch)
                ? _patchMap[TreeNode$.timeout].applyTo(this.timeout)
                : _patchMap[TreeNode$.timeout]
          : this.timeout,
      parent: _patchMap.containsKey(TreeNode$.parent)
          ? (_patchMap[TreeNode$.parent] is Function)
                ? _patchMap[TreeNode$.parent](this.parent)
                : (_patchMap[TreeNode$.parent] is Patch)
                ? _patchMap[TreeNode$.parent].applyTo(this.parent)
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
        timeout == other.timeout &&
        parent == other.parent;
  }

  @override
  int get hashCode {
    return Object.hash(this.value, this.children, this.timeout, this.parent);
  }

  @override
  String toString() {
    return 'TreeNode(' +
        'value: ${value}' +
        ', ' +
        'children: ${children}' +
        ', ' +
        'timeout: ${timeout}' +
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

extension TreeNodePropertyHelpers on TreeNode {
  bool get hasValue => value.isNotEmpty;
  bool get noValue => value.isEmpty;
  List<TreeNode> get childrenRequired =>
      children ?? (throw StateError('children is required but was null'));
  bool get hasChildren => children?.isNotEmpty ?? false;
  bool get noChildren => children?.isEmpty ?? true;
  bool get hasParent => parent != null;
  bool get noParent => parent == null;
  TreeNode get parentRequired =>
      parent ?? (throw StateError('parent is required but was null'));
}

extension TreeNodeSerialization on TreeNode {
  Map<String, dynamic> toJson() => _$TreeNodeToJson(this);
  Map<String, dynamic> toJsonLean() {
    final Map<String, dynamic> data = _$TreeNodeToJson(this);
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

enum TreeNode$ { value, children, timeout, parent }

class TreeNodePatch extends PatchBase<TreeNode, TreeNode$> {
  TreeNode applyTo(TreeNode entity) {
    return entity.patchWithTreeNode(patchInput: this);
  }

  TreeNodePatch withValue(String? value) {
    patchMap[TreeNode$.value] = value;
    return this;
  }

  TreeNodePatch withChildren(List<TreeNode>? value) {
    patchMap[TreeNode$.children] = value;
    return this;
  }

  TreeNodePatch updateChildrenAt(
    int index,
    TreeNodePatch Function(TreeNodePatch) patch,
  ) {
    patchMap[TreeNode$.children] = (List<dynamic> list) {
      var updatedList = List.from(list);
      if (index >= 0 && index < updatedList.length) {
        updatedList[index] = patch(
          TreeNodePatch(),
        ).applyTo(updatedList[index] as TreeNode);
      }
      return updatedList;
    };
    return this;
  }

  TreeNodePatch withTimeout(Duration? value) {
    patchMap[TreeNode$.timeout] = value;
    return this;
  }

  TreeNodePatch withParent(TreeNode? value) {
    patchMap[TreeNode$.parent] = value;
    return this;
  }

  TreeNodePatch withParentPatch(TreeNodePatch patch) {
    patchMap[TreeNode$.parent] = patch;
    return this;
  }

  TreeNodePatch withParentPatchFunc(
    TreeNodePatch Function(TreeNodePatch) patch,
  ) {
    patchMap[TreeNode$.parent] = (dynamic current) {
      var currentPatch = TreeNodePatch();
      return patch(currentPatch).applyTo(current as TreeNode);
    };
    return this;
  }
}

/// Field descriptors for [TreeNode] query construction
abstract final class TreeNodeFields {
  static String _$getvalue(TreeNode e) => e.value;
  static const value = Field<TreeNode, String>('value', _$getvalue);
  static List<TreeNode>? _$getchildren(TreeNode e) => e.children;
  static const children = Field<TreeNode, List<TreeNode>?>(
    'children',
    _$getchildren,
  );
  static Duration _$gettimeout(TreeNode e) => e.timeout;
  static const timeout = Field<TreeNode, Duration>('timeout', _$gettimeout);
  static TreeNode? _$getparent(TreeNode e) => e.parent;
  static const parent = Field<TreeNode, TreeNode?>('parent', _$getparent);
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
    if (timeout != other.timeout) {
      diff['timeout'] = () => other.timeout;
    }
    if (parent != other.parent) {
      diff['parent'] = () => other.parent;
    }
    return diff;
  }
}
