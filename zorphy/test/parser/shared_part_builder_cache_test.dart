import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import 'package:package_config/package_config.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/shared_part_builder.dart';

void main() {
  group('_ZorphySharedPartBuilder IR cache lifetime', () {
    late LibraryElement root;
    late _FakeResolver resolver;
    late _FakeBuildStep buildStep;
    late Directory tempDir;

    setUp(() async {
      tempDir = _makeFixtureDir();
      File(
        '${tempDir.path}/nodes.zorphy.dart',
      ).writeAsStringSync('part of \'nodes.dart\';\n');
      File('${tempDir.path}/nodes.dart').writeAsStringSync(
        "import 'package:zorphy_annotation/zorphy_annotation.dart';\n"
        "part 'nodes.zorphy.dart';\n\n"
        '@ZorphyValue()\n'
        'abstract class \$Shape {\n'
        '  String get id;\n'
        '}\n',
      );
      root = await _resolveRoot(tempDir.path);
      resolver = _FakeResolver(root);
      buildStep = _FakeBuildStep(resolver, {'lib/nodes.dart': 'd1'})
        ..wrapResolverInDelegating = true;
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test(
      'returns identical cached instance across sequential calls with new DelegatingResolver wrappers',
      () async {
        final first = await resolveSharedPartIrWithCacheForTest(buildStep, [
          root,
        ], root);
        expect(first.roots, hasLength(1));

        // Simulate build_runner 2.17.1 BuildStepImpl.resolver wrapping the same
        // delegate in a fresh DelegatingResolver instance on every property read.
        final second = await resolveSharedPartIrWithCacheForTest(buildStep, [
          root,
        ], root);

        expect(identical(first, second), isTrue);
      },
    );

    test('misses and re-resolves when a dependency digest changes', () async {
      final first = await resolveSharedPartIrWithCacheForTest(buildStep, [
        root,
      ], root);
      expect(first.roots, hasLength(1));

      buildStep.digests['lib/nodes.dart'] = 'd2';
      final second = await resolveSharedPartIrWithCacheForTest(buildStep, [
        root,
      ], root);

      expect(identical(first, second), isFalse);
    });

    test('misses and re-resolves when the analysis session changes', () async {
      final first = await resolveSharedPartIrWithCacheForTest(buildStep, [
        root,
      ], root);
      expect(first.roots, hasLength(1));

      final nextDir = _makeFixtureDir();
      File(
        '${nextDir.path}/nodes.zorphy.dart',
      ).writeAsStringSync('part of \'nodes.dart\';\n');
      File('${nextDir.path}/nodes.dart').writeAsStringSync(
        "import 'package:zorphy_annotation/zorphy_annotation.dart';\n"
        "part 'nodes.zorphy.dart';\n\n"
        '@ZorphyValue()\n'
        'abstract class \$Shape {\n'
        '  String get id;\n'
        '}\n',
      );
      final newRoot = await _resolveRoot(nextDir.path);
      final newResolver = _FakeResolver(newRoot);
      final nextStep = _FakeBuildStep(newResolver, {'lib/nodes.dart': 'd1'});
      final second = await resolveSharedPartIrWithCacheForTest(nextStep, [
        newRoot,
      ], newRoot);

      expect(identical(first, second), isFalse);
      nextDir.deleteSync(recursive: true);
    });
  });
}

/// Creates a fixture directory INSIDE the package tree so
/// `package:zorphy_annotation` resolves through the package's own
/// `.dart_tool/package_config.json`.
///
/// A copied `package_config.json` under the system temp breaks under every
/// analyzer version (analyzer_compat 13/14 red): its `rootUri` entries are
/// relative to `.dart_tool/`, so the copy points `zorphy_annotation` at a
/// non-existent sibling and `@ZorphyValue()` fails to resolve. This mirrors
/// the in-tree fixture pattern `test/parser/polymorphic_ir_test.dart` uses.
Directory _makeFixtureDir() {
  final root = Directory('test/.shared_part_cache_tmp').absolute;
  root.createSync(recursive: true);
  return root.createTempSync('fixture_');
}

Future<LibraryElement> _resolveRoot(String dirPath) async {
  final libraryPath = '$dirPath/nodes.dart';
  final collection = AnalysisContextCollection(includedPaths: [dirPath]);
  final resolved =
      await collection
              .contextFor(libraryPath)
              .currentSession
              .getResolvedLibrary(libraryPath)
          as ResolvedLibraryResult;
  return resolved.element;
}

class _FakeBuildStep implements BuildStep {
  _FakeBuildStep(this._resolver, Map<String, String> initialDigests)
    : digests = {...initialDigests};

  @override
  Resolver get resolver => wrapResolverInDelegating
      ? _DelegatingResolver(delegate: _resolver)
      : _resolver;
  final Resolver _resolver;
  bool wrapResolverInDelegating = false;

  final Map<String, String> digests;

  @override
  AssetId get inputId => AssetId('test_pkg', 'lib/nodes.dart');

  @override
  Future<LibraryElement> get inputLibrary async => resolver.libraryFor(inputId);

  @override
  Iterable<AssetId> get allowedOutputs => const [];

  @override
  Future<bool> canRead(AssetId id) async => true;

  @override
  Future<Digest> digest(AssetId id, {bool track = true}) async =>
      Digest(utf8.encode(digests[id.path] ?? ''));

  @override
  Stream<AssetId> findAssets(Glob glob) => const Stream.empty();

  @override
  Future<T> fetchResource<T>(Resource<T> resource) async {
    throw UnsupportedError('No resource manager in unit test');
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) async =>
      '';

  @override
  Future<List<int>> readAsBytes(AssetId id) async => const [];

  @override
  void reportUnusedAssets(Iterable<AssetId> ids) {}

  @override
  T trackStage<T>(
    String label,
    T Function() action, {
    bool isExternal = false,
  }) => action();

  @override
  Future<void> writeAsBytes(AssetId id, FutureOr<List<int>> bytes) async {}

  @override
  Future<void> writeAsString(
    AssetId id,
    FutureOr<String> contents, {
    Encoding encoding = utf8,
  }) async {}

  @override
  Future<PackageConfig> get packageConfig async =>
      PackageConfig(const <Package>[]);

  @override
  Future<LibrarySourceSink?> get librarySourceSink async => null;
}

class _DelegatingResolver implements Resolver {
  _DelegatingResolver({required Resolver delegate}) : _delegate = delegate;
  final Resolver _delegate;

  @override
  Future<bool> isLibrary(AssetId assetId) => _delegate.isLibrary(assetId);

  @override
  Stream<LibraryElement> get libraries => _delegate.libraries;

  @override
  Future<AstNode?> astNodeFor(Fragment fragment, {bool resolve = false}) =>
      _delegate.astNodeFor(fragment, resolve: resolve);

  @override
  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) => _delegate.compilationUnitFor(
    assetId,
    allowSyntaxErrors: allowSyntaxErrors,
  );

  @override
  Future<LibraryElement> libraryFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) => _delegate.libraryFor(assetId, allowSyntaxErrors: allowSyntaxErrors);

  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) =>
      _delegate.findLibraryByName(libraryName);

  @override
  Future<AssetId> assetIdForElement(Element element) =>
      _delegate.assetIdForElement(element);
}

class _FakeResolver implements Resolver {
  _FakeResolver(this.root);
  final LibraryElement root;

  @override
  Future<bool> isLibrary(AssetId assetId) async => true;

  @override
  Stream<LibraryElement> get libraries => Stream.value(root);

  @override
  Future<AstNode?> astNodeFor(
    Fragment fragment, {
    bool resolve = false,
  }) async => null;

  @override
  Future<CompilationUnit> compilationUnitFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) => throw UnimplementedError('compilationUnitFor');

  @override
  Future<LibraryElement> libraryFor(
    AssetId assetId, {
    bool allowSyntaxErrors = false,
  }) async => root;

  @override
  Future<LibraryElement?> findLibraryByName(String libraryName) async => null;

  @override
  Future<AssetId> assetIdForElement(Element element) async =>
      AssetId('test_pkg', 'lib/nodes.dart');
}
