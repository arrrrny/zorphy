// Issue #185 — behavioural proof that a nullable lens `set(root, null)` clears
// the field (review finding on PR #201, lens_generator.dart:154).
//
// The generated `copyWith` is `note: note ?? this.note`, so a nullable field's
// old `set` silently dropped an explicit null and broke the put-get law
// documented on [ZorphyLens]. The fix routes the null through the generated
// Patch, whose `containsKey` gate can express it. The sibling tests pin the
// EMITTED shape; this test EXECUTES the generated surface so the behaviour
// itself — field cleared, siblings untouched — is proven, not inferred.
//
// The pipeline is driven end-to-end (resolved ClassElement -> ClassAnalyzer ->
// Orchestrator.generate), the emitted part is analysed clean, and the library
// plus a `main()` that exercises the lens is run with `dart run`.

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

/// `$EditDraft` carries a populated nullable `note` alongside two sibling
/// fields (`title`, `price`) that a `set(note, null)` must leave untouched.
const _fixtureSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'lens_null_fixture.zorphy.dart';

@Zorphy()
abstract class \$EditDraft {
  String get title;
  double get price;
  String? get note;
}
''';

/// Generates every `@Zorphy` class of ONE fixture library, keyed by clean name.
Future<Map<String, String>> _generate(String libraryPath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [Directory(libraryPath).parent.path],
  );
  final outputs = <String, String>{};
  try {
    final result =
        await collection
                .contextFor(libraryPath)
                .currentSession
                .getResolvedUnit(libraryPath)
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

void main() {
  late Directory dir;

  setUpAll(() async {
    // A non-dot directory inside the package tree so `dart run` resolves the
    // package's own `.dart_tool/package_config.json` (and with it
    // `package:zorphy_annotation`).
    final base = Directory('test/lens_null_runtime_tmp').absolute
      ..createSync(recursive: true);
    dir = base.createTempSync('fixture_');
    // Write the source classes first so the analyzer can resolve them, then
    // generate, then append a `main()` that exercises the lens.
    final libFile = File('${dir.path}/lens_null_fixture.dart')
      ..writeAsStringSync(_fixtureSource);
    final generated = await _generate(libFile.path);
    expect(
      generated.keys,
      contains('EditDraft'),
      reason: 'the fixture class must generate; got ${generated.keys}',
    );
    // The generated part: every class's output concatenated.
    File('${dir.path}/lens_null_fixture.zorphy.dart').writeAsStringSync(
      "part of 'lens_null_fixture.dart';\n\n${generated.values.join('\n\n')}",
    );
    // A runnable library: the source classes + the part directive + a `main()`
    // that proves the behaviour.
    libFile.writeAsStringSync(
      _fixtureSource +
          r'''
void main() {
  final draft = EditDraft(title: 'widget', price: 10.0, note: 'saved');
  final cleared = EditDraft.lenses.note.set(draft, null);
  if (cleared.note != null) throw 'note not cleared: ${cleared.note}';
  if (cleared.title != 'widget') throw 'sibling title changed';
  if (cleared.price != 10.0) throw 'sibling price changed';
  // put-get on a non-null value still round-trips.
  final set = EditDraft.lenses.note.set(draft, 'x');
  if (set.note != 'x') throw 'set non-null failed';
  if (EditDraft.lenses.note.get(set) != 'x') throw 'get-after-set failed';
  print('ALL CHECKS PASSED');
}
''',
    );
  });

  tearDownAll(() {
    final tmp = Directory('test/lens_null_runtime_tmp');
    if (tmp.existsSync()) tmp.deleteSync(recursive: true);
  });

  test('set(root, null) clears a nullable field and preserves siblings',
      () async {
    final result = await Process.run('dart', [
      'run',
      '${dir.path}/lens_null_fixture.dart',
    ], workingDirectory: Directory.current.path);
    final stdout = '${result.stdout}\n${result.stderr}';
    expect(stdout, contains('ALL CHECKS PASSED'), reason: stdout);
    expect(result.exitCode, 0, reason: stdout);
  }, timeout: const Timeout(Duration(minutes: 2)));
}