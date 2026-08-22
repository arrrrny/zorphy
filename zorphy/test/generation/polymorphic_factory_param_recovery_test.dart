// Regression test: source-recovery of a static factory parameter whose
// declared type is a polymorphic subtype that the analyzer cannot resolve
// during generation (e.g. `UrlSpark` in `Zik.fromUrlSpark`).
//
// The parameter shares its name with a class member of a different type
// (`Spark? get spark`). Recovery must read the parameter's type from the
// enclosing executable's signature (`UrlSpark spark`) and must NOT fall back
// to the same-named getter (`Spark? get spark`).
//
// This also guards the generic-param case (`Map<String, int> spark`): the
// recovered type must include the full generic (commas inside `<>` must not
// be treated as parameter separators).

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/common/helpers.dart' as common_helpers;

const _src = '''
abstract class \$Base {
  String get id;
  BaseType? get spark;
  static Base create({required BaseType? spark}) => Base(spark: spark);
  static Base fromSub({required SubType spark}) => Base(spark: spark);
}
''';

Future<String> _recoverForParam(String methodName, String paramName) async {
  final dir = Directory.systemTemp.createTempSync('zorphy_poly');
  final f = File('${dir.path}/a.dart')..writeAsStringSync(_src);
  final collection = AnalysisContextCollection(includedPaths: [f.path]);
  final ctx = collection.contextFor(f.path);
  final result =
      await ctx.currentSession.getResolvedUnit(f.path) as ResolvedUnitResult;
  final lib = result.libraryElement as LibraryElement;
  final el = lib.getClass('\$Base')!;
  for (final m in (el as dynamic).methods) {
    if ((m as dynamic).name == methodName) {
      for (final p in (m as dynamic).formalParameters) {
        if ((p as dynamic).name == paramName) {
          // InvalidType simulates the analyzer failing to resolve the subtype
          // during generation — exactly when source recovery kicks in.
          return common_helpers.recoverTypeFromSource(p as Element, 'InvalidType');
        }
      }
    }
  }
  return '';
}

void main() {
  test('polymorphic subtype param recovers its declared type', () async {
    final recovered = await _recoverForParam('fromSub', 'spark');
    expect(recovered, 'SubType');
  });

  test('same-named field-type param is not shadowed by the getter', () async {
    // `create`'s `spark` is declared as `BaseType?` (the field type), which is
    // also the getter's type. Recovery must still return `BaseType?`, not a
    // wrong subtype, and must not crash.
    final recovered = await _recoverForParam('create', 'spark');
    expect(recovered, 'BaseType?');
  });
}
