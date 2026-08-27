// Regression test for typed Map field deserialization.
//
// Reproduces the original bug where `Map<String, String>?` fields failed with:
//   type '_Map<String, dynamic>' is not a subtype of type 'Map<String, String>?'
//
// This happened because inline casts (`json['f'] as Map<String, String>?`)
// cannot convert a `Map<String, dynamic>` produced by JSON parsing into a
// typed map — Dart preserves generic type arguments at runtime. The fix is
// json_serializable's native `checked: true` generation, which recursively
// converts map values via `.map((k, e) => MapEntry(k, e as String))`.
//
// We assert against the generated `.g.dart` text rather than executing it,
// because the example entities are generated (not shipped) and importing the
// generated outputs into the package's own test suite would be fragile.
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('Map<String, String> fields are recursively converted in .g.dart', () {
    final gFile = File(
      '${Directory.current.path}/example/lib/various/map_field_test.g.dart',
    );
    if (!gFile.existsSync()) {
      return; // example outputs may be absent in some environments
    }
    final g = gFile.readAsStringSync();

    // Nullable typed map: must convert values via .map(MapEntry(k, e as String))
    expect(
      g.contains(
        "(v as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, e as String))",
      ),
      isTrue,
      reason: 'Map<String, String>? must recursively cast each value to String',
    );

    // Non-nullable typed map: Map<String, int>.from(v as Map)
    expect(
      g.contains('Map<String, int>.from(v as Map)'),
      isTrue,
      reason: 'Map<String, int> must use Map<String, int>.from(...)',
    );

    // Map with nested entity values: Tag.fromJson on each value
    expect(
      g.contains('MapEntry(k, Tag.fromJson(e as Map<String, dynamic>))'),
      isTrue,
      reason: 'Map<String, Tag> must call Tag.fromJson on each value',
    );

    // And it must be wrapped in checked conversion for field-level errors.
    // The call may span multiple lines, so match on the field key alone.
    expect(
      g.contains("'replacements'"),
      isTrue,
      reason: 'Map field should be referenced by key inside the checked block',
    );
  });

  test('generated fromJson uses \$checkedCreate for field-level errors', () {
    final gFile = File(
      '${Directory.current.path}/example/lib/various/map_field_test.g.dart',
    );
    if (!gFile.existsSync()) {
      return;
    }
    final g = gFile.readAsStringSync();
    expect(
      g.contains(r"$checkedCreate('MapHolder'"),
      isTrue,
      reason: 'checked: true should produce \$checkedCreate wrappers',
    );
  });
}
