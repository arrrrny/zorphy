// Tests for ISSUE-005 (arrrrny/zorphy#180): `ZORPHY_LINT_NO_BOOL_FLAGS`.
//
// The rule exists to stop behavioral mode switches and lifecycle flags from
// being modelled as booleans on a polymorphic node: a state that carries
// `isLoading`/`hasError` has silently re-introduced the null-flag matrix that
// `AsyncSlice<T>` removes, and an intent that carries `forceRefresh`/`silent`
// makes two distinct commands indistinguishable on the wire. Both are reported
// as `ZORPHY_LINT_NO_BOOL_FLAGS` diagnostics on the resolved IR, with a message
// that names the replacement; `enforce` is the fail-the-build entry point a v3
// caller invokes (the v3 pipeline is not yet the `build_runner` path).
//
// Coverage:
//   - the lifecycle set on `@ZorphyState` and on `@ZorphyUnion` variants;
//   - the behavioral set (`force*`, `skip*`, `bypass*`, `isRetry`, `silent`,
//     `noCache`) on `@ZorphyIntent` and on a polymorphic subtype;
//   - the non-boolean guard (a `String get isLoading` is not a flag);
//   - the escape hatch `@ZorphyDomainBool()` and genuine domain booleans on
//     `@ZorphyEntity` / `@ZorphyValue`;
//   - `NoBoolFlagsLint.enforce` raising an actionable
//     `InvalidGenerationSourceError`.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/lints/no_bool_flags_lint.dart';
import 'package:zorphy/src/parser/hierarchy_resolver.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

const _annotationImport =
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n";

/// Writes [sources] (file name -> contents) into a fresh temp directory,
/// resolves the library at [libraryName] and hands its classes to
/// [HierarchyResolver.resolveLibrary] — the same element-level pattern
/// `test/parser/polymorphic_ir_test.dart` uses.
Future<PolymorphicIr> _resolve(
  Map<String, String> sources, {
  String libraryName = 'nodes.dart',
}) async {
  final root = Directory('test/.no_bool_flags_tmp').absolute.path;
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

/// Resolves EVERY source in [sources] as one graph, the way a multi-library
/// consumer does — the shape two same-named classes live in.
Future<PolymorphicIr> _resolveLibraries(Map<String, String> sources) async {
  final root = Directory('test/.no_bool_flags_tmp').absolute.path;
  Directory(root).createSync(recursive: true);
  final fixture = Directory(root).createTempSync('fixture_');
  for (final entry in sources.entries) {
    File('${fixture.path}/${entry.key}').writeAsStringSync(entry.value);
  }
  final collection = AnalysisContextCollection(includedPaths: [fixture.path]);
  final libraries = <ResolvedLibraryResult>[];
  for (final name in sources.keys) {
    final path = '${fixture.path}/$name';
    libraries.add(
      await collection.contextFor(path).currentSession.getResolvedLibrary(path)
          as ResolvedLibraryResult,
    );
  }
  final ir = HierarchyResolver.resolveLibraries([
    for (final library in libraries) library.element,
  ]);
  await collection.dispose();
  return ir;
}

/// The lint diagnostics [ir] carries, by their rendered message.
List<ZorphyDiagnostic> _lintHits(PolymorphicIr ir) => [
  for (final diagnostic in ir.diagnostics)
    if (diagnostic.codeName == NoBoolFlagsLint.code) diagnostic,
];

/// One single-library fixture whose `nodes.dart` body is [body].
Map<String, String> _fixture(String body) => {
  'nodes.dart': '$_annotationImport\npart \'nodes.zorphy.dart\';\n\n$body',
};

void main() {
  group('ZORPHY_LINT_NO_BOOL_FLAGS — lifecycle flags on states', () {
    test('a `@ZorphyState` lifecycle flag is rejected', () async {
      final ir = await _resolve(
        _fixture('''
@ZorphyState()
abstract class \$UiState {
  List<String> get items;
  bool get isLoading;
}
'''),
      );

      final hits = _lintHits(ir);
      expect(hits, hasLength(1));
      expect(hits.single.nodeName, r'$UiState');
      expect(
        hits.single.message,
        contains('isLoading'),
        reason: 'the message must name the offending field',
      );
      expect(
        hits.single.message,
        contains('AsyncSlice'),
        reason: 'the message must name the replacement',
      );
      expect(ir.hasErrors, isTrue, reason: 'a lint hit blocks generation');
    });

    test('every lifecycle name in the rule set is rejected', () async {
      final ir = await _resolve(
        _fixture('''
@ZorphyState()
abstract class \$UiState {
  bool get isLoading;
  bool get isFetching;
  bool get isCreating;
  bool get isUpdating;
  bool get isDeleting;
  bool get hasError;
}
'''),
      );

      expect(
        _lintHits(ir).map((d) => d.message).toList(),
        hasLength(6),
        reason: 'all six lifecycle names are in the rule set',
      );
    });

    test('a non-boolean lifecycle-named field is allowed', () async {
      final ir = await _resolve(
        _fixture('''
@ZorphyState()
abstract class \$UiState {
  String get isLoading;
}
'''),
      );

      expect(
        _lintHits(ir),
        isEmpty,
        reason: 'the rule targets boolean flags, not the name alone',
      );
    });

    test('a `@ZorphyUnion` variant lifecycle flag is rejected', () async {
      final ir = await _resolve(
        _fixture('''
@ZorphyUnion()
abstract class \$AsyncStatus {
  factory \$AsyncStatus.loading() = \$Loading;
  factory \$AsyncStatus.ready() = \$Ready;
}

@ZorphyValue()
class \$Loading {
  bool get hasError;
}

@ZorphyValue()
class \$Ready {
  String get value;
}
'''),
      );

      final hits = _lintHits(ir);
      expect(hits, hasLength(1));
      expect(hits.single.nodeName, r'$Loading');
      expect(hits.single.message, contains('hasError'));
    });

    test(
      'a member that only `implements` a union root is still checked',
      () async {
        // `isUnion` is stamped for factory variants and for the root itself.
        // A class that reaches the union through `implements $AsyncStatus`
        // is a real child of the root but carries none of those stamps, so
        // reading the flag alone left its flags unreported.
        final ir = await _resolve(
          _fixture('''
@ZorphyUnion()
abstract class \$AsyncStatus {
  factory \$AsyncStatus.loading() = \$Loading;
  factory \$AsyncStatus.ready() = \$Ready;
}

@ZorphyValue()
class \$Loading {
  String get value;
}

@ZorphyValue()
class \$Ready {
  String get value;
}

@ZorphyValue()
class \$Failed implements \$AsyncStatus {
  bool get hasError;
}
'''),
        );

        final hits = _lintHits(ir);
        expect(
          hits,
          hasLength(1),
          reason: 'the implements-only union member is in scope',
        );
        expect(hits.single.nodeName, r'$Failed');
        expect(hits.single.message, contains('hasError'));
      },
    );
  });

  group('ZORPHY_LINT_NO_BOOL_FLAGS — behavioral mode switches', () {
    test(
      '`force*`, `silent` and `noCache` are rejected on an intent',
      () async {
        final ir = await _resolve(
          _fixture('''
@ZorphyIntent(replaySafe: true)
abstract class \$RefreshProducts {
  bool get forceRefresh;
  bool get silent;
  bool get noCache;
}
'''),
        );

        final messages = _lintHits(ir).map((d) => d.message).toList();
        expect(messages, hasLength(3));
        expect(messages.join('\n'), contains('forceRefresh'));
        expect(messages.join('\n'), contains('silent'));
        expect(messages.join('\n'), contains('noCache'));
        for (final message in messages) {
          expect(
            message,
            contains('polymorphic subtype'),
            reason: 'the message must name the replacement',
          );
        }
      },
    );

    test(
      '`isRetry`, `skip*` and `bypass*` are rejected on an intent',
      () async {
        final ir = await _resolve(
          _fixture('''
@ZorphyIntent(replaySafe: false)
abstract class \$SyncAccount {
  bool get isRetry;
  bool get skipValidation;
  bool get bypassCache;
}
'''),
        );

        expect(_lintHits(ir), hasLength(3));
      },
    );

    test('a behavioral flag on a polymorphic subtype is rejected', () async {
      final ir = await _resolve(
        _fixture('''
@ZorphyState()
abstract class \$UiNode {
  String get id;
}

@ZorphyState()
class \$ZfaButtonNode implements \$UiNode {
  String get label;
  bool get silent;
}
'''),
      );

      final hits = _lintHits(ir);
      expect(hits, hasLength(1));
      expect(hits.single.nodeName, r'$ZfaButtonNode');
      expect(hits.single.message, contains('silent'));
    });

    test('a prefix-only name is not a match without the prefix', () async {
      final ir = await _resolve(
        _fixture('''
@ZorphyIntent(replaySafe: true)
abstract class \$RefreshProducts {
  bool get reinforced;
}
'''),
      );

      expect(
        _lintHits(ir),
        isEmpty,
        reason: '`reinforced` does not start with `force`',
      );
    });

    test(
      'two libraries declaring a same-named class are both checked',
      () async {
        // The graph is keyed by qualified name precisely so two libraries may
        // declare same-named classes. A `visited` set keyed by the bare class
        // name reintroduced that collapse: the first `$UiState` marked the
        // name visited and every other library's was dropped unexamined.
        final ir = await _resolveLibraries({
          'a.dart':
              '$_annotationImport'
              '''
part 'a.zorphy.dart';

@ZorphyState()
abstract class \$UiState {
  bool get isLoading;
}
''',
          'b.dart':
              '$_annotationImport'
              '''
part 'b.zorphy.dart';

@ZorphyState()
abstract class \$UiState {
  bool get hasError;
}
''',
        });

        final messages = _lintHits(ir).map((d) => d.message).toList();
        expect(messages, hasLength(2), reason: 'both libraries are in scope');
        expect(messages.join('\n'), contains('isLoading'));
        expect(messages.join('\n'), contains('hasError'));
      },
    );
  });

  group('ZORPHY_LINT_NO_BOOL_FLAGS — the escape hatch', () {
    test(
      '`@ZorphyDomainBool()` allows a lifecycle-named state field',
      () async {
        final ir = await _resolve(
          _fixture('''
@ZorphyState()
abstract class \$UiState {
  @ZorphyDomainBool()
  bool get isLoading;
}
'''),
        );

        expect(
          _lintHits(ir),
          isEmpty,
          reason: 'the annotation is the author\'s explicit domain claim',
        );
        expect(ir.hasErrors, isFalse);
      },
    );

    test('`@ZorphyDomainBool()` on a real FIELD exempts it too', () async {
      // A real field surfaces in `element.getters` as an implicit getter,
      // and the annotation lives on the FIELD. Reading only the getter let
      // the getter loop claim the name first, so the documented hatch never
      // fired for the declaration form the docs show for fields.
      final ir = await _resolve(
        _fixture('''
@ZorphyState()
abstract class \$UiState {
  List<String> get items;
  @ZorphyDomainBool()
  final bool hasError;
  \$UiState(this.hasError);
}
'''),
      );

      expect(
        _lintHits(ir),
        isEmpty,
        reason: 'the annotation on the field is the same domain claim',
      );
      expect(ir.hasErrors, isFalse);
    });

    test('an unannotated real field is still rejected', () async {
      final ir = await _resolve(
        _fixture('''
@ZorphyState()
abstract class \$UiState {
  List<String> get items;
  final bool hasError;
  \$UiState(this.hasError);
}
'''),
      );

      final hits = _lintHits(ir);
      expect(hits, hasLength(1), reason: 'the hatch is opt-in per field');
      expect(hits.single.message, contains('hasError'));
    });

    test(
      '`@ZorphyDomainBool()` allows a behavioral-named intent field',
      () async {
        final ir = await _resolve(
          _fixture('''
@ZorphyIntent(replaySafe: true)
abstract class \$RefreshProducts {
  @ZorphyDomainBool()
  bool get forceRefresh;
}
'''),
        );

        expect(_lintHits(ir), isEmpty);
      },
    );

    test(
      'genuine domain booleans on entities and values are not flags',
      () async {
        final ir = await _resolve(
          _fixture('''
@ZorphyEntity(principalKey: #id)
abstract class \$Product {
  String get id;
  bool get inStock;
}

@ZorphyValue()
abstract class \$UiNode {
  bool get enabled;
}
'''),
        );

        expect(
          _lintHits(ir),
          isEmpty,
          reason: '`inStock`/`enabled` are documented domain booleans',
        );
        expect(ir.hasErrors, isFalse);
      },
    );
  });

  group('NoBoolFlagsLint.enforce', () {
    test('raises an actionable InvalidGenerationSourceError', () async {
      final ir = await _resolve(
        _fixture('''
@ZorphyState()
abstract class \$UiState {
  bool get isLoading;
}
'''),
      );

      expect(
        () => NoBoolFlagsLint.enforce(ir),
        throwsA(
          isA<InvalidGenerationSourceError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('ZORPHY_LINT_NO_BOOL_FLAGS'),
              contains('isLoading'),
              contains('AsyncSlice'),
            ),
          ),
        ),
      );
    });

    test('is a no-op on a clean hierarchy', () async {
      final ir = await _resolve(
        _fixture('''
@ZorphyState()
abstract class \$UiState {
  List<String> get items;
  @ZorphyDomainBool()
  bool get isPinned;
}
'''),
      );

      expect(() => NoBoolFlagsLint.enforce(ir), returnsNormally);
    });
  });
}
