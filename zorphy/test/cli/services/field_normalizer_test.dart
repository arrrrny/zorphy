// Unit tests for `FieldNormalizer._determinePrefix` comment-safety (#310).
//
// The #310 fix made `_determinePrefix` return `''` (plain type) when the
// referenced file exists but declares no `abstract class $X` / `$$X`.
// However, the regex was run against the RAW file content (including
// comments). A doc comment in a hand-written class file that mentions the
// literal text `abstract class $X` (very common — e.g. `/// Plain class,
/// NO abstract class $X here.`) would falsely match and emit the `$`
// prefix, reproducing the `InvalidType` symptom.
//
// The fix strips `//` and `/* */` comments before running the regex.
//
// These tests drive `EntityCreator.create()` end-to-end (the same path
// `zfa entity create` uses) and assert the GENERATED source declares the
// field with the plain type when the referenced file is a hand-written
// class — with and without the offending comment.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zorphy/zorphy.dart';

void main() {
  group('FieldNormalizer._determinePrefix comment-safety (#310)', () {
    late Directory tmp;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('zorphy_310_');
    });

    tearDown(() async {
      await tmp.delete(recursive: true);
    });

    // Writes a hand-written (non-Zorphy) class file at
    // `<tmp>/<snake>/<snake>.dart` with the given [content].
    Future<void> writeHandWrittenClass(String name, String content) async {
      final snake = _toSnake(name);
      final dir = Directory(p.join(tmp.path, snake));
      await dir.create(recursive: true);
      await File(p.join(dir.path, '$snake.dart')).writeAsString(content);
    }

    // Creates a Zorphy entity [name] with a single field referencing
    // [refType]. Returns the generated source.
    Future<String> createEntityReferencing(String name, String refType) async {
      final creator = EntityCreator(baseOutputDir: tmp.path);
      // FieldDefinition.parse handles nullability stripping; the resulting
      // `fullType` getter re-adds the `?` based on `nullable`.
      final field = FieldDefinition.parse('ref:$refType');
      final result = await creator.create(
        EntityConfig(name: name, outputDir: tmp.path, fields: [field]),
      );
      expect(result.isSuccess, isTrue, reason: result.error);
      return File(result.filePath).readAsString();
    }

    test('hand-written sealed class WITHOUT comment -> plain type', () async {
      await writeHandWrittenClass('SearchResultPrice', '''
sealed class SearchResultPrice {
  const SearchResultPrice();
}
''');

      final src = await createEntityReferencing(
        'SearchResult',
        'SearchResultPrice?',
      );

      // The field declaration must be the PLAIN type (no `\$` prefix).
      expect(
        src,
        contains('SearchResultPrice? get ref;'),
        reason: 'Plain hand-written class must emit the plain type.',
      );
      expect(
        src,
        isNot(contains(r'$SearchResultPrice? get ref;')),
        reason:
            'A `\$` prefix here is the #310 bug — the analyzer cannot '
            'resolve `\$SearchResultPrice` for a hand-written class.',
      );
    });

    test(
      'hand-written sealed class WITH comment mentioning `abstract class \$X` '
      '-> plain type (comment-safety)',
      () async {
        // The doc comment contains the EXACT literal pattern the regex was
        // matching on (`abstract class $SearchResultPrice`). Before the
        // comment-stripping fix this falsely matched and emitted the `$`
        // prefix, reproducing the InvalidType symptom.
        await writeHandWrittenClass('SearchResultPrice', '''
/// Hand-written (non-Zorphy) sealed union dispatcher, like Vendure's
/// SearchResultPrice. This is a plain class — NO `abstract class \$SearchResultPrice`
/// declaration here, by design (kept as SDK glue).
sealed class SearchResultPrice {
  const SearchResultPrice();
}
''');

        final src = await createEntityReferencing(
          'SearchResult',
          'SearchResultPrice?',
        );

        // Despite the comment, the field declaration must be the PLAIN type.
        expect(
          src,
          contains('SearchResultPrice? get ref;'),
          reason:
              'Comment-safety: a doc comment mentioning the pattern '
              'must NOT trigger a false-positive `\$` prefix.',
        );
        expect(
          src,
          isNot(contains(r'$SearchResultPrice? get ref;')),
          reason:
              'The `\$` prefix here means the comment was NOT stripped '
              'before the regex — that is the #310 comment-matching bug.',
        );
      },
    );

    test('hand-written plain class with block comment -> plain type', () async {
      // Block comment variant — also must be stripped.
      await writeHandWrittenClass('Money', '''
/* Plain value object — does NOT declare `abstract class \$Money`.
   Kept hand-written because it carries a custom fromJson dispatcher. */
class Money {
  final int amount;
  const Money(this.amount);
}
''');

      final src = await createEntityReferencing('Invoice', 'Money?');

      expect(
        src,
        contains('Money? get ref;'),
        reason:
            'Block-comment mention of the pattern must NOT trigger a '
            'false-positive `\$` prefix.',
      );
      expect(
        src,
        isNot(contains(r'$Money? get ref;')),
        reason: 'Block comments must be stripped before the regex.',
      );
    });

    test(
      'Zorphy entity (`abstract class \$X`) -> `\$` prefix preserved',
      () async {
        // Sanity check: when the target IS a Zorphy entity (declares
        // `abstract class $X`), the `$` prefix is still emitted. This guards
        // against an over-eager comment-stripping regression that would
        // strip the actual class declaration.
        await writeHandWrittenClass('Country', '''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'country.zorphy.dart';

@Zorphy(generateJson: true)
abstract class \$Country {
  String get code;
}
''');

        final src = await createEntityReferencing('Address', 'Country?');

        expect(
          src,
          contains(r'$Country? get ref;'),
          reason:
              'A real Zorphy entity (declares `abstract class \$Country`) '
              'must still get the `\$` prefix — the comment-stripping must NOT '
              'remove the actual class declaration line.',
        );
      },
    );

    test(
      'Zorphy second-order entity (`abstract class \$\$X`) -> `\$\$` prefix',
      () async {
        await writeHandWrittenClass('BaseEntity', '''
import 'package:zorphy_annotation/zorphy_annotation.dart';
part 'base_entity.zorphy.dart';

@Zorphy(generateJson: true)
abstract class \$\$BaseEntity {
  String get id;
}
''');

        final src = await createEntityReferencing('Concrete', 'BaseEntity?');

        expect(
          src,
          contains(r'$$BaseEntity? get ref;'),
          reason:
              'A real second-order Zorphy entity must still get the `\$\$` '
              'prefix.',
        );
      },
    );

    test('forward reference (file does not exist) -> `\$` prefix', () async {
      // #315 regression guard: when the referenced file does NOT exist yet
      // (forward reference, batch creation), assume Zorphy entity and emit
      // the `$` prefix so the builder can resolve it once it exists.
      final src = await createEntityReferencing('Order', 'Customer?');

      expect(
        src,
        contains(r'$Customer? get ref;'),
        reason:
            'Forward references (file not on disk yet) must still get '
            'the `\$` prefix — that is the #315 fix.',
      );
    });
  });
}

String _toSnake(String input) {
  final result = <String>[];
  for (var i = 0; i < input.length; i += 1) {
    final char = input[i];
    if (i > 0 && char.toUpperCase() == char && char != '_') {
      result.add('_');
    }
    result.add(char.toLowerCase());
  }
  return result.join('');
}
