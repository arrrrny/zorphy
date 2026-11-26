// Regression tests for arrrrny/zorphy#273 (ZRP-010): the emitter must not
// append a redundant `?` to a field whose type is a type parameter whose bound
// is already nullable.
//
// The IR is resolved from real Dart source through the analyzer (the same view
// the generator sees), so the assertions are on the resolved nullability and on
// the EMITTED source text — both SDK-independent. The `unnecessary_question_mark`
// diagnostic itself is SDK-gated, so the structural emitted-source assertion is
// what proves the fix on every SDK.

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
Future<PolymorphicIr> _resolve(
  Map<String, String> sources, {
  String libraryName = 'nodes.dart',
}) async {
  final root = Directory('test/.nullable_type_param_tmp').absolute.path;
  Directory(root).createSync(recursive: true);
  final fixture = Directory(root).createTempSync('fixture_');
  for (final entry in sources.entries) {
    File('${fixture.path}/${entry.key}').writeAsStringSync(entry.value);
  }
  final libraryPath = '${fixture.path}/$libraryName';
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

void main() {
  group('nullable-bounded type parameter (#273)', () {
    test('a field typed by a type param with a nullable bound is NOT nullable '
        'in the IR (no redundant `?`)', () async {
      final ir = await _resolve({'nodes.dart': _nullableBound});
      final node = ir.rootFor('ToggleParams');
      expect(node, isNotNull);
      final id = node!.fields.firstWhere((f) => f.name == 'id');
      expect(
        id.isNullable,
        isFalse,
        reason: 'bound is Object? — appending `?` would be redundant',
      );
    });

    test(
      'a field typed by a type param with a non-nullable bound stays nullable '
      'in the IR',
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
      },
    );

    test('emitted source carries `I id` for a nullable bound and `I? id` for a '
        'non-nullable bound', () async {
      final nullableIr = await _resolve({'nodes.dart': _nullableBound});
      final nullableEmitted = const ArchetypeComposer().compose(nullableIr);
      expect(
        nullableEmitted,
        contains('final I id;'),
        reason: 'no redundant `?` on a nullable-bounded parameter field',
      );
      expect(
        nullableEmitted,
        isNot(contains('final I? id;')),
        reason: 'the redundant `final I? id;` field must not be emitted',
      );

      final nonNullableIr = await _resolve({'nodes.dart': _nonNullableBound});
      final nonNullableEmitted = const ArchetypeComposer().compose(
        nonNullableIr,
      );
      expect(
        nonNullableEmitted,
        contains('final I? id;'),
        reason: 'a non-nullable bound keeps the meaningful `?` field',
      );
    });
  });
}
