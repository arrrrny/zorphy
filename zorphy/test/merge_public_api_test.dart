import 'package:test/test.dart';

// Public-API import ONLY — no `package:zorphy/src/...` reach-in.
// Regression for arrrrny/zorphy#355: the smart-merge surface must be
// reachable through `package:zorphy/zorphy.dart` so consumers never need
// `// ignore: implementation_imports`.
import 'package:zorphy/zorphy.dart';

void main() {
  group('smart-merge public API (issue #355)', () {
    test('MergeOrchestrator is reachable from the public entrypoint', () {
      final result = MergeOrchestrator.merge(
        existingContent: '',
        generatedContent: 'class A {}\n',
      );
      expect(result, isA<MergeResult>());
      expect(result.hasChanges, isTrue);
    });

    test('MergeMode is reachable from the public entrypoint', () {
      final result = MergeOrchestrator.merge(
        existingContent: '',
        generatedContent: 'class B {}\n',
        mode: MergeMode.force,
      );
      expect(result.content, contains('class B'));
    });

    test('MergeStrategy is reachable from the public entrypoint', () {
      expect(MergeStrategy, isNotNull);
    });
  });
}
