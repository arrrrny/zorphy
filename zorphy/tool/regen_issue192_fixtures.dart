// Regenerates the byte-identical fixture regions the golden tests compare.
//
// Run from `zorphy/`: `dart run tool/regen_issue192_fixtures.dart`
//
// The fixture regions are the EMITTERS' real output — `patch_golden_test.dart`,
// `nested_and_collection_patch_golden_test.dart`,
// `polymorphic_patch_golden_test.dart` and `generic_patch_golden_test.dart`
// compare them byte for byte, so a hand-written edit would make the runtime
// suites exercise a lookalike instead of the emitted patch. This script is the
// only sanctioned way to move them.
//
// The FIELD LISTS are imported from the golden tests themselves, never
// restated here: a restated list drifts, and a drifted list regenerates a
// fixture from inputs no golden asserts (which is how `Address.postalCode`
// vanished from a fixture on the first attempt at this script).
import 'dart:io';

import 'package:zorphy/src/emission/patch_emitter.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';

import '../test/golden/generic_patch_golden_test.dart' as generic;
import '../test/golden/nested_and_collection_patch_golden_test.dart' as nested;
import '../test/golden/patch_golden_test.dart' as account;
import '../test/golden/polymorphic_patch_golden_test.dart' as polymorphic;

/// Replaces the region between [start] and [end] in [path] with [body].
void _replaceRegion(String path, String start, String end, String body) {
  final file = File(path);
  final source = file.readAsStringSync();
  final from = source.indexOf(start);
  final to = source.indexOf(end);
  if (from == -1 || to == -1) {
    stderr.writeln('missing markers in $path: $start / $end');
    exit(1);
  }
  final out =
      '${source.substring(0, from + start.length)}\n'
      '${body.trim()}\n'
      '${source.substring(to)}';
  file.writeAsStringSync(out);
  stdout.writeln('updated $path :: $start');
}

void main() {
  _replaceRegion(
    'test/runtime/fixtures/account.dart',
    '// GOLDEN-PATCH-START',
    '// GOLDEN-PATCH-END',
    PatchEmitter().emit(className: 'Account', fields: account.accountFields()),
  );

  // The Address region is what ProfilePatch's nested field decodes through,
  // and `nested_and_collection_patch_golden_test.dart` asserts it byte for
  // byte — an unasserted region is how it drifted once already.
  _replaceRegion(
    'test/runtime/fixtures/profile.dart',
    '// GOLDEN-ADDRESS-PATCH-START',
    '// GOLDEN-ADDRESS-PATCH-END',
    PatchEmitter().emit(className: 'Address', fields: nested.addressFields()),
  );

  _replaceRegion(
    'test/runtime/fixtures/profile.dart',
    '// GOLDEN-PROFILE-PATCH-START',
    '// GOLDEN-PROFILE-PATCH-END',
    PatchEmitter().emit(
      className: 'Profile',
      fields: nested.profileFields(),
      knownClasses: const ['Address'],
    ),
  );

  _replaceRegion(
    'test/runtime/fixtures/notification.dart',
    '// GOLDEN-POLY-ROOT-START',
    '// GOLDEN-POLY-ROOT-END',
    PolymorphicPatchEmitter().emitRoot(
      rootName: 'Notification',
      fields: polymorphic.rootFields(),
      subtypeNames: polymorphic.subtypes(),
    ),
  );

  _replaceRegion(
    'test/runtime/fixtures/notification.dart',
    '// GOLDEN-POLY-ORDER-START',
    '// GOLDEN-POLY-ORDER-END',
    PolymorphicPatchEmitter().emitSubtypePatch(
      subtypeName: 'OrderNotification',
      rootName: 'Notification',
      fields: polymorphic.orderFields(),
      sharedFields: const ['id', 'readAt'],
    ),
  );

  _replaceRegion(
    'test/runtime/fixtures/notification.dart',
    '// GOLDEN-POLY-PRICE-START',
    '// GOLDEN-POLY-PRICE-END',
    PolymorphicPatchEmitter().emitSubtypePatch(
      subtypeName: 'PriceDropNotification',
      rootName: 'Notification',
      fields: polymorphic.priceDropFields(),
      sharedFields: const ['id', 'readAt'],
    ),
  );

  // The generic golden is a whole FILE, not a marked region.
  File('test/runtime/fixtures/progress_box_patch.golden.txt').writeAsStringSync(
    PatchEmitter().emit(
      className: 'ProgressBox',
      fields: generic.progressBoxFields(),
      knownClasses: const ['Token'],
      genericTypeNames: const ['T'],
    ),
  );
  stdout.writeln('updated test/runtime/fixtures/progress_box_patch.golden.txt');
}
