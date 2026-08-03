import 'package:test/test.dart';
import 'package:zorphy/src/merge/merge.dart';

void main() {
  group('RegionParser', () {
    test('parses GENERATED regions', () {
      final source = '''// GENERATED - DO NOT EDIT
class \$User {
  final String name;
}
// END GENERATED
''';
      final regions = RegionParser.parse(source);
      expect(regions, hasLength(1));
      expect(regions[0].type, RegionType.generated);
      expect(regions[0].startLine, 0);
      expect(regions[0].content, contains('class \$User'));
    });

    test('parses @preserve regions', () {
      final source = '''// @preserve
customMethod() { /* ... */ }
// @end-preserve
''';
      final regions = RegionParser.parse(source);
      expect(regions, hasLength(1));
      expect(regions[0].type, RegionType.preserved);
      expect(regions[0].content, contains('customMethod'));
    });

    test('parses nested @preserve inside GENERATED', () {
      final source = '''// GENERATED - DO NOT EDIT
class \$User {
  final String name;
  // @preserve
  String customGetter => _custom;
  // @end-preserve
}
// END GENERATED
''';
      final regions = RegionParser.parse(source);
      expect(regions, hasLength(2));
      expect(regions[0].type, RegionType.generated);
      expect(regions[1].type, RegionType.preserved);
    });

    test('extractPreservedBlocks finds @preserve inside block', () {
      final block = '''final String name;
// @preserve
String customGetter => _custom;
// @end-preserve
int get age => _age;
''';
      final blocks = RegionParser.extractPreservedBlocks(block);
      expect(blocks, hasLength(1));
      expect(blocks[0].content, contains('customGetter'));
    });

    test('returns empty for source without markers', () {
      final source = 'class Foo { final int x; }';
      final regions = RegionParser.parse(source);
      expect(regions, isEmpty);
    });
  });

  group('AstDiff', () {
    test('returns empty for identical content', () {
      final source = 'class Foo { final int x; }';
      final entries = AstDiff.diff(
        existingSource: source,
        generatedSource: source,
      );
      expect(entries, isEmpty);
    });

    test('detects added declaration', () {
      final existing = 'class Foo { final int x; }';
      final generated = '''class Foo { final int x; }

extension FooX on Foo { String get display => "\$x"; }
''';
      final entries = AstDiff.diff(
        existingSource: existing,
        generatedSource: generated,
      );
      expect(entries.any((e) => e.type == DiffType.added), isTrue);
    });

    test('detects modified declaration', () {
      final existing = 'class Foo { final int x; }';
      final generated = 'class Foo { final String name; }';
      final entries = AstDiff.diff(
        existingSource: existing,
        generatedSource: generated,
      );
      expect(entries.any((e) => e.type == DiffType.modified), isTrue);
    });

    test('detects removed declaration', () {
      final existing = '''class Foo { final int x; }

extension FooX on Foo {}
''';
      final generated = 'class Foo { final int x; }';
      final entries = AstDiff.diff(
        existingSource: existing,
        generatedSource: generated,
      );
      expect(entries.any((e) => e.type == DiffType.removed), isTrue);
    });
  });

  group('MergeOrchestrator', () {
    test('force mode returns generated content', () {
      final existing = 'class Old { final int x; }';
      final generated = 'class New { final String name; }';
      final result = MergeOrchestrator.merge(
        existingContent: existing,
        generatedContent: generated,
        mode: MergeMode.force,
      );
      expect(result.content, contains('class New'));
      expect(result.hasChanges, isTrue);
      expect(result.conflicts, isEmpty);
    });

    test('no existing file returns generated content', () {
      final generated = 'class Foo { final int x; }';
      final result = MergeOrchestrator.merge(
        existingContent: '',
        generatedContent: generated,
      );
      expect(result.hasChanges, isTrue);
      expect(result.content, contains('class Foo'));
    });

    test('identical content returns unchanged', () {
      final source = 'class Foo { final int x; }';
      final result = MergeOrchestrator.merge(
        existingContent: source,
        generatedContent: source,
      );
      expect(result.hasChanges, isFalse);
    });

    test('smart merge with GENERATED markers replaces block', () {
      final existing = '''// GENERATED - DO NOT EDIT
class \$User {
  final String name;
}
// END GENERATED
''';
      final generated = '''// GENERATED - DO NOT EDIT
class \$User {
  final String name;
  final int? age;
}
// END GENERATED
''';
      final result = MergeOrchestrator.merge(
        existingContent: existing,
        generatedContent: generated,
      );
      expect(result.content, contains('age'));
      expect(result.hasChanges, isTrue);
      expect(result.conflicts, isEmpty);
    });

    test('smart merge preserves user code between regions', () {
      final existing = '''// GENERATED - DO NOT EDIT
class \$User {
  final String name;
}
// END GENERATED

class UserHelper {
  static String greet(String name) => "Hello \$name";
}
''';
      final generated = '''// GENERATED - DO NOT EDIT
class \$User {
  final String name;
  final int? age;
}
// END GENERATED
''';
      final result = MergeOrchestrator.merge(
        existingContent: existing,
        generatedContent: generated,
      );
      expect(result.content, contains('age'));
      expect(result.content, contains('UserHelper'));
      expect(result.content, contains('greet'));
    });

    test('structural merge keeps user-only declarations', () {
      final existing = '''class \$User {
  final String name;
}

class UserHelper {
  static void doStuff() {}
}
''';
      final generated = '''class \$User {
  final String name;
  final String email;
}
''';
      final result = MergeOrchestrator.merge(
        existingContent: existing,
        generatedContent: generated,
      );
      expect(result.content, contains('email'));
      expect(result.content, contains('UserHelper'));
    });
  });

  group('Golden test: manual edits survive regeneration', () {
    test('full scenario with @preserve inside GENERATED', () {
      final existing = '''// GENERATED - DO NOT EDIT
class \$Todo {
  final String title;
  final bool done;

  // @preserve
  String get statusText => done ? "Done" : "Pending";
  // @end-preserve
}
// END GENERATED

class TodoUtils {
  static String format(Todo todo) => todo.title.toUpperCase();
}
''';
      final generated = '''// GENERATED - DO NOT EDIT
class \$Todo {
  final String title;
  final bool done;
  final int? priority;
}
// END GENERATED
''';
      final result = MergeOrchestrator.merge(
        existingContent: existing,
        generatedContent: generated,
      );
      expect(result.content, contains('priority'));
      expect(result.content, contains('statusText'));
      expect(result.content, contains('TodoUtils'));
      expect(result.content, contains('format'));
    });
  });
}
