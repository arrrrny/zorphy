/// Zorphy Annotation - Annotations for code generation
///
/// This library provides annotations used by the Zorphy code generator
/// to create clean class definitions with advanced features.
///
/// The main annotation is:
/// - @Zorphy() - Primary annotation for code generation
///
/// Usage:
/// ```dart
/// import 'package:zorphy_annotation/zorphy_annotation.dart';
///
/// @Zorphy()
/// class User {
///   final String name;
///   final int age;
///
///   User({required this.name, required this.age});
/// }
/// ```
library zorphy_annotation;

// Export all annotations
export 'zorphy.dart';
export 'src/patch.dart';
