// Regenerates the GOLDEN-POLY-ROOT / GOLDEN-POLY-ORDER / GOLDEN-POLY-PRICE
// regions of test/runtime/fixtures/notification.dart after an intentional
// emission change (ISSUE-0223 added the with* fluent builders; ISSUE-0229 added
// the static diff). Prints the three emissions between their markers; splice
// verbatim.
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';

void main() {
  const emitter = PolymorphicPatchEmitter();
  final root = emitter.emitRoot(
    rootName: 'Notification',
    fields: [
      NameTypeClassComment('id', 'String', ''),
      NameTypeClassComment('readAt', 'DateTime?', ''),
    ],
    subtypeNames: ['OrderNotification', 'PriceDropNotification'],
  );
  final order = emitter.emitSubtypePatch(
    subtypeName: 'OrderNotification',
    rootName: 'Notification',
    fields: [
      NameTypeClassComment('id', 'String', ''),
      NameTypeClassComment('readAt', 'DateTime?', ''),
      NameTypeClassComment('itemCount', 'int', ''),
    ],
    sharedFields: const ['id', 'readAt'],
  );
  final priceDrop = emitter.emitSubtypePatch(
    subtypeName: 'PriceDropNotification',
    rootName: 'Notification',
    fields: [
      NameTypeClassComment('id', 'String', ''),
      NameTypeClassComment('readAt', 'DateTime?', ''),
      NameTypeClassComment('newPrice', 'double', ''),
    ],
    sharedFields: const ['id', 'readAt'],
  );
  print('// GOLDEN-POLY-ROOT-START');
  print(root.trim());
  print('// GOLDEN-POLY-ROOT-END');
  print('// GOLDEN-POLY-ORDER-START');
  print(order.trim());
  print('// GOLDEN-POLY-ORDER-END');
  print('// GOLDEN-POLY-PRICE-START');
  print(priceDrop.trim());
  print('// GOLDEN-POLY-PRICE-END');
}
