import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'zorphy_generator.dart';

/// A [Builder] that emits generated source into a single shared part file
/// per library via [BuildStep.librarySourceSink], rather than one output
/// file per input.
///
/// Zorphy 3.0.0: replaces the per-class `.zorphy.dart` `PartBuilder` output
/// with one `<library>.zorphy.part` per library. All entities in a library
/// share a single part, making cross-entity polymorphic dispatch a single
/// compilation unit and collapsing N files into one.
///
/// Falls back to the legacy per-library write when [BuildStep.librarySourceSink]
/// is unavailable (e.g. an older build runner), so the builder degrades
/// gracefully rather than dropping output.
Builder zorphySharedPartBuilder(BuilderOptions options) {
  final pluginUris = _extractPluginUris(options);
  final isDryRun = options.config['dry_run'] == true;
  final isForce = options.config['force'] == true;
  return _ZorphySharedPartBuilder(
    ZorphyGenerator(
      pluginUris: pluginUris,
      isDryRun: isDryRun,
      isForce: isForce,
    ),
  );
}

class _ZorphySharedPartBuilder extends Builder {
  _ZorphySharedPartBuilder(this._generator);

  final ZorphyGenerator _generator;

  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.zorphy.part'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;

    final library = await resolver.libraryFor(
      buildStep.inputId,
      allowSyntaxErrors: true,
    );
    final output = await _generator.generate(
      LibraryReader(library),
      buildStep,
    );
    if (output.isEmpty) return;

    final sink = await buildStep.librarySourceSink;
    if (sink != null) {
      // Shared-part path: add to the library's single `.zorphy.part`.
      sink.add(output);
      return;
    }

    // Fallback: no sink available (older build runner). Write a standalone
    // part file with the required `part of` directive so output is not lost.
    final partId = buildStep.inputId.changeExtension('.zorphy.part');
    await buildStep.writeAsString(
      partId,
      '// part of \'${buildStep.inputId.path}\';\n\n$output',
    );
  }
}

/// Extracts the `plugins` list from builder options.
List<String> _extractPluginUris(BuilderOptions options) {
  final raw = options.config['plugins'];
  if (raw is! List) return const [];
  return raw.whereType<String>().toList();
}