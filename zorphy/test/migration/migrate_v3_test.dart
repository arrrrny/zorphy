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

    test('a bare-expression fromJson call is left as a BoundaryResult', () {
      // No type context to preserve — the result is the natural value.
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
      expect(out, contains('Product.fromWire(map)'));
      expect(out, isNot(contains('.getOrThrow()')));
      expect(out, isNot(contains('Product.fromJson')));
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
