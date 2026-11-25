// E2E for issue #230: the v3 production builder must emit the typed lens
// registries and `resolvePath()` for generated entities, states and values, and
// the emitted surface must COMPILE and EXECUTE — not merely contain the right
// text.
//
// Before #230 `ArchetypeComposer` composed class shapes, codecs, patches, mocks
// and intents only, so a consumer's `Product.lenses.id` / `Product.resolvePath`
// were `undefined_getter` / `undefined_method` errors (the issue's reproduction).
//
// The source under test is the REAL build_runner output: `dart run build_runner
// build` inside example/ (CI runs it before this test, exactly as the #223 e2e
// does) writes the shared part this file reads. The part is a `part of`
// fragment, so — like the #223 compile probe — the `part of` directive is
// stripped and the annotation import prepended to make a standalone library.
//
// Execution runs under `dart compile exe` (AOT), so the resolver is exercised as
// the issue's AOT + #193 latency acceptance requires, and a budget guards the
// O(depth) switch resolution against a regression.

@Timeout(Duration(minutes: 8))
library;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final v3Part = File('example/lib/_br_/v3_archetypes/v3_archetypes.part.dart');

  late String body;

  setUpAll(() {
    if (!v3Part.existsSync()) {
      fail(
        'Missing generated file: ${v3Part.path}\n'
        'Run: cd example && dart run build_runner build '
        '--delete-conflicting-outputs',
      );
    }
    body = v3Part
        .readAsStringSync()
        .split('\n')
        .where((line) => !line.startsWith('part of'))
        .join('\n');
  });

  test(
    'the v3 part declares lens registries and resolvePath for every archetype',
    () {
      // The issue's exact reproduction names.
      for (final registry in const [
        'static const ProductLenses lenses = ProductLenses();',
        'static const ReadyStateLenses lenses = ReadyStateLenses();',
        'static const GreetingLenses lenses = GreetingLenses();',
      ]) {
        expect(body, contains(registry), reason: 'missing registry: $registry');
      }
      // The static resolver on a sealed root, a leaf, a state and a value.
      for (final className in const [
        'Product',
        'UiState',
        'ReadyState',
        'Greeting',
        'Event',
        'DeployEvent',
        'ProductUiState',
      ]) {
        expect(
          body,
          contains('static ZorphyLens<$className, Object?>? resolvePath('),
          reason: '$className must expose resolvePath',
        );
      }
      // Nested delegation hands the remainder to the nested type's resolver.
      expect(body, contains('EditDraft.resolvePath(remainder)'));
      expect(body, contains('.then(nested)'));
    },
  );

  test(
    'the generated surface compiles, executes and meets the latency budget',
    () {
      final probeParent = Directory('test/.issue_230_$pid')
        ..createSync(recursive: true);
      final probe = probeParent.createTempSync('issue_230_').absolute;
      addTearDown(() => probe.deleteSync(recursive: true));

      final annotationRoot = Directory.current.parent.uri
          .resolve('zorphy_annotation/')
          .toFilePath();

      File('${probe.path}/pubspec.yaml').writeAsStringSync(
        'name: issue_230_probe\n'
        'environment:\n'
        '  sdk: ">=3.11.0 <4.0.0"\n'
        'dependencies:\n'
        '  zorphy_annotation:\n'
        '    path: $annotationRoot\n',
      );
      Directory('${probe.path}/lib').createSync();
      Directory('${probe.path}/bin').createSync();
      File('${probe.path}/lib/generated.dart').writeAsStringSync(
        "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n$body",
      );
      File('${probe.path}/bin/main.dart').writeAsStringSync(_mainSource);

      final pubGet = Process.runSync('dart', [
        'pub',
        'get',
      ], workingDirectory: probe.path);
      expect(
        pubGet.exitCode,
        0,
        reason: 'dart pub get failed:\n${pubGet.stdout}\n${pubGet.stderr}',
      );

      final analyze = Process.runSync('dart', [
        'analyze',
        '--no-fatal-warnings',
        'lib/generated.dart',
      ], workingDirectory: probe.path);
      expect(
        analyze.exitCode,
        0,
        reason:
            'generated part does not compile:\n'
            '${analyze.stdout}\n${analyze.stderr}',
      );

      // AOT: the resolver must run as a compiled executable (the issue's AOT
      // acceptance), and the program self-checks the lens laws, the shared /
      // subtype-only / nested pointers and the latency budget.
      final compiled = Process.runSync('dart', [
        'compile',
        'exe',
        'bin/main.dart',
        '-o',
        'main',
      ], workingDirectory: probe.path);
      expect(
        compiled.exitCode,
        0,
        reason:
            'dart compile exe failed:\n'
            '${compiled.stdout}\n${compiled.stderr}',
      );

      final run = Process.runSync(
        '${probe.path}/main',
        const [],
        workingDirectory: probe.path,
      );
      expect(
        run.exitCode,
        0,
        reason:
            'generated resolver failed at runtime:\n'
            '${run.stdout}\n${run.stderr}',
      );
      expect(run.stdout.toString(), contains('ALL CHECKS PASSED'));
    },
  );
}

/// The executed program: lens laws, the three pointer disciplines and the
/// latency budget, all against the REAL generated surface.
const _mainSource = r'''
import 'dart:io';

import 'package:issue_230_probe/generated.dart';

void _check(bool condition, String label) {
  if (!condition) throw StateError('FAILED: $label');
}

void main() {
  // ── Lens laws on an entity, a state and a value (the issue's repro) ──────
  final product = Product.fromTrusted(id: 'p1', name: 'Widget');
  _check(Product.lenses.id.get(product) == 'p1', 'entity lens get');
  _check(Product.lenses.id.set(product, 'p2').id == 'p2', 'entity lens set');
  // put-get: get(set(root, v)) == v
  _check(Product.lenses.name.get(Product.lenses.name.set(product, 'Gadget')) ==
      'Gadget', 'entity put-get');
  // get-put: set(root, get(root)) == root
  _check(Product.lenses.name.set(product, Product.lenses.name.get(product)) ==
      product, 'entity get-put');

  final state = ReadyState.fromTrusted(label: 'L', detail: 'D');
  _check(ReadyState.lenses.detail.get(state) == 'D', 'state lens get');
  _check(ReadyState.lenses.detail.set(state, 'D2').detail == 'D2',
      'state lens set');
  _check(ReadyState.lenses.detail.set(state, ReadyState.lenses.detail.get(state)) ==
      state, 'state get-put');

  final greeting = Greeting.fromTrusted(message: 'hi');
  _check(Greeting.lenses.message.get(greeting) == 'hi', 'value lens get');
  _check(
      Greeting.lenses.message.set(greeting, Greeting.lenses.message.get(greeting)) ==
          greeting,
      'value get-put');

  // ── resolvePath: the issue's exact pointers ──────────────────────────────
  _check(Product.resolvePath('/name')!.get(product) == 'Widget', 'Product /name');
  _check(UiState.resolvePath('/detail')!.get(state) == 'D', 'UiState /detail');

  // ── Shared + subtype-only pointers across a three-level hierarchy ────────
  final button = ZfaButtonNode.fromTrusted(
      contractId: 'c1', mode: 'edit', label: 'OK');
  final text = ZfaTextNode.fromTrusted(contractId: 'c2', text: 'hello');

  // Shared pointer resolves for ANY subtype.
  _check(UiNode.resolvePath('/contractId')!.get(button) == 'c1',
      'shared /contractId on button');
  _check(UiNode.resolvePath('/contractId')!.get(text) == 'c2',
      'shared /contractId on text');

  // Subtype-only pointer resolves where applicable ...
  _check(UiNode.resolvePath('/mode')!.get(button) == 'edit',
      'subtype-only /mode on button');
  _check(UiNode.resolvePath('/label')!.get(button) == 'OK',
      'subtype-only /label on button');
  // ... and answers null (never throws) on an inapplicable subtype.
  _check(UiNode.resolvePath('/mode')!.get(text) == null,
      'subtype-only /mode null on text');
  _check(UiNode.resolvePath('/label')!.get(text) == null,
      'subtype-only /label null on text');
  _check(UiNode.resolvePath('/text')!.get(button) == null,
      'subtype-only /text null on button');
  _check(UiNode.resolvePath('/text')!.get(text) == 'hello',
      'subtype-only /text on text');

  // Unknown pointer answers null.
  _check(UiNode.resolvePath('/nope') == null, 'unknown pointer null');

  // ── Nested pointer delegation: /editDraft/price ──────────────────────────
  final draft = EditDraft.fromTrusted(title: 'T', price: 9.5);
  final ui = ProductUiState.fromTrusted(editDraft: draft, selectedTab: 2);
  _check(ProductUiState.resolvePath('/editDraft/price')!.get(ui) == 9.5,
      'nested /editDraft/price get');
  final bumped =
      ProductUiState.resolvePath('/editDraft/price')!.set(ui, 19.99);
  _check(bumped.editDraft.price == 19.99 && bumped.selectedTab == 2,
      'nested /editDraft/price set keeps siblings');
  _check(ProductUiState.resolvePath('/editDraft/nope') == null,
      'nested unknown leaf null');

  // ── #193 latency guard: O(depth) resolution stays cheap under AOT ────────
  final swatch = Stopwatch()..start();
  var sink = 0;
  for (var i = 0; i < 200000; i++) {
    sink += (Product.resolvePath('/name')!.get(product) as String).length;
  }
  swatch.stop();
  _check(sink > 0, 'latency loop ran');
  _check(
      swatch.elapsedMilliseconds < 2000,
      'resolvePath latency budget exceeded: '
      '${swatch.elapsedMilliseconds}ms for 200k lookups');

  stdout.writeln('ALL CHECKS PASSED '
      '(200k resolvePath lookups in ${swatch.elapsedMilliseconds}ms)');
}
''';
