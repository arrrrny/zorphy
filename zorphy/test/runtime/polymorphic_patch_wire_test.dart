// Runtime tests for ISSUE-017 (zorphy#192) — patch wire codecs.
//
// `toWire()` has existed since ISSUE-007/008/009; what this issue adds is the
// DECODE half: `static ZorphyBoundaryResult<Patch> fromWire(Map<String,
// Object?> raw)` on concrete and polymorphic patches, plus the polymorphic
// ENVELOPE (`entityType` / `patchKind` / `ops`) a cross-process transport
// (`ZfaLink`, platform channels) needs to name what it is carrying.
//
// The acceptance gate is twofold and both halves are proven here:
//
//   * a wire round-trip preserves algebraic equivalence — decoding a patch's
//     own wire form and applying it produces the same entity as applying the
//     original patch, across every polymorphic subtype;
//   * a corrupt patch is REJECTED at the boundary, never thrown: the result is
//     a `BoundaryErr` naming the offending JSON pointer.
//
// The fixtures (`fixtures/account.dart`, `fixtures/profile.dart`,
// `fixtures/notification.dart`) carry the emitters' real output, so these
// tests exercise emitted code rather than a hand-written lookalike.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy.dart';

import 'fixtures/account.dart';
import 'fixtures/notification.dart';
import 'fixtures/profile.dart';

void main() {
  group('ISSUE-017 concrete patch fromWire', () {
    test('round-trips the scalar changes toWire rendered', () {
      final patch = AccountPatch()
        ..withName('grace')
        ..withScore(9);

      final result = AccountPatch.fromWire(patch.toWire());

      expect(result.isOk, isTrue, reason: 'a valid wire map must decode');
      final decoded = result.getOrThrow();
      expect(decoded.isEmpty, isFalse);
      expect(
        decoded.apply(const Account(id: 'a1', name: 'ada', score: 1)),
        patch.apply(const Account(id: 'a1', name: 'ada', score: 1)),
        reason: 'the decoded patch must be algebraically equivalent',
      );
    });

    test('decodes an enum field by its name, not its index', () {
      final patch = AccountPatch()..withTier(AccountTier.enterprise);

      final decoded = AccountPatch.fromWire(patch.toWire()).getOrThrow();

      expect(
        decoded.apply(const Account(id: 'a1', name: 'ada', score: 1)).tier,
        AccountTier.enterprise,
      );
    });

    test('round-trips a collection delta', () {
      const previous = Profile(
        id: 'p1',
        displayName: 'ada',
        address: Address(street: 'Main', city: 'Springfield'),
        tags: ['x'],
        scores: {},
      );
      final next = previous.copyWith(tags: const ['x', 'y']);
      final patch = ProfilePatch.diff(previous, next);

      final decoded = ProfilePatch.fromWire(patch.toWire()).getOrThrow();

      expect(decoded.apply(previous).tags, [
        'x',
        'y',
      ], reason: 'a ListPatchOp delta must round-trip through the wire');
    });

    test('round-trips a map delta', () {
      const previous = Profile(
        id: 'p1',
        displayName: 'ada',
        address: Address(street: 'Main', city: 'Springfield'),
        tags: [],
        scores: {},
      );
      final next = previous.copyWith(scores: const {'math': 9});
      final patch = ProfilePatch.diff(previous, next);

      final decoded = ProfilePatch.fromWire(patch.toWire()).getOrThrow();

      expect(decoded.apply(previous).scores, {'math': 9});
    });

    test('round-trips a nested sub-patch as a PatchNested', () {
      const previous = Profile(
        id: 'p1',
        displayName: 'ada',
        address: Address(street: 'Main', city: 'Springfield'),
        tags: [],
        scores: {},
      );
      final next = previous.copyWith(
        address: const Address(street: 'Elm', city: 'Springfield'),
      );
      final patch = ProfilePatch.diff(previous, next);

      final decoded = ProfilePatch.fromWire(patch.toWire()).getOrThrow();

      expect(decoded.apply(previous).address.street, 'Elm');
    });

    test('an absent key leaves the field unchanged', () {
      final decoded = AccountPatch.fromWire(const {}).getOrThrow();

      expect(decoded.isEmpty, isTrue);
    });

    test('an explicit null clears a nullable field', () {
      const before = Account(id: 'a1', name: 'ada', score: 1, note: 'hi');
      final patch = AccountPatch()..withNote(null);

      final decoded = AccountPatch.fromWire(patch.toWire()).getOrThrow();

      expect(decoded.apply(before).note, isNull);
    });
  });

  group('ISSUE-017 corrupt concrete patch rejection', () {
    test('a wrong scalar type is a violation, never a thrown cast', () {
      final result = AccountPatch.fromWire(const {'score': 'not-a-number'});

      expect(result.isOk, isFalse);
      final error = result as BoundaryErr<AccountPatch>;
      expect(
        error.violations.map((v) => v.path),
        contains('/score'),
        reason: 'the violation must name the offending pointer',
      );
    });

    test('a corrupt list op names its position', () {
      final result = ProfilePatch.fromWire(const {
        'tags': {
          'ops': [
            {'op': 'append', 'item': 'y'},
            {'op': 'teleport'},
          ],
        },
      });

      expect(result.isOk, isFalse);
      final error = result as BoundaryErr<ProfilePatch>;
      expect(error.violations.map((v) => v.path), contains('/tags/ops/1'));
    });

    test('a non-map nested value is a violation', () {
      final result = ProfilePatch.fromWire(const {'address': 'Elm St'});

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<ProfilePatch>).violations.map((v) => v.path),
        contains('/address'),
      );
    });
  });

  group('ISSUE-017 polymorphic patch envelope', () {
    test('a shared patch renders and decodes its envelope', () {
      final readAt = DateTime.utc(2026, 11, 22, 10);
      final patch = NotificationPatch.shared(readAt: PatchValue.set(readAt));

      final envelope = patch.toEnvelope();
      expect(envelope['entityType'], 'Notification');
      expect(envelope['patchKind'], 'shared');
      expect(envelope['ops'], {'readAt': readAt});

      final decoded = NotificationPatch.fromWire(envelope).getOrThrow();
      expect(decoded, isA<NotificationSharedPatch>());
    });

    test('the shared envelope reaches every subtype after a round-trip', () {
      final readAt = DateTime.utc(2026, 11, 22, 10);
      final patch = NotificationPatch.shared(readAt: PatchValue.set(readAt));
      final decoded = NotificationPatch.fromWire(
        patch.toEnvelope(),
      ).getOrThrow();

      final notifications = <Notification>[
        const OrderNotification(id: 'o1', itemCount: 2),
        const PriceDropNotification(id: 'p1', newPrice: 19.99),
      ];

      for (final notification in notifications) {
        expect(
          decoded.apply(notification).readAt,
          readAt,
          reason:
              'algebraic equivalence must survive the wire for '
              '${notification.runtimeType}',
        );
      }
    });

    test('a subtype envelope decodes onto the root surface it can express', () {
      final patch = OrderNotificationPatch(itemCount: const PatchValue.set(3));

      final envelope = patch.toEnvelope();
      expect(envelope['entityType'], 'OrderNotification');
      expect(envelope['patchKind'], 'OrderNotification');

      // A generated library gives each concrete leaf a `PatchBase` patch, not
      // one that extends the root patch, so a root-typed decode cannot return
      // a leaf instance. What it MUST do is disclose the op it cannot express
      // rather than silently dropping it.
      final result = NotificationPatch.fromWire(envelope);
      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<NotificationPatch>).violations.map(
          (v) => v.path,
        ),
        contains('/ops/itemCount'),
      );
    });

    test('a subtype envelope whose ops are all shared fields decodes', () {
      final readAt = DateTime.utc(2026, 11, 22, 10);
      final patch = OrderNotificationPatch(readAt: PatchValue.set(readAt));

      final decoded = NotificationPatch.fromWire(
        patch.toEnvelope(),
      ).getOrThrow();

      expect(
        decoded.apply(const OrderNotification(id: 'o1', itemCount: 1)).readAt,
        readAt,
      );
    });

    test('a bare ops map still decodes on a concrete patch', () {
      // `toWire()` keeps its ISSUE-009 contract (the ops map), so a transport
      // that already knows the kind must not be forced through an envelope.
      final patch = OrderNotificationPatch(itemCount: const PatchValue.set(3));

      final decoded = OrderNotificationPatch.fromWire(
        patch.toWire(),
      ).getOrThrow();

      // The fixture entities carry no `operator ==`, so equivalence is read
      // off the field the patch set.
      expect(
        decoded
            .apply(const OrderNotification(id: 'o1', itemCount: 1))
            .itemCount,
        3,
      );
    });

    test('an unknown patchKind is a violation at /patchKind', () {
      final result = NotificationPatch.fromWire(const {
        'entityType': 'Notification',
        'patchKind': 'telepathy',
        'ops': <String, Object?>{},
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<NotificationPatch>).violations.map(
          (v) => v.path,
        ),
        contains('/patchKind'),
      );
    });

    test('a missing patchKind is a violation, never a default', () {
      final result = NotificationPatch.fromWire(const {
        'entityType': 'Notification',
        'ops': <String, Object?>{},
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<NotificationPatch>).violations.map(
          (v) => v.path,
        ),
        contains('/patchKind'),
      );
    });

    test('a wrong entityType is a violation, never a silent accept', () {
      final result = NotificationPatch.fromWire(const {
        'entityType': 'Invoice',
        'patchKind': 'shared',
        'ops': <String, Object?>{},
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<NotificationPatch>).violations.map(
          (v) => v.path,
        ),
        contains('/entityType'),
      );
    });

    test('a corrupt shared field is re-pathed under /ops', () {
      final result = NotificationPatch.fromWire(const {
        'entityType': 'Notification',
        'patchKind': 'shared',
        'ops': {'readAt': 42},
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<NotificationPatch>).violations.map(
          (v) => v.path,
        ),
        contains('/ops/readAt'),
      );
    });
  });

  group('review findings #215', () {
    test('an enum patch survives a JSON envelope hop with a principal key', () {
      final envelope = (AccountPatch()..withTier(AccountTier.enterprise))
          .toEnvelope(principalKey: 'a1');
      final wire = jsonDecode(jsonEncode(envelope)) as Map<String, dynamic>;

      expect(wire['principalKey'], 'a1');
      expect((wire['ops'] as Map)['tier'], 'enterprise');

      final decoded = AccountPatch.fromWire(Map<String, Object?>.from(wire));
      expect(decoded.isOk, isTrue);
      expect(
        decoded
            .getOrThrow()
            .apply(const Account(id: 'a1', name: 'ada', score: 1))
            .tier,
        AccountTier.enterprise,
      );
    });

    test('a corrupt calendar date is a violation, not a normalized date', () {
      final result = NotificationPatch.fromWire(const {
        'entityType': 'Notification',
        'patchKind': 'shared',
        'ops': {'readAt': '2020-01-42'},
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<NotificationPatch>).violations.map(
          (v) => v.path,
        ),
        contains('/ops/readAt'),
      );
    });

    test('a literal op key in a replacement map field round-trips', () {
      final patch = ProfilePatch()..withScores(const {'op': 7});

      final decoded = ProfilePatch.fromWire(patch.toWire()).getOrThrow();
      const before = Profile(
        id: 'p1',
        displayName: 'ada',
        address: Address(street: 'Main', city: 'Springfield'),
        tags: [],
        scores: {},
      );
      expect(decoded.apply(before).scores, {'op': 7});
    });

    test('a literal ops key in a replacement map field round-trips', () {
      final patch = ProfilePatch()..withScores(const {'ops': 7});

      final decoded = ProfilePatch.fromWire(patch.toWire()).getOrThrow();
      const before = Profile(
        id: 'p1',
        displayName: 'ada',
        address: Address(street: 'Main', city: 'Springfield'),
        tags: [],
        scores: {},
      );
      expect(decoded.apply(before).scores, {'ops': 7});
    });

    test('a map delta keeps its ordered steps on the wire', () {
      const before = Profile(
        id: 'p1',
        displayName: 'ada',
        address: Address(street: 'Main', city: 'Springfield'),
        tags: [],
        scores: {},
      );
      final patch = ProfilePatch.diff(
        before,
        before.copyWith(scores: const {'math': 9}),
      );
      final wire = patch.toWire();

      expect(wire['scores'], isA<List<Object?>>());
      expect(ProfilePatch.fromWire(wire).getOrThrow().apply(before).scores, {
        'math': 9,
      });
    });

    test('a nested replacement from null round-trips as a whole value', () {
      const before = Profile(
        id: 'p1',
        displayName: 'ada',
        address: Address(street: 'Main', city: 'Springfield'),
        tags: [],
        scores: {},
      );
      final next = before.copyWith(
        previousAddress: const Address(street: 'Elm', city: 'Springfield'),
      );
      final patch = ProfilePatch.diff(before, next);

      final decoded = ProfilePatch.fromWire(patch.toWire()).getOrThrow();
      expect(decoded.apply(before).previousAddress, next.previousAddress);
    });

    test('a negative list index is a decode violation', () {
      final result = ProfilePatch.fromWire(const {
        'tags': {
          'ops': [
            {'op': 'removeAt', 'index': -1},
          ],
        },
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<ProfilePatch>).violations.map((v) => v.path),
        contains('/tags/ops/0/index'),
      );
    });

    test('an index that cannot be valid after replaceAll is rejected', () {
      final result = ProfilePatch.fromWire(const {
        'tags': {
          'ops': [
            {
              'op': 'replaceAll',
              'items': ['a'],
            },
            {'op': 'append', 'item': 'b'},
            {'op': 'updateAt', 'index': 2, 'item': 'c'},
          ],
        },
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<ProfilePatch>).violations.map((v) => v.path),
        contains('/tags/ops/2/index'),
      );
    });

    test('the root entity name is not a valid patch kind', () {
      final result = NotificationPatch.fromWire(const {
        'entityType': 'Notification',
        'patchKind': 'Notification',
        'ops': <String, Object?>{},
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<NotificationPatch>).violations.map(
          (v) => v.path,
        ),
        contains('/patchKind'),
      );
    });

    test('a shared envelope rejects an op the shared patch cannot express', () {
      final result = NotificationPatch.fromWire(const {
        'entityType': 'Notification',
        'patchKind': 'shared',
        'ops': {'itemCount': 3},
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<NotificationPatch>).violations.map(
          (v) => v.path,
        ),
        contains('/ops/itemCount'),
      );
    });

    test('a subtype field violation is prefixed with /ops', () {
      final result = NotificationPatch.fromWire(const {
        'entityType': 'OrderNotification',
        'patchKind': 'OrderNotification',
        'ops': {'readAt': 42},
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<NotificationPatch>).violations.map(
          (v) => v.path,
        ),
        contains('/ops/readAt'),
      );
    });

    test('an explicit null clear through PatchWireSet wins over a shape', () {
      final patch = AccountPatch.fromWire(const {
        'note': PatchWireSet(null),
        'tier': PatchWireSet(AccountTier.pro),
      });

      expect(patch.isOk, isTrue);
      final applied = patch.getOrThrow().apply(
        const Account(id: 'a1', name: 'ada', score: 1, note: 'old'),
      );
      expect(applied.note, isNull);
      expect(applied.tier, AccountTier.pro);
    });

    test('a descriptor with no value cannot silently clear a scalar', () {
      final result = AccountPatch.fromWire(const {
        'note': {'op': 'set'},
      });

      expect(result.isOk, isFalse);
      expect(
        (result as BoundaryErr<AccountPatch>).violations.map((v) => v.path),
        contains('/note'),
      );
    });
  });
}
