// Regression test for issue #142:
// "zorphy: generated sealed base cannot be implemented outside its library
//  (multi-file hierarchies fail)"
//
// Symptom: `@Zorphy() abstract class $$ShadNode` in one file generates
// `sealed class ShadNode`, and a subtype declared in ANOTHER file
// (`@Zorphy() abstract class $ButtonNode implements $$ShadNode`) generates
// `class ButtonNode implements ShadNode`. Dart rejects that:
//
//   button_node.zorphy.dart:12:29: Error: The class 'ShadNode' can't be
//   extended, implemented, or mixed in outside of its library because it's a
//   sealed class.
//
// Root cause: zorphy always emitted the `$$` base as Dart `sealed`, which
// restricts subtyping to the declaring library, while the generator emits one
// library per source file — so a hierarchy split across files could never
// compile, and the generator offered no way to opt out short of `nonSealed`.
//
// Fix: seal the generated base only when sealing can buy anything — at least
// one subtype is declared in the SAME library — and never when a known
// subtype lives in another library. Otherwise emit `abstract`, which is
// implementable from any library.
//
// The tests drive the REAL pipeline (resolved ClassElement -> ClassAnalyzer ->
// Orchestrator.generate) over two-library fixtures and then run the analyzer
// over the generated sources, so the reported compile error is reproduced
// end-to-end.

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

/// The exact shape from the issue: the `$$` base lives in its own library and
/// the concrete node is declared in a second library that implements it.
const _baseSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'base_node.zorphy.dart';

@Zorphy()
abstract class \$\$ShadNode {
  String get id;
}
''';

const _buttonSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'base_node.dart';

part 'button_node.zorphy.dart';

@Zorphy()
abstract class \$ButtonNode implements \$\$ShadNode {
  String get label;
}
''';

/// Control shape: base and subtype in the SAME library, where `sealed` is
/// both legal and useful (switch exhaustiveness) — that behaviour must not be
/// relaxed by the #142 fix.
const _sameLibrarySource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'same_library_nodes.zorphy.dart';

@Zorphy()
abstract class \$\$Shape {
  double get area;
}

@Zorphy()
abstract class \$Circle implements \$\$Shape {
  double get radius;
}
''';

/// Resolves [libraryPath] and generates the `.zorphy.dart` output for
/// [className] through the real pipeline.
Future<String> _generate(
  Directory fixtureDir,
  String libraryPath,
  String className,
) async {
  final collection = AnalysisContextCollection(
    includedPaths: [fixtureDir.path],
  );
  final ctx = collection.contextFor(libraryPath);
  final result = await ctx.currentSession.getResolvedUnit(
    libraryPath,
  ) as ResolvedUnitResult;
  final element = result.libraryElement.getClass(className);
  expect(element, isNotNull, reason: 'class $className not resolved');
  final annotationReader = ConstantReader(
    _zorphyChecker.firstAnnotationOf(element!)!,
  );

  final graph = ClassGraph.fromLibraryClasses(
    result.libraryElement.classes.toList(),
    library: result.libraryElement,
  );

  final metadata = ClassAnalyzer.analyze(
    element,
    annotationReader,
    graph.annotated,
    graph.classesInExplicitSubtypes,
  );

  final ownFields = element.children
      .whereType<FieldElement>()
      .where((f) => f.name != 'hashCode' && f.name != 'runtimeType')
      .map((f) => f.name ?? '')
      .toSet();
  final options = AnnotationParser.parse(annotationReader);
  final config = GenerationConfig.fromAnnotationOptions(
    options,
    outputExtension: '.zorphy.dart',
    factoryMethods: metadata.factoryMethods,
    ownFields: ownFields,
  );

  final output = Orchestrator.generate(
    element,
    annotationReader,
    graph.annotated,
    config,
    graph.classesInExplicitSubtypes,
  );
  await collection.dispose();
  return output;
}

/// Writes [generated] next to the library as its generated part file.
///
/// `Orchestrator.generate` returns the part BODY only — the `part of`
/// directive is added by the build_runner wrapper in production, so the
/// fixture supplies it here to analyze the same shape the generator emits.
void _writePart(
  Directory fixtureDir,
  String libraryName,
  String partName,
  String generated,
) {
  File('${fixtureDir.path}/$partName')
      .writeAsStringSync("part of '$libraryName';\n\n$generated");
}

/// Every diagnostic the analyzer reports for the libraries at [libraryPaths]
/// (including their generated part files), formatted as
/// `<file>:<offset>: <code> — <message>`.
Future<List<String>> _diagnostics(
  Directory fixtureDir,
  List<String> libraryPaths,
) async {
  final collection = AnalysisContextCollection(
    includedPaths: [fixtureDir.path],
  );
  final diagnostics = <String>[];
  for (final path in libraryPaths) {
    final ctx = collection.contextFor(path);
    final library = await ctx.currentSession.getResolvedLibrary(
      path,
    ) as ResolvedLibraryResult;
    for (final unit in library.units) {
      for (final diagnostic in unit.diagnostics) {
        diagnostics.add(
          '${unit.path.split('/').last}:'
          '${diagnostic.problemMessage.offset}: '
          '${diagnostic.diagnosticCode.lowerCaseName} — '
          '${diagnostic.problemMessage.messageText(includeUrl: false)}',
        );
      }
    }
  }
  await collection.dispose();
  return diagnostics;
}

void main() {
  group('issue #142 — cross-library sealed base', () {
    late Directory fixtureDir;
    late String baseOutput;
    late String buttonOutput;
    late List<String> diagnostics;

    setUpAll(() async {
      final root = Directory('test/.issue_142_tmp').absolute.path;
      fixtureDir = Directory(root)..createSync(recursive: true);
      fixtureDir = fixtureDir.createTempSync('fixture_');

      final basePath = '${fixtureDir.path}/base_node.dart';
      final buttonPath = '${fixtureDir.path}/button_node.dart';
      File(basePath).writeAsStringSync(_baseSource);
      File(buttonPath).writeAsStringSync(_buttonSource);

      // The base first: its generated part must exist before the subtype
      // library (which imports it) is resolved.
      baseOutput = await _generate(fixtureDir, basePath, r'$$ShadNode');
      _writePart(
        fixtureDir,
        'base_node.dart',
        'base_node.zorphy.dart',
        baseOutput,
      );

      buttonOutput = await _generate(fixtureDir, buttonPath, r'$ButtonNode');
      _writePart(
        fixtureDir,
        'button_node.dart',
        'button_node.zorphy.dart',
        buttonOutput,
      );

      diagnostics = await _diagnostics(fixtureDir, [basePath, buttonPath]);
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
      final tmp = Directory('test/.issue_142_tmp');
      if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
    });

    test('base with no same-library subtype is emitted `abstract`, not '
        '`sealed`', () {
      // THE BUG: `sealed class ShadNode` is only implementable inside
      // base_node.dart, so the sibling library can never compile.
      expect(
        baseOutput,
        isNot(contains('sealed class ShadNode')),
        reason: 'a base whose subtypes live in another library must stay open',
      );
      expect(baseOutput, contains('abstract class ShadNode'));
    });

    test('subtype in another library implements the base', () {
      expect(buttonOutput, contains('class ButtonNode implements ShadNode'));
    });

    test('generated two-library hierarchy analyzes with no sealed error', () {
      // The exact symptom from the issue:
      //   The class 'ShadNode' can't be extended, implemented, or mixed in
      //   outside of its library because it's a sealed class.
      expect(
        diagnostics.where(
          (d) => d.contains('invalid_use_of_type_outside_library'),
        ),
        isEmpty,
        reason: 'diagnostics:\n${diagnostics.join('\n')}',
      );
    });
  });

  group('issue #142 — same-library sealed base is preserved', () {
    late Directory fixtureDir;
    late String output;

    setUpAll(() async {
      final root = Directory('test/.issue_142_same_lib_tmp').absolute.path;
      fixtureDir = Directory(root)..createSync(recursive: true);
      fixtureDir = fixtureDir.createTempSync('fixture_');

      final libraryPath = '${fixtureDir.path}/same_library_nodes.dart';
      File(libraryPath).writeAsStringSync(_sameLibrarySource);

      output = await _generate(fixtureDir, libraryPath, r'$$Shape');
      _writePart(
        fixtureDir,
        'same_library_nodes.dart',
        'same_library_nodes.zorphy.dart',
        output,
      );
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
      final tmp = Directory('test/.issue_142_same_lib_tmp');
      if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
    });

    test('base implemented in the same library still seals', () {
      expect(
        output,
        contains('sealed class Shape'),
        reason: 'switch exhaustiveness inside one library must keep working',
      );
    });
  });
}
