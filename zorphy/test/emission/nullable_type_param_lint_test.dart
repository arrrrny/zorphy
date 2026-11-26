// Regression tests for arrrrny/zorphy#273 (ZRP-010): the emitter must not
// append a redundant `?` to a field whose type is a type parameter whose bound
// is already nullable.
//
// The IR is resolved from real Dart source through the analyzer (the same view
// the generator sees), so the assertions are on the resolved nullability and on
// the EMITTED source text — both SDK-independent. The `unnecessary_question_mark`
// diagnostic itself is SDK-gated, so the structural emitted-source assertion is
// what proves the fix on every SDK.
//
// The redundant `?` is suppressed ONLY in the emitted type text. `isNullable`
// stays faithful to the source `?` so the generated API keeps its shape: an
// unbounded `I` can be instantiated as `String?`, so `fromTrusted` must not
// require the field and `copyWith(id: null)` must clear it.

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

void main() {
  tearDownAll(() {
    final root = Directory('test/.nullable_type_param_tmp');
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  group('nullable-bounded type parameter (#273)', () {
    test('isNullable stays faithful to the source `?`; only type text '
        'suppresses the redundant suffix', () async {
      final ir = await _resolve({'nodes.dart': _nullableBound});
      final node = ir.rootFor('ToggleParams');
      expect(node, isNotNull);
      final id = node!.fields.firstWhere((f) => f.name == 'id');
      expect(
        id.isNullable,
        isTrue,
        reason: 'the source declares `I?` — API shape must stay nullable',
      );
      expect(
        id.suppressQuestionMark,
        isTrue,
        reason: 'bound is Object? — appending `?` in type text is redundant',
      );
      expect(id.emitsQuestionMark, isFalse);
    });

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

    test('the API shape stays null-safe for a nullable-bounded generic '
        'entity', () async {
      final ir = await _resolve({'nodes.dart': _nullableBound});
      final emitted = const ArchetypeComposer().compose(ir);

      // `I` is unbounded: it can be instantiated as `String?`, so the field
      // must remain optional in fromTrusted rather than becoming required.
      expect(
        emitted,
        isNot(contains('fromTrusted({required this.id})')),
        reason: 'a nullable-bounded field must not be forced required',
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
        contains('identical(id, _sentinel) ? this.id : id as I'),
        reason: 'copyWith must take the clear-to-null sentinel path',
      );
    });
  });
}
