/// Zorphy Annotation - Annotations for code generation
///
/// This library provides annotations used by the Zorphy code generator
/// to create clean class definitions with advanced features.
///
/// The v3 archetypes (issue #176) are the only class annotations:
/// - @ZorphyEntity - an aggregate/event root with its own identity
/// - @ZorphyState - a state / view-model type
/// - @ZorphyUnion - a closed set of variants
/// - @ZorphyIntent - a command with replay semantics
/// - @ZorphyValue - an immutable value with no identity
///
/// They carry no codegen toggles: every archetype generates the same
/// surface, and what varies is the semantics.
///
/// Usage:
/// ```dart
/// import 'package:zorphy_annotation/zorphy_annotation.dart';
///
/// @ZorphyEntity(principalKey: #id)
/// abstract class $User {
///   String get id;
///   String get name;
///   int get age;
/// }
/// ```
library zorphy_annotation;

// Export all annotations.
//
// The v3 archetype surface is the only class annotation API (issue #233
// removed the legacy `@Zorphy` / `@Zorphy2` / `ZorphyPreset` /
// `generate*` surface after the v3 migration gate).
export 'zorphy.dart';
export 'src/archetype_bases.dart';
export 'src/archetypes.dart';
export 'src/intent.dart';
export 'src/merge_mode.dart';
export 'src/patch_base.dart';
export 'src/agent_annotations.dart';
export 'src/boundary.dart';
export 'src/patch_wire.dart';
export 'src/lens.dart';
export 'src/zorphy_field.dart';
export 'src/zorphy_query_predicates.dart';
