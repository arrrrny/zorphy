// Golden tests for the GENERIC-entity patch emission (review of #203).
//
// The generic path is the most intricate one — `diff` declares the class's
// type parameters on itself, `apply` narrows the `patchWith` result with a
// cast, and the const empty is reached through the constructor because type
// variables are illegal in const expressions — and neither the `Account`
// golden nor the property suite exercises it.
//
// Two regressions this locks down:
//   * a generic parameter must be matched as an IDENTIFIER, never as a
//     substring: `Token` is not `T`, so a generic entity's concrete `Token`
//     field keeps its `withTokenPatch`/`withTokenPatchFunc` builders;
//   * a generic-typed field keeps the legacy `dynamic` builder parameter
//     rather than the narrowed `T?`.
//
// The fixture is `test/runtime/fixtures/progress_box_patch.golden.txt`,
// byte-identical to `PatchEmitter`'s output for this entity — regenerate it
// deliberately when the emission is meant to change.

import 'dart:io';

import 'package:test/test.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/patch_emitter.dart';

const _goldenPath = 'test/runtime/fixtures/progress_box_patch.golden.txt';

/// A generic entity carrying one field per case the review named: a generic
/// scalar (`T?`), a plain scalar, and a concrete known-class reference whose
/// name merely contains the generic parameter (`Token` ⊃ `T`).
List<NameTypeClassComment> _progressBoxFields() => [
  NameTypeClassComment('value', 'T?', ''),
  NameTypeClassComment('label', 'String', ''),
  NameTypeClassComment('token', 'Token', ''),
];

String _emit() => PatchEmitter().emit(
  className: 'ProgressBox',
  fields: _progressBoxFields(),
  knownClasses: const ['Token'],
  genericTypeNames: const ['T'],
);

void main() {
  group('generic patch emission', () {
    test('emitted patch matches the golden fixture byte for byte', () {
      expect(
        _emit().trim(),
        File(_goldenPath).readAsStringSync().trim(),
        reason:
            'the generic path is locked by this fixture — regenerate '
            '$_goldenPath if the emission changed on purpose',
      );
    });

    test(
      'a generic parameter is matched as an identifier, not a substring',
      () {
        final emitted = _emit();

        // `Token` contains `T`, but it is not `T`: its nested builders must
        // survive, exactly as the legacy `helpers.getPatchClass` emitted them.
        expect(emitted, contains('withTokenPatch(TokenPatch patch)'));
        expect(emitted, contains('withTokenPatchFunc('));
        // And the field is emitted as a nested patch, not a raw scalar.
        expect(
          emitted,
          contains('TokenPatch.diff(previous.token, next.token)'),
        );
      },
    );

    test('a generic-typed field keeps the legacy dynamic builder', () {
      final emitted = _emit();

      expect(
        emitted,
        contains('ProgressBoxPatch withValue(dynamic value)'),
        reason: 'legacy emitted `dynamic` for generic fields (review of #203)',
      );
      expect(
        emitted,
        isNot(contains('withValue(T? value)')),
        reason: 'narrowing a generic builder changed legacy behaviour',
      );
      // A non-generic field keeps its declared (nullable) parameter type.
      expect(emitted, contains('ProgressBoxPatch withLabel(String? value)'));
    });

    test('the type parameters reach the members that need them', () {
      final emitted = _emit();

      expect(emitted, contains('class ProgressBoxPatch<T> extends'));
      expect(emitted, contains('ProgressBox<T> apply(ProgressBox<T> target)'));
      // A static member cannot see the class's type variables.
      expect(emitted, contains('static ProgressBoxPatch<T> diff<T>('));
      // Type variables are illegal in const expressions.
      expect(emitted, contains('return ProgressBoxPatch<T>.empty();'));
      expect(emitted, isNot(contains('static const ProgressBoxPatch')));
    });
  });
}
