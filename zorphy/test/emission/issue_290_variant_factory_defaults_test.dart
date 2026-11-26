// Regression tests for issue #290: a `@ZorphyUnion` variant factory must
// re-emit the SOURCE declaration's parameter list (names, requiredness and
// declared defaults) and must NOT emit a `const` redirect to a non-const
// `fromTrusted`.
//
// Two defects are covered, both from the issue's `AppFailure` reproduction:
//
//  1. A declared default (`bool isRetryable = false`) was dropped and the
//     parameter rebuilt as `required` from the variant's fields.
//  2. A variant with a collection field has a NON-const `fromTrusted` (the
//     #284 defensive copy), so `const factory … = Variant.fromTrusted;` is a
//     `redirect_to_non_const_constructor` compile error.
//
// The IR is built from resolved analyzer elements (the same view the generator
// sees) and the composed output is compiled with `dart analyze --fatal-infos`
// against `package:zorphy_annotation` — the issue's acceptance gate.

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
  final root = Directory('test/.issue290_tmp').absolute.path;
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

/// The issue's canonical reproduction: a `network` variant with a declared
/// default and a `violation` variant whose collection field makes its
/// `fromTrusted` non-const.
const _appFailure =
    '$_annotationImport'
    '''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class \$AppFailure {
  const factory \$AppFailure.network({
    required String message,
    bool isRetryable = false,
    int? statusCode,
  }) = \$NetworkFailure;
  const factory \$AppFailure.violation({
    required String message,
    List<String> violations = const [],
  }) = \$BoundaryViolationFailure;
}

@ZorphyValue()
class \$NetworkFailure implements \$AppFailure {
  @override
  final String message;
  @override
  final bool isRetryable;
  @override
  final int? statusCode;

  const \$NetworkFailure({
    required this.message,
    this.isRetryable = false,
    this.statusCode,
  });
}

@ZorphyValue()
class \$BoundaryViolationFailure implements \$AppFailure {
  @override
  final String message;
  @override
  final List<String> violations;

  const \$BoundaryViolationFailure({
    required this.message,
    this.violations = const [],
  });
}
''';
// The `violations` element type is `String` rather than the issue's
// `FieldViolation` only to avoid colliding with zorphy_annotation's own
// `FieldViolation` (boundary.dart) in the compile probe — any collection field
// makes `fromTrusted` non-const (#284), which is the symptom under test.

void main() {
  group('#290 union variant factory — emitted source', () {
    test('a declared default survives (not rebuilt as required)', () async {
      final (_, out) = await _compose({'nodes.dart': _appFailure});
      final tight = out
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(',)', ')')
          .replaceAll(',]', ']')
          .replaceAll(',}', '}');
      expect(
        tight,
        contains(
          'factoryAppFailure.network('
          '{requiredStringmessage,boolisRetryable=false,int?statusCode})',
        ),
        reason:
            'the declared default is re-emitted as `bool isRetryable = false` '
            'inside the factory, not dropped or forced required (the same '
            '`required bool isRetryable` legitimately appears on the morphing '
            'extension, so the check is scoped to the factory signature)',
      );
    });

    test(
      'a non-const fromTrusted target is a body factory, not a redirect',
      () async {
        final (_, out) = await _compose({'nodes.dart': _appFailure});
        final tight = out
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll(',)', ')')
            .replaceAll(',]', ']')
            .replaceAll(',}', '}');
        // The violation variant has a collection field → non-const fromTrusted.
        expect(
          tight,
          isNot(contains('=BoundaryViolationFailure.fromTrusted;')),
          reason: 'no const redirect to the non-const fromTrusted',
        );
        expect(
          tight,
          contains(
            'factoryAppFailure.violation('
            '{requiredStringmessage,List<String>violations=const[]})'
            '=>BoundaryViolationFailure.fromTrusted('
            'message:message,violations:violations)',
          ),
          reason: 'a body factory forwards each declared parameter by name',
        );
      },
    );

    test('a declaration with a default becomes a body factory (not a const '
        'redirect)', () async {
      final (_, out) = await _compose({'nodes.dart': _appFailure});
      final tight = out
          .replaceAll(RegExp(r'\s+'), '')
          .replaceAll(',)', ')')
          .replaceAll(',]', ']')
          .replaceAll(',}', '}');
      // NetworkFailure has no collection field, so its fromTrusted is const —
      // but the declaration carries a default, which is illegal on a redirect
      // (`default_value_in_redirecting_factory_constructor`), so the factory
      // must be a body factory forwarding by name.
      expect(
        tight,
        isNot(contains('=NetworkFailure.fromTrusted;')),
        reason: 'a declaration with a default is not a const redirect',
      );
      expect(
        tight,
        contains(
          'factoryAppFailure.network('
          '{requiredStringmessage,boolisRetryable=false,int?statusCode})'
          '=>NetworkFailure.fromTrusted('
          'message:message,isRetryable:isRetryable,statusCode:statusCode)',
        ),
        reason: 'a declaration with a default becomes a body factory',
      );
    });
  });

  group(
    '#290 union variant factory — generated code compiles (dart analyze)',
    () {
      test(
        'AppFailure.network / .violation analyze clean with no wrappers',
        () async {
          final (_, body) = await _compose({'nodes.dart': _appFailure});
          final probeParent = Directory('test/.issue_290_$pid')
            ..createSync(recursive: true);
          final probe = probeParent.createTempSync('issue_290_').absolute;
          addTearDown(() => probe.deleteSync(recursive: true));

          final annotationRoot = Directory.current.parent.uri
              .resolve('zorphy_annotation/')
              .toFilePath();

          File('${probe.path}/pubspec.yaml').writeAsStringSync(
            'name: issue_290_probe\n'
            'environment:\n'
            '  sdk: ">=3.11.0 <4.0.0"\n'
            'dependencies:\n'
            '  zorphy_annotation:\n'
            '    path: $annotationRoot\n',
          );
          Directory('${probe.path}/lib').createSync();
          File('${probe.path}/lib/generated.dart').writeAsStringSync(
            "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n$body",
          );

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
          ], workingDirectory: probe.path);
          expect(
            analyze.exitCode,
            0,
            reason:
                'generated union surface does not compile:\n'
                '${analyze.stdout}\n${analyze.stderr}',
          );
        },
        timeout: const Timeout(Duration(minutes: 6)),
      );
    },
  );
}
