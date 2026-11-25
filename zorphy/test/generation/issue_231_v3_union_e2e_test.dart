// E2E for issue #231: the composed v3 part of the example library must carry
// the union matcher (`when` / `maybeWhen`) and sibling-morphing
// (`changeTo<Sibling>`) surfaces, including over GENERIC hierarchies — the
// shapes a clean consumer probe generated 0 outputs for before this change.
//
// Follows the issue_223 e2e pattern: the part file is produced by
// `dart run build_runner build` inside example/ (CI runs it before this test)
// and asserted here. The runtime behavior on top of this surface is pinned by
// example/test/v3_union_runtime_test.dart.

import 'dart:io';

import 'package:test/test.dart';

void main() {
  final v3Part = File('example/lib/_br_/v3_archetypes/v3_archetypes.part.dart');

  late String v3;

  setUpAll(() {
    if (!v3Part.existsSync()) {
      fail(
        'Missing generated file: ${v3Part.path}\n'
        'Run: cd example && dart run build_runner build '
        '--delete-conflicting-outputs',
      );
    }
    v3 = v3Part.readAsStringSync();
  });

  group('#231 v3 union matchers — e2e build_runner smoke', () {
    test('AsyncStatus union: when + maybeWhen extension on the root', () {
      expect(v3, contains('extension AsyncStatusWhenE on AsyncStatus'));
      expect(v3, contains('T when<T>({'));
      expect(v3, contains('maybeWhen'));
      expect(v3, contains('Loading value => loading(value)'));
      expect(v3, contains('Ready value => ready(value)'));
    });

    test('AsyncStatus union: changeTo morphs in both directions', () {
      expect(v3, contains('extension ReadyMorphing on Ready'));
      expect(v3, contains('Loading changeToLoading()'));
      expect(v3, contains('extension LoadingMorphing on Loading'));
      expect(v3, contains('Ready changeToReady({required String value})'));
    });

    test(
      'generic union AsyncSlice<T>: classes, leaves and matcher carry T',
      () {
        expect(v3, contains('sealed class AsyncSlice<T>'));
        expect(v3, contains('final class SliceData<T> extends AsyncSlice<T>'));
        expect(
          v3,
          contains('final class SliceLoading<T> extends AsyncSlice<T>'),
        );
        expect(v3, contains('extension AsyncSliceWhenE<T> on AsyncSlice<T>'));
        expect(v3, contains('SliceData<T> value => sliceData(value)'));
        expect(v3, contains('SliceLoading<T> value => sliceLoading(value)'));
      },
    );

    test('generic union morphing extension carries T', () {
      expect(v3, contains('extension SliceDataMorphing<T> on SliceData<T>'));
      expect(v3, contains('SliceLoading<T> changeToSliceLoading()'));
      expect(
        v3,
        contains('extension SliceLoadingMorphing<T> on SliceLoading<T>'),
      );
      expect(
        v3,
        contains('SliceData<T> changeToSliceData({required T value})'),
      );
    });

    test('bounded generic union: T extends num reaches every member', () {
      expect(v3, contains('sealed class BoundedSlice<T extends num>'));
      expect(
        v3,
        contains(
          'final class BoundedData<T extends num> extends BoundedSlice<T>',
        ),
      );
      expect(
        v3,
        contains(
          'extension BoundedSliceWhenE<T extends num> on BoundedSlice<T>',
        ),
      );
      expect(
        v3,
        contains(
          'extension BoundedDataMorphing<T extends num> on BoundedData<T>',
        ),
      );
    });

    test('entity sibling pair: changeTo copies shared fields verbatim', () {
      expect(v3, contains('extension OpenTaskMorphing on OpenTask'));
      expect(v3, contains('DoneTask changeToDoneTask({'));
      expect(v3, contains('required String result'));
      // dart format wraps the fromTrusted(...) call across lines and keeps a
      // trailing comma, so compare with whitespace collapsed rather than
      // pinning one line layout.
      expect(
        v3.replaceAll(RegExp(r'\s+'), ' '),
        contains(
          'return DoneTask.fromTrusted( result: result, id: id, createdAt: createdAt, tags: tags, );',
        ),
      );
      expect(v3, contains('extension DoneTaskMorphing on DoneTask'));
      expect(
        v3,
        contains('OpenTask changeToOpenTask({required String assignee})'),
      );
    });
  });
}
