// Regression test for issue #159:
// "Sealed base with explicitSubTypes emits subtype toJson/fromJson calls when
//  generateJson is off (generated code does not compile)"
//
// Symptom: a `$$` base with `explicitSubTypes` gets a `changeTo<Subtype>`
// extension whose body round-trips through JSON —
//
//   final _json = Map<String, dynamic>.from(
//     switch (this) {
//       Circle circle => circle.toJson(),
//       _ => this.toJson(),
//     },
//   );
//   _json.addAll(_patcher.toJson());
//   return Circle.fromJson(_json);
//
// — but JSON generation is opt-in in every preset (`generateJson` defaults to
// false), so neither the base nor the subtypes have `toJson`/`fromJson` and
// the generated part fails to analyze:
//
//   sealed.dart: undefined_instance_member_read — The member 'toJson' isn't
//     defined for the type 'Circle'.
//   sealed.dart: undefined_static_member_read — The class 'Circle' doesn't
//     have a static member or constructor named 'fromJson'.
//
// Root cause: `ChangeToExtensionGenerator.shouldGenerate` only consults
// `generateChangeTo` + `explicitSubtypes`; it never asks whether the JSON
// surface its own body calls actually exists.
//
// The tests drive the REAL pipeline (resolved ClassElement -> ClassAnalyzer ->
// Orchestrator.generate) and then run the analyzer over the generated sources,
// so the reported compile error is reproduced end-to-end.

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

/// The exact shape from the issue: a sealed base with an explicitly declared
/// closed hierarchy, and no `generateJson` anywhere.
const _noJsonSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'sealed_no_json.zorphy.dart';

@Zorphy(explicitSubTypes: [\$Circle, \$Square])
abstract class \$\$Shape {
  double get area;
}

@Zorphy()
abstract class \$Circle implements \$\$Shape {
  double get radius;
}

@Zorphy()
abstract class \$Square implements \$\$Shape {
  double get side;
}
''';

/// Control shape: the same hierarchy with the JSON surface actually generated.
/// `changeTo` is a JSON round-trip by design, so with `generateJson: true` the
/// dispatch is legitimate and must keep working.
const _withJsonSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'sealed_with_json.zorphy.dart';

@Zorphy(generateJson: true, explicitSubTypes: [\$Circle])
abstract class \$\$Shape {
  double get area;
}

@Zorphy(generateJson: true)
abstract class \$Circle implements \$\$Shape {
  double get radius;
}
''';

/// Control shape: the base does not generate JSON but every declared subtype
/// does. A sealed base's `switch` covers exactly its subtypes, so the JSON
/// surface the `changeTo` body calls is complete without the base — the
/// feature must survive here (issue #159's "base **and/or** subtypes").
const _subtypesOnlyJsonSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'sealed_subtypes_json.zorphy.dart';

@Zorphy(explicitSubTypes: [\$Circle])
abstract class \$\$Shape {
  double get area;
}

@Zorphy(generateJson: true)
abstract class \$Circle implements \$\$Shape {
  double get radius;
}
''';

/// The shape from the #161 review's major finding: the `$$` base declares a
/// closed hierarchy whose subtype lives in ANOTHER library. Sealing is
/// withheld there (issue #142), so the base is plain `abstract` — and a plain
/// `abstract` base is still instantiable through its subtype switch, which
/// carries a `_ => this.toJson()` default. A base that declares
/// `explicitSubTypes` never gets a `toJson()` of its own: `JsonGenerator`
/// emits one only for a `nonSealed` base, and `JsonExtensionGenerator` skips
/// any class that declares subtypes. `generateJson: true` on both classes
/// therefore does NOT give the switch's default case a `toJson()` to call, and
/// the extension must be withheld rather than emitted broken.
const _crossLibraryBaseSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'cross_circle.dart';

part 'cross_base.zorphy.dart';

@Zorphy(generateJson: true, explicitSubTypes: [\$Circle])
abstract class \$\$Shape {
  double get area;
}
''';

/// The remote half of [_crossLibraryBaseSource]'s hierarchy: a JSON-generating
/// subtype that implements the base from its own library.
const _crossLibrarySubtypeSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

import 'cross_base.dart';

part 'cross_circle.zorphy.dart';

@Zorphy(generateJson: true)
abstract class \$Circle implements \$\$Shape {
  double get radius;
}
''';

/// Resolves every `@Zorphy` class in the library at [libraryPath] and returns
/// the generated part bodies keyed by class name.
Future<Map<String, String>> _generateLibrary(String libraryPath) async {
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
      final annotationReader = ConstantReader(annotation);

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

      outputs[element.displayName] = Orchestrator.generate(
        element,
        annotationReader,
        graph.annotated,
        config,
        graph.classesInExplicitSubtypes,
      );
    }
    return outputs;
  } finally {
    await collection.dispose();
  }
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
  File(
    '${fixtureDir.path}/$partName',
  ).writeAsStringSync("part of '$libraryName';\n\n$generated");
}

/// Every diagnostic the analyzer reports for the library at [libraryPath]
/// (including its generated part file), formatted as
/// `<file>:<offset>: <code> — <message>`.
Future<List<String>> _diagnostics(
  Directory fixtureDir,
  String libraryPath,
) async {
  final collection = AnalysisContextCollection(
    includedPaths: [fixtureDir.path],
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
          '${unit.path.split('/').last}:'
          '${diagnostic.problemMessage.offset}: '
          '${diagnostic.diagnosticCode.lowerCaseName} — '
          '${diagnostic.problemMessage.messageText(includeUrl: false)}',
        );
      }
    }
    return diagnostics;
  } finally {
    await collection.dispose();
  }
}

/// The diagnostics #159 is about: a call to a JSON member the class never got.
///
/// Deliberately narrow. The part file also references `_$XFromJson` /
/// `_$XToJson`, which json_serializable emits in a LATER build step
/// (`build.yaml`: `runs_before: ["json_serializable:json_serializable"]`), so a
/// whole-part "no diagnostics at all" assertion is not available to a
/// standalone Orchestrator pass — widen this only for missing-JSON-member
/// codes.
bool _isMissingJsonMember(String diagnostic) =>
    diagnostic.contains('undefined_instance_member_read') ||
    diagnostic.contains('undefined_static_member_read');

void main() {
  group('issue #159 — changeTo without generateJson', () {
    late Directory fixtureDir;
    late String libraryPath;
    late Map<String, String> outputs;
    late List<String> diagnostics;

    setUpAll(() async {
      final root = Directory('test/.issue_159_tmp').absolute.path;
      fixtureDir = Directory(root)..createSync(recursive: true);
      fixtureDir = fixtureDir.createTempSync('fixture_');

      libraryPath = '${fixtureDir.path}/sealed_no_json.dart';
      File(libraryPath).writeAsStringSync(_noJsonSource);

      outputs = await _generateLibrary(libraryPath);
      _writePart(
        fixtureDir,
        'sealed_no_json.dart',
        'sealed_no_json.zorphy.dart',
        outputs.values.join('\n\n'),
      );

      diagnostics = await _diagnostics(fixtureDir, libraryPath);
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
      final tmp = Directory('test/.issue_159_tmp');
      if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
    });

    test('emits no subtype toJson/fromJson dispatch without generateJson', () {
      final output = outputs.values.join('\n');
      expect(
        output,
        isNot(contains('toJson()')),
        reason:
            'a sealed base whose JSON surface was never generated must not '
            'emit changeTo bodies that call toJson()',
      );
      expect(
        output,
        isNot(contains('fromJson(')),
        reason:
            'a sealed base whose JSON surface was never generated must not '
            'emit changeTo bodies that call fromJson()',
      );
    });

    test('generated sealed-no-json library analyzes with zero diagnostics', () {
      expect(
        diagnostics.where(_isMissingJsonMember),
        isEmpty,
        reason:
            'the #159 defect must be gone. diagnostics:\n'
            '${diagnostics.join('\n')}',
      );
    });
  });

  group('issue #159 — changeTo with generateJson keeps its dispatch', () {
    late Directory fixtureDir;
    late String libraryPath;
    late Map<String, String> outputs;
    late List<String> diagnostics;

    setUpAll(() async {
      final root = Directory('test/.issue_159_json_tmp').absolute.path;
      fixtureDir = Directory(root)..createSync(recursive: true);
      fixtureDir = fixtureDir.createTempSync('fixture_');

      libraryPath = '${fixtureDir.path}/sealed_with_json.dart';
      File(libraryPath).writeAsStringSync(_withJsonSource);

      outputs = await _generateLibrary(libraryPath);
      _writePart(
        fixtureDir,
        'sealed_with_json.dart',
        'sealed_with_json.zorphy.dart',
        outputs.values.join('\n\n'),
      );

      diagnostics = await _diagnostics(fixtureDir, libraryPath);
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
      final tmp = Directory('test/.issue_159_json_tmp');
      if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
    });

    test('changeTo still round-trips through JSON', () {
      final base = outputs['\$\$Shape'] ?? '';
      expect(
        base,
        contains('changeToCircle'),
        reason: 'generateJson: true must keep the changeTo extension',
      );
      expect(base, contains('toJson()'));
      expect(base, contains('fromJson('));
    });

    test('generated sealed-json library analyzes with zero diagnostics', () {
      expect(
        diagnostics.where(_isMissingJsonMember),
        isEmpty,
        reason: 'diagnostics:\n${diagnostics.join('\n')}',
      );
    });
  });

  group('issue #159 — changeTo when only the subtypes generate JSON', () {
    late Directory fixtureDir;
    late String libraryPath;
    late Map<String, String> outputs;
    late List<String> diagnostics;

    setUpAll(() async {
      final root = Directory('test/.issue_159_subtypes_json_tmp').absolute.path;
      fixtureDir = Directory(root)..createSync(recursive: true);
      fixtureDir = fixtureDir.createTempSync('fixture_');

      libraryPath = '${fixtureDir.path}/sealed_subtypes_json.dart';
      File(libraryPath).writeAsStringSync(_subtypesOnlyJsonSource);

      outputs = await _generateLibrary(libraryPath);
      _writePart(
        fixtureDir,
        'sealed_subtypes_json.dart',
        'sealed_subtypes_json.zorphy.dart',
        outputs.values.join('\n\n'),
      );

      diagnostics = await _diagnostics(fixtureDir, libraryPath);
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
      final tmp = Directory('test/.issue_159_subtypes_json_tmp');
      if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
    });

    test('changeTo is kept when every declared subtype has JSON', () {
      final base = outputs['\$\$Shape'] ?? '';
      expect(
        base,
        contains('changeToCircle'),
        reason:
            'a sealed base switches over its subtypes only, so their JSON '
            'surface alone is enough for the changeTo body',
      );
    });

    test('generated subtypes-only-json library analyzes with zero '
        'diagnostics', () {
      expect(
        diagnostics.where(_isMissingJsonMember),
        isEmpty,
        reason: 'diagnostics:\n${diagnostics.join('\n')}',
      );
    });
  });

  group('issue #159 — cross-library base whose sealing is withheld (#142)', () {
    late Directory fixtureDir;
    late String basePath;
    late String baseOutput;
    late List<String> diagnostics;

    setUpAll(() async {
      final root = Directory('test/.issue_159_cross_library_tmp').absolute.path;
      fixtureDir = Directory(root)..createSync(recursive: true);
      fixtureDir = fixtureDir.createTempSync('fixture_');

      basePath = '${fixtureDir.path}/cross_base.dart';
      final subtypePath = '${fixtureDir.path}/cross_circle.dart';
      File(basePath).writeAsStringSync(_crossLibraryBaseSource);
      File(subtypePath).writeAsStringSync(_crossLibrarySubtypeSource);

      // The base first: its generated part must exist before the subtype
      // library (which imports it) is resolved.
      final baseOutputs = await _generateLibrary(basePath);
      baseOutput = baseOutputs.values.join('\n\n');
      _writePart(
        fixtureDir,
        'cross_base.dart',
        'cross_base.zorphy.dart',
        baseOutput,
      );

      final subtypeOutputs = await _generateLibrary(subtypePath);
      _writePart(
        fixtureDir,
        'cross_circle.dart',
        'cross_circle.zorphy.dart',
        subtypeOutputs.values.join('\n\n'),
      );

      diagnostics = await _diagnostics(fixtureDir, basePath);
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
      final tmp = Directory('test/.issue_159_cross_library_tmp');
      if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
    });

    test('the base is emitted abstract, not sealed', () {
      expect(
        baseOutput,
        isNot(contains('sealed class Shape')),
        reason:
            'a subtype in another library means sealing buys nothing '
            '(issue #142) and the base must stay implementable abroad',
      );
      expect(baseOutput, contains('abstract class Shape'));
    });

    test(
      'changeTo is withheld — the base has no toJson for its default case',
      () {
        expect(
          baseOutput,
          isNot(contains('changeToCircle')),
          reason:
              'the switch would fall through to `_ => this.toJson()` on a base '
              'that declared no toJson of its own (generateJson is not enough '
              'without nonSealed) — the #159 failure mode',
        );
      },
    );

    test(
      'generated cross-library hierarchy analyzes with zero diagnostics',
      () {
        expect(
          diagnostics.where(_isMissingJsonMember),
          isEmpty,
          reason: 'diagnostics:\n${diagnostics.join('\n')}',
        );
      },
    );
  });
}
