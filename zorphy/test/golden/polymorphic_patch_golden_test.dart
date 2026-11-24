// Golden tests for ISSUE-009 (zorphy#184) — polymorphic patch emission.
//
// A polymorphic root (`abstract class $$Notification`) currently emits NO
// patch at all: `PatchClassGenerator` returns early for every sealed root, so a
// caller holding a heterogeneous `List<Notification>` cannot apply a shared
// field update (`markAllRead`) without downcasting.
//
// `PolymorphicPatchEmitter` closes that gap: `emitRoot` produces the sealed
// `<Root>Patch`, and `emitSubtypePatch` produces the concrete `<Subtype>Patch`
// that implements it while narrowing `apply` to its own entity.
//
// These tests lock the emitted surface.

import 'package:test/test.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/polymorphic_patch_emitter.dart';

import 'dart:io';

/// The `Notification` root's shared fields — the ones a polymorphic patch
/// mutates across every subtype.
List<NameTypeClassComment> rootFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('readAt', 'DateTime?', ''),
];

List<String> subtypes() => ['OrderNotification', 'PriceDropNotification'];

List<NameTypeClassComment> orderFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('readAt', 'DateTime?', ''),
  NameTypeClassComment('itemCount', 'int', ''),
];

List<NameTypeClassComment> priceDropFields() => [
  NameTypeClassComment('id', 'String', ''),
  NameTypeClassComment('readAt', 'DateTime?', ''),
  NameTypeClassComment('newPrice', 'double', ''),
];

const _fixturePath = 'test/runtime/fixtures/notification.dart';

/// The fixture region between [start] and [end] markers, trimmed.
String _fixtureRegion(String start, String end) {
  final source = File(_fixturePath).readAsStringSync();
  final from = source.indexOf(start);
  final to = source.indexOf(end);
  expect(from, isNot(-1), reason: 'fixture must carry $start');
  expect(to, isNot(-1), reason: 'fixture must carry $end');
  return source.substring(from + start.length, to).trim();
}

void main() {
  group('ISSUE-009 PolymorphicPatchEmitter — sealed root patch', () {
    test('emits a sealed root patch class', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        contains('sealed class NotificationPatch'),
        reason: 'a polymorphic root must expose a sealed root patch',
      );
    });

    test('the root patch declares shared fields as PatchValue getters', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        contains('PatchValue<DateTime?> get readAt'),
        reason:
            'a shared nullable DateTime must keep its nullability in the '
            'PatchValue type, so null can be set deliberately',
      );
      expect(
        emitted,
        contains('PatchValue<String> get id'),
        reason: 'a shared non-nullable String must be a PatchValue getter',
      );
    });

    test('the root apply is covariant so subtypes may narrow it', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        contains('Notification apply(covariant Notification target)'),
        reason:
            'without covariant, a subtype patch cannot legally narrow apply '
            '(parameter types are contravariant in Dart)',
      );
    });

    test('the root patch is const-constructible', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        contains('const NotificationPatch()'),
        reason:
            'a const root is what the .shared(...) factory redirects to and '
            'what subtype patches extend',
      );
    });

    test('a root with no shared fields still emits a usable patch', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: const [],
        subtypeNames: subtypes(),
      );

      expect(emitted, contains('sealed class NotificationPatch'));
      expect(
        emitted,
        contains('return true;'),
        reason: 'a fieldless root patch is always empty',
      );
    });

    test('a root with no concrete subtypes is refused, not silently empty', () {
      expect(
        () => PolymorphicPatchEmitter().emitRoot(
          rootName: 'Lonely',
          fields: rootFields(),
          subtypeNames: const [],
        ),
        throwsA(isA<ArgumentError>()),
        reason:
            'a sealed root with no subtypes has nothing to dispatch to; '
            'emitting a patch that can never apply is a silent trap',
      );
    });

    test('the root emission matches the runtime fixture byte for byte', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );
      expect(
        emitted.trim(),
        _fixtureRegion('// GOLDEN-POLY-ROOT-START', '// GOLDEN-POLY-ROOT-END'),
        reason:
            'the runtime suite must exercise the real emitted root patch — '
            'regenerate $_fixturePath if the emission changed on purpose',
      );
    });
  });

  group('ISSUE-009 PolymorphicPatchEmitter — subtype narrowing', () {
    test('a concrete subtype patch extends the root patch interface', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );

      expect(
        emitted,
        contains('OrderNotificationPatch extends NotificationPatch'),
        reason:
            'OrderNotificationPatch must be assignable to NotificationPatch so '
            'a heterogeneous collection can be patched uniformly. It EXTENDS '
            'rather than implements: ZorphyPatch uses its type parameter in '
            'both parameter and return position, so ZorphyPatch<Order> and '
            'ZorphyPatch<Notification> cannot be implemented by one class',
      );
    });

    test('the subtype patch narrows apply to its own entity', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );

      expect(
        emitted,
        contains('OrderNotification apply(covariant OrderNotification target)'),
        reason:
            'subtype narrowing is the point: applying an OrderNotification '
            'patch must yield an OrderNotification, not a Notification',
      );
    });

    test('the subtype patch overrides the shared field getters', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );

      final overrides = 'override'.allMatches(emitted).length;
      expect(
        overrides,
        greaterThanOrEqualTo(3),
        reason:
            'isEmpty + apply + the two shared getters must each be an override',
      );
    });

    test('subtype fields never reach the root patch', () {
      final emitted = PolymorphicPatchEmitter().emitRoot(
        rootName: 'Notification',
        fields: rootFields(),
        subtypeNames: subtypes(),
      );

      expect(
        emitted,
        isNot(contains('itemCount')),
        reason:
            'a subtype-only field has no meaning on the root; leaking it there '
            'would make the root patch unapplicable to sibling subtypes',
      );
    });

    test('the OrderNotification emission matches the runtime fixture', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );
      expect(
        emitted.trim(),
        _fixtureRegion(
          '// GOLDEN-POLY-ORDER-START',
          '// GOLDEN-POLY-ORDER-END',
        ),
        reason: 'regenerate $_fixturePath if the emission changed on purpose',
      );
    });

    test('the PriceDropNotification emission matches the runtime fixture', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'PriceDropNotification',
        rootName: 'Notification',
        fields: priceDropFields(),
        sharedFields: const ['id', 'readAt'],
      );
      expect(
        emitted.trim(),
        _fixtureRegion(
          '// GOLDEN-POLY-PRICE-START',
          '// GOLDEN-POLY-PRICE-END',
        ),
        reason: 'regenerate $_fixturePath if the emission changed on purpose',
      );
    });
  });
}
