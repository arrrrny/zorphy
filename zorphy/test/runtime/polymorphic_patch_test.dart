// Runtime tests for ISSUE-009 (zorphy#184) — polymorphic patches in anger.
//
// `test/golden/polymorphic_patch_golden_test.dart` proves WHAT the emitter
// produces. This suite proves the emitted SHAPE works: the fixture carries a
// `Notification` sealed hierarchy whose patches were produced by
// `PolymorphicPatchEmitter`, and these tests exercise them the way `ZfaStore`
// would — a `markAllRead` over a heterogeneous list, without downcasting.

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy.dart';

import 'fixtures/notification.dart';

void main() {
  group('ISSUE-009 polymorphic patch across a heterogeneous collection', () {
    test('one shared patch reaches every concrete subtype', () {
      final readAt = DateTime.utc(2026, 11, 23, 9);

      final notifications = <Notification>[
        OrderNotification(id: 'o1', itemCount: 2),
        PriceDropNotification(id: 'p1', newPrice: 19.99),
      ];

      // The headline feature: ONE root-typed patch over a mixed collection,
      // no per-element downcast and no per-subtype patch construction.
      final patch = NotificationPatch.shared(readAt: PatchValue.set(readAt));

      final patched = [for (final n in notifications) patch.apply(n)];

      expect(patched, hasLength(2));
      for (final notification in patched) {
        expect(
          notification.readAt,
          readAt,
          reason:
              'a shared patch must reach the shared field on '
              '${notification.runtimeType}',
        );
      }

      // Each element keeps its own type AND its subtype-only fields.
      expect(patched[0], isA<OrderNotification>());
      expect((patched[0] as OrderNotification).itemCount, 2);
      expect(patched[1], isA<PriceDropNotification>());
      expect((patched[1] as PriceDropNotification).newPrice, 19.99);
    });

    test('a shared patch rejects a target outside the hierarchy loudly', () {
      final patch = NotificationPatch.shared(
        readAt: PatchValue.set(DateTime.utc(2026, 11, 23)),
      );

      expect(
        () => patch.apply(_Stranger(id: 'x')),
        throwsA(isA<ArgumentError>()),
        reason:
            'an unknown element in a bulk update must fail loudly, not be '
            'silently skipped',
      );
    });

    test('composing a shared patch with a subtype patch refuses loudly', () {
      final shared = NotificationPatch.shared(
        id: const PatchValue.set('renamed'),
      );
      final order = OrderNotificationPatch(itemCount: const PatchValue.set(7));

      // Rebuilding a shared patch here would copy the root fields and silently
      // DROP `itemCount`. Neither direction of a mismatched pair may lose data
      // quietly, so the kind guard refuses it — the same loud failure the
      // subtype arm already gave for sibling patches.
      expect(
        () => shared.compose(order),
        throwsA(isA<ArgumentError>()),
        reason:
            'composing a shared patch with a subtype patch must throw instead '
            'of rebuilding a shared patch that drops the subtype set fields',
      );
    });

    test('composing two shared patches folds the root fields', () {
      final first = NotificationPatch.shared(
        id: const PatchValue.set('renamed'),
      );
      final second = NotificationPatch.shared(
        readAt: PatchValue.set(DateTime.utc(2026, 11, 23)),
      );

      final applied = first
          .compose(second)
          .apply(OrderNotification(id: 'o1', itemCount: 5));

      expect(applied.id, 'renamed');
      expect(applied.readAt, DateTime.utc(2026, 11, 23));
      expect((applied as OrderNotification).itemCount, 5);
    });

    test('a shared patch clears a non-null nullable field', () {
      final stamped = OrderNotification(
        id: 'o1',
        itemCount: 2,
        readAt: DateTime.utc(2026, 11, 23, 9),
      );

      final cleared = NotificationPatch.shared(
        readAt: const PatchValue.set(null),
      ).apply(stamped);

      expect(
        cleared.readAt,
        isNull,
        reason:
            'PatchValue.set(null) must CLEAR the field; the copyWith sentinel '
            'contract is what makes an explicit null distinguishable from an '
            'omitted argument',
      );
      expect((cleared as OrderNotification).itemCount, 2);
    });

    test('a subtype patch clears a non-null nullable field', () {
      final stamped = PriceDropNotification(
        id: 'p1',
        newPrice: 4.5,
        readAt: DateTime.utc(2026, 11, 23, 15),
      );

      final cleared = PriceDropNotificationPatch(
        readAt: const PatchValue.set(null),
      ).apply(stamped);

      expect(cleared.readAt, isNull);
      expect(cleared.newPrice, 4.5);
    });

    test('an omitted field still keeps the current value', () {
      final readAt = DateTime.utc(2026, 11, 23, 9);
      final original = OrderNotification(
        id: 'o1',
        itemCount: 4,
        readAt: readAt,
      );

      final applied = NotificationPatch.shared(
        id: const PatchValue.set('o2'),
      ).apply(original) as OrderNotification;

      expect(applied.id, 'o2');
      expect(
        applied.readAt,
        readAt,
        reason:
            'an unchanged PatchValue must not clear the field — only an '
            'explicit PatchValue.set(null) does',
      );
      expect(applied.itemCount, 4);
    });

    test('a subtype patch narrows onto its own entity', () {
      final patch = OrderNotificationPatch(itemCount: const PatchValue.set(7));
      final NotificationPatch asRoot = patch;

      final applied = asRoot.apply(OrderNotification(id: 'o1', itemCount: 1));

      expect(applied, isA<OrderNotification>());
      expect((applied as OrderNotification).itemCount, 7);
    });

    test('a subtype patch on the wrong subtype fails loudly', () {
      final NotificationPatch patch = OrderNotificationPatch(
        itemCount: const PatchValue.set(9),
      );

      expect(
        () => patch.apply(PriceDropNotification(id: 'p1', newPrice: 1.0)),
        throwsA(isA<TypeError>()),
        reason:
            'the covariant narrowing must reject a mismatched element instead '
            'of silently skipping it — a skipped element in a bulk update is '
            'data loss nobody sees',
      );
    });

    test('an empty patch is a zero-copy no-op', () {
      final original = OrderNotification(id: 'o1', itemCount: 3);
      final applied = OrderNotificationPatch().apply(original);
      expect(
        identical(applied, original),
        isTrue,
        reason: 'the v3 contract requires an empty patch to return the target',
      );
    });
  });
}

/// An implementation outside the sealed hierarchy's known subtypes — the
/// shared patch's dispatch must refuse it instead of skipping it.
class _Stranger extends Notification {
  const _Stranger({required super.id});
}
