// Real migration pipeline for issue #235 (review finding on PR #238).
//
// The codemod's string-level tests cannot see a type error in the generated
// consumer. This test drives the SHIPPED CLI over both #235 reproductions:
//   v2 build_runner build + dart analyze
//     -> `dart run zorphy:migrate_v3 lib --apply`
//   v3 build_runner build + dart analyze
//     -> runtime decode / corrupt-wire / encode round-trip assertions.
//
// A throwaway package keeps the two codegen cycles out of the checkout's
// `example/` tree, so the repo's own prepared workspace is untouched.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  test(
    'v2 build/analyze -> migrate_v3 -> v3 build/analyze -> runtime checks',
    () async {
      final checkout = Directory.current;
      final probe = await Directory.systemTemp.createTemp(
        'zorphy_migration_pipeline_',
      );
      addTearDown(() {
        if (probe.existsSync()) probe.deleteSync(recursive: true);
      });
      _writePipelinePackage(probe, checkout);

      // Both reproductions are valid v2 consumers before the migration.
      await _run(probe, 'dart', ['pub', 'get'], 'pub get');
      await _run(probe, 'dart', ['run', 'build_runner', 'build'], 'v2 build');
      await _run(probe, 'dart', ['analyze', 'lib'], 'v2 analyze');

      // Exercise the real CLI (whole-tree first pass), not the codemod class
      // directly, so the migration under test is the one users run.
      await _run(probe, 'dart', [
        'run',
        'zorphy:migrate_v3',
        'lib',
        '--apply',
      ], 'migrate_v3');
      final product = File('${probe.path}/lib/product.dart').readAsStringSync();
      expect(product, contains('Product.fromWire(map).getOrThrow()'));
      expect(product, isNot(contains("part 'product.g.dart';")));
      final child = File('${probe.path}/lib/child.dart').readAsStringSync();
      expect(child, contains('@ZorphyEntity(principalKey: #id)'));

      // These calls only compile against the v3 wire API, so write them after
      // the migration and include them in the v3 analysis gate.
      File('${probe.path}/bin/check.dart').writeAsStringSync(_runtimeCheck);

      await _run(probe, 'dart', ['run', 'build_runner', 'build'], 'v3 build');
      await _run(probe, 'dart', ['analyze', 'lib', 'bin'], 'v3 analyze');
      final runtime = await _run(probe, 'dart', [
        'run',
        'bin/check.dart',
      ], 'runtime check');
      expect(runtime.stdout, contains('ALL CHECKS PASSED'));
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

void _writePipelinePackage(Directory probe, Directory checkout) {
  final annotationRoot = Directory(
    '${checkout.parent.path}/zorphy_annotation',
  ).absolute.path;
  final zorphyRoot = checkout.absolute.path;

  File('${probe.path}/pubspec.yaml').writeAsStringSync('''
name: migration_pipeline_probe
description: throwaway migration pipeline probe
publish_to: none
environment:
  sdk: ">=3.11.0 <4.0.0"
dependencies:
  zorphy_annotation:
    path: '$annotationRoot'
  json_annotation: ^4.12.0
dev_dependencies:
  zorphy:
    path: '$zorphyRoot'
  build_runner: ^2.17.1
  json_serializable: ^6.14.0

dependency_overrides:
  zorphy_annotation:
    path: '$annotationRoot'
''');

  // The shared-part generator emits an intentionally unused `_sentinel`; keep
  // that pre-existing warning out of the pipeline's clean-analyze gate.
  File('${probe.path}/analysis_options.yaml').writeAsStringSync('''
analyzer:
  errors:
    unused_element: ignore
''');

  File('${probe.path}/build.yaml').writeAsStringSync('''
targets:
  \$default:
    builders:
      zorphy:zorphy:
        enabled: true
      json_serializable:
        enabled: true
        options:
          explicit_to_json: false
          include_if_null: false
          generic_argument_factories: true
''');

  Directory('${probe.path}/lib').createSync();
  Directory('${probe.path}/bin').createSync();

  // Case 1: a returned `fromJson` whose generated `fromWire` returns a
  // ZorphyBoundaryResult, plus the v2 `part '*.g.dart'` that v3 no longer
  // generates.
  File('${probe.path}/lib/product.dart').writeAsStringSync(r'''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'product.g.dart';
part '_br_/product.part.dart';

@Zorphy(generateJson: true)
abstract class $Product {
  String get id;
  String get name;
}

Product decode(Map<String, Object?> map) => Product.fromJson(map);
Map<String, Object?> encode(Product product) => product.toJson();
''');

  // Case 2: the whole-tree archetype map must keep a child that inherits `id`
  // from a parent in another file an entity. Part files keep one library (so
  // the generator can resolve the hierarchy) while still exercising the
  // codemod's cross-file first pass.
  File('${probe.path}/lib/hierarchy.dart').writeAsStringSync(r'''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part '_br_/hierarchy.part.dart';
part 'base.dart';
part 'child.dart';
''');
  File('${probe.path}/lib/base.dart').writeAsStringSync(r'''
part of 'hierarchy.dart';

@Zorphy()
abstract class $Entity {
  String get id;
}
''');
  File('${probe.path}/lib/child.dart').writeAsStringSync(r'''
part of 'hierarchy.dart';

@Zorphy()
abstract class $Order implements $Entity {
  String get orderNumber;
}
''');
}

const String _runtimeCheck = r'''
import 'package:migration_pipeline_probe/hierarchy.dart';
import 'package:migration_pipeline_probe/product.dart';

void main() {
  // A valid wire decodes to the declared type.
  final product = Product.fromWire(const {'id': 'p1', 'name': 'Widget'})
      .getOrThrow();
  if (product.id != 'p1' || product.name != 'Widget') {
    throw StateError('bad decode: $product');
  }

  // A corrupt wire fails at the boundary with StateError, never TypeError.
  try {
    Product.fromWire(const {'id': 42, 'name': 'Widget'}).getOrThrow();
    throw StateError('corrupt wire did not throw');
  } on StateError catch (e) {
    if (!e.toString().contains('violation')) rethrow;
  }

  // Encoding round-trips.
  final round = Product.fromWire(product.toWire()).getOrThrow();
  if (round != product) throw StateError('encode round-trip failed');

  // The cross-file hierarchy stays an entity and decodes its inherited id.
  final order = Order.fromWire(const {'id': 'e1', 'orderNumber': 'A-1'})
      .getOrThrow();
  if (order.orderNumber != 'A-1' || order.toWire()['id'] != 'e1') {
    throw StateError('cross-file hierarchy failed: $order');
  }

  print('ALL CHECKS PASSED');
}
''';

/// Runs [executable] in [dir], failing the test with the full output when the
/// pipeline step exits non-zero.
Future<ProcessResult> _run(
  Directory dir,
  String executable,
  List<String> arguments,
  String label,
) async {
  final result = await Process.run(
    executable,
    arguments,
    workingDirectory: dir.path,
  );
  final output = '${result.stdout ?? ''}\n${result.stderr ?? ''}';
  expect(
    result.exitCode,
    0,
    reason: '$label failed (exit ${result.exitCode}):\n$output',
  );
  return result;
}
