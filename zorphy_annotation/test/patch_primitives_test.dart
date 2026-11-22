import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

/// A reference [ZorphyPatch] used to pin the algebra the interface promises.
///
/// The production implementations are the generated `<Name>Patch` classes
/// (ISSUE-007); these two are the smallest pair that satisfies the contract,
/// so the laws below are stated against an implementation rather than a
/// restatement of the interface.
final class _Assign implements ZorphyPatch<String> {
  const _Assign(this.value);

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
  ZorphyPatch<String> invert(String before) => _Assign(before);

  @override
  Map<String, Object?> toWire() => <String, Object?>{'assign': value};
}

/// The identity element of the patch monoid: it changes nothing and composes
/// away.
final class _Empty implements ZorphyPatch<String> {
  const _Empty();

  @override
  bool get isEmpty => true;

  @override
  bool get isNotEmpty => false;

  @override
  String apply(String target) => target;

  @override
  ZorphyPatch<String> compose(ZorphyPatch<String> next) =>
      next.isEmpty ? this : next;

  @override
  ZorphyPatch<String> invert(String _) => const _Empty();

  @override
  Map<String, Object?> toWire() => const <String, Object?>{};
}

void main() {
  group('PatchValue', () {
    test('unchanged carries no value and reports isUnchanged', () {
      const patch = PatchValue<String>.unchanged();
      expect(patch.isUnchanged, isTrue);
      expect(patch.isSet, isFalse);
      expect(patch.valueOrNull, isNull);
    });

    test('set carries the value and reports isSet', () {
      const patch = PatchValue<int>.set(7);
      expect(patch.isSet, isTrue);
      expect(patch.isUnchanged, isFalse);
      expect(patch.valueOrNull, 7);
    });

    test('set of a nullable value keeps the null as a set value', () {
      const patch = PatchValue<String?>.set(null);
      expect(patch.isSet, isTrue);
      expect(patch.valueOrNull, isNull);
    });

    test('fold bridges both shapes', () {
      const unchanged = PatchValue<int>.unchanged();
      const set = PatchValue<int>.set(7);
      expect(unchanged.fold<int>(() => -1, (value) => value * 2), -1);
      expect(set.fold<int>(() => -1, (value) => value * 2), 14);
    });

    test('equality is by shape and value', () {
      expect(const PatchValue<int>.set(1), const PatchValue<int>.set(1));
      expect(const PatchValue<int>.set(1), isNot(const PatchValue<int>.set(2)));
      expect(
        const PatchValue<int>.unchanged(),
        isNot(const PatchValue<int>.set(0)),
      );
    });
  });

  group('ListPatchOp', () {
    test('replaceAll swaps the whole list', () {
      const op = ListPatchOp<int>.replaceAll(<int>[3, 1]);
      expect(op.apply(<int>[9]), <int>[3, 1]);
    });

    test('append adds one item at the end', () {
      const op = ListPatchOp<String>.append('c');
      expect(op.apply(<String>['a', 'b']), <String>['a', 'b', 'c']);
    });

    test('removeAt drops the item at the index', () {
      const op = ListPatchOp<String>.removeAt(1);
      expect(op.apply(<String>['a', 'b', 'c']), <String>['a', 'c']);
    });

    test('updateAt replaces the item at the index', () {
      const op = ListPatchOp<int>.updateAt(0, 42);
      expect(op.apply(<int>[1, 2]), <int>[42, 2]);
    });

    test('removeAt out of range is a RangeError', () {
      const op = ListPatchOp<int>.removeAt(2);
      expect(() => op.apply(<int>[1]), throwsRangeError);
    });

    test('no op mutates its input', () {
      final source = <int>[1, 2];
      const ops = <ListPatchOp<int>>[
        ListPatchOp<int>.replaceAll(<int>[7]),
        ListPatchOp<int>.append(3),
        ListPatchOp<int>.removeAt(0),
        ListPatchOp<int>.updateAt(1, 9),
      ];
      for (final op in ops) {
        op.apply(source);
      }
      expect(source, <int>[1, 2]);
    });

    test('equality is by variant and payload', () {
      expect(
        const ListPatchOp<int>.append(1),
        const ListPatchOp<int>.append(1),
      );
      expect(
        const ListPatchOp<int>.append(1),
        isNot(const ListPatchOp<int>.append(2)),
      );
      expect(
        const ListPatchOp<int>.removeAt(0),
        isNot(const ListPatchOp<int>.updateAt(0, 0)),
      );
      expect(
        const ListPatchOp<int>.replaceAll(<int>[1]),
        const ListPatchOp<int>.replaceAll(<int>[1]),
      );
    });
  });

  group('MapPatchOp', () {
    test('replaceAll swaps the whole map', () {
      const op = MapPatchOp<String, int>.replaceAll(<String, int>{'b': 2});
      expect(op.apply(<String, int>{'a': 1}), <String, int>{'b': 2});
    });

    test('put inserts a missing key', () {
      const op = MapPatchOp<String, int>.put('a', 1);
      expect(op.apply(<String, int>{}), <String, int>{'a': 1});
    });

    test('put overwrites an existing key', () {
      const op = MapPatchOp<String, int>.put('a', 2);
      expect(op.apply(<String, int>{'a': 1}), <String, int>{'a': 2});
    });

    test('remove drops the key and is a no-op when absent', () {
      const op = MapPatchOp<String, int>.remove('a');
      expect(op.apply(<String, int>{'a': 1, 'b': 2}), <String, int>{'b': 2});
      expect(op.apply(<String, int>{'b': 2}), <String, int>{'b': 2});
    });

    test('no op mutates its input', () {
      final source = <String, int>{'a': 1};
      const ops = <MapPatchOp<String, int>>[
        MapPatchOp<String, int>.replaceAll(<String, int>{'z': 26}),
        MapPatchOp<String, int>.put('b', 2),
        MapPatchOp<String, int>.remove('a'),
      ];
      for (final op in ops) {
        op.apply(source);
      }
      expect(source, <String, int>{'a': 1});
    });

    test('equality is by variant and payload', () {
      expect(
        const MapPatchOp<String, int>.put('a', 1),
        const MapPatchOp<String, int>.put('a', 1),
      );
      expect(
        const MapPatchOp<String, int>.put('a', 1),
        isNot(const MapPatchOp<String, int>.put('a', 2)),
      );
      expect(
        const MapPatchOp<String, int>.remove('a'),
        isNot(const MapPatchOp<String, int>.put('a', 0)),
      );
    });
  });

  group('PatchNested', () {
    test('delegates isEmpty, apply, invert and toWire to the nested patch', () {
      const nested = PatchNested<String, _Assign>(_Assign('nested'));
      expect(nested.isEmpty, isFalse);
      expect(nested.isNotEmpty, isTrue);
      expect(nested.apply('before'), 'nested');
      expect(nested.patch, const _Assign('nested'));
      expect(nested.invert('before').apply('nested'), 'before');
      expect(nested.toWire(), <String, Object?>{'assign': 'nested'});
    });

    test('an empty nested patch is empty and applies unchanged', () {
      const nested = PatchNested<String, _Empty>(_Empty());
      expect(nested.isEmpty, isTrue);
      expect(nested.apply('same'), 'same');
      expect(nested.toWire(), isEmpty);
    });
  });

  group('ZorphyPatch algebraic laws', () {
    const assign = _Assign('a');
    const other = _Assign('b');

    test('isEmpty is a no-op: apply returns the target itself', () {
      const empty = _Empty();
      final target = 'untouched';
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
      expect(identical(empty.apply(target), target), isTrue);
    });

    test('identity: composing with the empty patch changes nothing', () {
      final target = 'target';
      expect(
        const _Empty().compose(assign).apply(target),
        assign.apply(target),
      );
      expect(
        assign.compose(const _Empty()).apply(target),
        assign.apply(target),
      );
    });

    test('compose is associative', () {
      const patches = <ZorphyPatch<String>>[
        _Assign('a'),
        _Empty(),
        _Assign('b'),
      ];
      for (final a in patches) {
        for (final b in patches) {
          for (final c in patches) {
            final left = a.compose(b).compose(c).apply('seed');
            final right = a.compose(b.compose(c)).apply('seed');
            expect(left, right, reason: '($a . $b) . $c != $a . ($b . $c)');
          }
        }
      }
    });

    test('compose applies left to right: (a . b)(x) == b(a(x))', () {
      final target = 'seed';
      expect(
        assign.compose(other).apply(target),
        other.apply(assign.apply(target)),
      );
    });

    test('invert round-trip restores the original value', () {
      const patch = _Assign('patched');
      final before = 'original';
      expect(patch.invert(before).apply(patch.apply(before)), before);
    });

    test('an empty patch inverts to an empty patch', () {
      const empty = _Empty();
      expect(empty.invert('original'), const _Empty());
      expect(empty.invert('original').apply('original'), 'original');
    });

    test('compose returns a patch, so chains type-check as ZorphyPatch', () {
      ZorphyPatch<String> patch = const _Empty();
      patch = patch.compose(const _Assign('a'));
      patch = patch.compose(const _Empty());
      expect(patch.apply('seed'), 'a');
    });
  });
}
