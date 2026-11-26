import 'circle.dart';
import 'base_shape.dart';

// The natural v2 construction: pass the inherited field.
final Shape shape = Circle.fromTrusted(color: 'red', radius: 1.0);
