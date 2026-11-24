// Behavioral checks for issue #179 (sibling `changeTo<Subtype>()` morphing
// and `when` / `maybeWhen` union matchers). Executed by
// zorphy/test/generation/issue_179_union_and_morphing_test.dart via
// `dart run` (cwd: zorphy/example), following the issue_131 / issue_2054
// pattern: the zorphy test package cannot import the example package's
// generated code directly.
//
// Exit code 0 = all checks passed. Any failure prints FAIL and exits 1.
import 'package:zorphy_example/various/issue_179_sealed_union.dart';
import 'package:zorphy_example/various/issue_179_union_morphing.dart';

final List<String> failures = <String>[];

void check(String name, bool condition) {
  if (condition) {
    print('PASS: $name');
  } else {
    failures.add(name);
    print('FAIL: $name');
  }
}

void main() {
  final created = DateTime.utc(2026, 11, 23, 10, 30);
  final read = DateTime.utc(2026, 11, 23, 11, 0);

  // ── Sibling morphing preserves the shared $Parent fields ─────────
  final order = OrderNotification179(
    id: 'notif-1',
    createdAt: created,
    readAt: read,
    orderId: 'order-9',
  );
  final drop = order.changeToPriceDropNotification179(
    productId: 'sku-42',
    oldPrice: 19.99,
    newPrice: 9.99,
  );

  check('morph preserves id', drop.id == 'notif-1');
  check('morph preserves createdAt', drop.createdAt == created);
  check('morph preserves readAt', drop.readAt == read);
  check(
    'morph takes the target-only fields',
    drop.productId == 'sku-42' &&
        drop.oldPrice == 19.99 &&
        drop.newPrice == 9.99,
  );

  // ── A shared-field override still wins over the receiver value ───
  final otherRead = DateTime.utc(2026, 11, 23, 12, 0);
  final overridden = order.changeToPriceDropNotification179(
    productId: 'sku-1',
    oldPrice: 5,
    newPrice: 3,
    readAt: otherRead,
  );
  check('an explicit shared override wins', overridden.readAt == otherRead);

  // ── The morph is available backwards too ─────────────────────────
  final back = drop.changeToOrderNotification179(orderId: 'order-10');
  check('the reverse morph preserves id', back.id == 'notif-1');
  check('the reverse morph preserves createdAt', back.createdAt == created);
  check('the reverse morph takes its own field', back.orderId == 'order-10');

  // ── when / maybeWhen on the closed hierarchy ─────────────────────
  final sealedDrop = PriceDropNotification179S(
    id: 'notif-2',
    createdAt: created,
    readAt: null,
    productId: 'sku-7',
    oldPrice: 30,
    newPrice: 20,
  );
  final sealedOrder = OrderNotification179S(
    id: 'notif-3',
    createdAt: created,
    readAt: null,
    orderId: 'order-3',
  );

  final label = sealedDrop.when<String>(
    orderNotification179S: (value) => 'order ${value.orderId}',
    priceDropNotification179S: (value) => 'drop ${value.productId}',
  );
  check('when matches the runtime variant', label == 'drop sku-7');

  final fallback = sealedOrder.maybeWhen<String>(
    priceDropNotification179S: (value) => 'drop ${value.productId}',
    orElse: () => 'other',
  );
  check('maybeWhen falls through to orElse', fallback == 'other');

  final matched = sealedDrop.maybeWhen<String>(
    priceDropNotification179S: (value) => 'drop ${value.productId}',
    orElse: () => 'other',
  );
  check(
    'maybeWhen matches when a callback is supplied',
    matched == 'drop sku-7',
  );

  if (failures.isEmpty) {
    print('ALL CHECKS PASSED');
    return;
  }
  print('FAILURES: ${failures.length}');
  throw StateError('issue #179 behavior checks failed: ${failures.join(', ')}');
}
