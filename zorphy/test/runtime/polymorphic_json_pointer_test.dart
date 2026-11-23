// Issue #186 — polymorphic, zero-reflection JSON-Pointer resolution.
//
// Every generated Zorphy class exposes
// `static ZorphyLens<T, Object?>? resolvePath(String pointer)`, a
// compile-time switch table over the class's own JSON-Pointer segments.
// A pointer that names a field returns a lens whose `get` dispatches on the
// RUNTIME subtype, so:
//
//  * a pointer naming a shared interface field (`/contractId`) resolves for a
//    node of ANY subtype in the hierarchy, and
//  * a pointer naming a subtype-specific field (`/enabled`) resolves through
//    runtime dispatch and answers `null` — never throws — on a subtype that
//    does not carry it.
//
// Resolution is O(path depth): one switch step per segment, no regex, no
// `dart:mirrors`, and no reflective field lookup.
//
// The pipeline is driven end-to-end (resolved ClassElement -> ClassAnalyzer ->
// Orchestrator.generate), so this pins the REAL generator, not a hand-built
// spec. The emitted parts are additionally handed to the analyzer, so a
// `resolvePath` that does not compile can never reach consumers.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/analysis/annotation_parser.dart';
import 'package:zorphy/src/analysis/class_analyzer.dart';
import 'package:zorphy/src/analysis/class_graph.dart';
import 'package:zorphy/src/models/generation_config.dart';
import 'package:zorphy/src/orchestrator.dart';

const _zorphyChecker = TypeChecker.fromUrl(
  'package:zorphy_annotation/src/annotations.dart#Zorphy',
);

/// The issue's exact hierarchy shape: a shared root carrying `/contractId`,
/// an intermediate node adding `/enabled`, and a leaf that is a SIBLING of the
/// interactive branch (so `/enabled` is inapplicable to it).
const _hierarchy = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'ui_node.zorphy.dart';

@Zorphy(explicitSubTypes: [\$InteractiveUiNode, \$ZfaTextNode])
abstract class \$UiNode {
  String get contractId;
}

@Zorphy(explicitSubTypes: [\$ZfaButtonNode])
abstract class \$InteractiveUiNode implements \$UiNode {
  bool get enabled;
}

@Zorphy()
abstract class \$ZfaButtonNode implements \$InteractiveUiNode {
  String get label;
}

@Zorphy()
abstract class \$ZfaTextNode implements \$UiNode {
  String get text;
}

@Zorphy()
abstract class \$EditDraft {
  String get title;
  double get price;
}

@Zorphy()
abstract class \$ProductUiState {
  EditDraft get editDraft;
  int get selectedTab;
}
''';

/// Generates every `@Zorphy` class of the fixture library.
Future<Map<String, String>> _generateHierarchy(Directory fixtureDir) async {
  final source = File('${fixtureDir.path}/ui_node.dart')
    ..writeAsStringSync(_hierarchy);
  final collection = AnalysisContextCollection(includedPaths: [source.path]);
  final outputs = <String, String>{};
  try {
    final result =
        await collection
                .contextFor(source.path)
                .currentSession
                .getResolvedUnit(source.path)
            as ResolvedUnitResult;
    final graph = ClassGraph.fromLibraryClasses(
      result.libraryElement.classes.toList(),
      library: result.libraryElement,
    );
    for (final element in result.libraryElement.classes) {
      final annotation = _zorphyChecker.firstAnnotationOf(element);
      if (annotation == null) continue;
      final reader = ConstantReader(annotation);
      final metadata = ClassAnalyzer.analyze(
        element,
        reader,
        graph.annotated,
        graph.classesInExplicitSubtypes,
      );
      final ownFields = element.children
          .whereType<FieldElement>()
          .where((f) => f.name != 'hashCode' && f.name != 'runtimeType')
          .map((f) => f.name ?? '')
          .toSet();
      final config = GenerationConfig.fromAnnotationOptions(
        AnnotationParser.parse(reader),
        outputExtension: '.zorphy.dart',
        factoryMethods: metadata.factoryMethods,
        ownFields: ownFields,
      );
      final name = (element.name ?? element.displayName).replaceAll(r'$', '');
      outputs[name] = Orchestrator.generate(
        element,
        reader,
        graph.annotated,
        config,
        graph.classesInExplicitSubtypes,
      );
    }
  } finally {
    await collection.dispose();
  }
  return outputs;
}

/// Analyzer diagnostics for the fixture library, so an emitted `resolvePath`
/// that does not compile fails here instead of at a consumer's `dart analyze`.
Future<List<String>> _diagnostics(String libraryPath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [Directory(libraryPath).parent.path],
  );
  final diagnostics = <String>[];
  try {
    final library =
        await collection
                .contextFor(libraryPath)
                .currentSession
                .getResolvedLibrary(libraryPath)
            as ResolvedLibraryResult;
    for (final unit in library.units) {
      for (final diagnostic in unit.diagnostics) {
        diagnostics.add(
          '${libraryPath.split('/').last}: '
          '${diagnostic.diagnosticCode.lowerCaseName} — '
          '${diagnostic.problemMessage.messageText(includeUrl: false)}',
        );
      }
    }
  } finally {
    await collection.dispose();
  }
  return diagnostics;
}

void main() {
  late Directory fixtureDir;
  late Map<String, String> outputs;

  setUpAll(() async {
    final base = Directory('test/.issue_186_tmp').absolute.path;
    Directory(base).createSync(recursive: true);
    fixtureDir = Directory(base).createTempSync('fixture_');
    outputs = await _generateHierarchy(fixtureDir);
  });

  tearDownAll(() {
    if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
    final tmp = Directory('test/.issue_186_tmp');
    if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
  });

  String outputFor(String className) {
    final output = outputs[className];
    expect(
      output,
      isNotNull,
      reason: 'no generated output for $className; got ${outputs.keys}',
    );
    return output!;
  }

  group('resolvePath — emitted contract', () {
    test('every class in the hierarchy declares the static entry point', () {
      for (final className in const [
        'UiNode',
        'InteractiveUiNode',
        'ZfaButtonNode',
        'ZfaTextNode',
      ]) {
        expect(
          outputFor(className),
          contains(
            'static ZorphyLens<$className, Object?>? resolvePath('
            'String pointer)',
          ),
          reason: '$className must expose the issue\'s exact signature',
        );
      }
    });

    test('shared interface pointers resolve on every subtype', () {
      // `/contractId` is declared on $UiNode, so every subtype's table must
      // answer it — that is what makes `UiNode.resolvePath('/contractId')`
      // work for a button and a text node alike.
      for (final className in const [
        'UiNode',
        'InteractiveUiNode',
        'ZfaButtonNode',
        'ZfaTextNode',
      ]) {
        expect(
          outputFor(className),
          contains("'/contractId' =>"),
          reason: '$className must resolve the shared `/contractId` pointer',
        );
      }
    });

    test(
      'subtype-specific pointers resolve only where they are applicable',
      () {
        // A button carries `label`, and `/enabled` belongs to the interactive
        // branch; a text node carries `text` and nothing interactive.
        expect(outputFor('ZfaButtonNode'), contains("'/label' =>"));
        expect(outputFor('ZfaButtonNode'), contains("'/enabled' =>"));
        expect(outputFor('ZfaTextNode'), contains("'/text' =>"));
        expect(
          outputFor('ZfaTextNode'),
          isNot(contains("'/enabled' =>")),
          reason: 'a text node is not interactive — it must not advertise it',
        );
        expect(outputFor('ZfaTextNode'), isNot(contains("'/label' =>")));
      },
    );

    test('runtime dispatch answers null on an inapplicable subtype', () {
      // The switch must dispatch on the RUNTIME subtype, not assume the
      // receiver is the class that declared the segment: resolving
      // `/enabled` through the `UiNode` table on a text node answers null
      // rather than throwing.
      expect(
        outputFor('UiNode'),
        contains("'/enabled' =>"),
        reason: 'the root table dispatches interactive segments too',
      );
      expect(
        outputFor('UiNode'),
        matches(RegExp(r"'/enabled' => [\s\S]{0,600}?default:\s*return null;")),
        reason: 'the interactive branch must fall through to null',
      );
    });

    test('unknown pointers answer null instead of throwing', () {
      for (final className in const ['UiNode', 'ZfaTextNode']) {
        expect(
          outputFor(className),
          contains('_ => null,'),
          reason: '$className must answer null for an unmatched pointer',
        );
      }
    });
  });

  group('resolvePath — zero-reflection and zero-regex', () {
    test('no dart:mirrors, no RegExp in any emitted table', () {
      for (final entry in outputs.entries) {
        expect(
          entry.value,
          isNot(contains('dart:mirrors')),
          reason: '${entry.key} emitted reflection',
        );
        expect(
          entry.value,
          isNot(contains('RegExp')),
          reason: '${entry.key} emitted a regex',
        );
      }
    });

    test('nested segments delegate to the nested type', () {
      // The issue's O(depth) contract: `editDraft/price` resolves
      // `editDraft` here and hands `/price` to `EditDraft`'s own table via
      // `then`, so each level pays one switch step.
      final nested = outputFor('ProductUiState');
      expect(
        nested,
        contains('.then('),
        reason: 'a nested segment must delegate through the child lens',
      );
      expect(
        nested,
        contains('EditDraft.resolvePath('),
        reason: 'the remainder must be handed to the nested type',
      );
    });
  });

  group('resolvePath — the emitted parts analyze clean', () {
    test('no analyzer diagnostics for the generated hierarchy', () async {
      // The real builder emits ONE shared part per library, so the fixture's
      // `part 'ui_node.zorphy.dart'` must receive every class's output
      // concatenated — writing a file per class would leave the directive
      // dangling and prove nothing about the emitted `resolvePath`.
      // The real builder prefixes its shared part with these two lint
      // headers (`_withLintHeader` in shared_part_builder.dart): generated
      // `value as String` casts are unavoidable in this API shape and are
      // suppressed fleet-wide, so the fixture carries the same headers or the
      // gate would fail on a diagnostic no real consumer ever sees.
      final part = StringBuffer()
        ..writeln('// ignore_for_file: UNNECESSARY_CAST')
        ..writeln('// ignore_for_file: type=lint')
        ..writeln('part of \'ui_node.dart\';');
      for (final output in outputs.values) {
        part.writeln(output);
      }
      File(
        '${fixtureDir.path}/ui_node.zorphy.dart',
      ).writeAsStringSync(part.toString());
      final diagnostics = await _diagnostics('${fixtureDir.path}/ui_node.dart');
      expect(diagnostics, isEmpty, reason: diagnostics.join('\n'));
    });
  });
}
