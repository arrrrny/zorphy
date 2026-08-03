/// Zorphy - Modern code generation for Dart/Flutter
///
/// This library provides a complete solution for generating
/// boilerplate code like copyWith, JSON serialization, equality,
/// toString, and more.
library zorphy;

export 'src/zorphy_generator.dart';
export 'package:zorphy_annotation/zorphy_annotation.dart';

// Plugin API
export 'zorphy_plugin.dart';
export 'src/plugins/plugin_context.dart';

// CLI module - Entity creation utilities
export 'src/cli/entity_creator.dart';
export 'src/cli/models/entity_config.dart';
export 'src/cli/utils/naming_utils.dart';