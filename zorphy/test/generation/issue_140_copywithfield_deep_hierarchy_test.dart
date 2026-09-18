// Regression test for issue #140:
// "copyWithField emits an invalid override in hierarchies deeper than 2
//  levels (covariant Field<Child,T> vs inherited Field<Root,T>)"
//
// Symptom: for a `$`-interface chain of depth >= 3 ($Root -> $Mid -> $Leaf),
// the generated `Leaf.copyWithField` declared `Field<Mid, T>` (the class's
// DIRECT parent) while the member it overrides is inherited from the chain
// ROOT, whose own `copyWithField` declares `Field<Root, T>`. Dart class type
// arguments are covariant, so `Field<Mid, T> <: Field<Root, T>` — an
// overriding parameter type must be a SUPERTYPE of the overridden one, so
// the generated file failed analysis:
//
//   Error: The parameter 'field' of the method 'TextListing.copyWithField'
//   has type 'Field<Listing, T>', which does not match the corresponding
//   type, 'Field<ListingOffer, T>', in the overridden method,
//   'ListingOffer.copyWithField'.
//
// Root cause: `CopyWithGenerator.generateSpec` picked
// `metadata.allValueTInterfaces.first` — the direct parent — as the
// `Field<..., T>` entity type. The fix resolves the ROOT of the `$`-interface
// chain (walk the first `$`-interface's supertypes while they are themselves
// `$`-prefixed zorphy interfaces of the collected set), so every descendant
// declares `Field<Root, T>` and the override chain is valid at any depth.
//
// The tests below drive the REAL pipeline end-to-end (resolved ClassElement
// -> ClassAnalyzer -> Orchestrator.generate) on the issue's exact shape: a
// three-level polymorphic hierarchy in one library.

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

/// The issue's exact hierarchy: three levels, each level implementing the
/// previous one. The root's own `copyWithField` anchors the parameter type
/// every descendant must accept.
const _hierarchySource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'issue140_listing.zorphy.dart';

@Zorphy()
abstract class \$ListingOffer {
  String get id;
  int get price;
}

@Zorphy()
abstract class \$Listing implements \$ListingOffer {
  String get title;
}

@Zorphy()
abstract class \$TextListing implements \$Listing {
  String get body;
}
''';

/// Generates the output for one entity of the temporary hierarchy library.
Future<String> _generateFor(Directory fixtureDir, String className) async {
  final source = File('${fixtureDir.path}/issue140_listing.dart')
    ..writeAsStringSync(_hierarchySource);
  final collection = AnalysisContextCollection(includedPaths: [source.path]);
  final ctx = collection.contextFor(source.path);
  final result =
      await ctx.currentSession.getResolvedUnit(source.path)
          as ResolvedUnitResult;
  final element = result.libraryElement.getClass(className)!;
  final annotationReader = ConstantReader(
    _zorphyChecker.firstAnnotationOf(element)!,
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

  return Orchestrator.generate(
    element,
    annotationReader,
    graph.annotated,
    config,
    graph.classesInExplicitSubtypes,
  );
}

/// The `copyWithField` declaration substring of [output], from a little
/// before the signature (to capture annotations) through the parameter list.
String _copyWithFieldDecl(String output) {
  final start = output.indexOf('copyWithField');
  expect(start, greaterThanOrEqualTo(0), reason: 'no copyWithField emitted');
  final from = (start - 120).clamp(0, output.length);
  final end = output.indexOf('{', start);
  expect(end, greaterThan(start), reason: 'unterminated copyWithField');
  return output.substring(from, end + 1);
}

void main() {
  late Directory fixtureDir;
  late String rootOutput;
  late String midOutput;
  late String leafOutput;

  setUpAll(() async {
    final base = Directory('test/.issue_140_tmp').absolute.path;
    fixtureDir = Directory(base)..createSync(recursive: true);
    fixtureDir = fixtureDir.createTempSync('fixture_');
    rootOutput = await _generateFor(fixtureDir, r'$ListingOffer');
    midOutput = await _generateFor(fixtureDir, r'$Listing');
    leafOutput = await _generateFor(fixtureDir, r'$TextListing');
  });

  tearDownAll(() {
    if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
    final tmp = Directory('test/.issue_140_tmp');
    if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
  });

  test('root declares copyWithField with its own type, no override', () {
    final decl = _copyWithFieldDecl(rootOutput);
    expect(
      rootOutput,
      contains('ListingOffer copyWithField<T>(Field<ListingOffer, T> field'),
      reason: decl,
    );
    expect(decl, isNot(contains('@override')), reason: decl);
  });

  test('mid-level entity copies with the ROOT field type', () {
    final decl = _copyWithFieldDecl(midOutput);
    expect(
      midOutput,
      contains('Listing copyWithField<T>(Field<ListingOffer, T> field'),
      reason: decl,
    );
    expect(decl, contains('@override'), reason: decl);
  });

  test(
    'leaf entity copies with the ROOT field type, not its parent (#140)',
    () {
      final decl = _copyWithFieldDecl(leafOutput);
      // THE BUG: the leaf used its direct parent's type, narrowing the
      // inherited parameter type and failing analysis.
      expect(
        leafOutput,
        isNot(contains('Field<Listing, T>')),
        reason:
            'TextListing must not narrow the inherited Field<ListingOffer, T> '
            'parameter to Field<Listing, T>; decl: $decl',
      );
      expect(
        leafOutput,
        contains('TextListing copyWithField<T>(Field<ListingOffer, T> field'),
        reason: decl,
      );
      expect(decl, contains('@override'), reason: decl);
    },
  );

  test(
    'deep chain stays consistent: all levels declare the same field type',
    () {
      for (final output in [midOutput, leafOutput]) {
        final decl = _copyWithFieldDecl(output);
        expect(
          decl,
          contains('Field<ListingOffer, T> field'),
          reason:
              'every descendant must accept the root field token; decl: $decl',
        );
      }
    },
  );
}
