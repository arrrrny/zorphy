// Regenerates the GOLDEN-POLY-ORDER / GOLDEN-POLY-PRICE regions of
// test/runtime/fixtures/notification.dart after an intentional emission
// change (ISSUE-0223 added the with* fluent builders). Prints the two
// emissions between their markers; splice verbatim.
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';

void main() {
  const emitter = PolymorphicPatchEmitter();
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
  print('// GOLDEN-POLY-ORDER-START');
  print(order.trim());
  print('// GOLDEN-POLY-ORDER-END');
  print('// GOLDEN-POLY-PRICE-START');
  print(priceDrop.trim());
  print('// GOLDEN-POLY-PRICE-END');
}
