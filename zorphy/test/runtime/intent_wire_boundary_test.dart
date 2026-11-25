// Tests for ISSUE (arrrrny/zorphy#232): the intent boundary is completed with
// `fromWire`, deterministic `<Intent>MockData` seeds and
// `<Intent>WireFixtures`, and intent-valued nested fields decode through the
// boundary codec instead of travelling as raw wire values.
//
// Runtime tests, in the #189 style: the composed fragment (the production
// `ArchetypeComposer` output, not an emitter in isolation) is written into a
// temp package, compiled and EXECUTED, and every acceptance criterion of the
// issue is asserted against the running generated code.
//
// Coverage (the issue's acceptance gate):
//   - every intent leaf round-trips through `fromWire(intent.toWire())`;
//   - the sealed root dispatches on the discriminator and preserves each
//     leaf's own `replaySafe`/`intentName`/digest across the round trip;
//   - every `corruptMaps()` entry returns `BoundaryErr` with exact paths,
//     including the missing/unknown discriminator maps;
//   - seeded lists rotate deterministically across all intent subtypes;
//   - per-leaf `replaySafe` and digest stability survive a wire round trip;
//   - a standalone intent (no hierarchy) gets the same surface;
//   - an intent-valued field on an entity decodes through the intent's own
//     `fromWire` and encodes through its `toWire`.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/emission/archetype_composer.dart';
import 'package:zorphy/src/parser/hierarchy_resolver.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

const _annotationImport =
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n";

final _tmpRoot = Directory('test/.intent_wire_tmp');

/// Resolves [sources] the way the generator sees a library.
Future<PolymorphicIr> _resolve(Map<String, String> sources) async {
  final root = _tmpRoot.absolute;
  root.createSync(recursive: true);
  final fixture = root.createTempSync('fixture_');
  for (final entry in sources.entries) {
    File('${fixture.path}/${entry.key}').writeAsStringSync(entry.value);
  }
  final libraryPath = '${fixture.path}/intents.dart';
  final collection = AnalysisContextCollection(includedPaths: [fixture.path]);
  final resolved =
      await collection
              .contextFor(libraryPath)
              .currentSession
              .getResolvedLibrary(libraryPath)
          as ResolvedLibraryResult;
  final ir = HierarchyResolver.resolveLibrary(resolved.element);
  await collection.dispose();
  return ir;
}

/// Composes [ir] through the production composer, writes the fragment next to
/// [sources] and runs [body] as a test program, returning its stdout.
///
/// The composed fragment is the REAL pipeline's output: classes, codecs, mock
/// fixtures and the shared boundary helpers, exactly as build_runner would
/// splice them into the library's shared part.
Future<String> _runComposed(
  PolymorphicIr ir,
  Map<String, String> sources,
  String body,
) async {
  final emitted = const ArchetypeComposer().compose(ir);

  final root = _tmpRoot.absolute;
  root.createSync(recursive: true);
  final fixture = root.createTempSync('run_');
  for (final entry in sources.entries) {
    File('${fixture.path}/${entry.key}').writeAsStringSync(entry.value);
  }
  final program =
      '''
$_annotationImport
import 'dart:io';

$emitted

void main() {
  stdout.writeln('==BEGIN==');
$body
  stdout.writeln('==END==');
}
''';
  File('${fixture.path}/main.dart').writeAsStringSync(program);

  final result = await Process.run(Platform.resolvedExecutable, [
    'run',
    '${fixture.path}/main.dart',
  ], workingDirectory: fixture.path);
  if (result.exitCode != 0) {
    fail(
      'composed program failed (exit ${result.exitCode})\n'
      '--- stdout ---\n${result.stdout}\n'
      '--- stderr ---\n${result.stderr}\n'
      '--- composed ---\n$emitted',
    );
  }
  final out = result.stdout as String;
  final begin = out.indexOf('==BEGIN==');
  final end = out.indexOf('==END==');
  if (begin < 0 || end < 0) {
    fail('composed program produced no marker block\n$out\n$emitted');
  }
  return out.substring(begin + '==BEGIN=='.length, end).trim();
}

/// The issue's consumer reproduction: a sealed intent root, two leaves with
/// their own `replaySafe` decisions, and a standalone intent with a nullable
/// field. `$Checkout` carries an intent-valued field, so the entity codec must
/// decode it through the intent's own `fromWire`.
const _fixtures =
    '''
$_annotationImport
part 'intents.zorphy.dart';

@ZorphyIntent(replaySafe: false)
abstract class \$ProductIntent {
  String get productId;
}

@ZorphyIntent(replaySafe: true)
abstract class \$InspectProductIntent implements \$ProductIntent {}

@ZorphyIntent(replaySafe: false)
abstract class \$DeleteProductIntent implements \$ProductIntent {
  String get reason;
}

@ZorphyIntent(replaySafe: true)
abstract class \$PingIntent {
  String get nonce;
  String? get note;
}

@ZorphyEntity(principalKey: #id)
abstract class \$Checkout {
  String get id;
  \$ProductIntent? get pending;
}

// #242 review: nullable collection elements/values must survive the wire
// round trip instead of being dropped by the decode guard.
@ZorphyIntent(replaySafe: false)
abstract class \$NullableCollectionsIntent {
  List<String?>? get items;
  Map<String, String?>? get labels;
}
''';

Map<String, String> _lines(String out) => {
  for (final line in out.split('\n'))
    if (line.contains('='))
      line.substring(0, line.indexOf('=')): line.substring(
        line.indexOf('=') + 1,
      ),
};

void main() {
  late PolymorphicIr ir;

  setUpAll(() async {
    ir = await _resolve({'intents.dart': _fixtures});
    expect(
      ir.diagnostics.map((d) => d.codeName),
      isEmpty,
      reason: 'the canonical fixture must resolve clean',
    );
  });

  tearDownAll(() {
    final root = _tmpRoot.absolute;
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('#232 — intent fromWire round-trips', () {
    test('every leaf round-trips through fromWire(intent.toWire())', () async {
      final out = await _runComposed(
        ir,
        {'intents.dart': _fixtures},
        '''
  final inspect = InspectProductIntent(productId: 'p-1');
  final delete = DeleteProductIntent(productId: 'p-2', reason: 'duplicate');

  final inspectBack = InspectProductIntent.fromWire(inspect.toWire());
  stdout.writeln('inspectOk=' + (inspectBack is BoundaryOk).toString());
  if (inspectBack is BoundaryOk<InspectProductIntent>) {
    final v = inspectBack.value;
    stdout.writeln('inspectProduct=' + v.productId);
    stdout.writeln('inspectName=' + v.intentName);
    stdout.writeln('inspectSafe=' + v.replaySafe.toString());
    stdout.writeln('inspectDigestSame=' +
        (v.intentDigest() == inspect.intentDigest()).toString());
  }

  final deleteBack = DeleteProductIntent.fromWire(delete.toWire());
  stdout.writeln('deleteOk=' + (deleteBack is BoundaryOk).toString());
  if (deleteBack is BoundaryOk<DeleteProductIntent>) {
    final v = deleteBack.value;
    stdout.writeln('deleteReason=' + v.reason);
    stdout.writeln('deleteName=' + v.intentName);
    stdout.writeln('deleteSafe=' + v.replaySafe.toString());
    stdout.writeln('deleteDigestSame=' +
        (v.intentDigest() == delete.intentDigest()).toString());
  }
''',
      );

      final lines = _lines(out);
      expect(lines['inspectOk'], 'true');
      expect(lines['inspectProduct'], 'p-1');
      expect(lines['inspectName'], 'inspect_product_intent');
      expect(lines['inspectSafe'], 'true', reason: 'leaf replaySafe preserved');
      expect(
        lines['inspectDigestSame'],
        'true',
        reason: 'digest stability across the wire round trip',
      );
      expect(lines['deleteOk'], 'true');
      expect(lines['deleteReason'], 'duplicate');
      expect(lines['deleteName'], 'delete_product_intent');
      expect(lines['deleteSafe'], 'false');
      expect(lines['deleteDigestSame'], 'true');
    });

    test('the sealed root dispatches on the discriminator', () async {
      final out = await _runComposed(
        ir,
        {'intents.dart': _fixtures},
        '''
  final inspect = InspectProductIntent(productId: 'p-1');
  final delete = DeleteProductIntent(productId: 'p-3', reason: 'stale');

  final a = ProductIntent.fromWire(inspect.toWire());
  stdout.writeln('aType=' + (a is BoundaryOk<ProductIntent>
      ? a.value.runtimeType.toString() : a.toString()));
  if (a is BoundaryOk<ProductIntent>) {
    stdout.writeln('aSafe=' + a.value.replaySafe.toString());
    stdout.writeln('aDigestSame=' +
        (a.value.intentDigest() == inspect.intentDigest()).toString());
  }

  final b = ProductIntent.fromWire(delete.toWire());
  if (b is BoundaryOk<ProductIntent>) {
    stdout.writeln('bType=' + b.value.runtimeType.toString());
    stdout.writeln('bSafe=' + b.value.replaySafe.toString());
  }

  final missing = ProductIntent.fromWire({'productId': 'p-1'});
  stdout.writeln('missingErr=' + (missing is BoundaryErr).toString());
  if (missing is BoundaryErr<ProductIntent>) {
    stdout.writeln('missingPaths=' +
        missing.violations.map((v) => v.path).join(','));
  }

  final unknown = ProductIntent.fromWire({
    'kind': '__unknown_discriminator__',
    'productId': 'p-1',
  });
  stdout.writeln('unknownErr=' + (unknown is BoundaryErr).toString());
''',
      );

      final lines = _lines(out);
      expect(lines['aType'], 'InspectProductIntent');
      expect(lines['aSafe'], 'true', reason: 'per-leaf replay metadata');
      expect(lines['aDigestSame'], 'true');
      expect(lines['bType'], 'DeleteProductIntent');
      expect(lines['bSafe'], 'false');
      expect(lines['missingErr'], 'true', reason: 'missing discriminator');
      expect(lines['missingPaths'], '/kind');
      expect(lines['unknownErr'], 'true', reason: 'unknown discriminator');
    });

    test('nullable fields survive the round trip in both states', () async {
      final out = await _runComposed(
        ir,
        {'intents.dart': _fixtures},
        '''
  final withNote = PingIntent(nonce: 'n-1', note: 'hi');
  final withoutNote = PingIntent(nonce: 'n-2');

  final back1 = PingIntent.fromWire(withNote.toWire());
  if (back1 is BoundaryOk<PingIntent>) {
    stdout.writeln('note=' + (back1.value.note ?? 'NULL'));
    stdout.writeln('digest1Same=' +
        (back1.value.intentDigest() == withNote.intentDigest()).toString());
  }
  final back2 = PingIntent.fromWire(withoutNote.toWire());
  if (back2 is BoundaryOk<PingIntent>) {
    stdout.writeln('absent=' + (back2.value.note ?? 'NULL'));
    stdout.writeln('digest2Same=' +
        (back2.value.intentDigest() == withoutNote.intentDigest()).toString());
  }
''',
      );

      final lines = _lines(out);
      expect(lines['note'], 'hi');
      expect(lines['digest1Same'], 'true');
      expect(lines['absent'], 'NULL');
      expect(lines['digest2Same'], 'true');
    });
  });

  group('#232 — <Intent>WireFixtures', () {
    test('validMap decodes; every corruptMaps entry is a BoundaryErr with '
        'exact paths', () async {
      final out = await _runComposed(
        ir,
        {'intents.dart': _fixtures},
        '''
  var validOk = 0;
  for (var seed = 0; seed < 4; seed++) {
    final wire = ProductIntentWireFixtures.validMap(seed: seed);
    final back = ProductIntent.fromWire(wire);
    if (back is BoundaryOk<ProductIntent>) validOk++;
  }
  stdout.writeln('validOk=' + validOk.toString());

  final paths = <String>[];
  var corruptOk = 0;
  for (final map in ProductIntentWireFixtures.corruptMaps()) {
    final back = ProductIntent.fromWire(map);
    if (back is BoundaryErr<ProductIntent>) {
      for (final v in back.violations) {
        paths.add(v.path);
      }
    } else {
      corruptOk++;
    }
  }
  stdout.writeln('corruptOk=' + corruptOk.toString());
  stdout.writeln('rootPaths=' + paths.toSet().join('|'));

  final leafPaths = <String>[];
  var leafErr = 0;
  for (final map in InspectProductIntentWireFixtures.corruptMaps()) {
    final back = InspectProductIntent.fromWire(map);
    if (back is BoundaryErr<InspectProductIntent>) leafErr++;
    for (final v in (back as BoundaryErr).violations) {
      leafPaths.add(v.path);
    }
  }
  stdout.writeln('leafErr=' + leafErr.toString());
  stdout.writeln('leafPaths=' + leafPaths.toSet().join('|'));

  final pingValid = PingIntent.fromWire(PingIntentWireFixtures.validMap());
  stdout.writeln('pingValidOk=' + (pingValid is BoundaryOk).toString());
  var pingErr = 0;
  for (final map in PingIntentWireFixtures.corruptMaps()) {
    if (PingIntent.fromWire(map) is BoundaryErr) pingErr++;
  }
  stdout.writeln('pingErr=' + pingErr.toString());
''',
      );

      final lines = _lines(out);
      expect(
        lines['validOk'],
        '4',
        reason: 'every seed of validMap decodes clean through the rotation',
      );
      expect(
        lines['corruptOk'],
        '0',
        reason: 'the gate: 100% of corruptMaps return BoundaryErr',
      );
      expect(
        lines['rootPaths'],
        contains('/kind'),
        reason: 'missing/unknown discriminator report the exact tag path',
      );
      expect(
        lines['rootPaths'],
        contains('/productId'),
        reason: 'required-field corruption reports the exact field path',
      );
      expect(
        lines['rootPaths'],
        contains('/reason'),
        reason: 'every leaf payload is covered by the root fixtures',
      );
      expect(lines['leafErr'], isNot('0'));
      expect(lines['pingValidOk'], 'true');
      expect(lines['pingErr'], isNot('0'));
    });
  });

  group('#232 — <Intent>MockData', () {
    test('seeded lists rotate deterministically across all subtypes', () async {
      final out = await _runComposed(
        ir,
        {'intents.dart': _fixtures},
        '''
  final list = ProductIntentMockData.list(count: 6);
  stdout.writeln('len=' + list.length.toString());
  stdout.writeln('types=' +
      list.map((i) => i.runtimeType.toString()).join(','));
  stdout.writeln('names=' + list.map((i) => i.intentName).join(','));

  final again = ProductIntentMockData.list(count: 6);
  var same = list.length == again.length;
  for (var i = 0; i < list.length && same; i++) {
    same = list[i].intentDigest() == again[i].intentDigest();
  }
  stdout.writeln('deterministic=' + same.toString());

  final single = ProductIntentMockData.single(seed: 1);
  stdout.writeln('singleType=' + single.runtimeType.toString());

  final pings = PingIntentMockData.list(count: 3);
  stdout.writeln('pingSeed=' + pings.first.nonce);

  final pingsAgain = PingIntentMockData.list(count: 3);
  stdout.writeln('pingDeterministic=' +
      (pings.first.intentDigest() == pingsAgain.first.intentDigest())
          .toString());
''',
      );

      final lines = _lines(out);
      expect(lines['len'], '6');
      expect(
        lines['types'],
        'InspectProductIntent,DeleteProductIntent,InspectProductIntent,'
        'DeleteProductIntent,InspectProductIntent,DeleteProductIntent',
        reason: 'seed % leaves rotates across every concrete leaf',
      );
      expect(lines['deterministic'], 'true');
      expect(lines['singleType'], 'DeleteProductIntent');
      expect(lines['pingSeed'], startsWith('nonce-'));
      expect(lines['pingDeterministic'], 'true');
    });

    test('MockData seeds feed the wire fixtures consistently', () async {
      final out = await _runComposed(
        ir,
        {'intents.dart': _fixtures},
        '''
  final seeded = ProductIntentMockData.single(seed: 0);
  final wire = ProductIntentWireFixtures.validMap(seed: 0);
  final back = ProductIntent.fromWire(wire);
  var same = back is BoundaryOk<ProductIntent>;
  if (back is BoundaryOk<ProductIntent>) {
    same = back.value.intentDigest() == seeded.intentDigest();
  }
  stdout.writeln('fixtureMatchesMock=' + same.toString());
''',
      );

      expect(_lines(out)['fixtureMatchesMock'], 'true');
    });
  });

  group('#232 — intent-valued nested fields decode through the codec', () {
    test('an entity field typed as an intent round-trips decoded', () async {
      final out = await _runComposed(
        ir,
        {'intents.dart': _fixtures},
        '''
  final inspect = InspectProductIntent(productId: 'p-9');
  final checkout = Checkout.fromTrusted(id: 'c-1', pending: inspect);

  final wire = checkout.toWire();
  stdout.writeln('pendingIsMap=' + (wire['pending'] is Map).toString());

  final back = Checkout.fromWire(wire);
  stdout.writeln('checkoutOk=' + (back is BoundaryOk).toString());
  if (back is BoundaryOk<Checkout>) {
    final pending = back.value.pending;
    stdout.writeln('pendingType=' +
        (pending is InspectProductIntent ? 'decoded' : 'other'));
    if (pending is InspectProductIntent) {
      stdout.writeln('pendingProduct=' + pending.productId);
      stdout.writeln('pendingDigestSame=' +
          (pending.intentDigest() == inspect.intentDigest()).toString());
    }
  }

  // A corrupt nested intent yields a BoundaryErr re-pathed under the field.
  final corruptWire = Map<String, Object?>.of(checkout.toWire())
    ..['pending'] = 'not-an-intent';
  final corrupt = Checkout.fromWire(corruptWire);
  stdout.writeln('corruptErr=' + (corrupt is BoundaryErr).toString());
''',
      );

      final lines = _lines(out);
      expect(
        lines['pendingIsMap'],
        'true',
        reason: 'toWire encodes the intent through its own toWire',
      );
      expect(lines['checkoutOk'], 'true');
      expect(
        lines['pendingType'],
        'decoded',
        reason: 'fromWire decodes the nested intent, not a raw wire value',
      );
      expect(lines['pendingProduct'], 'p-9');
      expect(lines['pendingDigestSame'], 'true');
      expect(lines['corruptErr'], 'true');
    });
  });

  group('#242 — review findings', () {
    test('a standalone numeric intent gets its value-exact helper', () async {
      // The composed program must COMPILE: with helper selection using the
      // entity/value (widening) config for every node, a `num`-only intent
      // referenced `_boundaryAs<num>` without the helper being emitted. A
      // DEDICATED fixture (no scalar fields) isolates that selection — the
      // shared fixture's `String` fields would emit `_boundaryAs` anyway.
      final numericSource = '''
$_annotationImport
part 'intents.zorphy.dart';

@ZorphyIntent(replaySafe: true)
abstract class \$AmountIntent {
  num get amount;
}
''';
      final numericIr = await _resolve({'intents.dart': numericSource});
      final out = await _runComposed(
        numericIr,
        {'intents.dart': numericSource},
        '''
  final amount = AmountIntent(amount: 2);
  final back = AmountIntent.fromWire(amount.toWire());
  stdout.writeln('ok=' + (back is BoundaryOk).toString());
  if (back is BoundaryOk<AmountIntent>) {
    stdout.writeln('amount=' + back.value.amount.toString());
    stdout.writeln('intExact=' + (back.value.amount is int).toString());
    stdout.writeln('digestSame=' +
        (back.value.intentDigest() == amount.intentDigest()).toString());
  }
''',
      );

      final lines = _lines(out);
      expect(lines['ok'], 'true');
      expect(lines['amount'], '2');
      expect(
        lines['intExact'],
        'true',
        reason: 'widenNumbers:false keeps the int 2 distinct from 2.0',
      );
      expect(lines['digestSame'], 'true');
    });

    test('nullable list/map elements survive the round trip', () async {
      final out = await _runComposed(
        ir,
        {'intents.dart': _fixtures},
        '''
  final value = NullableCollectionsIntent(
    items: ['a', null, 'c'],
    labels: {'k': null, 'v': 'x'},
  );
  final back = NullableCollectionsIntent.fromWire(value.toWire());
  stdout.writeln('ok=' + (back is BoundaryOk).toString());
  if (back is BoundaryOk<NullableCollectionsIntent>) {
    stdout.writeln('items=' + back.value.items.toString());
    stdout.writeln('labels=' + back.value.labels.toString());
    stdout.writeln('digestSame=' +
        (back.value.intentDigest() == value.intentDigest()).toString());
  }
''',
      );

      final lines = _lines(out);
      expect(lines['ok'], 'true');
      expect(lines['items'], '[a, null, c]');
      expect(lines['labels'], '{k: null, v: x}');
      expect(lines['digestSame'], 'true');
    });
  });
}
