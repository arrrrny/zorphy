import 'dart:io';

import 'package:test/test.dart';

/// Regression test for issue #117: cross-entity reference cast emits the
/// abstract `$Type` form, which the analyzer cannot assign to the concrete
/// `Type` form (the field's declared type).
///
/// When a Zorphy entity declares a field whose type is the ABSTRACT form of
/// another Zorphy entity (e.g. `$ArtifactRef get ref;` — the canonical shape
/// emitted by the CLI `FieldNormalizer`, which prepends the `$` prefix to
/// entity references), the generated `.zorphy.dart` part file previously
/// emitted:
///
/// ```dart
/// ref: _patchMap.containsKey(Entity$.ref)
///     ? ((...) as $ArtifactRef)  // abstract supertype
///     : this.ref,
/// ```
///
/// The cast target `$ArtifactRef` is the abstract supertype declared in the
/// source file; the field type is `ArtifactRef` (the concrete subtype
/// generated in the part file). Assigning the supertype to a parameter of
/// the subtype is an illegal downcast — the analyzer reports:
///
/// ```
/// error - entity.zorphy.dart: The argument type 'Object' can't be
///   assigned to the parameter type 'ArtifactRef'.
/// ```
///
/// (The analyzer's downcast analysis reports `Object` because the field type
/// `ArtifactRef` resolves to `Object` while the part file is being
/// generated — see issue #351 background.)
///
/// The fix: emit the cast target via
/// `helpers.replaceDollarTypesWithConcrete(f.type)` so it matches the
/// field's declared (concrete) type. The fixture pair lives at
/// `example/lib/various/issue117_ref/` and `example/lib/various/issue117_repro/`.
void main() {
  final reproFixture =
      File('example/lib/various/issue117_repro/issue117_repro.zorphy.dart');

  late String output;

  setUpAll(() {
    if (!reproFixture.existsSync()) {
      fail(
        'Fixture not generated. Run: cd example && '
        'dart run build_runner build --delete-conflicting-outputs',
      );
    }
    output = reproFixture.readAsStringSync();
  });

  group('issue #117 — cross-entity cast concrete form', () {
    test('field declaration uses the concrete entity type', () {
      expect(output, contains('final Issue117Ref ref;'));
    });

    test('patchWith cast target is the concrete entity type, not \$Type', () {
      // The cast MUST be `as Issue117Ref` (concrete form) — the previous
      // `as $Issue117Ref` (abstract form) caused argument_type_not_assignable.
      // The dart formatter places `as Issue117Ref` on its own line, so we use
      // a regex that matches across newlines.
      expect(
        RegExp(r'\)\s*as\s+Issue117Ref\b').hasMatch(output),
        isTrue,
        reason: 'patchWith cast must target the concrete Issue117Ref form',
      );
      expect(
        RegExp(r'\)\s*as\s+\$Issue117Ref\b').hasMatch(output),
        isFalse,
        reason: 'patchWith cast must NOT target the abstract \$Issue117Ref form',
      );
    });

    test('patchWithIssue117Repro references the patch enum by name', () {
      expect(output, contains('Issue117Repro\$.ref'));
    });

    test('no InvalidType leaks into the generated patch', () {
      expect(output, isNot(contains('InvalidType')));
    });

    test('copyWith parameter uses the concrete entity type', () {
      expect(output, contains('Issue117Ref? ref,'));
    });
  });
}
