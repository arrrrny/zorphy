// Runtime test for ZRP-009 (arrrrny/zorphy#272): codec-parameterized
// `toWire` / `fromWire` on a generic class, compiled and EXECUTED.
//
// The golden layer (`test/emission/generic_boundary_codec_test.dart`) pins the
// SHAPE of the emitted code. This layer proves it COMPILES and round-trips —
// the issue's acceptance gate:
//
//   > Generic classes emit compiling `toWire` and `fromWire` with no
//   > hand-written codec boilerplate.
//   > Generated output analyzes clean under `dart analyze --fatal-infos`.
//
// It composes a tiny generic program — a hand-shaped `CreateParams<T>` with
// the EMITTER'S REAL output spliced into its body, nothing hand-written into
// the codec — writes it inside the example package (so `package:` URIs
// resolve), analyzes it with `--fatal-infos`, then runs it.

@Timeout(Duration(minutes: 5))
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/emission/boundary_codec_emitter.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

ZorphyNodeIr _genericValue({
  required String className,
  required List<String> typeParameters,
}) => ZorphyNodeIr(
  className: className,
  cleanName: className.replaceAll(r'$', ''),
  archetype: ArchetypeKind.value,
  isSealedRoot: true,
  isAbstractIntermediate: false,
  isConcreteLeaf: true,
  superTypes: const [],
  directSubTypes: const [],
  allConcreteLeaves: const [],
  discriminatorKey: 'kind',
  discriminatorValue: className.replaceAll(r'$', ''),
  principalKey: null,
  replaySafe: null,
  isSyntheticLeaf: false,
  typeParameters: typeParameters,
);

String _codecFor(ZorphyNodeIr node, Map<String, List<BoundaryField>> fields) =>
    ZorphyEmitter().emitSpecs(
      const BoundaryCodecEmitter().emitCodec(node, fields),
    );

String _indent(String text) => text
    .split('\n')
    .map((line) => line.trimRight().isEmpty ? '' : '  $line')
    .join('\n');

const _checks = r'''
void check(bool condition, String message) {
  if (!condition) throw StateError('FAILED: $message');
}

Map<String, Object?> encodeProduct(Product value) => value.toWire();

void main() {
  // Product is the wrapped type; its own fromWire/toWire are passed directly
  // as the decoder/encoder, exactly as the issue's §3 example shows. A static
  // method is parameterized by ITS OWN type argument, so the call is
  // `CreateParams.fromWire<Product>(...)` — `CreateParams<Product>.fromWire`
  // would parse as a named-constructor invocation.
  final wire = <String, Object?>{
    'data': <String, Object?>{'sku': 'sku-1', 'price': 9.5},
    'idempotencyKey': 'idem-7',
  };

  final ok = CreateParams.fromWire<Product>(wire, Product.fromWire);
  check(ok.isOk, 'a well-formed generic payload decodes');
  final params = ok.getOrThrow();
  check(params.data.sku == 'sku-1', 'the wrapped value decoded');
  check(params.idempotencyKey == 'idem-7', 'the scalar field decoded');

  final encoded = params.toWire(encodeProduct);
  check((encoded['data'] as Map)['sku'] == 'sku-1', 'the wrapped value encoded');
  check(encoded['idempotencyKey'] == 'idem-7', 'the scalar re-encoded');

  // An absent nullable scalar is legal.
  final noKey = CreateParams.fromWire<Product>(
    <String, Object?>{'data': <String, Object?>{'sku': 'sku-2', 'price': 1}},
    Product.fromWire,
  );
  check(noKey.isOk, 'a missing nullable field is not a violation');

  // A corrupt wrapped value merges the inner violation under /data.
  final bad = CreateParams.fromWire<Product>(
    <String, Object?>{'data': <String, Object?>{'sku': 7, 'price': 'x'}},
    Product.fromWire,
  );
  check(!bad.isOk, 'a corrupt wrapped value is an error');
  final paths = (bad as BoundaryErr<CreateParams<Product>>).violations
      .map((v) => v.path)
      .toList();
  check(paths.any((p) => p.startsWith('/data')), 'the inner violation re-paths under /data');

  print('ALL GENERIC BOUNDARY CHECKS PASSED');
}
''';

String _buildProgram() {
  final node = _genericValue(
    className: r'$CreateParams',
    typeParameters: ['T'],
  );
  final product = _genericValue(
    className: r'$Product',
    typeParameters: const [],
  );
  final fields = <String, List<BoundaryField>>{
    r'$CreateParams': const [
      BoundaryField(name: 'data', type: 'T'),
      BoundaryField(name: 'idempotencyKey', type: 'String?'),
    ],
    // The hand-shaped wrapped type's own decode needs `_boundaryAs` +
    // `_boundaryDouble`; listing it here keeps the helper set complete without
    // pulling in the list/date-time helpers nothing calls.
    r'$Product': const [
      BoundaryField(name: 'sku', type: 'String'),
      BoundaryField(name: 'price', type: 'double'),
    ],
  };
  // Only the helpers the codecs actually call — an unreferenced helper is an
  // `unused_element` warning that `--fatal-infos` would treat as fatal.
  final helpers = ZorphyEmitter().emitSpecs(
    BoundaryCodecEmitter.usedHelperSpecs([node, product], fields),
  );

  return '''
// GENERATED BY test/runtime/generic_boundary_codec_test.dart — do not edit.
import 'package:zorphy_annotation/zorphy_annotation.dart';

final class Product {
  final String sku;
  final double price;

  const Product.fromTrusted({required this.sku, required this.price});

  static ZorphyBoundaryResult<Product> fromWire(Map<String, Object?> raw) {
    final violations = <FieldViolation>[];
    final Object? raw_sku = raw['sku'];
    String? _sku;
    _sku = _boundaryAs<String>(raw_sku, '/sku', violations);
    final Object? raw_price = raw['price'];
    double? _price;
    _price = _boundaryDouble(raw_price, '/price', violations);
    if (violations.isNotEmpty) {
      return BoundaryErr<Product>(
          targetType: 'Product', violations: violations);
    }
    return BoundaryOk<Product>(
        Product.fromTrusted(sku: _sku!, price: _price!));
  }

  Map<String, Object?> toWire() {
    final map = <String, Object?>{};
    map['sku'] = this.sku;
    map['price'] = this.price;
    return map;
  }
}

final class CreateParams<T> {
  final T data;
  final String? idempotencyKey;

  const CreateParams.fromTrusted({
    required this.data,
    this.idempotencyKey,
  });

${_indent(_codecFor(node, fields))}
}

$helpers
$_checks
''';
}

void main() {
  test('generic emitted codec compiles clean and round-trips', () {
    final program = _buildProgram();

    final directory = Directory(
      'example/.dart_tool/zorphy_272_runtime',
    ).absolute..createSync(recursive: true);
    addTearDown(() {
      if (directory.existsSync()) directory.deleteSync(recursive: true);
    });

    final file = File('${directory.path}/generic_boundary_program.dart')
      ..writeAsStringSync(program);

    // Acceptance: the generated output analyzes clean under --fatal-infos.
    final analyze = Process.runSync(
      Platform.resolvedExecutable,
      ['analyze', '--fatal-infos', file.path],
      workingDirectory: 'example',
      stdoutEncoding: const SystemEncoding(),
      stderrEncoding: const SystemEncoding(),
    );
    final analyzeOutput = '${analyze.stdout}\n${analyze.stderr}';
    expect(
      analyze.exitCode,
      0,
      reason: 'generated generic program failed to analyze:\n$analyzeOutput',
    );

    final result = Process.runSync(
      Platform.resolvedExecutable,
      ['run', file.path],
      workingDirectory: 'example',
      stdoutEncoding: const SystemEncoding(),
      stderrEncoding: const SystemEncoding(),
    );

    final output = '${result.stdout}\n${result.stderr}';
    expect(
      result.exitCode,
      0,
      reason: 'generated generic program failed:\n$output',
    );
    expect(output, contains('ALL GENERIC BOUNDARY CHECKS PASSED'));
  });
}
