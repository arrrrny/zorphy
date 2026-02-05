/// Zorphy Annotation - Annotations for code generation
///
/// This library provides annotations used by the Zorphy code generator
/// to create clean class definitions with advanced features.
///
/// ## Main Annotations
///
/// - **[@Zorphy()]** - Primary annotation for code generation
/// - **[@Zorphy2()]** - For dependency-ordered generation
///
/// ## Usage
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
///
/// See also:
/// - [Zorphy package](https://pub.dev/packages/zorphy) - Code generator
library zorphy_annotation;

// Export main annotation API
export 'src/annotations/annotations.dart';

// Export core types
export 'src/core/core.dart';

// Export special types
export 'src/types/types.dart';

// Export utilities
export 'src/utils/utils.dart';

// Export the barrel file for convenience
export 'src/src.dart';
