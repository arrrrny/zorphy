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
    test('a shared-field update reaches every concrete subtype', () {
      final readAt = DateTime.utc(2026, 11, 23, 9);

      final notifications = <Notification>[
        OrderNotification(id: 'o1', itemCount: 2),
        PriceDropNotification(id: 'p1', newPrice: 19.99),
      ];

      final patches = <NotificationPatch>[
        OrderNotificationPatch(readAt: PatchValue.set(readAt)),
        PriceDropNotificationPatch(readAt: PatchValue.set(readAt)),
      ];

      final patched = <Notification>[
        for (var i = 0; i < notifications.length; i++)
          patches[i].apply(notifications[i]),
      ];

      expect(patched, hasLength(2));
      for (final notification in patched) {
        expect(
          notification.readAt,
          readAt,
          reason:
              'a root patch must reach the shared field on ${notification.runtimeType}',
        );
      }
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
