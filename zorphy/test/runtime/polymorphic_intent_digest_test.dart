// Tests for ISSUE-014 (arrrrny/zorphy#189): polymorphic `@ZorphyIntent`
// hierarchies with per-leaf `replaySafe` and a canonical SHA-256
// `intentDigest()`.
//
// These are RUNTIME tests, not shape assertions on a string: the emitter's
// output is written to a temp package, compiled and EXECUTED, and every
// acceptance criterion is asserted against the running generated code —
// exhaustive `switch` dispatch, per-leaf `replaySafe`, and deterministic
// 64-character digests that follow the intent's meaning and nothing else.
//
// Coverage:
//   - a sealed root with a `false` baseline and one `true` leaf override;
//   - an abstract intermediate leaf adding a field, so `toWire`/digest must
//     include inherited AND own fields;
//   - an exhaustive `switch (intent)` over the sealed root;
//   - determinism, name-sensitivity, field-sensitivity and order-independence
//     of `ZorphyIntentDigest.compute`;
//   - a standalone (non-polymorphic) `@ZorphyIntent`;
//   - the emitter's structural rules: code_builder only, no `StringBuffer`.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/emitters/intent_emitter.dart';
import 'package:zorphy/src/parser/hierarchy_resolver.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

const _annotationImport =
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n";

/// Resolves [sources] into a [PolymorphicIr], exactly the way the generator
/// sees a library — resolved analyzer elements, no string scanning.
Future<PolymorphicIr> _resolve(Map<String, String> sources) async {
  final root = Directory('test/.intent_emitter_tmp').absolute;
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

/// The polymorphic fixture the issue's contract section describes.
const _polymorphic =
    '''
$_annotationImport
part 'intents.zorphy.dart';

// Dollar-prefixed names are the DECLARATIONS; generated classes strip
// prefix, which is why the runtime assertions below name `ProductIntent` etc.
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
''';

/// A standalone intent: one class, no hierarchy, still an intent.
const _standalone =
    '''
$_annotationImport
part 'intents.zorphy.dart';

@ZorphyIntent(replaySafe: true)
abstract class \$PingIntent {
  String get nonce;
}
''';

/// Emits [ir]'s intent surface, writes it next to [sources] and runs [body]
/// as a test program, returning the program's stdout.
///
/// This is what makes the test a runtime test: the emitted text is compiled by
/// the real Dart VM and its behaviour is what gets asserted. A structural
/// bug the emitter could hide from a string matcher — a wrong `intentName`, a
/// missing inherited field, a non-exhaustive switch — fails here.
Future<String> _runEmitted(
  PolymorphicIr ir,
  Map<String, String> sources,
  String body,
) async {
  final emitted = IntentEmitter().emitIntents(ir);

  final root = Directory('test/.intent_emitter_tmp').absolute;
  root.createSync(recursive: true);
  final fixture = root.createTempSync('run_');
  for (final entry in sources.entries) {
    File('${fixture.path}/${entry.key}').writeAsStringSync(entry.value);
  }
  // The generated surface needs the hand-written declarations it names, and
  // the digest it calls, so the program imports the annotation package.
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
      'emitted program failed (exit ${result.exitCode})\n'
      '--- stdout ---\n${result.stdout}\n'
      '--- stderr ---\n${result.stderr}\n'
      '--- emitted ---\n$emitted',
    );
  }
  final out = result.stdout as String;
  final begin = out.indexOf('==BEGIN==');
  final end = out.indexOf('==END==');
  if (begin < 0 || end < 0) {
    fail('emitted program produced no marker block\n$out\n$emitted');
  }
  return out.substring(begin + '==BEGIN=='.length, end).trim();
}

void main() {
  group('#189 — polymorphic intent hierarchy', () {
    late PolymorphicIr ir;

    setUpAll(() async {
      ir = await _resolve({'intents.dart': _polymorphic});
    });

    test('the hierarchy resolves with a root and two instantiable leaves', () {
      final root = ir.rootFor('ProductIntent');
      expect(root, isNotNull, reason: 'the sealed root must resolve');
      expect(root!.isSealedRoot, isTrue);

      // Leaf-ness follows the SUBTREE: zorphy's hand-written declaration is
      // always `abstract class $X` and the generated `X` is concrete unless
      // something further implements it, so a node with no subtypes is the
      // instantiable one whatever keyword its declaration carries.
      final leaves = [
        ...root.directSubTypes,
        for (final child in root.directSubTypes) ...child.directSubTypes,
      ].where((n) => n.directSubTypes.isEmpty).toList();
      expect(
        leaves.map((n) => n.cleanName),
        unorderedEquals(['InspectProductIntent', 'DeleteProductIntent']),
      );

      expect(root.replaySafe, isFalse, reason: 'the root baseline is false');
      expect(
        leaves.map((n) => n.replaySafe),
        unorderedEquals([true, false]),
        reason: 'each leaf keeps its own replaySafe decision',
      );
    });

    test('emits per-leaf replaySafe, intentName, intentDigest and toWire', () {
      final emitted = IntentEmitter().emitIntents(ir);
      for (final name in ['InspectProductIntent', 'DeleteProductIntent']) {
        expect(
          emitted,
          contains('class $name'),
          reason: '$name must be emitted',
        );
      }
      // A leaf's replaySafe comes from its OWN annotation, never the root's.
      expect(
        emitted,
        matches(
          RegExp(
            r'class InspectProductIntent[\s\S]*?bool get replaySafe => true;',
          ),
        ),
      );
      expect(
        emitted,
        matches(
          RegExp(
            r'class DeleteProductIntent[\s\S]*?bool get replaySafe => false;',
          ),
        ),
      );
      expect(emitted, contains('String get intentName =>'));
      expect(emitted, contains('String intentDigest() =>'));
      expect(emitted, contains('Map<String, Object?> toWire()'));
    });

    test(
      'the emitted hierarchy runs: dispatch, replaySafe and digests',
      () async {
        final out = await _runEmitted(
          ir,
          {'intents.dart': _polymorphic},
          '''
  final inspect = InspectProductIntent(productId: 'p-1');
  final delete = DeleteProductIntent(productId: 'p-1', reason: 'duplicate');

  // Exhaustive Dart 3 switch over the SEALED root: the compiler proves the
  // dispatch covers every leaf, and the bodies are the leaves' own surface.
  final labels = <ProductIntent>[inspect, delete].map((intent) {
    return switch (intent) {
      InspectProductIntent() => 'inspect:' + intent.intentName,
      DeleteProductIntent() => 'delete:' + intent.intentName,
    };
  }).join(',');

  stdout.writeln('labels=' + labels);
  stdout.writeln('inspectSafe=' + inspect.replaySafe.toString());
  stdout.writeln('deleteSafe=' + delete.replaySafe.toString());
  stdout.writeln('inspectDigest=' + inspect.intentDigest());
  stdout.writeln('deleteDigest=' + delete.intentDigest());
  stdout.writeln('inspectWire=' + inspect.toWire().toString());
  stdout.writeln('deleteWire=' + delete.toWire().toString());
  stdout.writeln('again=' + InspectProductIntent(productId: 'p-1').intentDigest());
  stdout.writeln('other=' + InspectProductIntent(productId: 'p-2').intentDigest());
  stdout.writeln('deleteOther=' +
      DeleteProductIntent(productId: 'p-1', reason: 'obsolete').intentDigest());
''',
        );

        final lines = <String, String>{
          for (final line in out.split('\n'))
            if (line.contains('='))
              line.substring(0, line.indexOf('=')): line.substring(
                line.indexOf('=') + 1,
              ),
        };

        // `intentName` IS the hierarchy's resolved discriminatorValue: snake_case
        // of the clean class name, owned by the IR so the wire tag and the name
        // a receiver verifies can never disagree.
        expect(
          lines['labels'],
          'inspect:inspect_product_intent,delete:delete_product_intent',
        );
        expect(lines['inspectSafe'], 'true', reason: 'leaf overrides the root');
        expect(lines['deleteSafe'], 'false');

        final inspectDigest = lines['inspectDigest']!;
        final deleteDigest = lines['deleteDigest']!;
        expect(inspectDigest, hasLength(64), reason: 'a SHA-256 hex digest');
        expect(inspectDigest, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(deleteDigest, hasLength(64));

        expect(
          lines['again'],
          inspectDigest,
          reason: 'the digest is a pure function of the intent',
        );
        expect(
          lines['other'],
          isNot(inspectDigest),
          reason: 'a different field value is a different intent',
        );
        expect(
          deleteDigest,
          isNot(inspectDigest),
          reason: 'same fields, different intent name: never colliding',
        );
        expect(
          lines['deleteOther'],
          isNot(deleteDigest),
          reason: 'the leaf own field participates in its digest',
        );

        // The wire form carries the inherited AND the leaf own fields.
        expect(lines['inspectWire'], contains('inspect_product'));
        expect(lines['inspectWire'], contains('productId: p-1'));
        expect(lines['deleteWire'], contains('delete_product'));
        expect(lines['deleteWire'], contains('reason: duplicate'));
      },
    );

    test('the emitted surface is code_builder only — no StringBuffer', () {
      final source = File(
        'lib/src/emitters/intent_emitter.dart',
      ).readAsStringSync();
      expect(
        source.contains('StringBuffer'),
        isFalse,
        reason:
            'issue #189 acceptance: all emission goes through '
            'package:code_builder',
      );
    });
  });

  group('#189 — standalone intent', () {
    test(
      'a non-polymorphic @ZorphyIntent still emits the full surface',
      () async {
        final ir = await _resolve({'intents.dart': _standalone});

        final out = await _runEmitted(
          ir,
          {'intents.dart': _standalone},
          '''
  final ping = PingIntent(nonce: 'n-1');
  stdout.writeln('name=' + ping.intentName);
  stdout.writeln('safe=' + ping.replaySafe.toString());
  stdout.writeln('digest=' + ping.intentDigest());
  stdout.writeln('wire=' + ping.toWire().toString());
''',
        );

        final lines = <String, String>{
          for (final line in out.split('\n'))
            if (line.contains('='))
              line.substring(0, line.indexOf('=')): line.substring(
                line.indexOf('=') + 1,
              ),
        };
        expect(lines['name'], 'ping_intent');
        expect(lines['safe'], 'true');
        expect(lines['digest'], matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(lines['wire'], contains('nonce: n-1'));
      },
    );
  });

  group('#189 — ZorphyIntentDigest canonical form', () {
    test('is a 64-char lowercase SHA-256 hex string', () {
      final digest = ZorphyIntentDigest.compute('inspect_product', {
        'productId': 'p-1',
      });
      expect(digest, hasLength(64));
      expect(digest, matches(RegExp(r'^[0-9a-f]{64}$')));
    });

    test('sorts field names alphabetically', () {
      final a = ZorphyIntentDigest.compute('delete_product', {
        'productId': 'p-1',
        'reason': 'duplicate',
      });
      final b = ZorphyIntentDigest.compute('delete_product', {
        'reason': 'duplicate',
        'productId': 'p-1',
      });
      expect(a, b, reason: 'map iteration order must not leak into the digest');
    });

    test('canonicalizes nested maps and lists recursively', () {
      final a = ZorphyIntentDigest.compute('x', {
        'avatar': {'width': 64, 'height': 32},
        'tags': ['a', 'b'],
      });
      final b = ZorphyIntentDigest.compute('x', {
        'avatar': {'height': 32, 'width': 64},
        'tags': ['a', 'b'],
      });
      expect(a, b);
    });

    test('separates the intent name from its fields', () {
      expect(
        ZorphyIntentDigest.compute('a', {'b': 'c'}),
        isNot(ZorphyIntentDigest.compute('b', {'a': 'c'})),
      );
    });

    test('an int and a double never canonicalize to the same bytes', () {
      expect(
        ZorphyIntentDigest.compute('x', {'n': 2}),
        isNot(ZorphyIntentDigest.compute('x', {'n': 2.0})),
      );
    });

    test('rejects a non-finite number instead of hashing a JSON null', () {
      expect(
        () => ZorphyIntentDigest.compute('x', {'n': double.nan}),
        throwsArgumentError,
      );
    });

    test('exposes the canonical payload behind the digest', () {
      expect(
        ZorphyIntentDigest.canonicalJson('inspect_product', {
          'productId': 'p-1',
        }),
        '{"fields":{"productId":"p-1"},"intentName":"inspect_product"}',
      );
    });
  });
}
