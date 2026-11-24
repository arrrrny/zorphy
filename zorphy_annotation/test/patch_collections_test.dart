// Tests for ISSUE-008 (zorphy#183) — collection deltas and nested patches.
//
// `ListPatchDelta` / `MapPatchDelta` carry an ORDERED sequence of
// `ListPatchOp` / `MapPatchOp` steps and implement the same v3 algebra the
// generated `<Name>Patch` classes do, so a collection field can be patched
// operationally instead of being replaced wholesale.
//
// Laws under test:
//   * diff is minimal — identical and content-equal pairs carry no op at all
//   * apply folds the ops in order and never mutates its target
//   * compose concatenates, so (a.compose(b)).apply(x) == b.apply(a.apply(x))
//   * invert round-trip — d.invert(x).apply(d.apply(x)) == x
//   * a delta and a nested patch both resolve through the legacy `Patch`
//     surface, which is how the generated `patchWith` applies them

import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

/// A minimal [ZorphyPatch] of [String], used as the nested `SubPatch`.
final class _NamePatch implements ZorphyPatch<String> {
  const _NamePatch(this.value);

  final String value;

  @override
  bool get isEmpty => false;

  @override
  bool get isNotEmpty => true;

  @override
  String apply(String _) => value;

  @override
  ZorphyPatch<String> compose(ZorphyPatch<String> next) =>
      next.isEmpty ? this : next;

  @override
  ZorphyPatch<String> invert(String before) => _NamePatch(before);

  @override
  Map<String, Object?> toWire() => <String, Object?>{'name': value};
}

void main() {
  group('ListPatchDelta.diff', () {
    test('identical lists carry no op', () {
      final list = <int>[1, 2, 3];
      final delta = ListPatchDelta.diff<int>(list, list);
      expect(delta.isEmpty, isTrue);
      expect(identical(delta.apply(list), list), isTrue, reason: 'zero-copy');
    });

    test('content-equal lists carry no op', () {
      final delta = ListPatchDelta.diff<int>(<int>[1, 2], <int>[1, 2]);
      expect(delta.isEmpty, isTrue, reason: 'equal content is no change');
    });

    test('an append at the tail is one append op', () {
      final delta = ListPatchDelta.diff<int>(<int>[1, 2], <int>[1, 2, 3]);
      expect(delta.ops, <ListPatchOp<int>>[const ListPatchOp<int>.append(3)]);
    });

    test('a tail removal is one removeAt op', () {
      final delta = ListPatchDelta.diff<int>(<int>[1, 2, 3], <int>[1, 2]);
      expect(delta.ops, <ListPatchOp<int>>[const ListPatchOp<int>.removeAt(2)]);
    });

    test('an in-place edit is one updateAt op', () {
      final delta = ListPatchDelta.diff<int>(<int>[1, 2, 3], <int>[1, 9, 3]);
      expect(delta.ops, <ListPatchOp<int>>[
        const ListPatchOp<int>.updateAt(1, 9),
      ]);
    });

    test('several in-place edits stay granular', () {
      final delta = ListPatchDelta.diff<int>(<int>[1, 2, 3], <int>[7, 2, 9]);
      expect(delta.ops, <ListPatchOp<int>>[
        const ListPatchOp<int>.updateAt(0, 7),
        const ListPatchOp<int>.updateAt(2, 9),
      ]);
    });

    test('a middle insertion falls back to one replaceAll', () {
      // The op vocabulary has no insertAt, so a structural change between
      // unchanged neighbours cannot be expressed as single-step ops.
      final delta = ListPatchDelta.diff<int>(<int>[1, 3], <int>[1, 2, 3]);
      expect(delta.ops, <ListPatchOp<int>>[
        const ListPatchOp<int>.replaceAll(<int>[1, 2, 3]),
      ]);
    });
  });

  group('ListPatchDelta algebra', () {
    test('apply folds the ops in order and never mutates the target', () {
      final target = <int>[1, 3];
      final delta = ListPatchDelta<int>(<ListPatchOp<int>>[
        const ListPatchOp<int>.append(4),
        const ListPatchOp<int>.updateAt(0, 0),
      ]);
      expect(delta.apply(target), <int>[0, 3, 4]);
      expect(target, <int>[1, 3], reason: 'the target is untouched');
    });

    test('compose concatenates, matching apply-then-apply', () {
      final base = <int>[1, 2];
      final a = ListPatchDelta.diff<int>(base, <int>[1, 2, 3]);
      final b = ListPatchDelta.diff<int>(<int>[1, 2, 3], <int>[0, 2, 3]);
      expect(a.compose(b).apply(base), b.apply(a.apply(base)));
      expect(a.compose(b).apply(base), <int>[0, 2, 3]);
    });

    test('compose with the empty delta is the identity', () {
      final base = <int>[1, 2];
      final delta = ListPatchDelta.diff<int>(base, <int>[1, 5]);
      final empty = ListPatchDelta<int>.empty();
      expect(empty.compose(delta).apply(base), delta.apply(base));
      expect(delta.compose(empty).apply(base), delta.apply(base));
    });

    test('invert round-trips every non-removal shape', () {
      final base = <int>[1, 2, 3];
      for (final next in <List<int>>[
        <int>[1, 2, 3, 4],
        <int>[1, 9, 3],
        <int>[7, 8, 9],
      ]) {
        final delta = ListPatchDelta.diff<int>(base, next);
        expect(delta.apply(base), next);
        expect(
          delta.invert(base).apply(delta.apply(base)),
          base,
          reason: 'invert restores $base from $next',
        );
      }
    });

    test('invert round-trips a removal as a whole-list restore', () {
      final base = <int>[1, 2, 3];
      final next = <int>[1, 2];
      final delta = ListPatchDelta.diff<int>(base, next);
      expect(delta.invert(base).apply(delta.apply(base)), base);
    });

    test('toWire renders one descriptor per step', () {
      final delta = ListPatchDelta.diff<int>(<int>[1], <int>[1, 2]);
      expect(delta.toWire(), <String, Object?>{
        'ops': <Object?>[
          <String, Object?>{'op': 'append', 'item': 2},
        ],
      });
    });
  });

  group('MapPatchDelta', () {
    test(
      'diff emits one put per added or changed key and a remove per drop',
      () {
        final delta = MapPatchDelta.diff<String, int>(
          <String, int>{'a': 1, 'b': 2, 'c': 3},
          <String, int>{'a': 9, 'c': 3, 'd': 4},
        );
        expect(delta.ops, <MapPatchOp<String, int>>[
          const MapPatchOp<String, int>.put('a', 9),
          const MapPatchOp<String, int>.put('d', 4),
          const MapPatchOp<String, int>.remove('b'),
        ]);
      },
    );

    test('identical and content-equal maps carry no op', () {
      final map = <String, int>{'a': 1};
      expect(MapPatchDelta.diff<String, int>(map, map).isEmpty, isTrue);
      expect(
        MapPatchDelta.diff<String, int>(
          <String, int>{'a': 1},
          <String, int>{'a': 1},
        ).isEmpty,
        isTrue,
      );
    });

    test('apply and compose follow the algebra', () {
      final base = <String, int>{'a': 1};
      final a = MapPatchDelta.diff<String, int>(base, <String, int>{
        'a': 1,
        'b': 2,
      });
      final b = MapPatchDelta.diff<String, int>(
        <String, int>{'a': 1, 'b': 2},
        <String, int>{'b': 9},
      );
      expect(a.compose(b).apply(base), b.apply(a.apply(base)));
      expect(a.compose(b).apply(base), <String, int>{'b': 9});
    });

    test('invert round-trips added, changed and removed keys', () {
      final base = <String, int>{'a': 1, 'b': 2};
      final next = <String, int>{'a': 7, 'c': 3};
      final delta = MapPatchDelta.diff<String, int>(base, next);
      expect(delta.apply(base), next);
      expect(delta.invert(base).apply(delta.apply(base)), base);
    });

    test('toWire renders one descriptor per step', () {
      final delta = MapPatchDelta<String, int>(<MapPatchOp<String, int>>[
        const MapPatchOp<String, int>.put('a', 1),
        const MapPatchOp<String, int>.remove('b'),
      ]);
      expect(delta.toWire(), <String, Object?>{
        'ops': <Object?>[
          <String, Object?>{'op': 'put', 'key': 'a', 'value': 1},
          <String, Object?>{'op': 'remove', 'key': 'b'},
        ],
      });
    });
  });

  group('PatchNested', () {
    test('resolves through the legacy Patch surface', () {
      const nested = PatchNested<String, _NamePatch>(_NamePatch('grace'));
      expect(nested, isA<Patch<String>>());
      expect((nested as Patch<String>).applyTo('ada'), 'grace');
    });

    test('delegates the patch algebra to the nested patch', () {
      const nested = PatchNested<String, _NamePatch>(_NamePatch('grace'));
      expect(nested.isEmpty, isFalse);
      expect(nested.apply('ada'), 'grace');
      expect(nested.invert('ada').apply('grace'), 'ada');
      expect(nested.toWire(), <String, Object?>{'name': 'grace'});
    });
  });
}
