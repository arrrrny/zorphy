// Issue #231 — v3 union matchers (`when` / `maybeWhen`), sibling morphing
// (`changeTo<Sibling>`), and generic hierarchies.
//
// Before this change the v3 composer emitted only the class shape + boundary
// codec: a consumer's `const Loading().when` or
// `Ready.fromTrusted(value: 'x').changeToLoading()` had no member to call, and
// a generic `@ZorphyUnion` root (`AsyncSlice<T>`) was pruned outright —
// `ArchetypeComposer` skipped every generic root and its subtree, so the
// builder wrote 0 outputs for the #179 acceptance shape.
//
// This test drives the REAL v3 pipeline — `HierarchyResolver` over a resolved
// fixture library, then `ArchetypeComposer.compose` — and proves the composed
// part against the analyzer, the same way issue_179's test proves the legacy
// surface: the part must produce ZERO diagnostics, which is what makes
// "the matcher's switch is exhaustive" and "the morphing body type-checks"
// checkable claims rather than string-shaped hopes.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/emission/archetype_composer.dart';
import 'package:zorphy/src/parser/hierarchy_resolver.dart';

/// The consumer reproduction: a closed union with factory variants. The
/// generated surface must carry `AsyncStatusWhenE` (`when` + `maybeWhen`) and
/// one `changeTo*` method per sibling direction.
const _statusSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'status.zorphy.dart';

@ZorphyUnion()
abstract class \$AsyncStatus {
  factory \$AsyncStatus.loading() = \$Loading;
  factory \$AsyncStatus.ready(String value) = \$Ready;
}

@ZorphyValue()
class \$Loading implements \$AsyncStatus {
  const \$Loading();
}

@ZorphyValue()
class \$Ready implements \$AsyncStatus {
  final String value;

  const \$Ready(this.value);
}
''';

/// The #179 acceptance shape, declared with v3 annotations: a GENERIC union
/// root whose leaves carry the type argument through. This is the fixture the
/// issue says a clean consumer probe generated 0 outputs for.
const _genericSliceSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'slice.zorphy.dart';

@ZorphyUnion()
abstract class \$AsyncSlice<T> {
  String get source;
}

@ZorphyValue()
abstract class \$SliceData<T> implements \$AsyncSlice<T> {
  T get value;
}

@ZorphyValue()
abstract class \$SliceLoading<T> implements \$AsyncSlice<T> {}
''';

/// The bounded-generic variant: `T extends num` must reach the classes, the
/// leaves and both extensions, or the emitted `on Slice<T>` is not
/// well-bounded (`type_argument_not_matching_bounds`).
const _boundedSliceSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'bounded.zorphy.dart';

@ZorphyUnion()
abstract class \$BoundedSlice<T extends num> {
  String get source;
}

@ZorphyValue()
abstract class \$BoundedData<T extends num> implements \$BoundedSlice<T> {
  T get value;
}

@ZorphyValue()
abstract class \$BoundedLoading<T extends num> implements \$BoundedSlice<T> {}
''';

/// Sibling morphing on an ENTITY hierarchy: the shared root fields (the
/// `principalKey`, a `DateTime`, a collection) must be copied by reference —
/// the emitted body passes `this.field`, never a clone.
const _taskSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'task.zorphy.dart';

@ZorphyEntity(principalKey: #id)
abstract class \$Task {
  String get id;
  DateTime get createdAt;
  List<String> get tags;
}

@ZorphyEntity()
abstract class \$OpenTask implements \$Task {
  String get assignee;
}

@ZorphyEntity()
abstract class \$DoneTask implements \$Task {
  String get result;
}
''';

/// A variant whose type parameter is RENAMED (`U` under the root's `T`) and
/// a root-declared generic field the leaf must redeclare in ITS OWN scope:
/// `Envelope<T> { T get payload }` under `Closed<U>` redeclares
/// `final U payload`, and the matcher's arm is `Closed<T>` — the root's
/// parameter is the only one in scope inside the extension.
const _renamedParamSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'renamed.zorphy.dart';

@ZorphyUnion()
abstract class \$Envelope<T> {
  T get payload;
}

@ZorphyValue()
abstract class \$Closed<U> implements \$Envelope<U> {}

@ZorphyValue()
abstract class \$Opened<U> implements \$Envelope<U> {
  U get note;
}
''';

/// A variant bound TIGHTER than the root's (`Narrow<T extends int>` under
/// `Measure<T extends num>`): the classes still emit, but the matcher must be
/// withheld (its `Narrow<T>` arm would carry a `num`-bounded `T`) and the
/// morph method into `Narrow` must be withheld — both would fail
/// `type_argument_not_matching_bounds` in the consumer.
const _tightBoundSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'tight_bound.zorphy.dart';

@ZorphyUnion()
abstract class \$Measure<T extends num> {
  T get amount;
}

@ZorphyValue()
abstract class \$Narrow<T extends int> implements \$Measure<T> {}

@ZorphyValue()
abstract class \$Wide<T extends num> implements \$Measure<T> {}
''';

/// Variants whose lower-camel names collide with the matcher's GENERATED
/// identifiers: `Value` would emit `Value value => value(value)` (the pattern
/// variable hides the callback) and `OrElse` duplicates the required `orElse`
/// parameter. The reserved-identifier policy renames the callbacks. The
/// second union declares `T`, `TResult`, `TValue` AND `TOut`, so the result
/// parameter falls through to a suffixed `TResult2`.
const _collisionSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'collision.zorphy.dart';

@ZorphyUnion()
abstract class \$Slot {
  factory \$Slot.value() = \$Value;
  factory \$Slot.orElse() = \$OrElse;
}

@ZorphyValue()
class \$Value implements \$Slot {
  const \$Value();
}

@ZorphyValue()
class \$OrElse implements \$Slot {
  const \$OrElse();
}

@ZorphyUnion()
abstract class \$Quad<T, TResult, TValue, TOut> {}

@ZorphyValue()
abstract class \$QuadFirst<T, TResult, TValue, TOut>
    implements \$Quad<T, TResult, TValue, TOut> {}
''';

/// Composes the v3 surface for the library at [libraryPath] through the
/// production pipeline the generator itself calls, on the group's SHARED
/// [collection] — one analyzer context for every fixture, so composing the
/// full fixture set in `setUpAll` stays cheap.
Future<String> _compose(
  AnalysisContextCollection collection,
  String libraryPath,
) async {
  final result =
      await collection
              .contextFor(libraryPath)
              .currentSession
              .getResolvedUnit(libraryPath)
          as ResolvedUnitResult;
  final ir = HierarchyResolver.resolveLibrary(result.libraryElement);
  if (ir.hasErrors) {
    fail(
      'resolver diagnostics:\n${ir.diagnostics.map((d) => d.render()).join('\n')}',
    );
  }
  return const ArchetypeComposer().compose(ir);
}

/// Writes [composed] next to the library as its generated part file, with the
/// `part of` header the shared part carries in a real build.
void _writePart(
  Directory fixtureDir,
  String libraryName,
  String partName,
  String composed,
) {
  File('${fixtureDir.path}/$partName')
      .writeAsStringSync("part of '$libraryName';\n\n$composed");
}

/// Every diagnostic the analyzer reports for the fixture directory — each
/// declaration library resolved WITH its generated part, the way the
/// issue_179 harness reads them: a part file is never a context of its own.
Future<List<String>> _diagnostics(Directory fixtureDir) async {
  final collection = AnalysisContextCollection(
    includedPaths: [fixtureDir.path],
  );
  final diagnostics = <String>[];
  try {
    for (final file
        in fixtureDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .where((file) => !file.path.endsWith('.zorphy.dart'))) {
      final context = collection.contextFor(file.path);
      final library = await context.currentSession.getResolvedLibrary(
        file.path,
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
    return diagnostics;
  } finally {
    await collection.dispose();
  }
}

void main() {
  group(
    'issue #231 — v3 union matchers, morphing and generic hierarchies',
    // Each test drives a real analyzer context; a cold one takes about a
    // minute, well past the 30s default.
    timeout: Timeout.factor(10),
    () {
      late Directory fixtureDir;
      late AnalysisContextCollection collection;

      /// The composed part source per fixture library, keyed by file name.
      final composedByLibrary = <String, String>{};

      /// Every fixture this group composes. The set lives in ONE place so
      /// the aggregate analysis test can assert it is complete before
      /// trusting its own result.
      const fixtureSources = <String, String>{
        'status.dart': _statusSource,
        'slice.dart': _genericSliceSource,
        'bounded.dart': _boundedSliceSource,
        'task.dart': _taskSource,
        'renamed.dart': _renamedParamSource,
        'tight_bound.dart': _tightBoundSource,
        'collision.dart': _collisionSource,
      };

      String partNameOf(String libraryName) =>
          libraryName.replaceAll('.dart', '.zorphy.dart');

      setUpAll(() async {
        final root = Directory('test/.issue_231_tmp').absolute.path;
        Directory(root).createSync(recursive: true);
        fixtureDir = Directory(root).createTempSync('fixture_');
        // Every fixture is composed HERE, once, so no test depends on another
        // test's output: selecting any single test still finds the full
        // fixture set on disk (the order-dependence the #243 review flagged).
        for (final entry in fixtureSources.entries) {
          File('${fixtureDir.path}/${entry.key}')
              .writeAsStringSync(entry.value);
        }
        collection = AnalysisContextCollection(
          includedPaths: [fixtureDir.path],
        );
        for (final libraryName in fixtureSources.keys) {
          final composed = await _compose(
            collection,
            '${fixtureDir.path}/$libraryName',
          );
          expect(
            composed,
            isNotEmpty,
            reason: 'the composer must emit a surface for $libraryName',
          );
          _writePart(
            fixtureDir,
            libraryName,
            partNameOf(libraryName),
            composed,
          );
          composedByLibrary[libraryName] = composed;
        }
      });

      tearDownAll(() async {
        await collection.dispose();
        if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
        final tmp = Directory('test/.issue_231_tmp');
        if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
      });

      test(
        'union matchers: when + maybeWhen on the AsyncStatus repro',
        () async {
          final composed = composedByLibrary['status.dart']!;

          expect(
            composed,
            contains('extension AsyncStatusWhenE on AsyncStatus'),
          );
          expect(composed, contains('T when<T>({'));
          expect(composed, contains('maybeWhen'));
          // The switch is exhaustive because every concrete variant has an arm.
          expect(composed, contains('switch (this)'));
          expect(composed, contains('Loading value => loading(value)'));
          expect(composed, contains('Ready value => ready(value)'));
          // maybeWhen keeps an orElse: the callbacks are optional.
          expect(composed, contains('required T Function() orElse'));
        },
      );

      test('sibling morphing: changeTo in both directions', () async {
        final composed = composedByLibrary['status.dart']!;

        // Ready -> Loading: Loading has no fields of its own, so no parameter.
        expect(composed, contains('extension ReadyMorphing on Ready'));
        expect(composed, contains('Loading changeToLoading()'));
        expect(composed, contains('return Loading.fromTrusted();'));
        // Loading -> Ready: `value` is target-owned, so the caller supplies it.
        expect(composed, contains('extension LoadingMorphing on Loading'));
        expect(
          composed,
          contains('Ready changeToReady({required String value})'),
        );
        expect(composed, contains('return Ready.fromTrusted(value: value);'));
      });

      test(
        'generic union: AsyncSlice<T> emits classes, arms and morphing',
        () async {
          final composed = composedByLibrary['slice.dart']!;

          expect(composed, contains('sealed class AsyncSlice<T>'));
          expect(
            composed,
            contains('final class SliceData<T> extends AsyncSlice<T>'),
          );
          expect(
            composed,
            contains('final class SliceLoading<T> extends AsyncSlice<T>'),
          );
          expect(
            composed,
            contains('extension AsyncSliceWhenE<T> on AsyncSlice<T>'),
          );
          // The arms carry the type argument: a bare `SliceData` arm would not
          // type-check against an `AsyncSlice<T>` receiver.
          expect(composed, contains('SliceData<T> value => sliceData(value)'));
          expect(
            composed,
            contains('SliceLoading<T> value => sliceLoading(value)'),
          );
          // Morphing carries `T` too — the extension declares it and the target
          // constructor call binds it.
          expect(
            composed,
            contains('extension SliceDataMorphing<T> on SliceData<T>'),
          );
          expect(composed, contains('SliceLoading<T> changeToSliceLoading()'));
          expect(
            composed,
            contains('return SliceLoading<T>.fromTrusted(source: source);'),
          );
          expect(
            composed,
            contains('extension SliceLoadingMorphing<T> on SliceLoading<T>'),
          );
          expect(composed, contains('required T value'));
          expect(
            composed,
            contains(
              'return SliceData<T>.fromTrusted(value: value, source: source);',
            ),
          );
          // copyWith keeps the class's type argument in its return type and
          // its fromTrusted call — the bare name would re-instantiate T as
          // dynamic.
          expect(composed, contains('SliceData<T> copyWith({'));
          expect(composed, contains('SliceLoading<T> copyWith({'));
        },
      );

      test(
        'bounded generic union: T extends num reaches every emitted member',
        () async {
          final composed = composedByLibrary['bounded.dart']!;

          expect(
            composed,
            contains('sealed class BoundedSlice<T extends num>'),
          );
          expect(
            composed,
            contains(
              'final class BoundedData<T extends num> extends BoundedSlice<T>',
            ),
          );
          expect(
            composed,
            contains(
              'extension BoundedSliceWhenE<T extends num> on BoundedSlice<T>',
            ),
          );
          expect(
            composed,
            contains(
              'extension BoundedDataMorphing<T extends num> on BoundedData<T>',
            ),
          );
        },
      );

      test(
        'entity morphing: shared fields pass by reference, only target-owned '
        'fields are asked for',
        () async {
          final composed = composedByLibrary['task.dart']!;

          expect(composed, contains('extension OpenTaskMorphing on OpenTask'));
          expect(composed, contains('DoneTask changeToDoneTask({'));
          // `result` is DoneTask-owned: required. The shared fields are NOT.
          expect(composed, contains('required String result'));
          // The body is long enough that dart format wraps it — pin the pieces.
          expect(composed, contains('return DoneTask.fromTrusted('));
          expect(composed, contains('result: result,'));
          expect(composed, contains('id: id,'));
          expect(composed, contains('createdAt: createdAt,'));
          expect(composed, contains('tags: tags,'));
          expect(composed, contains('extension DoneTaskMorphing on DoneTask'));
          expect(composed, contains('OpenTask changeToOpenTask({'));
          expect(composed, contains('required String assignee'));
          // Matchers are union-only: an entity hierarchy keeps none.
          expect(composed, isNot(contains('TaskWhenE')));
        },
      );

      test('renamed variant parameters bind positionally, and an inherited '
          'generic field redeclares in the leaf scope', () async {
        final composed = composedByLibrary['renamed.dart']!;

        // The class surface keeps the variant's own parameter names.
        expect(composed, contains('final class Closed<U> extends Envelope<U>'));
        // The root's `T get payload` is redeclared as `U` in the leaf —
        // `T` is not in scope there.
        expect(composed, contains('final U payload;'));
        // The matcher binds the variant with the ROOT's parameter: `U` is
        // not in scope inside the extension either.
        expect(composed, contains('extension EnvelopeWhenE<T> on Envelope<T>'));
        expect(composed, contains('Closed<T> value => closed(value)'));
        expect(composed, contains('Opened<T> value => opened(value)'));
        // Morphing reads the target payload in the SOURCE extension's
        // scope: Closed's inherited `payload` (declared `T` on the root)
        // is rebound to the source's `U`, never left an unbound name.
        expect(composed, contains('extension OpenedMorphing<U> on Opened<U>'));
        expect(composed, contains('Closed<U> changeToClosed()'));
        expect(
          composed,
          contains('return Closed<U>.fromTrusted(payload: payload);'),
        );
      });

      test('a variant bound tighter than the root keeps its classes but loses '
          'the matcher and the inbound morph', () async {
        final composed = composedByLibrary['tight_bound.dart']!;

        // The classes compile as declared — nothing is pruned.
        expect(composed, contains('sealed class Measure<T extends num>'));
        expect(
          composed,
          contains('final class Narrow<T extends int> extends Measure<T>'),
        );
        expect(
          composed,
          contains('final class Wide<T extends num> extends Measure<T>'),
        );
        // The matcher is withheld whole: a `Narrow<T>` arm would carry the
        // extension's `num`-bounded `T` into an `int` bound.
        expect(composed, isNot(contains('MeasureWhenE')));
        // The morph into Narrow is withheld for the same reason; the morph
        // out of it has no sibling method to pair with either way.
        expect(composed, isNot(contains('changeToNarrow')));
        expect(composed, isNot(contains('changeToWide')));
      });

      test(
        'variants named Value and OrElse get reserved-safe callback names, '
        'and an exhausted result-parameter list falls through to a suffix',
        () async {
          final composed = composedByLibrary['collision.dart']!;

          // `Value value => value(value)` would hide the callback behind the
          // pattern variable; the reserved-identifier policy renames it.
          expect(composed, contains('Value value => value2(value)'));
          expect(composed, contains('required T Function(Value) value2'));
          // `OrElse` collides with maybeWhen's required `orElse` parameter.
          expect(composed, contains('required T Function(OrElse) orElse2'));
          expect(composed, contains('required T Function() orElse'));
          // T, TResult, TValue and TOut are all declared by the union, so the
          // result parameter is a fresh suffixed name, not a shadowed one.
          expect(composed, contains('TResult2 when<TResult2>({'));
        },
      );

      test('every composed fixture analyzes clean', () async {
        // Fixtures are composed in setUpAll, so this test is
        // order-independent — but only if the full set is actually on disk.
        // Assert the expected fixture count BEFORE the aggregate analysis:
        // analyzing a subset would pass vacuously.
        for (final libraryName in fixtureSources.keys) {
          expect(
            File('${fixtureDir.path}/$libraryName').existsSync(),
            isTrue,
            reason: '$libraryName was not composed in setUpAll',
          );
          expect(
            File('${fixtureDir.path}/${partNameOf(libraryName)}').existsSync(),
            isTrue,
            reason: 'the part for $libraryName was not written in setUpAll',
          );
        }
        expect(composedByLibrary.length, fixtureSources.length);
        final diagnostics = await _diagnostics(fixtureDir);
        expect(diagnostics, isEmpty, reason: diagnostics.join('\n'));
      });
    },
  );
}
