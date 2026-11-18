// Unit tests for [CrossEntityImportDetector] — the pure-function helper
// extracted from `ZorphyGenerator._detectMissingImportGuidance` as part
// of the issue #117 follow-up.
//
// The detector scans a `@Zorphy` source file for cross-entity field
// references (types whose declared name starts with `$`) and checks
// whether the parent library imports the corresponding sibling entity
// file. When any are missing, it returns a structured guidance comment
// listing the required imports.
//
// These tests exercise the detector directly with synthetic source
// strings (no I/O, no analyzer, no build_runner) so behavior is
// deterministic and fast.
import 'package:test/test.dart';
import 'package:zorphy/src/analysis/cross_entity_import_detector.dart';

void main() {
  group('CrossEntityImportDetector.detect', () {
    group('pre-filter', () {
      test('returns empty result for a non-@Zorphy file', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:flutter/material.dart';
class PlainWidget extends StatelessWidget {}
''');
        expect(result.detectedTypes, isEmpty);
        expect(result.missingImports, isEmpty);
        expect(result.hasMissing, isFalse);
        expect(result.toGuidanceComment(), isNull);
      });

      test('returns empty result for empty source', () {
        final result = CrossEntityImportDetector.detect('');
        expect(result.hasMissing, isFalse);
      });

      test(
        'returns empty result when @Zorphy is mentioned only in a comment',
        () {
          // The pre-filter is `source.contains('@Zorphy')` — even a comment
          // mention passes the pre-filter. Then the field-type regex scans
          // for `\$Type` patterns and finds none, so no missing imports.
          final result = CrossEntityImportDetector.detect('''
// See @Zorphy docs for details.
class Plain {}
''');
          expect(result.detectedTypes, isEmpty);
          expect(result.hasMissing, isFalse);
        },
      );
    });

    group('self-reference', () {
      test('does not flag a field referencing the same class', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'self_ref.zorphy.dart';

@Zorphy()
abstract class \$SelfRef {
  \$SelfRef get parent;
  String get id;
}
''');
        // The detector filters out self-references from `detectedTypes`
        // so that the public field only exposes TRUE cross-entity
        // references (pointing at OTHER entities).
        expect(result.detectedTypes, isEmpty);
        expect(
          result.hasMissing,
          isFalse,
          reason: 'A class is always visible inside its own library',
        );
        expect(result.toGuidanceComment(), isNull);
      });

      test('does not flag a field referencing the concrete form of self', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'self_ref.zorphy.dart';

@Zorphy()
abstract class \$SelfRef {
  SelfRef get parent;
  String get id;
}
''');
        // The concrete `SelfRef` form is NOT matched by the field-type
        // regex (which requires a leading `\$`). This is intentional —
        // concrete-form references in user-authored source are usually
        // forward references to entities in OTHER files, and the import
        // is checked by the analyzer. The detector only flags the
        // canonical CLI-emitted `\$Type` form.
        expect(result.detectedTypes, isEmpty);
        expect(result.hasMissing, isFalse);
      });
    });

    group('sibling reference — missing import', () {
      test('flags \$ArtifactRef when the sibling import is absent', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'artifact_store.zorphy.dart';

@Zorphy()
abstract class \$ArtifactStore {
  \$ArtifactRef get ref;
  bool get summarized;
}
''');
        expect(result.detectedTypes, {'\$ArtifactRef'});
        expect(result.hasMissing, isTrue);
        final comment = result.toGuidanceComment();
        expect(comment, isNotNull);
        expect(
          comment!,
          contains("import '../artifact_ref/artifact_ref.dart';"),
        );
        expect(comment, contains('\$ArtifactRef'));
      });

      test(r'flags nullable sibling reference ($ArtifactRef?)', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'holder.zorphy.dart';

@Zorphy()
abstract class \$Holder {
  \$ArtifactRef? get ref;
}
''');
        expect(result.detectedTypes, {'\$ArtifactRef'});
        expect(result.hasMissing, isTrue);
      });

      test('flags sibling reference inside a `final` field declaration', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'holder.zorphy.dart';

@Zorphy()
abstract class \$Holder {
  final \$ArtifactRef ref;
  String get id;
}
''');
        expect(result.detectedTypes, {'\$ArtifactRef'});
        expect(result.hasMissing, isTrue);
      });

      test('flags sibling reference inside a generic type argument', () {
        // `List<\$ArtifactRef>` — the regex matches `\$ArtifactRef`
        // inside the angle brackets.
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'holder.zorphy.dart';

@Zorphy()
abstract class \$Holder {
  List<\$ArtifactRef> get refs;
}
''');
        expect(result.detectedTypes, {'\$ArtifactRef'});
        expect(result.hasMissing, isTrue);
      });

      test('flags sibling reference inside a Map value type argument', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'holder.zorphy.dart';

@Zorphy()
abstract class \$Holder {
  Map<String, \$ArtifactRef> get refs;
}
''');
        expect(result.detectedTypes, {'\$ArtifactRef'});
        expect(result.hasMissing, isTrue);
      });

      test('flags multiple distinct sibling references at once', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'composite.zorphy.dart';

@Zorphy()
abstract class \$Composite {
  \$ArtifactRef get ref;
  \$Issue117Ref get issue;
  String get id;
}
''');
        expect(result.detectedTypes, {'\$ArtifactRef', '\$Issue117Ref'});
        expect(result.hasMissing, isTrue);
        final comment = result.toGuidanceComment()!;
        expect(
          comment,
          contains("import '../artifact_ref/artifact_ref.dart';"),
        );
        expect(
          comment,
          contains("import '../issue117_ref/issue117_ref.dart';"),
        );
      });
    });

    group('sibling reference — import present', () {
      test('does NOT flag when relative import path is present', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
import '../artifact_ref/artifact_ref.dart';
part 'artifact_store.zorphy.dart';

@Zorphy()
abstract class \$ArtifactStore {
  \$ArtifactRef get ref;
  bool get summarized;
}
''');
        expect(result.detectedTypes, {'\$ArtifactRef'});
        expect(
          result.hasMissing,
          isFalse,
          reason: 'The sibling is imported via a relative path',
        );
        expect(result.toGuidanceComment(), isNull);
      });

      test('does NOT flag when package: import path is present', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:my_app/src/domain/entities/artifact_ref/artifact_ref.dart';
part 'artifact_store.zorphy.dart';

@Zorphy()
abstract class \$ArtifactStore {
  \$ArtifactRef get ref;
}
''');
        expect(result.hasMissing, isFalse);
      });

      test(
        'does NOT flag when caller-supplied importUris include the sibling',
        () {
          final result = CrossEntityImportDetector.detect(
            '''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'artifact_store.zorphy.dart';

@Zorphy()
abstract class \$ArtifactStore {
  \$ArtifactRef get ref;
}
''',
            importUris: {
              'package:zorphy_annotation/zorphy_annotation.dart',
              '../artifact_ref/artifact_ref.dart',
            },
          );
          expect(result.hasMissing, isFalse);
        },
      );

      test(
        'flags \$Ref even when ../other/artifact_ref.dart is imported (regression for finding #2)',
        () {
          // The canonical pattern `ref/ref.dart` should NOT match
          // `../other/artifact_ref.dart` even though it ends with `ref.dart`.
          final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
import '../other/artifact_ref.dart';
part 'holder.zorphy.dart';

@Zorphy()
abstract class \$Holder {
  \$Ref get ref;
}
''');
          expect(result.detectedTypes, {'\$Ref'});
          expect(
            result.hasMissing,
            isTrue,
            reason:
                'artifact_ref.dart does not match the canonical ref/ref.dart pattern',
          );
          final comment = result.toGuidanceComment()!;
          expect(comment, contains("import '../ref/ref.dart';"));
        },
      );

      test(
        'does NOT flag when the canonical snake/snake.dart import is present (regression for finding #2)',
        () {
          // Verify that the canonical `ref/ref.dart` pattern DOES match correctly.
          final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
import '../ref/ref.dart';
part 'holder.zorphy.dart';

@Zorphy()
abstract class \$Holder {
  \$Ref get ref;
}
''');
          expect(result.detectedTypes, {'\$Ref'});
          expect(
            result.hasMissing,
            isFalse,
            reason: 'The canonical ref/ref.dart import is present',
          );
        },
      );
    });

    group('snake_case conversion', () {
      test('converts simple PascalCase names', () {
        expect(
          CrossEntityImportDetector.toSnakeCase('ArtifactRef'),
          'artifact_ref',
        );
        expect(
          CrossEntityImportDetector.toSnakeCase('Issue117Ref'),
          'issue117_ref',
        );
      });

      test(
        'converts acronym-style names matching NamingUtils behavior (regression for finding #3)',
        () {
          // The toSnakeCase implementation now matches NamingUtils.toSnakeCase
          // from the CLI, which inserts `_` before EVERY uppercase letter
          // (except the first). This means `HTTPServer` -> `h_t_t_p_server`,
          // not `httpserver` or `http_server`.
          expect(
            CrossEntityImportDetector.toSnakeCase('HTTPServer'),
            'h_t_t_p_server',
            reason: 'Should match NamingUtils behavior for acronyms',
          );
          expect(
            CrossEntityImportDetector.toSnakeCase('ArtifactRef'),
            'artifact_ref',
          );
          expect(
            CrossEntityImportDetector.toSnakeCase('XMLParser'),
            'x_m_l_parser',
            reason: 'Each uppercase letter gets its own underscore',
          );
        },
      );

      test('handles single-word names', () {
        expect(CrossEntityImportDetector.toSnakeCase('User'), 'user');
        expect(CrossEntityImportDetector.toSnakeCase('Profile'), 'profile');
      });

      test('handles trailing digits', () {
        expect(CrossEntityImportDetector.toSnakeCase('Order2'), 'order2');
      });
    });

    group('scanImportUris', () {
      test('collects both single-quoted and double-quoted imports', () {
        final uris = CrossEntityImportDetector.scanImportUris('''
import 'package:foo/foo.dart';
import "package:bar/bar.dart";
import '../baz/baz.dart';
''');
        expect(uris, contains('package:foo/foo.dart'));
        expect(uris, contains('package:bar/bar.dart'));
        expect(uris, contains('../baz/baz.dart'));
      });

      test('excludes imports in line comments (regression for finding #1)', () {
        final uris = CrossEntityImportDetector.scanImportUris('''
// import 'commented_out.dart';
import 'real.dart';
// Another commented import: import "also_commented.dart";
''');
        expect(uris, contains('real.dart'));
        expect(
          uris,
          isNot(contains('commented_out.dart')),
          reason: 'Line-commented imports should be excluded',
        );
        expect(
          uris,
          isNot(contains('also_commented.dart')),
          reason: 'Line-commented imports should be excluded',
        );
      });

      test(
        'excludes imports in block comments (regression for finding #1)',
        () {
          final uris = CrossEntityImportDetector.scanImportUris('''
/* import 'block_commented.dart'; */
import 'real.dart';
/*
  Multi-line block comment:
  import "multi_line_commented.dart";
*/
''');
          expect(uris, contains('real.dart'));
          expect(
            uris,
            isNot(contains('block_commented.dart')),
            reason: 'Block-commented imports should be excluded',
          );
          expect(
            uris,
            isNot(contains('multi_line_commented.dart')),
            reason: 'Block-commented imports should be excluded',
          );
        },
      );

      test(
        'excludes imports in string literals (regression for finding #1)',
        () {
          final uris = CrossEntityImportDetector.scanImportUris('''
String example = "import 'not_a_real_import.dart';";
import 'real.dart';
final doc = 'Usage: import "fake_import.dart";';
''');
          expect(uris, contains('real.dart'));
          expect(
            uris,
            isNot(contains('not_a_real_import.dart')),
            reason: 'Imports in string literals should be excluded',
          );
          expect(
            uris,
            isNot(contains('fake_import.dart')),
            reason: 'Imports in string literals should be excluded',
          );
        },
      );
    });

    group('guidance comment format', () {
      test('uses a stable, parseable header', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'artifact_store.zorphy.dart';

@Zorphy()
abstract class \$ArtifactStore {
  \$ArtifactRef get ref;
}
''');
        final comment = result.toGuidanceComment()!;
        // The header lines should be stable so downstream tools can
        // detect+parse the guidance comment.
        expect(comment, contains('Cross-entity references detected.'));
        expect(comment, contains('Part files inherit imports from their'));
        expect(comment, contains('add these imports to <name>.dart'));
      });

      test('emits one import line per missing sibling', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'composite.zorphy.dart';

@Zorphy()
abstract class \$Composite {
  \$ArtifactRef get ref;
  \$Issue117Ref get issue;
  \$UserRef get user;
}
''');
        final comment = result.toGuidanceComment()!;
        final missingLines = comment
            .split('\n')
            .where((line) => line.startsWith('//   \$'))
            .toList();
        expect(missingLines.length, 3);
        expect(missingLines.any((l) => l.contains('artifact_ref')), isTrue);
        expect(missingLines.any((l) => l.contains('issue117_ref')), isTrue);
        expect(missingLines.any((l) => l.contains('user_ref')), isTrue);
      });

      test('uses the relative path form `../snake/snake.dart`', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'holder.zorphy.dart';

@Zorphy()
abstract class \$Holder {
  \$ArtifactRef get ref;
}
''');
        final comment = result.toGuidanceComment()!;
        // The suggested import is a relative path that works for the
        // canonical zorphy entity layout: <entity_dir>/<entity_dir>.dart
        // (e.g. `entities/artifact_ref/artifact_ref.dart`).
        expect(
          comment,
          contains("import '../artifact_ref/artifact_ref.dart';"),
        );
      });
    });

    group('issue #117 regression', () {
      // The exact fixture from the issue body:
      //   @Zorphy()
      //   abstract class $ArtifactStoreResult {
      //     $ArtifactRef get ref;
      //     bool get summarized;
      //     String? get summary;
      //   }
      //
      // When the parent .dart file is missing the
      // `import '../artifact_ref/artifact_ref.dart';` line, the detector
      // must emit a guidance comment listing exactly that import.
      test('flags the canonical issue #117 fixture', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'artifact_store_result.zorphy.dart';
part 'artifact_store_result.g.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class \$ArtifactStoreResult {
  \$ArtifactRef get ref;
  bool get summarized;
  String? get summary;
}
''');
        expect(result.detectedTypes, {'\$ArtifactRef'});
        expect(result.hasMissing, isTrue);
        final comment = result.toGuidanceComment()!;
        expect(
          comment,
          contains("import '../artifact_ref/artifact_ref.dart';"),
        );
        expect(comment, contains('\$ArtifactRef'));
      });

      test('no guidance when the canonical issue #117 fixture IS imported', () {
        final result = CrossEntityImportDetector.detect('''
import 'package:zorphy_annotation/zorphy_annotation.dart';
import '../artifact_ref/artifact_ref.dart';

part 'artifact_store_result.zorphy.dart';
part 'artifact_store_result.g.dart';

@Zorphy(generateJson: true, generateCompareTo: true)
abstract class \$ArtifactStoreResult {
  \$ArtifactRef get ref;
  bool get summarized;
  String? get summary;
}
''');
        expect(result.detectedTypes, {'\$ArtifactRef'});
        expect(result.hasMissing, isFalse);
        expect(result.toGuidanceComment(), isNull);
      });
    });
  });
}
