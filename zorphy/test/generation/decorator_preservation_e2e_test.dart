// E2E test for issue #135: custom decorators on raw entities must be
// preserved on generated entities by the real build_runner pipeline.
//
// Follows the issue_109_extends_test.dart pattern: the generated part
// file is produced by `dart run build_runner build` inside example/ and
// asserted here. If the artifact is missing the test fails loudly with
// the exact build command.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final generatedFile = File(
    'example/lib/various/decorator_preservation.zorphy.dart',
  );

  late String output;

  setUpAll(() {
    if (!generatedFile.existsSync()) {
      fail(
        'Missing generated file: ${generatedFile.path}\n'
        'Run: cd example && dart run build_runner build '
        '--delete-conflicting-outputs',
      );
    }
    output = generatedFile.readAsStringSync();
  });

  group('#135 decorator preservation (e2e)', () {
    test(
      'SC-1: @Cacheable(ttl: Duration(hours: 1)) ports to generated Task',
      () {
        // Plain entities emit a single generated concrete class.
        final annotations = _annotationsAbove(
          output,
          RegExp(r'^class Task\b'),
        );
        expect(annotations, isNotEmpty, reason: 'generated Task not found');
        expect(
          annotations,
          contains('@Cacheable(ttl: Duration(hours: 1))'),
          reason: 'custom decorator @Cacheable was dropped from Task',
        );
      },
    );

    test('US3: @Cacheable ports to generated concrete Task as well', () {
      final annotations = _annotationsAbove(
        output,
        RegExp(r'^class Task\b'),
      );
      expect(
        annotations,
        contains('@Cacheable(ttl: Duration(hours: 1))'),
        reason: 'custom decorator @Cacheable was dropped from concrete Task',
      );
    });

    test(
      'SC-2/SC-3: multiple decorators with mixed args port verbatim, in order',
      () {
        final annotations = _annotationsAbove(
          output,
          RegExp(r'^abstract class \$Report\b'),
        );
        expect(annotations, isNotEmpty, reason: 'generated \$Report not found');
        expect(
          annotations,
          contains('@Throttle(30, per: Duration(seconds: 5))'),
        );
        expect(annotations, contains('@Audited()'));
        expect(
          annotations.indexOf('@Throttle(30, per: Duration(seconds: 5))'),
          lessThan(annotations.indexOf('@Audited()')),
          reason: 'decorator source order must be preserved',
        );

        final concrete = _annotationsAbove(
          output,
          RegExp(r'^class Report\b'),
        );
        expect(concrete, isNotEmpty);
        expect(
          concrete,
          contains('@Throttle(30, per: Duration(seconds: 5))'),
        );
        expect(concrete, contains('@Audited()'));
      },
    );

    test(
      'SC-5: no @Zorphy/@Zorphy2 directive is re-emitted on generated classes',
      () {
        expect(
          output.contains('@Zorphy('),
          isFalse,
          reason:
              'generator directive @Zorphy must not be re-emitted on '
              'generated classes (recursive generation hazard)',
        );
        expect(
          output.contains('@Zorphy2'),
          isFalse,
          reason: 'directive @Zorphy2 must not be re-emitted either',
        );
      },
    );

    test('SC-4: decorator-free entity emits no ported class annotations', () {
      final annotations = _annotationsAbove(
        output,
        RegExp(r'^class Plain\b'),
      );
      expect(annotations, isNotEmpty, reason: 'generated Plain not found');
      for (final decorator in ['@Cacheable', '@Throttle', '@Audited']) {
        expect(
          annotations.where((a) => a.startsWith(decorator)),
          isEmpty,
          reason: 'no decorator may appear when the raw entity has none',
        );
      }
    });

    test('US1: decorators port to the generated sealed base class', () {
      // Raw `$$Character` (with @Audited()) generates `sealed class
      // Character` — the decorator must port there.
      final annotations = _annotationsAbove(
        output,
        RegExp(r'^sealed class Character\b'),
      );
      expect(
        annotations,
        isNotEmpty,
        reason: 'generated sealed class Character not found',
      );
      expect(annotations, contains('@Audited()'));
    });

    test('US3: decorators port to generated concrete subtype classes', () {
      // Raw `$Hero` (with @Cacheable) generates concrete `class Hero`.
      final annotations = _annotationsAbove(
        output,
        RegExp(r'^class Hero\b'),
      );
      expect(annotations, isNotEmpty, reason: 'generated Hero not found');
      expect(annotations, contains('@Cacheable(ttl: Duration(minutes: 5))'));
    });
  });
}

/// Returns the annotation lines (`@...`) directly above the top-level
/// class declaration matching [declaration], in source order.
///
/// The generated artifacts are dart_style-formatted: class-level
/// annotations occupy their own lines immediately above the declaration.
List<String> _annotationsAbove(String source, RegExp declaration) {
  final lines = source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    if (declaration.firstMatch(lines[i]) != null) {
      final result = <String>[];
      var j = i - 1;
      while (j >= 0 && lines[j].trimLeft().startsWith('@')) {
        result.insert(0, lines[j].trim());
        j--;
      }
      return result;
    }
  }
  return [];
}
