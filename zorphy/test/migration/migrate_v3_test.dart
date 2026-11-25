// TDD acceptance for the v2 -> v3 AST migration codemod (ISSUE-019, #194).
//
// The codemod must, on a representative v2 polymorphic corpus:
//   - strip every v2 preset and `generate*` boolean argument,
//   - turn `@Zorphy` on an `id`-bearing class into
//     `@ZorphyEntity(principalKey: #id)`,
//   - turn `@Zorphy` on an `id`-less class into `@ZorphyValue()`,
//   - turn `@ZorphySealed` into `@ZorphyUnion`,
//   - rewrite zorphy `.fromJson(map)` to `.fromWire(map)` with a trust-boundary
//     TODO, and `.toJson()` to `.toWire()`, while leaving unrelated
//     serializers untouched.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:zorphy/src/migration/part_directive_cleaner.dart';
import 'package:zorphy/src/migration/v3_codemod.dart';

void main() {
  final fixtureDir = p.join('test', 'migration', 'fixtures');

  String fixture(String name) =>
      File(p.join(fixtureDir, name)).readAsStringSync();

  final corpusNames = [
    'entity_with_id.dart',
    'value_without_id.dart',
    'sealed_with_codecs.dart',
  ];

  // Mirror the CLI: collect the annotated types across all files before
  // rewriting, so `User.fromJson(...)` is recognised even in the fixture that
  // does not itself declare `$User`.
  final corpusTypes = <String>{
    for (final name in corpusNames) ...V3Codemod.zorphyTypesIn(fixture(name)),
  };
  final codemod = V3Codemod(knownTypes: corpusTypes);

  group('v3 codemod — annotations', () {
    test('id-bearing @Zorphy becomes @ZorphyEntity(principalKey: #id)', () {
      final out = codemod.transform(fixture('entity_with_id.dart'));
      expect(out, contains('@ZorphyEntity(principalKey: #id)'));
      expect(out, isNot(contains('@Zorphy(')));
      expect(out, isNot(contains('ZorphyPreset')));
      expect(out, isNot(contains('generateJson')));
      expect(out, isNot(contains('generatePatch')));
    });

    test('id-less @Zorphy becomes @ZorphyValue()', () {
      final out = codemod.transform(fixture('value_without_id.dart'));
      expect(out, contains('@ZorphyValue()'));
      expect(out, isNot(contains('@Zorphy(')));
      expect(out, isNot(contains('generateCompareTo')));
    });

    test('@ZorphySealed becomes @ZorphyUnion', () {
      final out = codemod.transform(fixture('sealed_with_codecs.dart'));
      expect(out, contains('@ZorphyUnion('));
      expect(out, isNot(contains('@ZorphySealed')));
    });

    test('@Zorphy2 is rewritten like @Zorphy', () {
      const source = '''
@Zorphy2()
abstract class \$Legacy {
  final String id;
}
''';
      final out = codemod.transform(source);
      expect(out, contains('@ZorphyEntity(principalKey: #id)'));
      expect(out, isNot(contains('@Zorphy2')));
    });

    test('an id inherited from a supertype is detected', () {
      const source = '''
@Zorphy()
abstract class \$Base {
  final String id;
}

@Zorphy()
abstract class \$Child extends \$Base {
}
''';
      final out = codemod.transform(source);
      // Both annotations become entities: `$Base` declares `id` and `$Child`
      // inherits it instead of being misclassified as `@ZorphyValue()`.
      expect(out, contains('@ZorphyEntity(principalKey: #id)'));
      expect(out, isNot(contains('@ZorphyValue()')));
      expect(out, isNot(contains('@Zorphy(')));
    });
  });

  group('v3 codemod — codecs', () {
    test(
      '.fromJson(map) becomes .fromWire(map) with a trust-boundary TODO',
      () {
        final out = codemod.transform(fixture('sealed_with_codecs.dart'));
        expect(out, contains('.fromWire(map)'));
        expect(out, isNot(contains('.fromJson(')));
        expect(out, contains('TODO(trust-boundary): handle BoundaryErr'));
      },
    );

    test('.toJson() becomes .toWire()', () {
      final out = codemod.transform(fixture('sealed_with_codecs.dart'));
      expect(out, contains('.toWire()'));
      expect(out, isNot(contains('.toJson()')));
    });

    test('non-zorphy fromJson/toJson receivers stay untouched', () {
      const source = '''
@Zorphy()
abstract class \$User {
  final String id;
}

User decode(Map<String, Object?> map) => User.fromJson(map);
Map<String, Object?> encode(User user) => user.toJson();

final external = External.fromJson(const {});
final map = external.toJson();
''';
      final out = codemod.transform(source);
      expect(out, contains('User.fromWire(map)'));
      expect(out, contains('user.toWire()'));
      expect(out, contains('External.fromJson(const {})'));
      expect(out, contains('external.toJson()'));
      expect(out, isNot(contains('External.fromWire')));
      expect(out, isNot(contains('external.toWire')));
      // Only the zorphy call earns a trust-boundary marker.
      expect('TODO(trust-boundary)'.allMatches(out), hasLength(1));
    });

    test('two codecs on one line get one TODO at the call indentation', () {
      const source = '''
@Zorphy()
abstract class \$User {
  final String id;
}
User decode(Map a, Map b) {
  final x = User.fromJson(a), y = User.fromJson(b);
  return x;
}
''';
      final out = codemod.transform(source);
      expect(out, contains('User.fromWire(a)'));
      expect(out, contains('User.fromWire(b)'));
      expect(out, isNot(contains('fromJson')));
      expect('TODO(trust-boundary)'.allMatches(out), hasLength(1));
      final todoLine = out
          .split('\n')
          .firstWhere((line) => line.contains('TODO(trust-boundary)'));
      expect(todoLine, startsWith('  // TODO(trust-boundary)'));
    });
  });

  group('v3 codemod — cross-file inheritance (whole-tree archetype map)', () {
    test('inherited id crosses the file boundary via known archetypes', () {
      // The CLI's first pass builds a whole-tree map: `$Entity` declares `id`
      // (entity), `$Order` inherits it across files. Both annotations must
      // become entities — the child must NOT be misclassified as a value.
      final baseTypes = V3Codemod.zorphyTypesIn(
        fixture('cross_file_base.dart'),
      );
      final childTypes = V3Codemod.zorphyTypesIn(
        fixture('cross_file_child.dart'),
      );
      final known = <String>{...baseTypes, ...childTypes};
      final entityRoots = V3Codemod.entityRootsIn(
        fixture('cross_file_base.dart'),
      );
      final codemod = V3Codemod(
        knownTypes: known,
        knownEntityRoots: entityRoots,
      );

      final out = codemod.transform(fixture('cross_file_child.dart'));
      expect(out, contains('@ZorphyEntity(principalKey: #id)'));
      // The child annotation must be an entity, not a value — check the
      // annotation line, since the fixture's comment mentions `@ZorphyValue()`.
      final annotationLine = out
          .split('\n')
          .firstWhere((line) => line.startsWith('@Zorphy'));
      expect(annotationLine, contains('@ZorphyEntity(principalKey: #id)'));
      expect(annotationLine, isNot(contains('@ZorphyValue()')));
      expect(out, isNot(contains('@Zorphy(')));
    });

    test('id propagates transitively through a cross-file parent', () {
      // $Root declares `id`; $Middle (other file) implements $Root; $Leaf
      // (another file) implements $Middle. Only the edges let $Leaf stay an
      // entity instead of falling back to @ZorphyValue() (#238).
      const root = '''
@Zorphy()
abstract class \$Root {
  String get id;
}
''';
      const middle = '''
@Zorphy()
abstract class \$Middle implements \$Root {}
''';
      const leaf = '''
@Zorphy()
abstract class \$Leaf implements \$Middle {}
''';
      final edges = <String, List<String>>{
        ...V3Codemod.inheritanceEdgesIn(root),
        ...V3Codemod.inheritanceEdgesIn(middle),
        ...V3Codemod.inheritanceEdgesIn(leaf),
      };
      final codemod = V3Codemod(
        knownEntityRoots: V3Codemod.entityRootsIn(root),
        inheritanceEdges: edges,
      );

      final out = codemod.transform(leaf);
      expect(out, contains('@ZorphyEntity(principalKey: #id)'));
      expect(out, isNot(contains('@ZorphyValue()')));
    });

    test('a local parent wins over a same-named global entity root', () {
      // Another file declares an entity `$Base` with `id`; this file declares
      // its own `$Base` WITHOUT `id`. The child must stay a value — global
      // bare-name matching must not override the local declaration (#238).
      const local = '''
@Zorphy()
abstract class \$Base {}

@Zorphy()
abstract class \$Child extends \$Base {}
''';
      const foreign = '''
@Zorphy()
abstract class \$Base {
  String get id;
}
''';
      final codemod = V3Codemod(
        knownEntityRoots: V3Codemod.entityRootsIn(foreign),
      );

      final out = codemod.transform(local);
      expect(out, isNot(contains('@ZorphyEntity(principalKey: #id)')));
      expect('@ZorphyValue()'.allMatches(out), hasLength(2));
    });
  });

  group('v3 codemod — type-correct fromWire rewrites', () {
    test('a returned fromJson call gets .getOrThrow() to keep its type', () {
      const source = '''
@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}

Product decode(Map<String, Object?> map) => Product.fromJson(map);
''';
      final out = codemod.transform(source);
      expect(out, contains('Product.fromWire(map).getOrThrow()'));
      expect(out, isNot(contains('Product.fromJson')));
      // The trust-boundary TODO is retained for explicit handling.
      expect(out, contains('TODO(trust-boundary): handle BoundaryErr'));
    });

    test('an assigned fromJson call gets .getOrThrow() to keep its type', () {
      const source = '''
@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}

Product load(Map<String, Object?> map) {
  final product = Product.fromJson(map);
  return product;
}
''';
      final out = codemod.transform(source);
      expect(out, contains('Product.fromWire(map).getOrThrow()'));
      expect(out, isNot(contains('Product.fromJson')));
    });

    test('an argument-position fromJson call gets .getOrThrow()', () {
      // `print(...)` takes an argument, not a discarded expression statement:
      // the result is consumed as a value, so unwrap it (#238).
      const source = '''
@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}

void log(Map<String, Object?> map) {
  print(Product.fromJson(map));
}
''';
      final out = codemod.transform(source);
      expect(out, contains('print(Product.fromWire(map).getOrThrow())'));
      expect(out, isNot(contains('Product.fromJson')));
    });

    test('a discarded fromJson call keeps the BoundaryResult', () {
      const source = '''
@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}

void ignore(Map<String, Object?> map) {
  Product.fromJson(map);
}
''';
      final out = codemod.transform(source);
      expect(out, contains('Product.fromWire(map);'));
      expect(out, isNot(contains('.getOrThrow()')));
    });

    test('nested value positions unwrap the BoundaryResult', () {
      const source = '''
@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}

Product accept(Product p) => p;

Product nested(Map<String, Object?> map, Product fallback) {
  final a = Product.fromJson(map) ?? fallback;
  final b = true ? Product.fromJson(map) : fallback;
  final c = accept(Product.fromJson(map));
  final d = <Product>[Product.fromJson(map)];
  final e = (Product.fromJson(map)).id;
  return a;
}
''';
      final out = codemod.transform(source);
      expect(out, isNot(contains('Product.fromJson')));
      expect(
        'Product.fromWire(map).getOrThrow()'.allMatches(out),
        hasLength(5),
      );
    });

    test('a typed instance fromJson call rewrites to the static type call', () {
      // The generated `fromWire` is static, so `codec.fromWire(map)` would not
      // compile; the receiver must become the declared zorphy type (#238).
      const source = '''
@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}

Product decode(Product codec, Map<String, Object?> map) =>
    codec.fromJson(map);
''';
      final out = codemod.transform(source);
      expect(out, contains('Product.fromWire(map).getOrThrow()'));
      expect(out, isNot(contains('codec.fromWire')));
      expect(out, isNot(contains('codec.fromJson')));
    });

    test('a stale v2 json_serializable part is dropped on migration', () {
      const source = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'legacy.g.dart';

@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}
''';
      final out = codemod.transform(source);
      expect(out, isNot(contains("part 'legacy.g.dart';")));
      expect(out, contains('@ZorphyEntity(principalKey: #id)'));
    });

    test('a json_serializable part is kept for other annotated classes', () {
      const source = '''
part 'legacy.g.dart';

@JsonSerializable()
class Other {
  final int value;
}

@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}
''';
      final out = codemod.transform(source);
      expect(out, contains("part 'legacy.g.dart';"));
    });
  });

  group('v3 codemod — stale part directives (#249)', () {
    test('a stale v2 zorphy part directive is stripped on migration', () {
      const source = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'product.zorphy.dart';
part 'product.g.dart';

@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}
''';
      final out = codemod.transform(source, fileName: 'product.dart');
      expect(out, isNot(contains('.zorphy.dart')));
      expect(out, isNot(contains("part '")));
      expect(out, contains('@ZorphyEntity(principalKey: #id)'));
    });

    test('a migrated-but-stale file loses only its zorphy part', () {
      // The annotation is already v3 and no codec is called, so the file
      // carries no v2 construct BESIDES the stale part — the part still goes
      // (v3 never keeps a hand-written zorphy part), the json part stays.
      const source = '''
part 'product.zorphy.dart';
part 'product.g.dart';

@ZorphyEntity(principalKey: #id)
abstract class \$Product {
  String get id;
}
''';
      final out = codemod.transform(source, fileName: 'product.dart');
      expect(out, isNot(contains('.zorphy.dart')));
      expect(out, contains("part 'product.g.dart';"));
    });

    test('a non-zorphy json_serializable file passes through unchanged', () {
      const source = '''
part 'other.g.dart';

@JsonSerializable()
class Other {
  final int value;
}
''';
      expect(codemod.transform(source), source);
    });

    test('the cleaner reports the stale zorphy parts the CLI must delete', () {
      const source = '''
part 'a.zorphy.dart';
part 'b.zorphy.dart';
part 'a.g.dart';

@Zorphy()
abstract class \$A {}
''';
      final result = PartDirectiveCleaner.clean(
        PartDirectiveCleanArg(
          source: source,
          libraryFileName: 'a.dart',
          stripJsonParts: true,
        ),
      );
      expect(result.removedZorphyParts, ['a.zorphy.dart', 'b.zorphy.dart']);
      expect(result.removedJsonParts, ['a.g.dart']);
      expect(result.restoredJsonPart, isNull);
      expect(result.changed, isTrue);
    });

    test('a file with its own @JsonSerializable classes gets exactly one clean '
        'json part', () {
      const source = '''
part 'legacy.zorphy.dart';
part 'legacy.g.dart';
part 'legacy.g.dart';

@JsonSerializable()
class Other {
  final int value;
}

@Zorphy(generateJson: true)
abstract class \$Product {
  String get id;
}
''';
      final result = PartDirectiveCleaner.clean(
        PartDirectiveCleanArg(
          source: source,
          libraryFileName: 'product.dart',
          stripJsonParts: true,
        ),
      );
      expect(result.restoredJsonPart, 'product.g.dart');
      final out = result.source;
      expect(out, isNot(contains('legacy')));
      expect("part '".allMatches(out), hasLength(1));
      expect(out, contains("part 'product.g.dart';"));
    });

    test('the restored json part reuses the removed URI without a name', () {
      const source = '''
part 'legacy.g.dart';

@JsonSerializable()
class Other {}
''';
      final result = PartDirectiveCleaner.clean(
        PartDirectiveCleanArg(source: source, stripJsonParts: true),
      );
      expect(result.restoredJsonPart, 'legacy.g.dart');
      expect(result.source, contains("part 'legacy.g.dart';"));
    });

    test('an unparseable file is returned unchanged', () {
      const source = 'class {';
      final result = PartDirectiveCleaner.clean(
        PartDirectiveCleanArg(source: source, stripJsonParts: true),
      );
      expect(result.changed, isFalse);
      expect(result.source, source);
      expect(codemod.transform(source), source);
    });
  });

  group('v3 codemod — whole-corpus invariants', () {
    test('no v2 preset or generate* toggle survives anywhere', () {
      for (final name in corpusNames) {
        final out = codemod.transform(fixture(name));
        expect(out, isNot(matches(RegExp(r'ZorphyPreset'))), reason: name);
        expect(out, isNot(matches(RegExp(r'generate[A-Z]\w*'))), reason: name);
        expect(out, isNot(contains('@ZorphySealed')), reason: name);
      }
    });

    test('a file with no v2 constructs is returned unchanged', () {
      const clean = 'void main() { print("hi"); }\n';
      expect(codemod.transform(clean), clean);
    });
  });
}
