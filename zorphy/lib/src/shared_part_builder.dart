import 'dart:async';

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'zorphy_generator.dart';

/// A [Builder] that emits generated source into a single shared part file
/// per library via [BuildStep.librarySourceSink], rather than one output
/// file per input.
///
/// Zorphy 3.0.0: replaces the per-class `.zorphy.dart` `PartBuilder` output
/// with one `<library>.part.dart` per library under `lib/_br_/`. All entities
/// in a library share a single part, making cross-entity polymorphic dispatch
/// a single compilation unit and collapsing N files into one.
///
/// [BuildStep.librarySourceSink] has no "unavailable" branch here: it answers
/// `null` only when the primary input is not a library (the guard below has
/// already returned on that), and it throws `UnsupportedError` when the
/// builder is applied without `adds_to_library: true` — which `zorphy/build.yaml`
/// declares. Output is therefore never dropped for want of a sink.
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
    final output = await _generator.generate(LibraryReader(library), buildStep);
    if (output.isEmpty) return;

    final sink = await buildStep.librarySourceSink;
    // Non-null by contract: the input is a library (returned on above) and the
    // builder opts into `adds_to_library` in build.yaml. `librarySourceSink`
    // answers `null` only for a non-library input and throws
    // `UnsupportedError` when that opt-in is missing, so there is no null
    // branch to write and no standalone-part fallback to take.
    sink!.add(_withLintHeader(output));
  }
}

/// The `// ignore_for_file` header `PartBuilder` used to prepend.
///
/// The sink writes the generator's output verbatim, so without this every
/// consumer would lint generated code it cannot edit, under its own
/// `analysis_options.yaml`. A comment is not a directive, so the sink's
/// "no directives in the source" contract still holds.
String _withLintHeader(String output) =>
    '// ignore_for_file: UNNECESSARY_CAST\n'
    '// ignore_for_file: type=lint\n'
    '$output';

/// Extracts the `plugins` list from builder options.
List<String> _extractPluginUris(BuilderOptions options) {
  final raw = options.config['plugins'];
  if (raw is! List) return const [];
  return raw.whereType<String>().toList();
}
