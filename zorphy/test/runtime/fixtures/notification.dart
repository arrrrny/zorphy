// Runtime fixture for ISSUE-009 (zorphy#184).
//
// `Notification` is a sealed root and `OrderNotification` /
// `PriceDropNotification` are its concrete siblings. The PATCH sections below
// are BYTE-IDENTICAL to `PolymorphicPatchEmitter`'s output —
// `test/golden/polymorphic_patch_golden_test.dart` compares them, so the
// runtime suite exercises the real emitted patches rather than a hand-written
// lookalike. Regenerate deliberately when the emission is meant to change.

import 'package:zorphy_annotation/zorphy.dart';

/// Sentinel for `copyWith`'s nullable parameters, matching the contract
/// `PolymorphicPatchEmitter` documents: an OMITTED argument keeps the current
/// value, an argument passed as `null` CLEARS the field.
const Object _unset = Object();

abstract class Notification {
  const Notification({required this.id, this.readAt});

  final String id;

  /// The shared field a polymorphic patch exists to update (`markAllRead`).
  final DateTime? readAt;
}

class OrderNotification extends Notification {
  const OrderNotification({
    required super.id,
    super.readAt,
    required this.itemCount,
  });

  final int itemCount;

  OrderNotification copyWith({
    String? id,
    Object? readAt = _unset,
    int? itemCount,
  }) => OrderNotification(
    id: id ?? this.id,
    readAt: identical(readAt, _unset) ? this.readAt : readAt as DateTime?,
    itemCount: itemCount ?? this.itemCount,
  );
}

class PriceDropNotification extends Notification {
  const PriceDropNotification({
    required super.id,
    super.readAt,
    required this.newPrice,
  });

  final double newPrice;

  PriceDropNotification copyWith({
    String? id,
    Object? readAt = _unset,
    double? newPrice,
  }) => PriceDropNotification(
    id: id ?? this.id,
    readAt: identical(readAt, _unset) ? this.readAt : readAt as DateTime?,
    newPrice: newPrice ?? this.newPrice,
  );
}

// GOLDEN-POLY-ROOT-START
sealed class NotificationPatch implements ZorphyPatch<Notification> {
  const NotificationPatch();

  factory NotificationPatch.shared({
    PatchValue<String> id = const PatchValue.unchanged(),
    PatchValue<DateTime?> readAt = const PatchValue.unchanged(),
  }) {
    return NotificationSharedPatch(id: id, readAt: readAt);
  }

  PatchValue<String> get id;
  PatchValue<DateTime?> get readAt;
  @override
  bool get isEmpty {
    return id.isUnchanged && readAt.isUnchanged;
  }

  @override
  bool get isNotEmpty {
    return !isEmpty;
  }

  @override
  Notification apply(covariant Notification target);
  @override
  NotificationPatch compose(covariant NotificationPatch next);
  @override
  NotificationPatch invert(Notification before);
  @override
  Map<String, Object?> toWire();
  Map<String, Object?> toEnvelope({Object? principalKey});
  static ZorphyBoundaryResult<NotificationPatch> fromWire(
    Map<String, Object?> raw,
  ) {
    final kind = ZorphyPatchWire.patchKindOf(raw);
    if (kind == null) {
      return BoundaryErr<NotificationPatch>(
        targetType: 'NotificationPatch',
        violations: <FieldViolation>[
          FieldViolation(
            path: '/patchKind',
            expected: 'String (one of: shared, OrderNotification, PriceDropNotification)',
            actual: ZorphyPatchWire.describe(null),
          ),
        ],
      );
    }
    final hierarchy = const <String>[
      'Notification',
      'OrderNotification',
      'PriceDropNotification',
    ];
    final entityType = ZorphyPatchWire.entityTypeOf(raw);
    if (entityType != null && !hierarchy.contains(entityType)) {
      return BoundaryErr<NotificationPatch>(
        targetType: 'NotificationPatch',
        violations: <FieldViolation>[
          FieldViolation(
            path: '/entityType',
            expected: 'one of: ${hierarchy.join(', ')}',
            actual: ZorphyPatchWire.describe(entityType),
          ),
        ],
      );
    }
    final ops = ZorphyPatchWire.opsOf(raw, '', <FieldViolation>[]);
    if (ops == null) {
      return BoundaryErr<NotificationPatch>(
        targetType: 'NotificationPatch',
        violations: <FieldViolation>[
          FieldViolation(
            path: '/ops',
            expected: 'Map<String, Object?>',
            actual: ZorphyPatchWire.describe(raw['ops']),
          ),
        ],
      );
    }
    if (kind == 'shared' ||
        const <String>[
          'OrderNotification',
          'PriceDropNotification',
        ].contains(kind)) {
      final prefix = ZorphyPatchWire.opsPathOf(raw);
      final decoded = NotificationSharedPatch.fromWire(ops);
      final sharedKeys = const <String>['id', 'readAt'];
      final unknown = <FieldViolation>[];
      for (final key in ops.keys) {
        if (!sharedKeys.contains(key)) {
          unknown.add(
            FieldViolation(
              path: '$prefix/$key',
              expected: 'one of: ${sharedKeys.join(', ')}',
              actual: ZorphyPatchWire.describe(ops[key]),
            ),
          );
        }
      }
      return decoded.fold<ZorphyBoundaryResult<NotificationPatch>>(
        (value) => unknown.isEmpty
            ? BoundaryOk<NotificationPatch>(value)
            : BoundaryErr<NotificationPatch>(
                targetType: 'NotificationPatch',
                violations: unknown,
              ),
        (error) => BoundaryErr<NotificationPatch>(
          targetType: error.targetType,
          violations: <FieldViolation>[
            ...ZorphyPatchWire.prefix(error.violations, prefix),
            ...unknown,
          ],
        ),
      );
    }
    return BoundaryErr<NotificationPatch>(
      targetType: 'NotificationPatch',
      violations: <FieldViolation>[
        FieldViolation(
          path: '/patchKind',
          expected: 'String (one of: shared, OrderNotification, PriceDropNotification)',
          actual: ZorphyPatchWire.describe(kind),
        ),
      ],
    );
  }
}

final class NotificationSharedPatch extends NotificationPatch {
  NotificationSharedPatch({
    PatchValue<String> id = const PatchValue.unchanged(),
    PatchValue<DateTime?> readAt = const PatchValue.unchanged(),
  }) : id = id,
       readAt = readAt;

  @override
  final PatchValue<String> id;

  @override
  final PatchValue<DateTime?> readAt;

  @override
  bool get isEmpty {
    return id.isUnchanged && readAt.isUnchanged;
  }

  @override
  bool get isNotEmpty {
    return !isEmpty;
  }

  @override
  Notification apply(Notification target) {
    if (isEmpty) return target;
    if (target is OrderNotification) {
      return target.copyWith(
        id: id.isUnchanged ? target.id : id.valueOrNull,
        readAt: readAt.isUnchanged ? target.readAt : readAt.valueOrNull,
      );
    }
    if (target is PriceDropNotification) {
      return target.copyWith(
        id: id.isUnchanged ? target.id : id.valueOrNull,
        readAt: readAt.isUnchanged ? target.readAt : readAt.valueOrNull,
      );
    }
    throw ArgumentError.value(
      target,
      'target',
      'NotificationPatch cannot apply to ${target.runtimeType}',
    );
  }

  @override
  NotificationPatch compose(covariant NotificationPatch next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    if (next is! NotificationSharedPatch) {
      throw ArgumentError.value(
        next,
        'next',
        'NotificationSharedPatch cannot compose ${next.runtimeType}',
      );
    }
    return NotificationSharedPatch(
      id: next.id.isUnchanged ? id : next.id,
      readAt: next.readAt.isUnchanged ? readAt : next.readAt,
    );
  }

  @override
  NotificationSharedPatch invert(Notification before) {
    return NotificationSharedPatch(
      id: id.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.id),
      readAt: readAt.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.readAt),
    );
  }

  @override
  Map<String, Object?> toWire() {
    final wire = <String, Object?>{};
    if (id.isSet) wire['id'] = id.valueOrNull;
    if (readAt.isSet) wire['readAt'] = readAt.valueOrNull;
    return wire;
  }

  Map<String, Object?> toEnvelope({Object? principalKey}) {
    return <String, Object?>{
      'entityType': 'Notification',
      'patchKind': 'shared',
      'principalKey': principalKey,
      'ops': toWire(),
    };
  }

  static ZorphyBoundaryResult<NotificationSharedPatch> fromWire(
    Map<String, Object?> raw,
  ) {
    final violations = <FieldViolation>[];
    final ops = ZorphyPatchWire.opsOf(raw, '', violations);
    PatchValue<String>? idValue;
    if (ops != null && ops.containsKey('id')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['id'],
        '/id',
        violations,
      );
      idValue = (() {
        final idDecoded = ZorphyPatchWire.as<String>(
          rawValue,
          '/id',
          violations,
        );
        return idDecoded == null ? null : PatchValue<String>.set(idDecoded);
      })();
    }
    PatchValue<DateTime?>? readAtValue;
    if (ops != null && ops.containsKey('readAt')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['readAt'],
        '/readAt',
        violations,
      );
      readAtValue = (() {
        if (rawValue == null) return PatchValue<DateTime?>.set(null);
        final readAtDecoded = ZorphyPatchWire.asDateTime(
          rawValue,
          '/readAt',
          violations,
        );
        return readAtDecoded == null
            ? null
            : PatchValue<DateTime?>.set(readAtDecoded);
      })();
    }
    if (violations.isNotEmpty) {
      return BoundaryErr<NotificationSharedPatch>(
        targetType: 'NotificationSharedPatch',
        violations: violations,
      );
    }
    return BoundaryOk<NotificationSharedPatch>(
      NotificationSharedPatch(
        id: idValue ?? const PatchValue<String>.unchanged(),
        readAt: readAtValue ?? const PatchValue<DateTime?>.unchanged(),
      ),
    );
  }
}
// GOLDEN-POLY-ROOT-END

// GOLDEN-POLY-ORDER-START
final class OrderNotificationPatch extends NotificationPatch {
  OrderNotificationPatch({
    PatchValue<String> id = const PatchValue.unchanged(),
    PatchValue<DateTime?> readAt = const PatchValue.unchanged(),
    PatchValue<int> itemCount = const PatchValue.unchanged(),
  }) : id = id,
       readAt = readAt,
       itemCount = itemCount;

  @override
  final PatchValue<String> id;

  @override
  final PatchValue<DateTime?> readAt;

  final PatchValue<int> itemCount;

  OrderNotificationPatch withId(String value) {
    return OrderNotificationPatch(
      id: PatchValue.set(value),
      readAt: this.readAt,
      itemCount: this.itemCount,
    );
  }

  OrderNotificationPatch withReadAt(DateTime? value) {
    return OrderNotificationPatch(
      id: this.id,
      readAt: PatchValue.set(value),
      itemCount: this.itemCount,
    );
  }

  OrderNotificationPatch withItemCount(int value) {
    return OrderNotificationPatch(
      id: this.id,
      readAt: this.readAt,
      itemCount: PatchValue.set(value),
    );
  }

  @override
  bool get isEmpty {
    return id.isUnchanged && readAt.isUnchanged && itemCount.isUnchanged;
  }

  @override
  bool get isNotEmpty {
    return !isEmpty;
  }

  @override
  OrderNotification apply(covariant OrderNotification target) {
    if (isEmpty) return target;
    return target.copyWith(
      id: id.isUnchanged ? target.id : id.valueOrNull,
      readAt: readAt.isUnchanged ? target.readAt : readAt.valueOrNull,
      itemCount: itemCount.isUnchanged
          ? target.itemCount
          : itemCount.valueOrNull,
    );
  }

  @override
  NotificationPatch compose(covariant NotificationPatch next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    if (next is! OrderNotificationPatch) {
      throw ArgumentError.value(
        next,
        'next',
        'OrderNotificationPatch cannot compose ${next.runtimeType}',
      );
    }
    return OrderNotificationPatch(
      id: next.id.isUnchanged ? id : next.id,
      readAt: next.readAt.isUnchanged ? readAt : next.readAt,
      itemCount: next.itemCount.isUnchanged ? itemCount : next.itemCount,
    );
  }

  @override
  OrderNotificationPatch invert(Notification before) {
    if (before is! OrderNotification) {
      throw ArgumentError.value(
        before,
        'before',
        'OrderNotificationPatch cannot invert ${before.runtimeType}',
      );
    }
    return OrderNotificationPatch(
      id: id.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.id),
      readAt: readAt.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.readAt),
      itemCount: itemCount.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.itemCount),
    );
  }

  @override
  Map<String, Object?> toWire() {
    final wire = <String, Object?>{};
    if (id.isSet) wire['id'] = id.valueOrNull;
    if (readAt.isSet) wire['readAt'] = readAt.valueOrNull;
    if (itemCount.isSet) wire['itemCount'] = itemCount.valueOrNull;
    return wire;
  }

  Map<String, Object?> toEnvelope({Object? principalKey}) {
    return <String, Object?>{
      'entityType': 'OrderNotification',
      'patchKind': 'OrderNotification',
      'principalKey': principalKey,
      'ops': toWire(),
    };
  }

  static ZorphyBoundaryResult<OrderNotificationPatch> fromWire(
    Map<String, Object?> raw,
  ) {
    final violations = <FieldViolation>[];
    final ops = ZorphyPatchWire.opsOf(raw, '', violations);
    PatchValue<String>? idValue;
    if (ops != null && ops.containsKey('id')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['id'],
        '/id',
        violations,
      );
      idValue = (() {
        final idDecoded = ZorphyPatchWire.as<String>(
          rawValue,
          '/id',
          violations,
        );
        return idDecoded == null ? null : PatchValue<String>.set(idDecoded);
      })();
    }
    PatchValue<DateTime?>? readAtValue;
    if (ops != null && ops.containsKey('readAt')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['readAt'],
        '/readAt',
        violations,
      );
      readAtValue = (() {
        if (rawValue == null) return PatchValue<DateTime?>.set(null);
        final readAtDecoded = ZorphyPatchWire.asDateTime(
          rawValue,
          '/readAt',
          violations,
        );
        return readAtDecoded == null
            ? null
            : PatchValue<DateTime?>.set(readAtDecoded);
      })();
    }
    PatchValue<int>? itemCountValue;
    if (ops != null && ops.containsKey('itemCount')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['itemCount'],
        '/itemCount',
        violations,
      );
      itemCountValue = (() {
        final itemCountDecoded = ZorphyPatchWire.as<int>(
          rawValue,
          '/itemCount',
          violations,
        );
        return itemCountDecoded == null
            ? null
            : PatchValue<int>.set(itemCountDecoded);
      })();
    }
    if (violations.isNotEmpty) {
      return BoundaryErr<OrderNotificationPatch>(
        targetType: 'OrderNotificationPatch',
        violations: violations,
      );
    }
    return BoundaryOk<OrderNotificationPatch>(
      OrderNotificationPatch(
        id: idValue ?? const PatchValue<String>.unchanged(),
        readAt: readAtValue ?? const PatchValue<DateTime?>.unchanged(),
        itemCount: itemCountValue ?? const PatchValue<int>.unchanged(),
      ),
    );
  }
}
// GOLDEN-POLY-ORDER-END

// GOLDEN-POLY-PRICE-START
final class PriceDropNotificationPatch extends NotificationPatch {
  PriceDropNotificationPatch({
    PatchValue<String> id = const PatchValue.unchanged(),
    PatchValue<DateTime?> readAt = const PatchValue.unchanged(),
    PatchValue<double> newPrice = const PatchValue.unchanged(),
  }) : id = id,
       readAt = readAt,
       newPrice = newPrice;

  @override
  final PatchValue<String> id;

  @override
  final PatchValue<DateTime?> readAt;

  final PatchValue<double> newPrice;

  PriceDropNotificationPatch withId(String value) {
    return PriceDropNotificationPatch(
      id: PatchValue.set(value),
      readAt: this.readAt,
      newPrice: this.newPrice,
    );
  }

  PriceDropNotificationPatch withReadAt(DateTime? value) {
    return PriceDropNotificationPatch(
      id: this.id,
      readAt: PatchValue.set(value),
      newPrice: this.newPrice,
    );
  }

  PriceDropNotificationPatch withNewPrice(double value) {
    return PriceDropNotificationPatch(
      id: this.id,
      readAt: this.readAt,
      newPrice: PatchValue.set(value),
    );
  }

  @override
  bool get isEmpty {
    return id.isUnchanged && readAt.isUnchanged && newPrice.isUnchanged;
  }

  @override
  bool get isNotEmpty {
    return !isEmpty;
  }

  @override
  PriceDropNotification apply(covariant PriceDropNotification target) {
    if (isEmpty) return target;
    return target.copyWith(
      id: id.isUnchanged ? target.id : id.valueOrNull,
      readAt: readAt.isUnchanged ? target.readAt : readAt.valueOrNull,
      newPrice: newPrice.isUnchanged ? target.newPrice : newPrice.valueOrNull,
    );
  }

  @override
  NotificationPatch compose(covariant NotificationPatch next) {
    if (next.isEmpty) return this;
    if (isEmpty) return next;
    if (next is! PriceDropNotificationPatch) {
      throw ArgumentError.value(
        next,
        'next',
        'PriceDropNotificationPatch cannot compose ${next.runtimeType}',
      );
    }
    return PriceDropNotificationPatch(
      id: next.id.isUnchanged ? id : next.id,
      readAt: next.readAt.isUnchanged ? readAt : next.readAt,
      newPrice: next.newPrice.isUnchanged ? newPrice : next.newPrice,
    );
  }

  @override
  PriceDropNotificationPatch invert(Notification before) {
    if (before is! PriceDropNotification) {
      throw ArgumentError.value(
        before,
        'before',
        'PriceDropNotificationPatch cannot invert ${before.runtimeType}',
      );
    }
    return PriceDropNotificationPatch(
      id: id.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.id),
      readAt: readAt.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.readAt),
      newPrice: newPrice.isUnchanged
          ? const PatchValue.unchanged()
          : PatchValue.set(before.newPrice),
    );
  }

  @override
  Map<String, Object?> toWire() {
    final wire = <String, Object?>{};
    if (id.isSet) wire['id'] = id.valueOrNull;
    if (readAt.isSet) wire['readAt'] = readAt.valueOrNull;
    if (newPrice.isSet) wire['newPrice'] = newPrice.valueOrNull;
    return wire;
  }

  Map<String, Object?> toEnvelope({Object? principalKey}) {
    return <String, Object?>{
      'entityType': 'PriceDropNotification',
      'patchKind': 'PriceDropNotification',
      'principalKey': principalKey,
      'ops': toWire(),
    };
  }

  static ZorphyBoundaryResult<PriceDropNotificationPatch> fromWire(
    Map<String, Object?> raw,
  ) {
    final violations = <FieldViolation>[];
    final ops = ZorphyPatchWire.opsOf(raw, '', violations);
    PatchValue<String>? idValue;
    if (ops != null && ops.containsKey('id')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['id'],
        '/id',
        violations,
      );
      idValue = (() {
        final idDecoded = ZorphyPatchWire.as<String>(
          rawValue,
          '/id',
          violations,
        );
        return idDecoded == null ? null : PatchValue<String>.set(idDecoded);
      })();
    }
    PatchValue<DateTime?>? readAtValue;
    if (ops != null && ops.containsKey('readAt')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['readAt'],
        '/readAt',
        violations,
      );
      readAtValue = (() {
        if (rawValue == null) return PatchValue<DateTime?>.set(null);
        final readAtDecoded = ZorphyPatchWire.asDateTime(
          rawValue,
          '/readAt',
          violations,
        );
        return readAtDecoded == null
            ? null
            : PatchValue<DateTime?>.set(readAtDecoded);
      })();
    }
    PatchValue<double>? newPriceValue;
    if (ops != null && ops.containsKey('newPrice')) {
      final Object? rawValue = ZorphyPatchWire.fieldValue(
        ops['newPrice'],
        '/newPrice',
        violations,
      );
      newPriceValue = (() {
        final newPriceDecoded = ZorphyPatchWire.asDouble(
          rawValue,
          '/newPrice',
          violations,
        );
        return newPriceDecoded == null
            ? null
            : PatchValue<double>.set(newPriceDecoded);
      })();
    }
    if (violations.isNotEmpty) {
      return BoundaryErr<PriceDropNotificationPatch>(
        targetType: 'PriceDropNotificationPatch',
        violations: violations,
      );
    }
    return BoundaryOk<PriceDropNotificationPatch>(
      PriceDropNotificationPatch(
        id: idValue ?? const PatchValue<String>.unchanged(),
        readAt: readAtValue ?? const PatchValue<DateTime?>.unchanged(),
        newPrice: newPriceValue ?? const PatchValue<double>.unchanged(),
      ),
    );
  }
}
// GOLDEN-POLY-PRICE-END
