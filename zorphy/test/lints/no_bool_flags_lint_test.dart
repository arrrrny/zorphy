// Tests for ISSUE-005 (arrrrny/zorphy#180): `ZORPHY_LINT_NO_BOOL_FLAGS`.
//
// The rule exists to stop behavioral mode switches and lifecycle flags from
// being modelled as booleans on a polymorphic node: a state that carries
// `isLoading`/`hasError` has silently re-introduced the null-flag matrix that
// `AsyncSlice<T>` removes, and an intent that carries `forceRefresh`/`silent`
// makes two distinct commands indistinguishable on the wire. Both must be
// reported (and rejectable via `NoBoolFlagsLint.enforce`), with a message that
// names the replacement.
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
      'a union member that only `implements` the root is still in scope',
      () async {
        // `$FailedImpl` reaches the union through `implements $AsyncStatus`,
        // not a factory redirect, so it is not stamped `isUnion` itself. It is
        // a real child of the union and must be checked all the same.
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
class \$FailedImpl implements \$AsyncStatus {
  bool get hasError;
}
'''),
        );

        final hits = _lintHits(ir);
        expect(
          hits.map((d) => d.nodeName),
          contains(r'$FailedImpl'),
          reason: 'an implements-only union member is in scope',
        );
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
      '`@ZorphyDomainBool()` on a REAL field (not a getter) is honoured',
      () async {
        // A real field surfaces as its own implicit getter, so the getter loop
        // claims the name first; the hatch annotation lives on the FIELD. The
        // resolver must read it there too, or an author who annotates a real
        // field is told to annotate the thing they already annotated.
        final ir = await _resolve(
          _fixture('''
@ZorphyState()
abstract class \$UiState {
  @ZorphyDomainBool()
  bool hasError;
}
'''),
        );

        expect(
          _lintHits(ir),
          isEmpty,
          reason: 'the field-form annotation is the author\'s domain claim',
        );
        expect(ir.hasErrors, isFalse);
      },
    );

    test(
      'a real lifecycle field WITHOUT the hatch is still rejected',
      () async {
        final ir = await _resolve(
          _fixture('''
@ZorphyState()
abstract class \$UiState {
  bool hasError;
}
'''),
        );

        final hits = _lintHits(ir);
        expect(hits, hasLength(1));
        expect(hits.single.message, contains('hasError'));
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

  group('ZORPHY_LINT_NO_BOOL_FLAGS — cross-library dedupe', () {
    test(r'two libraries each declaring `$UiState` are BOTH checked', () async {
      // `PolymorphicIr.nodes` keys by `libraryUri#ClassName` precisely so two
      // libraries may declare same-named classes. The walk's `visited` set must
      // key the same way — keyed by bare `className` the first `$UiState`
      // marks the name seen and the second library's node is dropped unexamined.
      ZorphyNodeIr stateNode(String uri, String flagged) => ZorphyNodeIr(
        className: r'$UiState',
        qualifiedName: '$uri#\$UiState',
        cleanName: 'UiState',
        archetype: ArchetypeKind.state,
        isSealedRoot: true,
        isAbstractIntermediate: false,
        isConcreteLeaf: false,
        superTypes: const [],
        directSubTypes: const [],
        allConcreteLeaves: const [],
        discriminatorKey: 'kind',
        discriminatorValue: 'ui_state',
        fields: [ZorphyFieldIr(name: flagged, type: 'bool')],
      );

      final ir = PolymorphicIr(
        nodes: {
          'a.dart#\$UiState': stateNode('a.dart', 'isLoading'),
          'b.dart#\$UiState': stateNode('b.dart', 'hasError'),
        },
        roots: [
          stateNode('a.dart', 'isLoading'),
          stateNode('b.dart', 'hasError'),
        ],
        diagnostics: const [],
      );

      final messages = NoBoolFlagsLint.check(ir).map((d) => d.message).toList();
      expect(
        messages.join('\n'),
        contains('isLoading'),
        reason: 'a.dart\'s flag is reported',
      );
      expect(
        messages.join('\n'),
        contains('hasError'),
        reason: 'b.dart\'s same-named node is NOT dropped',
      );
      expect(messages, hasLength(2));
    });
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
