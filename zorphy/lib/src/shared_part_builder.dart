import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:meta/meta.dart';
import 'package:source_gen/source_gen.dart';

import 'emission/archetype_composer.dart';
import 'parser/archetype_parser.dart';
import 'parser/hierarchy_resolver.dart';
import 'parser/polymorphic_ir.dart';

final class _CachedIr {
  const _CachedIr(this.ir, this.libraries);

  final PolymorphicIr ir;
  final List<LibraryElement> libraries;
}

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
    // Resolve the same-package import closure so transitive bases are visible.
    final libraries = _samePackageClosure(inputLibrary);

    final ir = await resolveWithCache(buildStep, libraries, inputLibrary);
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

  List<LibraryElement> _samePackageClosure(LibraryElement root) {
    final rootPackage = root.uri.pathSegments.first;
    final seen = <LibraryElement>{root};
    final pending = <LibraryElement>[root];
    final result = <LibraryElement>[];

    while (pending.isNotEmpty) {
      final library = pending.removeLast();
      result.add(library);
      for (final fragment in library.fragments) {
        for (final imported in fragment.libraryImports) {
          final importedLibrary = imported.importedLibrary;
          if (importedLibrary == null) continue;
          if (importedLibrary.uri.pathSegments.first != rootPackage) continue;
          if (seen.add(importedLibrary)) pending.add(importedLibrary);
        }
      }
    }
    return result;
  }

  /// Final root graphs retained for incremental rebuilds.
  ///
  /// The cached [PolymorphicIr] graph is shared READ-ONLY across build steps:
  /// [build] wraps `ir.nodes` in a fresh `localIr` and never mutates the cached
  /// nodes or node map, so a future consumer must treat cached entries as
  /// immutable to avoid leaking mutations across libraries.
  static final Map<String, _CachedIr> _irCache = {};

  /// Parsed declarations reused across libraries that import the same base.
  static final Map<String, ArchetypeLibraryIr> _libraryIrCache = {};
  static Object? _irCacheSession;
  static LibraryElement? _irCacheRoot;

  /// Bound retained graphs; clearing only sacrifices a cache hit.
  static const int _irCacheLimit = 128;
  static const int _libraryIrCacheLimit = 512;

  @visibleForTesting
  Future<PolymorphicIr> resolveWithCache(
    BuildStep buildStep,
    List<LibraryElement> libraries,
    LibraryElement root,
  ) async {
    final Object? session = root.session;
    if (session == null) {
      if (!identical(root, _irCacheRoot)) {
        _irCacheRoot = root;
        _irCache.clear();
        _libraryIrCache.clear();
      }
    } else if (!identical(session, _irCacheSession)) {
      _irCacheSession = session;
      _irCache.clear();
      _libraryIrCache.clear();
    }

    final libraryKeys = <String, LibraryElement>{};
    final key = await _closureDigestKey(buildStep, libraries, libraryKeys);
    if (key != null) {
      final cached = _irCache[key];
      if (cached != null &&
          _sameLibraryIdentities(cached.libraries, libraries)) {
        return cached.ir;
      }
    }

    final parsed = key == null ? null : _parsedLibraries(libraryKeys);
    final ir = HierarchyResolver.resolveLibraries(
      libraries,
      parsedLibraries: parsed,
    );
    if (key != null) {
      if (_irCache.length >= _irCacheLimit) _irCache.clear();
      _irCache[key] = _CachedIr(ir, List.unmodifiable(libraries));
    }
    return ir;
  }

  bool _sameLibraryIdentities(
    List<LibraryElement> cached,
    List<LibraryElement> current,
  ) {
    if (cached.length != current.length) return false;
    final identities = Set<LibraryElement>.identity()..addAll(cached);
    return current.every(identities.contains);
  }

  Map<LibraryElement, ArchetypeLibraryIr> _parsedLibraries(
    Map<String, LibraryElement> libraryKeys,
  ) {
    final parsed = <LibraryElement, ArchetypeLibraryIr>{};
    for (final entry in libraryKeys.entries) {
      final cached = _libraryIrCache[entry.key];
      if (cached != null && identical(cached.library, entry.value)) {
        parsed[entry.value] = cached;
        continue;
      }
      final value = ArchetypeParser.parseLibrary(entry.value);
      if (_libraryIrCache.length >= _libraryIrCacheLimit) {
        _libraryIrCache.clear();
      }
      _libraryIrCache[entry.key] = value;
      parsed[entry.value] = value;
    }
    return parsed;
  }

  /// Digest key for the resolved same-package closure, or null if unavailable.
  Future<String?> _closureDigestKey(
    BuildStep buildStep,
    List<LibraryElement> libraries,
    Map<String, LibraryElement> libraryKeys,
  ) async {
    final resolver = buildStep.resolver;
    final parts = <String>[];

    for (final library in libraries) {
      final AssetId assetId;
      try {
        assetId = await resolver.assetIdForElement(library);
      } on Object {
        // An undigestable library disables caching for this call.
        return null;
      }
      final digest = await buildStep.digest(assetId);
      final key = '${assetId.path}=$digest';
      libraryKeys[key] = library;
      parts.add(key);
    }

    parts.sort();
    return parts.join('|');
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

@visibleForTesting
Future<PolymorphicIr> resolveSharedPartIrWithCacheForTest(
  BuildStep buildStep,
  List<LibraryElement> libraries,
  LibraryElement root,
) => _ZorphySharedPartBuilder().resolveWithCache(buildStep, libraries, root);
