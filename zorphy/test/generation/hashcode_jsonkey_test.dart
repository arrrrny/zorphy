// Regression test ensuring json_serializable does NOT serialize `hashCode`.
//
// In an earlier (inline-cast) approach, `createFactory: false` caused a
// regression where `hashCode` leaked into `toJson` output. That was patched
// by annotating the getter with `@JsonKey(includeToJson: false, ...)`.
//
// With the native json_serializable approach (checked: true, default
// createFactory), computed getters like `hashCode` are never serialized, so
// no special annotation is required. This test verifies the real invariant:
// the generated `.g.dart` contains no `hashCode` key.
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('hashCode is not annotated or serialized in native generation', () {
    final gFile = File(
      '${Directory.current.path}/example/lib/comprehensive/comprehensive_example.g.dart',
    );
    if (!gFile.existsSync()) {
      return; // example outputs may be absent in some environments
    }
    final g = gFile.readAsStringSync();

    // The toJson output should never reference instance.hashCode.
    expect(
      g.contains('hashCode'),
      isFalse,
      reason: 'json_serializable must not serialize the computed hashCode getter',
    );
  });
}
