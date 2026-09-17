// Regression test for issue #138:
// "Factory constructors emit duplicated parameters (invalid Dart) —
//  corruption is introduced in the code_builder emission step, not by the
//  #129 dedup"
//
// Symptom: regenerating an entity whose `@Zorphy` abstract base declares
// `static` factory methods produced `factory X.y({...})` constructors with
// N(N+1)/2 parameters (the growing prefixes of the real parameter list
// concatenated), so the generated file failed analysis with
// `Error: Duplicated parameter name 'url'.`
//
// Root cause: the InvalidType source-recovery path
// (`helpers.recoverTypeFromSource`, executable-anchored parameter branch)
// captured the type with a character class that admits commas and
// newlines, so recovering a later parameter swallowed every preceding
// sibling (`create({required String url, required UrlEndpoint
// urlEndpoint})` recovered `String url,\n required UrlEndpoint` as the
// type of `urlEndpoint`). The factory spec kept one entry per parameter
// NAME (why the #129 dedup looked innocent) but each polluted type text
// emitted extra `Type name,` fragments — the "growing prefixes".
//
// The tests below drive the REAL pipeline end-to-end (resolved
// ClassElement -> ClassAnalyzer -> AnnotationParser -> Orchestrator.
// generate -> ZorphyEmitter) with the issue's exact trigger: factory
// parameter types that reference the CONCRETE names of entities whose
// generated classes do not exist yet (first-generation build), so the
// analyzer reports InvalidType and recovery kicks in. They assert each
// user-declared static factory declares each of its parameters exactly
// once, in source order, with `required` preserved.

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

/// Supporting entities live in their own file, exactly like the reporter's
/// app; only their abstract forms exist during a first-generation build.
const _sparkSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

@Zorphy(generateJson: true)
abstract class \$Issue138Spark {
  String get id;
}

@Zorphy(generateJson: true)
abstract class \$Issue138UrlSpark {
  String get id;
  String get url;
}
''';

const _endpointSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

@Zorphy(generateJson: true)
abstract class \$Issue138UrlEndpoint {
  String get id;
}
''';

/// The analyzed entity: factory parameters use the CONCRETE names of the
/// sibling entities (`Issue138Spark`, ...) which the analyzer cannot
/// resolve before those entities are generated — InvalidType -> recovery.
/// Factory bodies span multiple lines with trailing commas, the shape the
/// issue reported (the generator synthesizes the abstract-factory
/// delegation for them).
const _zikSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'issue138_spark.dart';
import 'issue138_endpoint.dart';

part 'issue138_zik.zorphy.dart';

@Zorphy(generateJson: true)
abstract class \$Issue138Zik {
  String get id;
  \$Issue138Spark? get spark;
  String get url;
  \$Issue138UrlEndpoint get urlEndpoint;

  static Issue138Zik create({
    required String url,
    required Issue138UrlEndpoint urlEndpoint,
    Issue138Spark? spark,
  }) => Issue138Zik(
        id: 'id',
        url: url,
        spark: spark,
        urlEndpoint: urlEndpoint,
      );

  static Issue138Zik fromUrlSpark({
    required Issue138UrlSpark spark,
    required Issue138UrlEndpoint urlEndpoint,
  }) => Issue138Zik(
        id: 'id',
        url: spark.url,
        spark: spark,
        urlEndpoint: urlEndpoint,
      );
}
''';

/// Extracts the parameter list source of `factory <className>.<name>(...)`.
String _factoryParams(String output, String className, String name) {
  final marker = 'factory $className.$name(';
  final start = output.indexOf(marker);
  expect(start, greaterThanOrEqualTo(0), reason: 'missing $marker');
  final paramsStart = start + marker.length;
  // The parameter list ends at the first `)` followed by `=>` or `{`.
  var cursor = paramsStart;
  while (cursor < output.length) {
    if (output[cursor] == ')') {
      final rest = output.substring(cursor + 1).trimLeft();
      if (rest.startsWith('=>') || rest.startsWith('{')) break;
    }
    cursor++;
  }
  expect(
    cursor,
    lessThan(output.length),
    reason: 'unterminated parameter list for $marker',
  );
  return output.substring(paramsStart, cursor);
}

/// Counts whole-word occurrences of [identifier] in [source].
int _countWord(String source, String identifier) =>
    RegExp(r'\b' + identifier + r'\b').allMatches(source).length;

void main() {
  late Directory fixtureDir;
  late String generated;

  setUpAll(() async {
    // The fixtures must live inside the package so `package:` imports
    // resolve through the package config.
    final root = Directory('test/.issue_138_tmp').absolute.path;
    fixtureDir = Directory(root)..createSync(recursive: true);
    fixtureDir = fixtureDir.createTempSync('fixture_');
    File('${fixtureDir.path}/issue138_spark.dart')
        .writeAsStringSync(_sparkSource);
    File('${fixtureDir.path}/issue138_endpoint.dart')
        .writeAsStringSync(_endpointSource);
    final zikFile = File('${fixtureDir.path}/issue138_zik.dart')
      ..writeAsStringSync(_zikSource);

    final collection = AnalysisContextCollection(includedPaths: [zikFile.path]);
    final ctx = collection.contextFor(zikFile.path);
    final result = await ctx.currentSession.getResolvedUnit(
      zikFile.path,
    ) as ResolvedUnitResult;
    final element = result.libraryElement.getClass(r'$Issue138Zik')!;
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
    expect(
      metadata.factoryMethods.map((f) => f.name),
      unorderedEquals(['create', 'fromUrlSpark']),
      reason: 'both static factories must be picked up by analysis',
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

    generated = Orchestrator.generate(
      element,
      annotationReader,
      graph.annotated,
      config,
      graph.classesInExplicitSubtypes,
    );
  });

  tearDownAll(() {
    if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
    final tmp = Directory('test/.issue_138_tmp');
    if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
  });

  test('create declares each parameter exactly once', () {
    final params = _factoryParams(generated, 'Issue138Zik', 'create');
    expect(_countWord(params, 'url'), 1, reason: 'params: $params');
    expect(_countWord(params, 'urlEndpoint'), 1, reason: 'params: $params');
    expect(_countWord(params, 'spark'), 1, reason: 'params: $params');
  });

  test('fromUrlSpark declares each parameter exactly once', () {
    final params = _factoryParams(generated, 'Issue138Zik', 'fromUrlSpark');
    expect(_countWord(params, 'spark'), 1, reason: 'params: $params');
    expect(_countWord(params, 'urlEndpoint'), 1, reason: 'params: $params');
  });

  test('factory parameters keep source order and required keywords', () {
    final params = _factoryParams(generated, 'Issue138Zik', 'create');
    final urlAt = params.indexOf(RegExp(r'\burl\b'));
    final urlEndpointAt = params.indexOf(RegExp(r'\burlEndpoint\b'));
    final sparkAt = params.indexOf(RegExp(r'\bspark\b'));
    expect(urlAt, greaterThanOrEqualTo(0), reason: 'params: $params');
    expect(urlEndpointAt, greaterThan(urlAt), reason: 'params: $params');
    expect(sparkAt, greaterThan(urlEndpointAt), reason: 'params: $params');

    expect(
      RegExp(r'\brequired\b').allMatches(params).length,
      2,
      reason: 'create declares 2 required params; got: $params',
    );
  });

  test('recovered parameter types match the source declarations', () {
    final params = _factoryParams(generated, 'Issue138Zik', 'create');
    expect(
      params,
      contains('required Issue138UrlEndpoint urlEndpoint'),
      reason:
          'recovery must yield the declared type, not a polluted '
          'multi-parameter fragment; params: $params',
    );
    expect(params, contains('Issue138Spark? spark'), reason: 'params: $params');
  });
}
