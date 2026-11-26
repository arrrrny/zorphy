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

/// Collapses *formatting* whitespace but preserves whitespace that belongs to
/// a string literal's content, so a golden comparison is insensitive to the
/// line-wrapping the locally resolved `dart_style` (`^3.1.1`) chooses without
/// going blind to a changed literal token (zorphy#260).
///
/// The emitted code is formatted by whatever `dart_style` patch release
/// resolves; a release that wraps a long string literal onto a continuation
/// line (or back) changes only the whitespace *between* tokens — the literal's
/// content is identical — yet used to fail the byte-for-byte golden whose
/// fixture came from an earlier style. Collapsing outside-string whitespace
/// removes that drift. Whitespace *inside* a literal is semantic: `'shared,
/// OrderNotification'` and `'shared,  OrderNotification'` are different
/// diagnostics, so it is copied verbatim. A blanket `\s+` collapse erased that
/// distinction and let a changed diagnostic pass as equal.
String _normalize(String source) {
  final buffer = StringBuffer();

  // A frame is a region being scanned: a 'code' frame collapses whitespace,
  // a 'string' frame preserves it. `${...}` inside a string pushes a nested
  // code frame so quotes within interpolation are recognized as their own
  // literals (e.g. `'one of: ${hierarchy.join(', ')}'`).
  final frames = <_NormalizeFrame>[_NormalizeFrame.code()];
  var pendingSpace = false;

  void flushSpace() {
    if (pendingSpace && buffer.isNotEmpty) buffer.write(' ');
    pendingSpace = false;
  }

  for (var i = 0; i < source.length; i++) {
    final frame = frames.last;
    final c = source[i];

    if (frame.isString) {
      // Inside a literal: copy every character verbatim.
      buffer.write(c);
      if (frame.escaped) {
        frame.escaped = false;
      } else if (c == r'\' && !frame.raw) {
        frame.escaped = true;
      } else if (frame.triple &&
          c == frame.quote &&
          i + 2 < source.length &&
          source[i + 1] == frame.quote &&
          source[i + 2] == frame.quote) {
        buffer.write(source[i + 1]);
        buffer.write(source[i + 2]);
        i += 2;
        frames.removeLast();
      } else if (!frame.triple && c == frame.quote) {
        frames.removeLast();
      } else if (c == r'$' && i + 1 < source.length && source[i + 1] == '{') {
        buffer.write('{');
        i++;
        frames.add(_NormalizeFrame.interpolation());
      }
      continue;
    }

    // Code (including interpolation expressions): collapse whitespace runs.
    if (c == ' ' || c == '\n' || c == '\r' || c == '\t') {
      pendingSpace = true;
      continue;
    }

    final isQuote = c == r"'" || c == r'"';
    if (isQuote) {
      flushSpace();
      final raw = i > 0 && source[i - 1] == 'r';
      final triple =
          i + 2 < source.length && source[i + 1] == c && source[i + 2] == c;
      buffer.write(c);
      if (triple) {
        buffer.write(c);
        buffer.write(c);
        i += 2;
      }
      frames.add(_NormalizeFrame.string(c, triple, raw));
      continue;
    }

    flushSpace();
    buffer.write(c);
    // Track interpolation brace depth so a `}` closes the string only when
    // the nested `${...}` it opened is complete.
    if (c == '{' && frame.braceDepth > 0) {
      frame.braceDepth++;
    } else if (c == '}' && frame.braceDepth > 0) {
      frame.braceDepth--;
      if (frame.braceDepth == 0) frames.removeLast();
    }
  }
  // A trailing whitespace run is dropped — emitted source starts and ends with
  // code, so the ends are trimmed without touching any string content.
  return buffer.toString();
}

class _NormalizeFrame {
  _NormalizeFrame.code()
    : quote = '',
      triple = false,
      raw = false,
      escaped = false,
      braceDepth = 0;

  _NormalizeFrame.interpolation()
    : quote = '',
      triple = false,
      raw = false,
      escaped = false,
      braceDepth = 1;

  _NormalizeFrame.string(this.quote, this.triple, this.raw)
    : escaped = false,
      braceDepth = 0;

  final String quote;
  final bool triple;
  final bool raw;
  bool escaped;
  int braceDepth;

  bool get isString => quote.isNotEmpty;
}

/// A three-level hierarchy whose concrete leaves narrow an inherited field:
/// `SystemEvent.payload` is `Object`, `DeployEvent.payload` is `String` and
/// `AlertEvent.payload` is `int`. The intermediate `apply` must dispatch to
/// each leaf's `copyWith` through the leaf's declared type (#229 §3).
String _emitIntermediateHierarchy() {
  return const PolymorphicPatchEmitter().emitIntermediatePatch(
    name: 'SystemEvent',
    rootName: 'Event',
    basePatchName: 'EventPatch',
    fields: [
      NameTypeClassComment('id', 'String', ''),
      NameTypeClassComment('source', 'String', ''),
      NameTypeClassComment('payload', 'Object', ''),
    ],
    sharedFields: const ['id'],
    leafNames: const ['DeployEvent', 'AlertEvent'],
    leafFieldTypes: const {
      'DeployEvent': {'id': 'String', 'source': 'String', 'payload': 'String'},
      'AlertEvent': {'id': 'String', 'source': 'String', 'payload': 'int'},
    },
  );
}

/// Entity half of the compile probe: the emitted root patch supplies
/// `EventPatch`, so only the entities live in the fixture.
const _intermediateEntitiesFixture = r'''
abstract class Event {
  const Event({required this.id});
  final String id;
}

abstract class SystemEvent extends Event {
  const SystemEvent({
    required super.id,
    required this.source,
    required this.payload,
  });
  final String source;
  final Object payload;
}

class DeployEvent extends SystemEvent {
  const DeployEvent({
    required super.id,
    required super.source,
    required super.payload,
  });
  @override
  String get payload => super.payload as String;
  DeployEvent copyWith({String? id, String? source, String? payload}) {
    return DeployEvent(
      id: id ?? this.id,
      source: source ?? this.source,
      payload: payload ?? this.payload,
    );
  }
}

class AlertEvent extends SystemEvent {
  const AlertEvent({
    required super.id,
    required super.source,
    required super.payload,
  });
  @override
  int get payload => super.payload as int;
  AlertEvent copyWith({String? id, String? source, int? payload}) {
    return AlertEvent(
      id: id ?? this.id,
      source: source ?? this.source,
      payload: payload ?? this.payload,
    );
  }
}
''';

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

    test(
      'the root emission matches the runtime fixture (whitespace-insensitive)',
      () {
        final emitted = PolymorphicPatchEmitter().emitRoot(
          rootName: 'Notification',
          fields: rootFields(),
          subtypeNames: subtypes(),
        );
        expect(
          _normalize(emitted),
          _normalize(
            _fixtureRegion(
              '// GOLDEN-POLY-ROOT-START',
              '// GOLDEN-POLY-ROOT-END',
            ),
          ),
          reason:
              'the runtime suite must exercise the real emitted root patch — '
              'regenerate $_fixturePath if the emission changed on purpose',
        );
      },
    );
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
        _normalize(emitted),
        _normalize(
          _fixtureRegion(
            '// GOLDEN-POLY-ORDER-START',
            '// GOLDEN-POLY-ORDER-END',
          ),
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
        _normalize(emitted),
        _normalize(
          _fixtureRegion(
            '// GOLDEN-POLY-PRICE-START',
            '// GOLDEN-POLY-PRICE-END',
          ),
        ),
        reason: 'regenerate $_fixturePath if the emission changed on purpose',
      );
    });

    test('subtype patches carry the fluent builders samplePatch builds', () {
      // ISSUE-0223: MockFixtureEmitter.samplePatch() builds through
      // `with<Name>` builders, so every concrete patch carries them.
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: const ['id', 'readAt'],
      );

      expect(emitted, contains('OrderNotificationPatch withId(String value)'));
      expect(
        emitted,
        contains('OrderNotificationPatch withItemCount(int value)'),
      );
      expect(
        emitted,
        contains('OrderNotificationPatch withReadAt(DateTime? value)'),
      );
      expect(
        emitted,
        contains('itemCount: PatchValue.set(value)'),
        reason: 'the builder sets its own field and carries the rest over',
      );
    });
  });

  group('ISSUE-0223 PolymorphicPatchEmitter — standalone entity patch', () {
    test('emits one concrete ZorphyPatch-implementing class', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Product',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('name', 'String', ''),
        ],
      );

      expect(
        emitted,
        contains('final class ProductPatch implements ZorphyPatch<Product>'),
      );
      expect(
        emitted,
        isNot(contains('extends')),
        reason: 'a standalone entity has no root patch to extend',
      );
      expect(emitted, contains('ProductPatch withName(String value)'));
      expect(emitted, contains('Product apply(covariant Product target)'));
      expect(
        emitted,
        contains('ProductPatch compose(ZorphyPatch<Product> next)'),
        reason:
            'the parameter stays the interface type so the kind guard is not '
            'dead code',
      );
    });

    test('the standalone emission compiles against the annotation library', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Product',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('name', 'String', ''),
        ],
      );
      final result = _analyzeEmitted(emitted, _standaloneFixture);
      expect(result.exitCode, 0, reason: result.output);
    });

    test('a field named value does not shadow the carried field', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Box',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('value', 'String', ''),
        ],
      );

      // `withId(String value)` must carry `value: this.value` — an
      // unqualified `value: value` picks up the builder's parameter instead
      // of the existing patch field and fails to compile.
      expect(emitted, contains('value: this.value'));
      expect(emitted, contains('id: this.id'));

      final result = _analyzeEmitted(emitted, _standaloneValueFixture);
      expect(result.exitCode, 0, reason: result.output);
    });

    test('a field named target does not shadow the apply entity', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Targeted',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('target', 'String', ''),
        ],
      );

      // `apply(covariant Targeted target)` names its entity parameter
      // `target`. An unqualified patch-field read resolves to that parameter
      // (which has neither `isUnchanged` nor `valueOrNull`) and cannot compile.
      expect(
        emitted,
        contains(
          'target: this.target.isUnchanged ? target.target : '
          'this.target.valueOrNull',
        ),
      );
      expect(
        emitted,
        contains('id: this.id.isUnchanged ? target.id : this.id.valueOrNull'),
      );

      final result = _analyzeEmitted(emitted, _standaloneTargetFixture);
      expect(result.exitCode, 0, reason: result.output);
    });

    test('a field named next does not shadow the compose parameter', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Tagged',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('next', 'String', ''),
        ],
      );

      // `compose(ZorphyPatch<Tagged> next)` names its parameter `next`. An
      // unqualified fallback reads that parameter (the incoming patch)
      // instead of the existing patch field and fails to compile.
      expect(
        emitted,
        contains('next: next.next.isUnchanged ? this.next : next.next'),
      );

      final result = _analyzeEmitted(emitted, _standaloneCollisionsFixture);
      expect(result.exitCode, 0, reason: result.output);
    });

    test('a field named before does not shadow the invert parameter', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Tagged',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('before', 'String', ''),
        ],
      );

      // `invert(Tagged before)` names its parameter `before`. An unqualified
      // unchanged-test resolves to that parameter (which has no
      // `isUnchanged`) and cannot compile; `before.before` stays the prior
      // entity value. (The formatter wraps the ternary, so assert the two
      // halves.)
      expect(emitted, contains('before: this.before.isUnchanged'));
      expect(emitted, contains(': PatchValue.set(before.before)'));

      final result = _analyzeEmitted(emitted, _standaloneCollisionsFixture);
      expect(result.exitCode, 0, reason: result.output);
    });

    test('a field named wire does not shadow the toWire output map', () {
      final emitted = PolymorphicPatchEmitter().emitStandalone(
        name: 'Tagged',
        fields: [
          NameTypeClassComment('id', 'String', ''),
          NameTypeClassComment('wire', 'String', ''),
        ],
      );

      // `toWire` declares `final wire = <String, Object?>{}`. An unqualified
      // patch-field read resolves to that local map (which has neither
      // `isSet` nor `valueOrNull`) and cannot compile; the map write stays
      // `wire[...]`.
      expect(emitted, contains('if (this.wire.isSet)'));
      expect(emitted, contains("wire['wire'] = this.wire.valueOrNull"));
      expect(emitted, contains("wire['id'] = this.id.valueOrNull"));

      final result = _analyzeEmitted(emitted, _standaloneCollisionsFixture);
      expect(result.exitCode, 0, reason: result.output);
    });
  });

  group('ISSUE-0229 PolymorphicPatchEmitter — intermediate patch surface', () {
    test('emits a concrete patch with its own fields and the full algebra', () {
      final emitted = _emitIntermediateHierarchy();

      expect(emitted, contains('class SystemEventPatch extends EventPatch'));
      expect(
        emitted,
        isNot(contains('abstract class SystemEventPatch')),
        reason: 'the intermediate is concrete — diff and the builders use it',
      );
      expect(emitted, contains('SystemEventPatch withSource(String value)'));
      expect(
        emitted,
        contains('static SystemEventPatch diff('),
        reason: 'the intermediate carries the same diff surface as its leaves',
      );
      expect(
        emitted,
        contains('if (identical(previous, next)) return SystemEventPatch()'),
      );
      expect(emitted, contains('if (target is DeployEvent)'));
      expect(emitted, contains('if (target is AlertEvent)'));
      // Each leaf's copyWith gets the LEAF's declared payload type, not the
      // intermediate's wider `Object` — the same narrowing rule the root's
      // shared apply follows.
      expect(emitted, contains('as String'));
      expect(emitted, contains('as int'));
      expect(
        emitted,
        contains('EventPatch compose(covariant EventPatch next)'),
      );
      expect(emitted, contains('SystemEventPatch invert(Event before)'));
      expect(emitted, contains("'patchKind': 'SystemEvent'"));
      expect(
        emitted,
        contains('static ZorphyBoundaryResult<SystemEventPatch> fromWire('),
      );
    });

    test(
      'the intermediate emission compiles against the annotation library',
      () {
        final emitted = [
          const PolymorphicPatchEmitter().emitRoot(
            rootName: 'Event',
            fields: [NameTypeClassComment('id', 'String', '')],
            subtypeNames: const ['DeployEvent', 'AlertEvent'],
          ),
          _emitIntermediateHierarchy(),
        ].join('\n\n');

        final result = _analyzeEmitted(emitted, _intermediateEntitiesFixture);
        expect(result.exitCode, 0, reason: result.output);
      },
    );

    test(
      'the runtime fixture carries the exact emitted intermediate patch',
      () {
        final source = File(
          'test/runtime/fixtures/intermediate.dart',
        ).readAsStringSync();
        final from = source.indexOf('// GOLDEN-POLY-INTERMEDIATE-START');
        final to = source.indexOf('// GOLDEN-POLY-INTERMEDIATE-END');
        expect(from, isNot(-1));
        expect(to, isNot(-1));
        final region = source
            .substring(from + '// GOLDEN-POLY-INTERMEDIATE-START'.length, to)
            .trim();
        expect(
          _normalize(region),
          _normalize(_emitIntermediateHierarchy()),
          reason:
              'the runtime suite must exercise the real emitted intermediate '
              'patch — regenerate test/runtime/fixtures/intermediate.dart if '
              'the emission changed on purpose',
        );
      },
    );
  });

  group('ISSUE-0229 PolymorphicPatchEmitter — static diff (RED→GREEN)', () {
    test(
      'a standalone patch declares static diff with the identical fast path',
      () {
        final emitted = PolymorphicPatchEmitter().emitStandalone(
          name: 'Product',
          fields: [
            NameTypeClassComment('id', 'String', ''),
            NameTypeClassComment('name', 'String', ''),
          ],
        );

        expect(
          emitted,
          contains('static ProductPatch diff(Product previous, Product next)'),
        );
        expect(
          emitted,
          contains('if (identical(previous, next)) return ProductPatch('),
          reason: 'the O(1) fast path returns the canonical empty patch',
        );
        // Unchanged-field omission: a field equal on both sides is not recorded.
        expect(emitted, contains('if (previous.id != next.id)'));
        expect(emitted, contains('if (previous.name != next.name)'));

        final result = _analyzeEmitted(emitted, _standaloneFixture);
        expect(result.exitCode, 0, reason: result.output);
      },
    );

    test('a subtype patch declares static diff returning its own type', () {
      final emitted = PolymorphicPatchEmitter().emitSubtypePatch(
        subtypeName: 'OrderNotification',
        rootName: 'Notification',
        fields: orderFields(),
        sharedFields: ['id', 'readAt'],
      );

      expect(
        emitted,
        contains('static OrderNotificationPatch diff('),
        reason: 'a concrete subtype patch declares static diff',
      );
      expect(emitted, contains('OrderNotification previous,'));
      expect(emitted, contains('OrderNotification next,'));
      // The subtype's own field is diffed; the identical fast path is present.
      expect(emitted, contains('if (previous.itemCount != next.itemCount)'));
      expect(emitted, contains('if (identical(previous, next)) return'));
    });
  });

  // Regression for zorphy#260: the byte-for-byte golden broke whenever a
  // `dart_style` patch release changed how it wraps a long string literal. The
  // normalizer collapses whitespace so only token content is compared, making
  // the golden independent of the resolved `dart_style` version.
  group('ISSUE-260 golden whitespace normalization', () {
    // The exact shape of the drift from the issue: a long `expected:` string
    // literal wrapped onto a continuation line by one dart_style version and
    // kept on one line by another — semantically identical, byte-different.
    const wrapped =
        "expected:\n"
        "            'String (one of: shared, OrderNotification, "
        "PriceDropNotification)',";
    const unwrapped =
        "expected: 'String (one of: shared, OrderNotification, "
        "PriceDropNotification)',";

    test(
      'a line-wrap-only difference is byte-unequal but normalized-equal',
      () {
        // RED condition (the bug): a byte-for-byte compare rejects the drift.
        expect(wrapped, isNot(unwrapped));
        // GREEN condition (the fix): normalization treats them as identical.
        expect(_normalize(wrapped), _normalize(unwrapped));
      },
    );

    test('a real token change stays unequal after normalization', () {
      final changed = unwrapped.replaceFirst('shared', 'sharedX');
      expect(_normalize(unwrapped), isNot(_normalize(changed)));
    });

    test('whitespace inside a string literal is preserved', () {
      // Review finding on #263: a blanket \s+ collapse would normalize both
      // of these to the same text, letting a changed diagnostic (a doubled
      // space inside the literal) pass the golden. Formatting whitespace is
      // normalized; string-literal content is compared exactly.
      const oneSpace =
          "expected: 'String (one of: shared, OrderNotification)',";
      const twoSpaces =
          "expected: 'String (one of: shared,  OrderNotification)',";
      expect(oneSpace, isNot(twoSpaces));
      expect(_normalize(oneSpace), isNot(_normalize(twoSpaces)));
    });
  });
}

/// Standalone entity carrying a field literally named `target` — the name
/// collides with the `apply` method's entity parameter.
const _standaloneTargetFixture = r'''
final class Targeted {
  const Targeted({required this.id, required this.target});

  final String id;
  final String target;

  Targeted copyWith({String? id, String? target}) {
    return Targeted(id: id ?? this.id, target: target ?? this.target);
  }
}
''';

/// The minimal entity surface a standalone patch applies to.
const _standaloneFixture = r'''
final class Product {
  const Product({required this.id, required this.name});

  final String id;
  final String name;

  Product copyWith({String? id, String? name}) {
    return Product(id: id ?? this.id, name: name ?? this.name);
  }
}
''';

/// Standalone entity carrying a field literally named `value` — the name
/// collides with the `with*` builders' own parameter.
const _standaloneValueFixture = r'''
final class Box {
  const Box({required this.id, required this.value});

  final String id;
  final String value;

  Box copyWith({String? id, String? value}) {
    return Box(id: id ?? this.id, value: value ?? this.value);
  }
}
''';

/// Standalone entity whose field names collide with the emitter's own
/// parameter and local spellings — `compose`'s `next`, `invert`'s `before`
/// and `toWire`'s output map `wire`. One fixture serves the compile probe of
/// all three: `copyWith` takes every field optionally, so a patch carrying a
/// subset still type-checks against it.
const _standaloneCollisionsFixture = r'''
final class Tagged {
  const Tagged({
    required this.id,
    required this.next,
    required this.before,
    required this.wire,
  });

  final String id;
  final String next;
  final String before;
  final String wire;

  Tagged copyWith({String? id, String? next, String? before, String? wire}) {
    return Tagged(
      id: id ?? this.id,
      next: next ?? this.next,
      before: before ?? this.before,
      wire: wire ?? this.wire,
    );
  }
}
''';

/// Analyzes [emitted] spliced after [fixture] in a throwaway package that
/// depends on the real `zorphy_annotation` — the same probe the mock-data
/// compile suite uses, because a `contains(...)` assertion cannot see a type
/// error inside the generated code.
({int exitCode, String output}) _analyzeEmitted(
  String emitted,
  String fixture,
) {
  final annotationRoot = Directory.current.parent.uri
      .resolve('zorphy_annotation/')
      .toFilePath();
  final probeParent = Directory('test/.poly_patch_compile_$pid')
    ..createSync(recursive: true);
  final probe = probeParent.createTempSync('issue_223_');
  addTearDown(() => probe.deleteSync(recursive: true));

  File('${probe.path}/pubspec.yaml').writeAsStringSync(
    'name: poly_patch_probe\n'
    'environment:\n'
    '  sdk: ">=3.11.0 <4.0.0"\n'
    'dependencies:\n'
    '  zorphy_annotation:\n'
    '    path: $annotationRoot\n',
  );
  Directory('${probe.path}/lib').createSync();
  File('${probe.path}/lib/emitted.dart').writeAsStringSync(
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n\n"
    '$fixture\n'
    '$emitted',
  );

  final pubGet = Process.runSync('dart', [
    'pub',
    'get',
  ], workingDirectory: probe.path);
  if (pubGet.exitCode != 0) {
    return (
      exitCode: pubGet.exitCode,
      output: 'dart pub get failed:\n${pubGet.stdout}\n${pubGet.stderr}',
    );
  }
  final analyze = Process.runSync('dart', [
    'analyze',
    '--no-fatal-warnings',
    'lib/emitted.dart',
  ], workingDirectory: probe.path);
  return (
    exitCode: analyze.exitCode,
    output: '${analyze.stdout}\n${analyze.stderr}',
  );
}
