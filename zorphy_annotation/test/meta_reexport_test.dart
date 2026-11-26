// Finding 1 of arrrrny/zorphy#274: the v2 annotation package re-exported
// `package:meta/meta.dart`, so a consumer that imported `@protected` /
// `@immutable` through `zorphy_annotation` kept compiling. The v3 barrel
// dropped that re-export (and the `meta` dependency), so the same consumer
// fails to compile after `migrate_v3`. The single documented import must
// resolve the `package:meta` annotations again.
import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

void main() {
  test('package:meta annotations are re-exported from the barrel', () {
    // Referencing the top-level `immutable` / `protected` constants proves
    // they resolve through `package:zorphy_annotation/zorphy_annotation.dart`
    // alone — the import a migrated consumer already has.
    expect(immutable, isNotNull);
    expect(protected, isNotNull);
  });
}
