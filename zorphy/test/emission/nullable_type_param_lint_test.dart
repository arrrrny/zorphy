// Regression tests for arrrrny/zorphy#351: nullable generic fields keep the
// source `?` in generated type text. Suppressing it on an unbounded type
// parameter makes the generated constructor reject nullable values.
//
// The IR is resolved from real Dart source through the analyzer, so these
// assertions cover both implicit and explicit non-nullable bounds.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/emission/archetype_composer.dart';
import 'package:zorphy/src/parser/hierarchy_resolver.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

const _annotationImport =
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n";

/// Writes [sources] into a fresh temp directory, resolves the library at
/// [libraryName] and hands its classes to [HierarchyResolver.resolveLibrary].
///
/// The fixture lives in-package so `package:zorphy_annotation` resolves, but
/// it is removed on every path — including a failed analysis — so a run never
/// leaves `fixture_*` litter under `test/`.
Future<PolymorphicIr> _resolve(
  Map<String, String> sources, {
  String libraryName = 'nodes.dart',
}) async {
  final root = Directory('test/.nullable_type_param_tmp').absolute.path;
  Directory(root).createSync(recursive: true);
  final fixture = Directory(root).createTempSync('fixture_');
  try {
    for (final entry in sources.entries) {
      File('${fixture.path}/${entry.key}').writeAsStringSync(entry.value);
    }
    final libraryPath = '${fixture.path}/$libraryName';
    final collection = AnalysisContextCollection(includedPaths: [fixture.path]);
    try {
      final resolved =
          await collection
                  .contextFor(libraryPath)
                  .currentSession
                  .getResolvedLibrary(libraryPath)
              as ResolvedLibraryResult;
      return HierarchyResolver.resolveLibrary(resolved.element);
    } finally {
      await collection.dispose();
    }
  } finally {
    if (fixture.existsSync()) fixture.deleteSync(recursive: true);
  }
}

/// A generic entity whose type parameter has an IMPLICIT nullable bound
/// (`class ToggleParams<I>` — bound `Object?`) and a nullable field `I? get id`.
const _nullableBound =
    '$_annotationImport'
    '''
part 'nodes.zorphy.dart';

@ZorphyEntity(principalKey: #id)
abstract class \$ToggleParams<I> {
  I? get id;
}
''';

/// A generic entity whose type parameter has a NON-nullable bound
/// (`class DeleteParams<I extends Object>`) and a nullable field `I? get id`.
const _nonNullableBound =
    '$_annotationImport'
    '''
part 'nodes.zorphy.dart';

@ZorphyEntity(principalKey: #id)
abstract class \$DeleteParams<I extends Object> {
  I? get id;
}
''';

/// A compile-clean fixture for the `--fatal-infos` probe: the nullable generic
/// field is NOT the principal key (a separate non-nullable `String key` is), so
/// the only question under test is whether `I?` trips
/// `unnecessary_question_mark` — not an unrelated `principalKey` return-type
/// error.
const _nullableGenericField =
    '$_annotationImport'
    '''
part 'nodes.zorphy.dart';

@ZorphyEntity(principalKey: #key)
abstract class \$Profile<I> {
  String get key;
  I? get nickname;
}
''';

void main() {
  tearDownAll(() {
    final root = Directory('test/.nullable_type_param_tmp');
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('nullable generic fields (#351)', () {
    test(
      'source nullability stays in type text for an implicit bound',
      () async {
        final ir = await _resolve({'nodes.dart': _nullableBound});
        final node = ir.rootFor('ToggleParams');
        expect(node, isNotNull);
        final id = node!.fields.firstWhere((f) => f.name == 'id');
        expect(id.isNullable, isTrue);
        expect(id.suppressQuestionMark, isFalse);
        expect(id.emitsQuestionMark, isTrue);
      },
    );

    test(
      'a field typed by a type param with a non-nullable bound stays nullable '
      'and keeps its `?`',
      () async {
        final ir = await _resolve({'nodes.dart': _nonNullableBound});
        final node = ir.rootFor('DeleteParams');
        expect(node, isNotNull);
        final id = node!.fields.firstWhere((f) => f.name == 'id');
        expect(
          id.isNullable,
          isTrue,
          reason: 'bound is Object — `I?` is a meaningful nullable',
        );
        expect(id.suppressQuestionMark, isFalse);
        expect(id.emitsQuestionMark, isTrue);
      },
    );

    test('emitted source keeps `I?` for both bound shapes', () async {
      final nullableIr = await _resolve({'nodes.dart': _nullableBound});
      final nullableEmitted = const ArchetypeComposer().compose(nullableIr);
      expect(nullableEmitted, contains('final I? id;'));

      final nonNullableIr = await _resolve({'nodes.dart': _nonNullableBound});
      final nonNullableEmitted = const ArchetypeComposer().compose(
        nonNullableIr,
      );
      expect(nonNullableEmitted, contains('final I? id;'));
    });

    test('the emitted nullable-generic output compiles under --fatal-infos '
        '(#273 -> #351 reversal is compile-safe)', () async {
      // #351 review: the `I?` reversal of #273 is asserted on emitted text
      // only. The whole premise of #273 was the `unnecessary_question_mark`
      // diagnostic, so lock it with a real `dart analyze --fatal-infos` of the
      // generated output — a future SDK that flags `I?` on an unbounded
      // parameter turns this red here instead of in a consumer's code.
      final ir = await _resolve({'nodes.dart': _nullableGenericField});
      final out = const ArchetypeComposer().compose(ir);
      final probe = Directory('test/.nullable351_tmp').absolute.path;
      Directory(probe).createSync(recursive: true);
      final fixture = Directory(probe).createTempSync('fixture_');
      addTearDown(() => fixture.deleteSync(recursive: true));
      File('${fixture.path}/pubspec.yaml').writeAsStringSync(
        'name: probe_nullable_351\n'
        'environment:\n'
        '  sdk: ">=3.11.0 <4.0.0"\n'
        'dependencies:\n'
        '  zorphy_annotation:\n'
        '    path: ${Directory.current.parent.uri.resolve('zorphy_annotation/').toFilePath()}\n',
      );
      Directory('${fixture.path}/lib').createSync();
      File('${fixture.path}/lib/emitted.dart').writeAsStringSync(
        "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n$out",
      );
      final pubGet = Process.runSync('dart', [
        'pub',
        'get',
      ], workingDirectory: fixture.path);
      expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}${pubGet.stderr}');
      final analyze = Process.runSync('dart', [
        'analyze',
        '--fatal-infos',
        'lib/emitted.dart',
      ], workingDirectory: fixture.path);
      expect(
        analyze.exitCode,
        0,
        reason: '${analyze.stdout}${analyze.stderr}',
      );
    });

    test('the API shape stays null-safe for a nullable-bounded generic '
        'entity', () async {
      final ir = await _resolve({'nodes.dart': _nullableBound});
      final emitted = const ArchetypeComposer().compose(ir);

      // The field stays optional in fromTrusted and copyWith can clear it.
      expect(
        emitted,
        isNot(contains('fromTrusted({required this.id})')),
        reason: 'a nullable field must not be forced required',
      );
      expect(emitted, contains('fromTrusted({this.id})'));

      // The clear-to-null sentinel must survive: copyWith(id: null) has to
      // clear a field instantiated as `String?` (arrrrny/zorphy#277 finding).
      expect(
        emitted,
        contains('Object? id = _sentinel'),
        reason: 'the sentinel parameter is what makes explicit null clear',
      );
      expect(
        emitted,
        contains('identical(id, _sentinel) ? this.id : id as I?'),
        reason: 'copyWith must take the clear-to-null sentinel path',
      );
    });
  });
}
