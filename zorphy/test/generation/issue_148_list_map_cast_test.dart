// Tests for issue #148: composite list fields must not be hard-cast at
// the generated cast sites.
//
// A field declared `List<Map<String, dynamic>>` receives raw
// `jsonDecode` payloads as `List<dynamic>` (with `Map<String, dynamic>`
// elements), so the previous list-level casts
// (`value as List<Map<String, dynamic>>` in the copyWithField switch,
// `... as List<Map<String, dynamic>>` in the patch-merge arms) threw an
// uncaught TypeError. The generator must emit json_serializable's
// checked element-wise conversion instead, with an entry-wise Map
// conversion for typed map values (`List<Map<String, String>>` — a
// decoded `Map<String, dynamic>` entry must be converted, not hard-cast;
// CodeRabbit finding on PR #149) and an identity fast path for values
// already carrying the declared runtime type.
//
// Two layers, mirroring the issue_131 test shape:
//
//   1. Golden assertions against the regenerated fixture
//      `example/lib/various/issue_148_list_map_cast_example.zorphy.dart`
//      (regenerate with `dart run build_runner build
//      --delete-conflicting-outputs` in zorphy/example before tests
//      run). Cast-expression expectations are compared against a
//      whitespace-stripped copy of the fixture so the assertions do not
//      depend on how dart_style breaks the long patch arms.
//
//   2. Behavioral checks executed in the example package context via
//      `dart run tool/issue_148_behavior_check.dart` — raw JSON payloads
//      through copyWithField and the patch-merge arms must not throw.
library test.generation.issue_148_list_map_cast_test;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final fixture = File(
    'example/lib/various/issue_148_list_map_cast_example.zorphy.dart',
  );
  final runner = File('example/tool/issue_148_behavior_check.dart');
  late String output;
  // Whitespace-stripped fixture text: robust against formatter line
  // breaks inside the long generated expressions.
  late String compact;

  setUpAll(() {
    if (!fixture.existsSync()) {
      fail(
        'Fixture not generated. Run: cd example && '
        'dart run build_runner build --delete-conflicting-outputs',
      );
    }
    output = fixture.readAsStringSync();
    compact = output.replaceAll(RegExp(r'\s+'), '');
  });

  group('golden: copyWithField switch', () {
    test('the composite list field has a switch arm', () {
      expect(output, contains("case 'marketplaces':"));
      expect(output, contains("case 'errors':"));
      expect(output, contains("case 'payloads':"));
    });

    test('emits checked element-wise conversion, not a hard list cast', () {
      // Fast path keeps an already-typed value; the conversion branch
      // maps the raw list and converts each entry to the declared Map
      // element type (CodeRabbit finding on PR #149) instead of a hard
      // element cast.
      expect(
        compact,
        contains(
          'returncopyWith(marketplaces:'
          '(valueisList<Map<String,dynamic>>?value:'
          '(valueasList<dynamic>)'
          '.map((e)=>eisMap<String,dynamic>'
          '?e:Map<String,dynamic>.from(easMap<dynamic,dynamic>,),).toList()),);',
        ),
      );
      expect(compact, isNot(contains('valueasList<Map')));
      expect(compact, isNot(contains('=>easMap<String,dynamic>')));
    });

    test('nullable list field keeps null-aware semantics', () {
      expect(
        compact,
        contains(
          'returncopyWith(payloads:'
          '(valueisList<Map<String,dynamic>>??value:'
          '(valueasList<dynamic>?)?'
          '.map((e)=>eisMap<String,dynamic>'
          '?e:Map<String,dynamic>.from(easMap<dynamic,dynamic>,),)?.toList()),);',
        ),
      );
    });

    test('primitive fields keep the plain hard cast', () {
      // The fix is scoped to composite list fields; bool/String arms
      // must stay byte-identical to the issue_131 shape.
      expect(output, contains("return copyWith(success: value as bool);"));
    });
  });

  group('golden: patch-merge arms', () {
    test('patchWith arm emits checked element-wise conversion', () {
      expect(
        compact,
        contains(
          'asList<dynamic>)'
          '.map((e)=>eisMap<String,dynamic>'
          '?e:Map<String,dynamic>.from(easMap<dynamic,dynamic>,),).toList())'
          ':this.marketplaces,',
        ),
      );
      expect(
        compact,
        contains(
          'asList<dynamic>)'
          '.map((e)=>eisMap<String,dynamic>'
          '?e:Map<String,dynamic>.from(easMap<dynamic,dynamic>,),).toList())'
          ':this.errors,',
        ),
      );
      expect(compact, isNot(contains(')asList<Map')));
      expect(compact, isNot(contains('=>easMap<String,dynamic>')));
    });

    test('nullable patch arm keeps null-aware semantics', () {
      expect(
        compact,
        contains(
          'asList<dynamic>?)?'
          '.map((e)=>eisMap<String,dynamic>'
          '?e:Map<String,dynamic>.from(easMap<dynamic,dynamic>,),)?.toList())'
          ':this.payloads,',
        ),
      );
    });
  });

  group('golden: typed map values (CodeRabbit finding on PR #149)', () {
    test('switch arm covers the typed-map fixture fields', () {
      expect(output, contains("case 'tags':"));
      expect(output, contains("case 'maybeTags':"));
    });

    test('entries are converted to the declared map element type', () {
      expect(
        compact,
        contains(
          'returncopyWith(tags:'
          '(valueisList<Map<String,String>>?value:'
          '(valueasList<dynamic>)'
          '.map((e)=>eisMap<String,String>'
          '?e:Map<String,String>.from(easMap<dynamic,dynamic>,),).toList()),);',
        ),
      );
      expect(
        compact,
        contains(
          'returncopyWith(maybeTags:'
          '(valueisList<Map<String,String>>??value:'
          '(valueasList<dynamic>?)?'
          '.map((e)=>eisMap<String,String>'
          '?e:Map<String,String>.from(easMap<dynamic,dynamic>,),)?.toList()),);',
        ),
      );
      expect(
        compact,
        contains(
          'asList<dynamic>)'
          '.map((e)=>eisMap<String,String>'
          '?e:Map<String,String>.from(easMap<dynamic,dynamic>,),).toList())'
          ':this.tags,',
        ),
      );
      expect(compact, isNot(contains('=>easMap<String,String>')));
    });
  });

  group('behavior: runner executed in example package context', () {
    test('all runtime checks pass', () async {
      if (!runner.existsSync()) {
        fail(
          'Behavior runner missing: example/tool/issue_148_behavior_check.dart',
        );
      }
      final result = await Process.run('dart', [
        'run',
        'tool/issue_148_behavior_check.dart',
      ], workingDirectory: 'example');
      final stdoutText = result.stdout as String;
      // Surface the runner output for CI debugging on failure.
      expect(stdoutText, contains('ALL CHECKS PASSED'));
      expect(result.exitCode, 0, reason: stdoutText);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
