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

/// Composes the v3 surface for the library at [libraryPath] through the
/// production pipeline the generator itself calls.
Future<String> _compose(String libraryPath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [Directory(libraryPath).parent.path],
  );
  try {
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
  } finally {
    await collection.dispose();
  }
}

/// Writes [composed] next to the library as its generated part file, with the
/// `part of` header the shared part carries in a real build.
void _writePart(
  Directory fixtureDir,
  String libraryName,
  String partName,
  String composed,
) {
  File(
    '${fixtureDir.path}/$partName',
  ).writeAsStringSync("part of '$libraryName';\n\n$composed");
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
      final library =
          await context.currentSession.getResolvedLibrary(file.path)
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

      setUpAll(() {
        final root = Directory('test/.issue_231_tmp').absolute.path;
        Directory(root).createSync(recursive: true);
        fixtureDir = Directory(root).createTempSync('fixture_');
      });

      tearDownAll(() {
        if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
        final tmp = Directory('test/.issue_231_tmp');
        if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
      });

      Future<List<String>> composeAndWrite(
        String source,
        String libraryName,
        String partName,
      ) async {
        final libraryPath = '${fixtureDir.path}/$libraryName';
        File(libraryPath).writeAsStringSync(source);
        final composed = await _compose(libraryPath);
        expect(
          composed,
          isNotEmpty,
          reason: 'the composer must emit a surface',
        );
        _writePart(fixtureDir, libraryName, partName, composed);
        return [composed];
      }

      test(
        'union matchers: when + maybeWhen on the AsyncStatus repro',
        () async {
          await composeAndWrite(
            _statusSource,
            'status.dart',
            'status.zorphy.dart',
          );
          final composed = File(
            '${fixtureDir.path}/status.zorphy.dart',
          ).readAsStringSync();

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
        final composed = File(
          '${fixtureDir.path}/status.zorphy.dart',
        ).readAsStringSync();

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
          await composeAndWrite(
            _genericSliceSource,
            'slice.dart',
            'slice.zorphy.dart',
          );
          final composed = File(
            '${fixtureDir.path}/slice.zorphy.dart',
          ).readAsStringSync();

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
        },
      );

      test(
        'bounded generic union: T extends num reaches every emitted member',
        () async {
          await composeAndWrite(
            _boundedSliceSource,
            'bounded.dart',
            'bounded.zorphy.dart',
          );
          final composed = File(
            '${fixtureDir.path}/bounded.zorphy.dart',
          ).readAsStringSync();

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
          await composeAndWrite(_taskSource, 'task.dart', 'task.zorphy.dart');
          final composed = File(
            '${fixtureDir.path}/task.zorphy.dart',
          ).readAsStringSync();

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

      test('every composed fixture analyzes clean', () async {
        // The parts for all four fixtures are on disk by now.
        final diagnostics = await _diagnostics(fixtureDir);
        expect(diagnostics, isEmpty, reason: diagnostics.join('\n'));
      });
    },
  );
}
