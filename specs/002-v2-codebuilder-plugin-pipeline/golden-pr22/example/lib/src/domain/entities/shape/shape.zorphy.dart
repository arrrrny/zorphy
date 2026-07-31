// dart format width=80
// ignore_for_file: UNNECESSARY_CAST
// ignore_for_file: type=lint

part of 'shape.dart';

// **************************************************************************
// ZorphyGenerator
// **************************************************************************

sealed class Shape {
  String get color;

  /// Creates a [Shape] instance from JSON
  factory Shape.fromJson(Map<String, dynamic> json) {
    if (json['__typename'] == "Circle") {
      return Circle.fromJson(json);
    } else if (json['__typename'] == "Rectangle") {
      return Rectangle.fromJson(json);
    }
    throw UnsupportedError(
      "The __typename '${json['__typename']}' is not supported by the $className.fromJson constructor.",
    );
  }
}

extension ShapePolymorphicE on Shape {
  bool get isCircle => this is Circle;
  Circle? get asCircle => this is Circle ? this as Circle : null;
  bool get isRectangle => this is Rectangle;
  Rectangle? get asRectangle => this is Rectangle ? this as Rectangle : null;
}

extension ShapePropertyHelpers on Shape {
  bool get hasColor => color.isNotEmpty;
  bool get noColor => color.isEmpty;
}

enum Shape$ { color }

/// Field descriptors for [Shape] query construction
abstract final class ShapeFields {
  static String _$getcolor(Shape e) => e.color;
  static const color = Field<Shape, String>('color', _$getcolor);
}

extension ShapeCompareE on Shape {
  Map<String, dynamic> compareToShape(Shape other) {
    final Map<String, dynamic> diff = {};

    if (color != other.color) {
      diff['color'] = () => other.color;
    }
    return diff;
  }
}

extension ShapeChangeToE on Shape {
  Circle changeToCircle({String? color}) {
    final _patcher = CirclePatch();
    if (color != null) {
      _patcher.withColor(color);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return Circle.fromJson(_json);
  }

  Rectangle changeToRectangle({String? color}) {
    final _patcher = RectanglePatch();
    if (color != null) {
      _patcher.withColor(color);
    }
    final _json = Map<String, dynamic>.from((this as dynamic).toJson());
    _json.addAll(_patcher.toJson());
    return Rectangle.fromJson(_json);
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Circle implements Shape {
  final String color;

  Circle({required this.color});

  Circle copyWith({String? color}) {
    return Circle(color: color ?? this.color);
  }

  Circle copyWithCircle({String? color}) {
    return copyWith(color: color);
  }

  Circle patchWithCircle({CirclePatch? patchInput}) {
    final _patcher = patchInput ?? CirclePatch();
    final _patchMap = _patcher.patchMap;
    return Circle(
      color: _patchMap.containsKey(Circle$.color)
          ? (_patchMap[Circle$.color] is Function)
                ? _patchMap[Circle$.color](this.color)
                : (_patchMap[Circle$.color] is Patch)
                ? _patchMap[Circle$.color].applyTo(this.color)
                : _patchMap[Circle$.color]
          : this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Circle && color == other.color;
  }

  @override
  int get hashCode {
    return Object.hash(color, 0);
  }

  @override
  String toString() {
    return 'Circle(' + 'color: ${color})';
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

  Map<String, dynamic> toJson() {
    final json = _$CircleToJson(this);
    json['__typename'] = 'Circle';
    return json;
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

enum Circle$ { color }

class CirclePatch extends PatchBase<Circle, Circle$> {
  Circle applyTo(Circle entity) {
    return entity.patchWithCircle(patchInput: this);
  }

  CirclePatch withColor(String? value) {
    patchMap[Circle$.color] = value;
    return this;
  }
}

/// Field descriptors for [Circle] query construction
abstract final class CircleFields {
  static String _$getcolor(Circle e) => e.color;
  static const color = Field<Circle, String>('color', _$getcolor);
}

extension CircleCompareE on Circle {
  Map<String, dynamic> compareToCircle(Circle other) {
    final Map<String, dynamic> diff = {};

    if (color != other.color) {
      diff['color'] = () => other.color;
    }
    return diff;
  }
}

@JsonSerializable(explicitToJson: true, checked: true)
class Rectangle implements Shape {
  final String color;

  Rectangle({required this.color});

  Rectangle copyWith({String? color}) {
    return Rectangle(color: color ?? this.color);
  }

  Rectangle copyWithRectangle({String? color}) {
    return copyWith(color: color);
  }

  Rectangle patchWithRectangle({RectanglePatch? patchInput}) {
    final _patcher = patchInput ?? RectanglePatch();
    final _patchMap = _patcher.patchMap;
    return Rectangle(
      color: _patchMap.containsKey(Rectangle$.color)
          ? (_patchMap[Rectangle$.color] is Function)
                ? _patchMap[Rectangle$.color](this.color)
                : (_patchMap[Rectangle$.color] is Patch)
                ? _patchMap[Rectangle$.color].applyTo(this.color)
                : _patchMap[Rectangle$.color]
          : this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Rectangle && color == other.color;
  }

  @override
  int get hashCode {
    return Object.hash(color, 0);
  }

  @override
  String toString() {
    return 'Rectangle(' + 'color: ${color})';
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

  Map<String, dynamic> toJson() {
    final json = _$RectangleToJson(this);
    json['__typename'] = 'Rectangle';
    return json;
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

enum Rectangle$ { color }

class RectanglePatch extends PatchBase<Rectangle, Rectangle$> {
  Rectangle applyTo(Rectangle entity) {
    return entity.patchWithRectangle(patchInput: this);
  }

  RectanglePatch withColor(String? value) {
    patchMap[Rectangle$.color] = value;
    return this;
  }
}

/// Field descriptors for [Rectangle] query construction
abstract final class RectangleFields {
  static String _$getcolor(Rectangle e) => e.color;
  static const color = Field<Rectangle, String>('color', _$getcolor);
}

extension RectangleCompareE on Rectangle {
  Map<String, dynamic> compareToRectangle(Rectangle other) {
    final Map<String, dynamic> diff = {};

    if (color != other.color) {
      diff['color'] = () => other.color;
    }
    return diff;
  }
}
