import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('package retains the downstream smart-merge surface (#347)', () {
    const requiredFiles = <String>[
      'ast_diff.dart',
      'declaration_scanner.dart',
      'merge.dart',
      'merge_orchestrator.dart',
      'merge_strategy.dart',
      'merge_types.dart',
      'region_parser.dart',
    ];

    for (final name in requiredFiles) {
      expect(
        File('lib/src/merge/$name').existsSync(),
        isTrue,
        reason:
            'zorphy consumers import package:zorphy/src/merge/merge.dart; '
            '$name must ship in every release',
      );
    }

    final barrel = File('lib/src/merge/merge.dart').readAsStringSync();
    expect(barrel, contains("export 'merge_orchestrator.dart';"));
    expect(barrel, contains("export 'merge_strategy.dart';"));
    expect(barrel, contains("export 'merge_types.dart';"));
  });
}
