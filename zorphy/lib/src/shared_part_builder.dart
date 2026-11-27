import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'emission/archetype_composer.dart';
import 'parser/hierarchy_resolver.dart';
import 'parser/polymorphic_ir.dart';

/// A [Builder] that emits generated source into a single colocated part file
/// per library (`<library>.zorphy.dart` beside the input), rather than one
/// output file per annotated class.
///
/// Zorphy 3.0.0 (issue #309): one colocated `<library>.zorphy.dart` per
/// library, written as a plain `build_to: source` output. All entities in a
/// library share a single part, making cross-entity polymorphic dispatch a
/// single compilation unit and collapsing N files into one.
///
/// This is deliberately NOT build_runner's `adds_to_library` /
/// [BuildStep.librarySourceSink] shared part: build_runner forces that output
/// under its reserved `_br_/` tree (`build_runner`'s `br_outputs.dart`)
/// regardless of the consumer's `part` directive, which is exactly the mirror
/// tree #309 retires. A plain output builder writing `<library>.zorphy.dart`
/// colocated with the source is the v2 shape, carrying the v3 content.
Builder zorphySharedPartBuilder(BuilderOptions options) {
  return _ZorphySharedPartBuilder();
}

class _ZorphySharedPartBuilder extends Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.zorphy.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;
    if (!await resolver.isLibrary(buildStep.inputId)) return;

    final inputLibrary = await resolver.libraryFor(
      buildStep.inputId,
      allowSyntaxErrors: true,
    );
    // Issue #278: resolve the input library TOGETHER with the same-package
    // libraries it imports that also carry archetype annotations, so a leaf
    // whose base lives in another library sees the cross-library `implements`
    // edge and merges the base's fields. The single-library path emitted each
    // library standalone — the leaf neither extended its base nor took the
    // inherited field — breaking every construction site that passed it.
    final libraries = <LibraryElement>[inputLibrary];
    for (final fragment in inputLibrary.fragments) {
      for (final imported in fragment.libraryImports) {
        final importedLibrary = imported.importedLibrary;
        if (importedLibrary == null) continue;
        // Same package only: a cross-package base is a different build's
        // output and cannot be emitted into this library's part.
        if (importedLibrary.uri.pathSegments.first !=
            inputLibrary.uri.pathSegments.first) {
          continue;
        }
        libraries.add(importedLibrary);
      }
    }

    final ir = HierarchyResolver.resolveLibraries(libraries);
    if (ir.hasErrors) {
      throw InvalidGenerationSourceError(
        'Zorphy v3 archetype diagnostics:\n'
        '${ir.diagnostics.map((d) => d.render()).join('\n')}',
      );
    }
    // Each library emits ONLY the classes it declares: a base class belongs to
    // its own library's shared part, and the leaf in the importing library
    // extends it. Emitting the whole graph here would duplicate every
    // cross-library class into a second part — a duplicate-definition error.
    //
    // A cross-library leaf is NOT a graph root (the base is), so filtering the
    // roots alone would drop it. Walk every root's subtree, keep the nodes
    // declared in the input library, and re-root at the input library's
    // topmost kept node (the one whose parent is declared elsewhere) — the
    // composer then emits that node and its input-local descendants, with the
    // cross-library base already resolved into `superTypes` for the field
    // merge and the `extends` edge.
    final inputPrefix = '${inputLibrary.uri.toString()}#';
    bool isLocal(ZorphyNodeIr node) =>
        node.qualifiedName.startsWith(inputPrefix);
    final localRoots = <ZorphyNodeIr>[];
    for (final root in ir.roots) {
      void collect(ZorphyNodeIr node, ZorphyNodeIr? parent) {
        if (isLocal(node)) {
          if (parent == null || !isLocal(parent)) localRoots.add(node);
        }
        // Always descend: a cross-library base is not local, but its local
        // leaf children are exactly what this library must emit.
        for (final child in node.directSubTypes) {
          collect(child, node);
        }
      }

      collect(root, null);
    }
    // The full graph stays in `nodes` so the leaf's field merge and `extends`
    // edge resolve against the base; only the locally-declared nodes are
    // emitted as top-level surfaces (issue #278).
    final localNames = <String>{
      for (final node in ir.nodes.values)
        if (isLocal(node)) node.qualifiedName,
    };
    final localIr = PolymorphicIr(
      nodes: ir.nodes,
      roots: localRoots,
      diagnostics: ir.diagnostics,
    );
    final output = const ArchetypeComposer().compose(
      localIr,
      onlyNodeQualNames: localNames,
    );
    if (output.isEmpty) return;

    // Issue #309: emit a colocated `<library>.zorphy.dart` part file beside the
    // input library (the v2 shape, carrying the v3 shared-part content). This
    // is a plain `build_to: source` output — NOT build_runner's `adds_to_library`
    // shared part, which build_runner forces under its reserved `_br_/` tree
    // (`build_runner/lib/src/build/br_outputs.dart`) regardless of the consumer's
    // `part` directive. A colocated file is the only way to retire `_br_/`.
    final outputId = buildStep.inputId.changeExtension('.zorphy.dart');
    final libraryName = buildStep.inputId.pathSegments.last;
    final partOf = "part of '$libraryName';\n\n";
    await buildStep.writeAsString(
      outputId,
      '$partOf${_withLintHeader(output)}',
    );
  }
}

/// The `// ignore_for_file` header `PartBuilder` used to prepend.
///
/// Without this every consumer would lint generated code it cannot edit, under
/// its own `analysis_options.yaml`. A comment is not a directive, so it does
/// not disturb the `part of` header the file carries.
String _withLintHeader(String output) =>
    '// ignore_for_file: UNNECESSARY_CAST\n'
    '// ignore_for_file: type=lint\n'
    '$output';
