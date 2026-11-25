// Runtime contract for issue #231 — the composed v3 union surface must not
// only generate and analyze, it must RUN: both matcher variants, sibling
// morphing in both directions, and reference preservation across the morph.
//
// This file lives in example/ on purpose: it imports the REAL build_runner
// output (the shared part of lib/v3_archetypes), so a generator regression
// fails here before it can reach a consumer.

import 'package:test/test.dart';
import 'package:zorphy_example/v3_archetypes/v3_archetypes.dart';

void main() {
  group('v3 union matchers (when / maybeWhen)', () {
    test('when dispatches both variants', () {
      final loading = const Loading().when<String>(
        loading: (l) => 'loading',
        ready: (r) => 'ready:${r.value}',
      );
      expect(loading, 'loading');

      final ready = const Ready.fromTrusted(value: 'next').when<String>(
        loading: (l) => 'loading',
        ready: (r) => 'ready:${r.value}',
      );
      expect(ready, 'ready:next');
    });

    test('maybeWhen falls back to orElse', () {
      final hit = const Ready.fromTrusted(value: 'x').maybeWhen<String>(
        ready: (r) => 'ready:${r.value}',
        orElse: () => 'other',
      );
      expect(hit, 'ready:x');

      final miss = const Loading().maybeWhen<String>(
        ready: (r) => 'ready:${r.value}',
        orElse: () => 'other',
      );
      expect(miss, 'other');
    });

    test('generic union: when carries the type argument', () {
      const data = SliceData<int>.fromTrusted(source: 's', value: 1);
      final value = data.when<int>(
        sliceData: (d) => d.value,
        sliceLoading: (l) => -1,
      );
      expect(value, 1);

      const loading = SliceLoading<String>.fromTrusted(source: 's');
      final label = loading.when<String>(
        sliceData: (d) => d.value,
        sliceLoading: (l) => 'loading:${l.source}',
      );
      expect(label, 'loading:s');
    });

    test('bounded generic union: when on T extends num', () {
      const data = BoundedData<double>.fromTrusted(source: 'b', value: 2.5);
      final value = data.when<double>(
        boundedData: (d) => d.value,
        boundedLoading: (l) => -1,
      );
      expect(value, 2.5);
    });
  });

  group('v3 sibling morphing (changeTo*)', () {
    test('union morphs in both directions', () {
      // Ready -> Loading: Loading owns nothing, so nothing is asked for.
      final loading = const Ready.fromTrusted(value: 'next').changeToLoading();
      expect(loading, isA<Loading>());

      // Loading -> Ready: `value` is target-owned.
      final ready = const Loading().changeToReady(value: 'back');
      expect(ready.value, 'back');
    });

    test('generic union morph preserves the shared field by reference', () {
      const data = SliceData<List<int>>.fromTrusted(source: 's', value: [1]);
      final loading = data.changeToSliceLoading();
      expect(loading.source, 's');
      expect(identical(loading.source, data.source), isTrue);

      const seed = SliceLoading<List<int>>.fromTrusted(source: 's');
      final back = seed.changeToSliceData(value: [2]);
      expect(back.value, [2]);
      expect(identical(back.source, seed.source), isTrue);
    });

    test('bounded generic union morphs', () {
      const data = BoundedData<int>.fromTrusted(source: 'b', value: 7);
      final loading = data.changeToBoundedLoading();
      expect(loading.source, 'b');
      expect(identical(loading.source, data.source), isTrue);
    });

    test('entity morph preserves principalKey and shared references', () {
      final tags = ['a', 'b'];
      final createdAt = DateTime.fromMillisecondsSinceEpoch(0);
      final open = OpenTask.fromTrusted(
        id: 'task-1',
        createdAt: createdAt,
        tags: tags,
        assignee: 'ada',
      );

      final done = open.changeToDoneTask(result: 'shipped');

      expect(done.id, 'task-1');
      expect(done.result, 'shipped');
      // The principalKey and the shared collection/DateTime references are
      // preserved with `identical` — the morph constructs the target from
      // `this`'s fields, never cloning.
      expect(done.id, open.id);
      expect(identical(done.createdAt, open.createdAt), isTrue);
      expect(identical(done.tags, open.tags), isTrue);

      // And back: only the target-owned field is asked for.
      final reopened = done.changeToOpenTask(assignee: 'grace');
      expect(reopened.assignee, 'grace');
      expect(identical(reopened.tags, done.tags), isTrue);
    });
  });
}
