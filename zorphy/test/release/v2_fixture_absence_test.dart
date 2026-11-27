import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('retired v2 fixtures and build_runner mirror trees stay absent', () {
    final retiredPaths = <String>[
      '_br_',
      'example/lib/_br_',
      'test/runtime/fixtures/account.dart',
      'test/runtime/fixtures/profile.dart',
      'test/runtime/fixtures/progress_box_patch.golden.txt',
      '../specs/002-v2-codebuilder-plugin-pipeline/golden-pr22',
    ];

    final present = retiredPaths.where(
      (path) =>
          FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound,
    );
    expect(present, isEmpty, reason: 'retired v2 paths present: $present');
  });
}
