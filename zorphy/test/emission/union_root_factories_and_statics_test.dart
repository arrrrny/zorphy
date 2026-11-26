// Tests for issue #271 (ZRP-008): `@ZorphyUnion` sealed roots must emit
// redirecting variant factories and forward user-declared static methods and
// body factory constructors, with `$Variant` references rewritten to
// `Variant`.
//
// The IR is built from resolved analyzer elements (the same view the generator
// sees), so every fixture is real Dart source written to a temp directory and
// resolved through `AnalysisContextCollection` — the pattern
// `test/parser/polymorphic_ir_test.dart` already uses. The composed output is
// then compiled with `dart analyze` against `package:zorphy_annotation`, the
// issue's acceptance gate (no hand-written top-level wrappers, analyze clean).

@Timeout(Duration(minutes: 8))
library;

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/emission/archetype_composer.dart';
import 'package:zorphy/src/parser/hierarchy_resolver.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

const _annotationImport =
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n";

/// Resolves the library at [libraryName] from [sources] and composes its v3
/// fragment, returning both the IR and the emitted source.
Future<(PolymorphicIr, String)> _compose(
  Map<String, String> sources, {
  String libraryName = 'nodes.dart',
}) async {
  final root = Directory('test/.union271_tmp').absolute.path;
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
  final composed = const ArchetypeComposer().compose(ir);
  await collection.dispose();
  return (ir, composed);
}

/// The issue's canonical reproduction shape: an `AppFailure` union with a
/// redirecting `network` variant, a body `from` factory and a static helper.
const _appFailure =
    '$_annotationImport'
    '''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class \$AppFailure {
  factory \$AppFailure.network({required String message, String? traceId}) =
      \$NetworkFailure;
  factory \$AppFailure.from(Object error, [StackTrace? st]) {
    return \$AppFailure.network(message: error.toString());
  }
  static String describe(\$AppFailure failure) => failure.toString();
}

@ZorphyValue()
class \$NetworkFailure implements \$AppFailure {
  @override
  final String message;
  @override
  final String? traceId;

  const \$NetworkFailure({required this.message, this.traceId});
}
''';

/// Regression fixture for issue #281: a forwarded body whose string carries
/// `$` in three forms — interpolation (`$amount`), a raw literal (`r'$literal'`)
/// and an escaped dollar (`\$literal`) — while `$NetworkFailure` in the same
/// body is a real identifier that must still be lowered.
const _dollarInBody =
    _annotationImport +
    r'''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class $Invoice {
  factory $Invoice.network({required String message}) = $NetworkFailure;
  static String describe($Invoice invoice, String amount) {
    final kind = $NetworkFailure(message: amount).runtimeType;
    return "charge: $amount; raw: r'\$literal'; kind: $kind";
  }
}

@ZorphyValue()
class $NetworkFailure implements $Invoice {
  @override
  final String message;

  const $NetworkFailure({required this.message});
}
''';

void main() {
  group('#271 union root — IR carries variant factories and user members', () {
    test(
      'the union root node carries one variant factory per redirect',
      () async {
        final (ir, _) = await _compose({'nodes.dart': _appFailure});
        final root = ir.rootFor('AppFailure');
        expect(root, isNotNull);
        expect(root!.isUnion, isTrue);
        expect(root.variantFactories.map((f) => f.name), contains('network'));
        final network = root.variantFactories.firstWhere(
          (f) => f.name == 'network',
        );
        expect(network.variantClassName, '\$NetworkFailure');
      },
    );

    test(
      'the union root node carries user statics and body factories',
      () async {
        final (ir, _) = await _compose({'nodes.dart': _appFailure});
        final root = ir.rootFor('AppFailure')!;
        final names = root.userMembers.map((m) => m.name).toSet();
        expect(names, contains('from'), reason: 'body factory is carried');
        expect(names, contains('describe'), reason: 'static method is carried');
      },
    );
  });

  group('#271 union root — emitted source', () {
    test('emits a redirecting const factory per variant', () async {
      final (_, out) = await _compose({'nodes.dart': _appFailure});
      expect(
        out.replaceAll(RegExp(r'\s+'), ' '),
        contains(
          'const factory AppFailure.network({required String message, '
          'String? traceId}) = NetworkFailure.fromTrusted;',
        ),
      );
    });

    test(r'carries the user body factory with $Variant rewritten', () async {
      final (_, out) = await _compose({'nodes.dart': _appFailure});
      final flat = out.replaceAll(RegExp(r'\s+'), ' ');
      expect(flat, contains('factory AppFailure.from('));
      expect(flat, contains('NetworkFailure.fromTrusted('));
      expect(
        flat,
        isNot(contains('\$NetworkFailure')),
        reason: r'no $Variant reference survives in the output',
      );
    });

    test(r'carries the user static method with $Variant rewritten', () async {
      final (_, out) = await _compose({'nodes.dart': _appFailure});
      final flat = out.replaceAll(RegExp(r'\s+'), ' ');
      expect(flat, contains('static String describe(AppFailure failure)'));
      expect(flat, isNot(contains('\$AppFailure')));
    });

    test('a generic union root keeps its type parameter on the factory', () async {
      const generic =
          '$_annotationImport'
          '''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class \$AsyncSlice<T> {
  factory \$AsyncSlice.ready({required T value}) = \$SliceReady;
}

@ZorphyValue()
class \$SliceReady<T> implements \$AsyncSlice<T> {
  @override
  final T value;

  const \$SliceReady({required this.value});
}
''';
      final (_, out) = await _compose({'nodes.dart': generic});
      final flat = out.replaceAll(RegExp(r'\s+'), ' ');
      expect(flat, contains('sealed class AsyncSlice<T>'));
      // The class carries `<T>`; the redirecting factory is a member of it, so
      // its name does NOT repeat the type parameter (the issue's own example).
      expect(flat, contains('const factory AsyncSlice.ready('));
      expect(flat, contains('= SliceReady.fromTrusted;'));
    });

    test(
      'a factory name that collides with an existing member is skipped',
      () async {
        const collision =
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class \$Result {
  factory \$Result.ok({required int code}) = \$Ok;
  // `describe` collides with the user static below — the redirecting factory
  // for the `describe` variant must be skipped, never emitted twice.
  factory \$Result.describe({required int code}) = \$Ok;
  static String describe(\$Result r) => r.toString();
}

@ZorphyValue()
class \$Ok implements \$Result {
  @override
  final int code;

  const \$Ok({required this.code});
}
''';
        final (_, out) = await _compose({'nodes.dart': collision});
        final flat = out.replaceAll(RegExp(r'\s+'), ' ');
        // The user static survives; the colliding variant factory is dropped.
        expect(flat, contains('static String describe(Result r)'));
        expect(
          flat,
          isNot(contains('factory Result.describe(')),
          reason: 'the colliding redirecting factory is skipped',
        );
      },
    );

    test(
      r'a dollar sign inside a forwarded body string is preserved',
      () async {
        final (_, out) = await _compose({'nodes.dart': _dollarInBody});
        final flat = out.replaceAll(RegExp(r'\s+'), ' ');
        // `$` inside string literals (interpolation, raw, escaped) is prose,
        // not a `$Variant` identifier — the token-aware rewrite must leave it.
        expect(
          flat,
          contains(r"charge: $amount; raw: r'\$literal'; kind: $kind"),
          reason: 'dollar signs in the string survive verbatim',
        );
        expect(
          flat,
          isNot(contains('charge: amount')),
          reason: 'interpolation is not stripped',
        );
        expect(
          flat,
          contains('NetworkFailure(message: amount)'),
          reason: r'real $Variant identifiers are still rewritten',
        );
      },
    );
  });

  group('#271 union root — generated code compiles (dart analyze)', () {
    test(
      'AppFailure.network / .network / .from compile with no wrappers',
      () async {
        final (_, body) = await _compose({'nodes.dart': _appFailure});
        final probeParent = Directory('test/.issue_271_$pid')
          ..createSync(recursive: true);
        final probe = probeParent.createTempSync('issue_271_').absolute;
        addTearDown(() => probe.deleteSync(recursive: true));

        final annotationRoot = Directory.current.parent.uri
            .resolve('zorphy_annotation/')
            .toFilePath();

        File('${probe.path}/pubspec.yaml').writeAsStringSync(
          'name: issue_271_probe\n'
          'environment:\n'
          '  sdk: ">=3.11.0 <4.0.0"\n'
          'dependencies:\n'
          '  zorphy_annotation:\n'
          '    path: $annotationRoot\n',
        );
        Directory('${probe.path}/lib').createSync();
        Directory('${probe.path}/bin').createSync();
        File('${probe.path}/lib/generated.dart').writeAsStringSync(
          "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n$body",
        );
        File('${probe.path}/bin/main.dart').writeAsStringSync(_mainSource);

        final pubGet = Process.runSync('dart', [
          'pub',
          'get',
        ], workingDirectory: probe.path);
        expect(
          pubGet.exitCode,
          0,
          reason: 'dart pub get failed:\n${pubGet.stdout}\n${pubGet.stderr}',
        );

        final analyze = Process.runSync('dart', [
          'analyze',
          '--fatal-infos',
          'lib/generated.dart',
          'bin/main.dart',
        ], workingDirectory: probe.path);
        expect(
          analyze.exitCode,
          0,
          reason:
              'generated union surface does not compile:\n'
              '${analyze.stdout}\n${analyze.stderr}',
        );

        final run = Process.runSync('dart', [
          'run',
          'bin/main.dart',
        ], workingDirectory: probe.path);
        expect(
          run.exitCode,
          0,
          reason:
              'generated union surface failed at runtime:\n'
              '${run.stdout}\n${run.stderr}',
        );
        expect(run.stdout.toString(), contains('ALL CHECKS PASSED'));
      },
      timeout: const Timeout(Duration(minutes: 6)),
    );
  });
}

/// Exercises the generated surface exactly as a consumer would: the
/// redirecting factory, dot-shorthand, and the forwarded body factory — with
/// no hand-written top-level wrapper.
const _mainSource = r'''
import 'package:issue_271_probe/generated.dart';

void _check(bool condition, String label) {
  if (!condition) throw StateError('FAILED: $label');
}

void main() {
  // Redirecting variant factory.
  final a = AppFailure.network(message: 'boom', traceId: 't1');
  _check(a is NetworkFailure, 'network builds a NetworkFailure');
  _check((a as NetworkFailure).message == 'boom', 'message carried');

  // Dot-shorthand (Dart 3) resolves the same redirecting factory.
  final AppFailure b = .network(message: 'dot');
  _check(b is NetworkFailure, 'dot-shorthand builds a NetworkFailure');

  // Forwarded body factory.
  final c = AppFailure.from(StateError('bad'));
  _check(c is NetworkFailure, 'from builds a NetworkFailure');
  _check((c as NetworkFailure).message.contains('bad'), 'from maps the error');

  // Forwarded static method.
  final d = AppFailure.describe(a);
  _check(d.contains('boom'), 'static describe runs');

  print('ALL CHECKS PASSED');
}
''';
