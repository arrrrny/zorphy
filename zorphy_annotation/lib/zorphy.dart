// The v3 archetype surface is the only class annotation API. The legacy
// `@Zorphy` / `@Zorphy2` / `ZorphyPreset` / `generate*` surface was removed
// after the v3 migration gate (issue #233).
//
// `json_annotation` is re-exported because the v3 wire contract still uses
// `@JsonKey` for per-field wire names / defaults — the generator reads it by
// simple name (zorphy #88), and the single-import ergonomics the README
// documents (`import 'package:zorphy_annotation/...'`) require it to resolve
// here. This is the field-level wire annotation, not the removed legacy class
// surface.
export 'package:json_annotation/json_annotation.dart';

// `package:meta` is re-exported because the v2 annotation package did, and a
// consumer that imported `@protected` / `@immutable` / `@visibleForTesting`
// through `zorphy_annotation` must keep compiling after `migrate_v3` (zorphy
// #274). The single documented import resolves these annotations again.
export 'package:meta/meta.dart';

export 'src/archetypes.dart';
export 'src/archetype_bases.dart';
export 'src/equality.dart';
export 'src/opt.dart';
export 'src/List_E.dart';
export 'src/patch.dart';
export 'src/boundary.dart';
export 'src/patch_wire.dart';
export 'src/lens.dart';

export 'src/patch_base.dart';
export 'src/zorphy_entity_descriptor.dart';
export 'src/query/field.dart';
export 'src/query/filter.dart';
export 'src/query/sort.dart';
export 'src/query/query_iterables.dart';
