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

    test(
      'a generic union root keeps its type parameter on the factory',
      () async {
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
      },
    );

    // Issue #290 (zuraffa 8.0 adoption): two defects the real AppFailure
    // union exposed — a non-const `fromTrusted` target, and declared defaults
    // being re-derived away from the variant's fields.
    group('#290 — variant factory follows the source declaration', () {
      const declared =
          '$_annotationImport'
          r"""
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class $AppFailure {
  factory $AppFailure.network({
    required String message,
    bool isRetryable = false,
    int? statusCode,
  }) = $NetworkFailure;
  factory $AppFailure.violation({
    required String message,
    List<String> violations = const [],
  }) = $Violation;
}

@ZorphyValue()
class $NetworkFailure implements $AppFailure {
  @override
  final String message;
  @override
  final bool isRetryable;
  final int? statusCode;

  const $NetworkFailure({
    required this.message,
    this.isRetryable = false,
    this.statusCode,
  });
}

@ZorphyValue()
class $Violation implements $AppFailure {
  @override
  final String message;
  final List<String> violations;

  const $Violation({
    required this.message,
    this.violations = const [],
  });
}
""";

      test('a declared default is honoured via a body factory', () async {
        final (_, out) = await _compose({'nodes.dart': declared});
        final flat = out.replaceAll(RegExp(r'[\s,]+'), '');
        // `isRetryable` is non-nullable on the variant; the field-derived list
        // would have emitted `required bool isRetryable`. The source factory
        // declared a default, so the generated one keeps it — as a BODY
        // factory, since Dart forbids defaults on a redirecting one.
        expect(
          flat,
          contains(
            'factoryAppFailure.network({requiredStringmessage'
            'boolisRetryable=falseint?statusCode})'
            '=>NetworkFailure.fromTrusted(message:message'
            'isRetryable:isRetryablestatusCode:statusCode);',
          ),
        );
        // Only the ROOT factory is under test: the variant's own fromTrusted
        // (and copyWithField) legitimately carry `required bool isRetryable`.
        final rootFactory = flat.substring(
          flat.indexOf('factoryAppFailure.network('),
          flat.indexOf('factoryAppFailure.violation('),
        );
        expect(rootFactory, isNot(contains('requiredboolisRetryable')));
      });

      test('a collection-bearing variant never takes a const redirect', () async {
        final (_, out) = await _compose({'nodes.dart': declared});
        final flat = out.replaceAll(RegExp(r'[\s,]+'), '');
        // `violations` is a List, so `Violation.fromTrusted` snapshots it in an
        // initializer list and is NOT const; a const redirect to it would be
        // `redirect_to_non_const_constructor`.
        expect(flat, isNot(contains('constfactoryAppFailure.violation(')));
        expect(
          flat,
          contains(
            'factoryAppFailure.violation({requiredStringmessage'
            'List<String>violations=const[]})'
            '=>Violation.fromTrusted(message:messageviolations:violations);',
          ),
        );
      });

      test('the emitted root compiles (the analyze acceptance gate)', () async {
        final (_, out) = await _compose({'nodes.dart': declared});
        final probe = Directory('test/.union290_tmp').absolute.path;
        Directory(probe).createSync(recursive: true);
        final fixture = Directory(probe).createTempSync('fixture_');
        addTearDown(() => fixture.deleteSync(recursive: true));
        File('${fixture.path}/pubspec.yaml').writeAsStringSync(
          'name: probe_290\n'
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
    });

    // Issue #293: a user body factory constructs a variant the way the SOURCE
    // declares it; the generated leaf only has `fromTrusted`.
    group('#293 — body factories construct variants through fromTrusted', () {
      const bodyFactory =
          '$_annotationImport'
          r"""
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class $AppFailure {
  factory $AppFailure.network({required String message, bool isRetryable = false}) {
    return $NetworkFailure(message: message, isRetryable: isRetryable);
  }
  static Type networkType() => $NetworkFailure;
  static String describe($AppFailure failure, String amount) {
    // `$NetworkFailure(` inside a string must not be touched.
    final literal = 'cost: $amount for $NetworkFailure(...) in prose';
    return '$literal ${failure.runtimeType}';
  }
}

@ZorphyValue()
class $NetworkFailure implements $AppFailure {
  @override
  final String message;
  @override
  final bool isRetryable;

  const $NetworkFailure({required this.message, this.isRetryable = false});
}
""";

      test(r'a $Variant(...) call becomes Variant.fromTrusted(...)', () async {
        final (_, out) = await _compose({'nodes.dart': bodyFactory});
        final flat = out.replaceAll(RegExp(r'[\s,]+'), '');
        expect(
          flat,
          contains(
            'returnNetworkFailure.fromTrusted(message:message'
            'isRetryable:isRetryable);',
          ),
        );
      });

      test(
        'type positions, member accesses, comments and strings are left alone',
        () async {
          final (_, out) = await _compose({'nodes.dart': bodyFactory});
          final flat = out.replaceAll(RegExp(r'\s+'), ' ');
          expect(
            flat,
            contains('static Type networkType() => NetworkFailure;'),
          );
          // The string literal and the comment survive byte-for-byte (modulo the
          // `$AppFailure` parameter type lowering, which is the plain rule).
          expect(
            flat,
            contains(r"'cost: $amount for $NetworkFailure(...) in prose'"),
          );
          expect(flat, isNot(contains('AppFailure.fromTrusted(')));
        },
      );

      test('the emitted root compiles (the analyze acceptance gate)', () async {
        final (_, out) = await _compose({'nodes.dart': bodyFactory});
        final probe = Directory('test/.union293_tmp').absolute.path;
        Directory(probe).createSync(recursive: true);
        final fixture = Directory(probe).createTempSync('fixture_');
        addTearDown(() => fixture.deleteSync(recursive: true));
        File('${fixture.path}/pubspec.yaml').writeAsStringSync(
          'name: probe_293\n'
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
    });

    // Issue #294: a field typed as one of the node's own type parameters can
    // hold a collection at runtime; `==` compared those by identity.
    group('#294 — a type-parameter field compares by content', () {
      const genericLeaf =
          '$_annotationImport'
          r"""
part 'nodes.zorphy.dart';

@ZorphyValue()
class $Box<T> {
  final T payload;
  final String id;

  const $Box({required this.payload, required this.id});
}
""";

      test('== and hashCode route a type-parameter field through the dynamic '
          'collection helpers', () async {
        final (_, out) = await _compose({'nodes.dart': genericLeaf});
        final flat = out.replaceAll(RegExp(r'\s+'), ' ');
        expect(
          flat,
          contains(
            'return other is Box && Box._zorphyCollectionEquals('
            'this.payload, other.payload) && this.id == other.id;',
          ),
        );
        expect(
          flat,
          contains('Object.hashAll([Box._zorphyCollectionHash(payload), id])'),
        );
        expect(flat, contains('static bool _zorphyCollectionEquals('));
        expect(flat, contains('this.id == other.id'));
      });

      test(
        'the emitted class compiles and two Map payloads compare equal',
        () async {
          final (_, out) = await _compose({'nodes.dart': genericLeaf});
          final probe = Directory('test/.box294_tmp').absolute.path;
          Directory(probe).createSync(recursive: true);
          final fixture = Directory(probe).createTempSync('fixture_');
          addTearDown(() => fixture.deleteSync(recursive: true));
          File('${fixture.path}/pubspec.yaml').writeAsStringSync(
            'name: probe_294\n'
            'environment:\n'
            '  sdk: ">=3.11.0 <4.0.0"\n'
            'dependencies:\n'
            '  zorphy_annotation:\n'
            '    path: ${Directory.current.parent.uri.resolve('zorphy_annotation/').toFilePath()}\n'
            'dev_dependencies:\n'
            '  test: any\n',
          );
          Directory('${fixture.path}/lib').createSync();
          Directory('${fixture.path}/test').createSync();
          File('${fixture.path}/lib/emitted.dart').writeAsStringSync(
            "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n$out",
          );
          File('${fixture.path}/test/box_test.dart').writeAsStringSync(r'''
import 'package:test/test.dart';
import 'package:probe_294/emitted.dart';
void main() {
  test('two Boxes with equal Map payloads are == and hash equal', () {
    final a = Box<Map<String, dynamic>>.fromTrusted(
      payload: <String, dynamic>{'name': 'x'},
      id: '1',
    );
    final b = Box<Map<String, dynamic>>.fromTrusted(
      payload: <String, dynamic>{'name': 'x'},
      id: '1',
    );
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
    final c = Box<int>.fromTrusted(payload: 3, id: '1');
    final d = Box<int>.fromTrusted(payload: 3, id: '1');
    expect(c, equals(d));
  });
}
''');
          final pubGet = Process.runSync('dart', [
            'pub',
            'get',
          ], workingDirectory: fixture.path);
          expect(
            pubGet.exitCode,
            0,
            reason: '${pubGet.stdout}${pubGet.stderr}',
          );
          final analyze = Process.runSync('dart', [
            'analyze',
            '--fatal-infos',
            'lib',
            'test',
          ], workingDirectory: fixture.path);
          expect(
            analyze.exitCode,
            0,
            reason: '${analyze.stdout}${analyze.stderr}',
          );
          final run = Process.runSync('dart', [
            'test',
          ], workingDirectory: fixture.path);
          expect(run.exitCode, 0, reason: '${run.stdout}${run.stderr}');
        },
      );
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
      r'a user body factory invoking a variant constructor $Variant(...) is rewritten to Variant.fromTrusted(...)',
      () async {
        const fixture =
            '$_annotationImport'
            r'''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class $AppFailure {
  factory $AppFailure.network({required String message}) = $NetworkFailure;
  factory $AppFailure.fromError(Object error) {
    return $NetworkFailure(message: error.toString());
  }
}

@ZorphyValue()
class $NetworkFailure implements $AppFailure {
  @override
  final String message;
  const $NetworkFailure({required this.message});
}
''';
        final (_, out) = await _compose({'nodes.dart': fixture});
        final flat = out.replaceAll(RegExp(r'\s+'), ' ');
        expect(
          flat,
          contains(
            'factory AppFailure.fromError(Object error) { return '
            'NetworkFailure.fromTrusted(message: error.toString()); }',
          ),
        );
        expect(flat, isNot(contains(r'$NetworkFailure')));
      },
    );

    test(
      r'a generic $Variant<...>(...) rewrites even when the type argument is a function or record type',
      () async {
        // Review of #295: `_constructorInvocationParen` used to bail on `)`/`,`
        // at angle-depth 1, so a body factory constructing a variant with a
        // function-typed or record-typed type argument was silently NOT
        // rewritten and still failed `dart analyze` with #293's error.
        const fixture =
            '$_annotationImport'
            r'''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class $Envelope<T> {
  factory $Envelope.wrap({required T value}) = $Wrapped<T>;
  factory $Envelope.callback(void Function() cb) {
    return $Wrapped<void Function()>(value: cb);
  }
  factory $Envelope.pair((int, String) pair) {
    return $Wrapped<(int, String)>(value: pair);
  }
}

@ZorphyValue()
class $Wrapped<T> implements $Envelope<T> {
  @override
  final T value;
  const $Wrapped({required this.value});
}
''';
        final (_, out) = await _compose({'nodes.dart': fixture});
        final flat = out.replaceAll(RegExp(r'\s+'), ' ');
        expect(
          flat,
          contains('Wrapped<void Function()>.fromTrusted(value: cb)'),
          reason:
              r'function-typed generic argument is rewritten to .fromTrusted',
        );
        expect(
          flat,
          contains('Wrapped<(int, String)>.fromTrusted(value: pair)'),
          reason: r'record-typed generic argument is rewritten to .fromTrusted',
        );
        expect(flat, isNot(contains(r'$Wrapped')));
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
          contains('NetworkFailure.fromTrusted(message: amount)'),
          reason:
              // #293: a `$Variant(...)` constructor invocation in a forwarded
              // body targets the generated leaf's `fromTrusted` — the only
              // constructor it has. Everything else in the body (the raw
              // `r'\$literal'`, the interpolation, the `$kind` reference) is
              // preserved verbatim.
              r'real $Variant identifiers are still rewritten',
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

  // Issue #310 (review finding): the generated `fromJson`/`toJson` compat
  // aliases must not collide with a user member of the same name on a
  // non-generic union root. The user's own member wins and the alias yields.
  group('#310 — compat aliases yield to same-named user members', () {
    const withJsonMembers =
        '$_annotationImport'
        r'''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class $AppFailure {
  factory $AppFailure.network({required String message}) = $NetworkFailure;

  // User statics that collide with the #310 compat aliases. Before the fix
  // these produced duplicate_definition (fromJson) and
  // conflicting_static_and_instance (toJson), so the library stopped compiling.
  static $AppFailure fromJson(Map<String, dynamic> json) =>
      $NetworkFailure(message: json['message'] as String);
  static String toJson($AppFailure failure) => 'custom';
}

@ZorphyValue()
class $NetworkFailure implements $AppFailure {
  @override
  final String message;

  const $NetworkFailure({required this.message});
}
''';

    test('the emitted union root compiles with user fromJson/toJson', () async {
      final (_, body) = await _compose({'nodes.dart': withJsonMembers});
      final flat = body.replaceAll(RegExp(r'\s+'), ' ');

      // The user members survive verbatim...
      expect(flat, contains('static AppFailure fromJson('));
      expect(flat, contains('static String toJson('));
      // ...and the generated aliases yield, for BOTH names. (The leaf still
      // carries its own aliases — it forwards no user members.)
      expect(
        flat,
        isNot(contains('static ZorphyBoundaryResult<AppFailure> fromJson(')),
      );
      final root = body.substring(
        body.indexOf('sealed class AppFailure'),
        body.indexOf('final class NetworkFailure'),
      );
      expect(
        root.replaceAll(RegExp(r'\s+'), ''),
        isNot(contains('Map<String,dynamic>toJson()')),
      );
      // The canonical wire pair is untouched.
      expect(
        flat,
        contains('static ZorphyBoundaryResult<AppFailure> fromWire('),
      );

      final probeParent = Directory('test/.issue_310_$pid')
        ..createSync(recursive: true);
      final probe = probeParent.createTempSync('issue_310_').absolute;
      addTearDown(() => probe.deleteSync(recursive: true));

      File('${probe.path}/pubspec.yaml').writeAsStringSync(
        'name: issue_310_probe\n'
        'environment:\n'
        '  sdk: ">=3.11.0 <4.0.0"\n'
        'dependencies:\n'
        '  zorphy_annotation:\n'
        '    path: ${Directory.current.parent.uri.resolve('zorphy_annotation/').toFilePath()}\n',
      );
      Directory('${probe.path}/lib').createSync();
      File('${probe.path}/lib/generated.dart').writeAsStringSync(
        "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n$body",
      );

      final pubGet = Process.runSync('dart', [
        'pub',
        'get',
      ], workingDirectory: probe.path);
      expect(pubGet.exitCode, 0, reason: '${pubGet.stdout}${pubGet.stderr}');

      final analyze = Process.runSync('dart', [
        'analyze',
        '--fatal-infos',
        'lib/generated.dart',
      ], workingDirectory: probe.path);
      expect(
        analyze.exitCode,
        0,
        reason:
            'generated union surface does not compile:\n'
            '${analyze.stdout}\n${analyze.stderr}',
      );
    }, timeout: const Timeout(Duration(minutes: 6)));
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
