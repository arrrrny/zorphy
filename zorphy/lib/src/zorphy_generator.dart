import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zorphy/src/emission/archetype_composer.dart';
import 'package:zorphy/src/parser/hierarchy_resolver.dart';

/// Unified single-pass generator for the v3 archetype surface.
///
/// Since zorphy 3.0 the legacy `@Zorphy` / `@Zorphy2` presets and `generate*`
/// toggles are gone (issue #233): this generator resolves the library's
/// [PolymorphicIr] from the zero-preset archetypes (`@ZorphyEntity` /
/// `@ZorphyValue` / `@ZorphyUnion`), enforces its diagnostics, and composes
/// the v3 emitter surface (class shape, boundary codec, intent surface, mock
/// fixtures). It keeps NO process-global mutable state — the annotated-class
/// graph is rebuilt from the library's class list on every pass.
///
/// [pluginUris] are accepted for `build.yaml` compatibility but dynamic
/// URI-based plugin loading is not part of the v3 surface.
class ZorphyGenerator extends Generator {
  /// Creates the unified generator.
  ///
  /// [pluginUris] are import-URI strings from `build.yaml` options.
  ///
  /// [isDryRun] when true, prevents file changes (preview mode).
  /// [isForce] when true, bypasses smart merge and regenerates from scratch.
  const ZorphyGenerator({
    this.pluginUris = const [],
    this.isDryRun = false,
    this.isForce = false,
  });

  /// Plugin import URIs from build.yaml (deferred resolution).
  final List<String> pluginUris;

  /// Dry-run mode: preview changes without writing.
  final bool isDryRun;

  /// Force mode: bypass merge and regenerate from scratch.
  final bool isForce;

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    // v3 archetype pass (issue #223): resolve the library's [PolymorphicIr],
    // enforce its diagnostics, and compose the v3 emitter surface (class
    // shape, boundary codec, intent surface, mock fixtures).
    final ir = HierarchyResolver.resolveLibrary(library.element);
    if (ir.hasErrors) {
      throw InvalidGenerationSourceError(
        'Zorphy v3 archetype diagnostics:\n'
        '${ir.diagnostics.map((d) => d.render()).join('\n')}',
      );
    }
    return const ArchetypeComposer().compose(ir);
  }
}
