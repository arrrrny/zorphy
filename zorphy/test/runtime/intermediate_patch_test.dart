// Runtime tests for ISSUE-0229 (zorphy#229) — the intermediate patch surface.
//
// `test/golden/polymorphic_patch_golden_test.dart` proves WHAT the emitter
// produces (including that its output is byte-identical to the fixture below).
// This suite proves the emitted SHAPE works: an intermediate patch carries its
// own fields, dispatches through each concrete leaf's narrowed `copyWith`, and
// keeps the diff/compose/invert/wire algebra.

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy.dart';

import 'fixtures/intermediate.dart';

void main() {
  final before = DeployEvent(id: 'e1', source: 'ci', payload: 'v1');

  group('ISSUE-0229 intermediate patch in anger', () {
    test('diff omits unchanged fields and applies to a narrowed leaf', () {
      final next = DeployEvent(id: 'e1', source: 'ci', payload: 'v2');

      final patch = SystemEventPatch.diff(before, next);

      expect(patch.toWire(), {'payload': 'v2'});
      expect(
        patch.toWire(),
        isNot(containsPair('id', anything)),
        reason: 'an unchanged field must be omitted from the wire form',
      );
      final applied = patch.apply(before);
      expect(applied, isA<DeployEvent>());
      expect((applied as DeployEvent).payload, 'v2');
      expect(applied.id, 'e1');
      expect(applied.source, 'ci');
    });

    test('apply casts the payload to each leaf declared type', () {
      final alert = AlertEvent(id: 'a1', source: 'ops', payload: 1);

      final applied =
          SystemEventPatch(payload: PatchValue.set(7)).apply(alert)
              as AlertEvent;

      expect(applied.payload, 7);
      expect(applied.source, 'ops');
      expect(applied.id, 'a1');
    });

    test('an empty patch is a zero-copy no-op', () {
      expect(SystemEventPatch().apply(before), same(before));
    });

    test('compose threads left to right and invert round-trips', () {
      final first = SystemEventPatch(source: PatchValue.set('deploy'));
      final second = SystemEventPatch(payload: PatchValue.set('v3'));

      final applied = first.compose(second).apply(before) as DeployEvent;
      expect(applied.source, 'deploy');
      expect(applied.payload, 'v3');

      final undone = first.invert(before).apply(first.apply(before));
      expect(undone.source, before.source);
      expect((undone as DeployEvent).payload, 'v1');
    });

    test('the wire envelope round-trips through fromWire', () {
      final envelope = SystemEventPatch(
        payload: PatchValue.set('v2'),
      ).toEnvelope(principalKey: 'e1');

      expect(envelope['entityType'], 'SystemEvent');
      expect(envelope['patchKind'], 'SystemEvent');

      final decoded = SystemEventPatch.fromWire(envelope);
      expect(decoded.isOk, isTrue);
      expect(decoded.valueOrNull, isA<SystemEventPatch>());
      expect(decoded.valueOrNull!.toWire(), {'payload': 'v2'});
    });

    test('a target outside the hierarchy fails loudly', () {
      expect(
        () => SystemEventPatch(source: PatchValue.set('x')).apply(
          // ignore: argument_type_not_assignable
          _Stranger(id: 's') as dynamic,
        ),
        throwsA(isA<TypeError>()),
        reason:
            'apply is narrowed to SystemEvent, so an alien target is refused '
            'before the leaf dispatch',
      );
    });
  });
}

class _Stranger extends Event {
  const _Stranger({required super.id});
}
