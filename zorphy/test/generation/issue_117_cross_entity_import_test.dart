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
///
/// Extended fixtures test additional code paths:
/// - `issue117_manual_json/` — manual non-generic fromJson
/// - `issue117_generic/` — manual generic fromJson
/// - `issue117_interface/` — interface-specific patchWith
void main() {
  final reproFixture =
      File('example/lib/various/issue117_repro/issue117_repro.zorphy.dart');
  final manualJsonFixture =
      File('example/lib/various/issue117_manual_json/issue117_manual_json.zorphy.dart');
  final genericFixture =
      File('example/lib/various/issue117_generic/issue117_generic.zorphy.dart');
  final interfaceFixture =
      File('example/lib/various/issue117_interface/issue117_interface.zorphy.dart');

  late String output;
  late String manualJsonOutput;
  late String genericOutput;
  late String interfaceOutput;

  setUpAll(() {
    if (!reproFixture.existsSync()) {
      fail(
        'Fixture not generated. Run: cd example && '
        'dart run build_runner build --delete-conflicting-outputs',
      );
    }
    output = reproFixture.readAsStringSync();

    if (manualJsonFixture.existsSync()) {
      manualJsonOutput = manualJsonFixture.readAsStringSync();
    }
    if (genericFixture.existsSync()) {
      genericOutput = genericFixture.readAsStringSync();
    }
    if (interfaceFixture.existsSync()) {
      interfaceOutput = interfaceFixture.readAsStringSync();
    }
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

  group('issue #117 — manual non-generic fromJson cast', () {
    test('manual fromJson cast uses concrete entity type, not \$Type', () {
      if (!manualJsonFixture.existsSync()) {
        markTestSkipped('Manual JSON fixture not generated');
        return;
      }

      // The manual fromJson code path (json_generator.dart line 89) must emit:
      //   ... as Issue117Ref : null
      // NOT:
      //   ... as $Issue117Ref : null
      expect(
        RegExp(r'as\s+Issue117Ref\??\s*:\s*null').hasMatch(manualJsonOutput),
        isTrue,
        reason: 'manual fromJson cast must target concrete Issue117Ref',
      );
      expect(
        RegExp(r'as\s+\$Issue117Ref\??\s*:\s*null').hasMatch(manualJsonOutput),
        isFalse,
        reason: 'manual fromJson cast must NOT target abstract \$Issue117Ref',
      );
    });

    test('field declaration uses the concrete entity type', () {
      if (!manualJsonFixture.existsSync()) {
        markTestSkipped('Manual JSON fixture not generated');
        return;
      }
      expect(manualJsonOutput, contains('final Issue117Ref? ref;'));
    });

    test('no InvalidType leaks into the generated code', () {
      if (!manualJsonFixture.existsSync()) {
        markTestSkipped('Manual JSON fixture not generated');
        return;
      }
      expect(manualJsonOutput, isNot(contains('InvalidType')));
    });
  });

  group('issue #117 — manual generic fromJson cast', () {
    test('manual generic fromJson cast uses concrete entity type, not \$Type', () {
      if (!genericFixture.existsSync()) {
        markTestSkipped('Generic fixture not generated');
        return;
      }

      // The manual generic fromJson code path (json_generator.dart line 248) must emit:
      //   ... as Issue117Ref : null
      // NOT:
      //   ... as $Issue117Ref : null
      expect(
        RegExp(r'as\s+Issue117Ref\??\s*:\s*null').hasMatch(genericOutput),
        isTrue,
        reason: 'manual generic fromJson cast must target concrete Issue117Ref',
      );
      expect(
        RegExp(r'as\s+\$Issue117Ref\??\s*:\s*null').hasMatch(genericOutput),
        isFalse,
        reason: 'manual generic fromJson cast must NOT target abstract \$Issue117Ref',
      );
    });

    test('field declaration uses the concrete entity type', () {
      if (!genericFixture.existsSync()) {
        markTestSkipped('Generic fixture not generated');
        return;
      }
      expect(genericOutput, contains('final Issue117Ref? ref;'));
    });

    test('generic fromJson has type parameters', () {
      if (!genericFixture.existsSync()) {
        markTestSkipped('Generic fixture not generated');
        return;
      }
      // Verify this is actually a generic entity
      expect(
        RegExp(r'factory\s+Issue117Generic\s*<').hasMatch(genericOutput),
        isTrue,
        reason: 'fromJson should be generic',
      );
    });

    test('no InvalidType leaks into the generated code', () {
      if (!genericFixture.existsSync()) {
        markTestSkipped('Generic fixture not generated');
        return;
      }
      expect(genericOutput, isNot(contains('InvalidType')));
    });
  });

  group('issue #117 — interface-specific patchWith cast', () {
    test('interface-specific patchWith cast uses concrete entity type, not \$Type', () {
      if (!interfaceFixture.existsSync()) {
        markTestSkipped('Interface fixture not generated');
        return;
      }

      // The interface-specific patchWith code path (patch_generator.dart line 97) must emit:
      //   ) as Issue117Ref
      // NOT:
      //   ) as $Issue117Ref
      // This applies to the patchWithIssue117Ref method (interface-specific method).
      expect(
        RegExp(r'\)\s*as\s+Issue117Ref\b').hasMatch(interfaceOutput),
        isTrue,
        reason: 'interface-specific patchWith cast must target concrete Issue117Ref',
      );
      expect(
        RegExp(r'\)\s*as\s+\$Issue117Ref\b').hasMatch(interfaceOutput),
        isFalse,
        reason: 'interface-specific patchWith cast must NOT target abstract \$Issue117Ref',
      );
    });

    test('patchWithIssue117Ref method exists (interface-specific)', () {
      if (!interfaceFixture.existsSync()) {
        markTestSkipped('Interface fixture not generated');
        return;
      }
      // Verify the interface-specific patchWith method is generated
      expect(
        interfaceOutput,
        contains('patchWithIssue117Ref'),
        reason: 'interface-specific patchWithIssue117Ref method should be generated',
      );
    });

    test('field declarations use concrete entity types', () {
      if (!interfaceFixture.existsSync()) {
        markTestSkipped('Interface fixture not generated');
        return;
      }
      // Inherited field from interface
      expect(interfaceOutput, contains('final String id;'));
      // Additional cross-entity field
      expect(interfaceOutput, contains('final Issue117Ref? relatedRef;'));
    });

    test('no InvalidType leaks into the generated code', () {
      if (!interfaceFixture.existsSync()) {
        markTestSkipped('Interface fixture not generated');
        return;
      }
      expect(interfaceOutput, isNot(contains('InvalidType')));
    });
  });
}
