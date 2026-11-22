// Tests for ISSUE-002 (arrrrny/zorphy#177): the unified `PolymorphicIr`.
//
// The IR is built from resolved analyzer elements (the same view the
// generator sees), so every fixture here is real Dart source written to a
// temp directory and resolved through `AnalysisContextCollection` — the
// pattern `test/generation/issue_142_cross_library_sealed_test.dart` already
// uses for element-level work.
//
// Coverage:
//   - 1-level, 2-level and 3-level `implements $Parent` trees;
//   - `@ZorphyUnion` lowering into the same synthetic-leaf shape;
//   - inherited `principalKey` and per-leaf `replaySafe` resolution;
//   - the compile-time diagnostics ZORPHY_E001..ZORPHY_E003.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/parser/hierarchy_resolver.dart';
import 'package:zorphy/src/parser/polymorphic_ir.dart';

const _annotationImport =
    "import 'package:zorphy_annotation/zorphy_annotation.dart';\n";

/// Writes [sources] (file name -> contents) into a fresh temp directory,
/// resolves the library at [libraryName] and hands its classes to
/// [HierarchyResolver.resolveLibrary].
Future<PolymorphicIr> _resolve(
  Map<String, String> sources, {
  String libraryName = 'nodes.dart',
}) async {
  final root = Directory('test/.polymorphic_ir_tmp').absolute.path;
  Directory(root).createSync(recursive: true);
  final fixture = Directory(root).createTempSync('fixture_');
  for (final entry in sources.entries) {
    File('${fixture.path}/${entry.key}').writeAsStringSync(entry.value);
  }
  final libraryPath = '${fixture.path}/$libraryName';
  final collection = AnalysisContextCollection(includedPaths: [fixture.path]);
  final resolved =
      await collection
              .contextFor(libraryPath)
              .currentSession
              .getResolvedLibrary(libraryPath)
          as ResolvedLibraryResult;
  final ir = HierarchyResolver.resolveLibrary(resolved.element);
  await collection.dispose();
  return ir;
}

/// Single-library fixture with a three-level `implements $Parent` tree:
/// `$UiNode` -> `$InteractiveUiNode` -> `$ZfaButtonNode`.
const _threeLevel =
    '$_annotationImport'
    '''
part 'nodes.zorphy.dart';

@ZorphyState()
abstract class \$UiNode {
  String get id;
}

@ZorphyState()
abstract class \$InteractiveUiNode implements \$UiNode {
  bool get enabled;
}

@ZorphyState()
abstract class \$ZfaButtonNode implements \$InteractiveUiNode {
  String get label;
}
''';

void main() {
  group('PolymorphicIr — multi-level implements \$Parent', () {
    test(
      'a 3-level tree produces one sealed root and one concrete leaf',
      () async {
        final ir = await _resolve({'nodes.dart': _threeLevel});

        expect(ir.roots, hasLength(1));
        final root = ir.rootFor('UiNode');
        expect(root, isNotNull);
        expect(root!.archetype, ArchetypeKind.state);
        expect(root.isSealedRoot, isTrue);
        expect(root.isAbstractIntermediate, isFalse);
        expect(root.isConcreteLeaf, isFalse);
        expect(root.discriminatorKey, 'kind');
        expect(root.discriminatorValue, 'ui_node');

        // `$InteractiveUiNode` is the middle node: neither root nor leaf.
        final middle = root.directSubTypes.single;
        expect(middle.className, r'$InteractiveUiNode');
        expect(middle.cleanName, 'InteractiveUiNode');
        expect(middle.isAbstractIntermediate, isTrue);
        expect(middle.isSealedRoot, isFalse);
        expect(middle.isConcreteLeaf, isFalse);
        expect(middle.discriminatorValue, 'interactive_ui_node');

        // `$ZfaButtonNode` closes the hierarchy.
        final leaf = middle.directSubTypes.single;
        expect(leaf.className, r'$ZfaButtonNode');
        expect(leaf.cleanName, 'ZfaButtonNode');
        expect(leaf.isConcreteLeaf, isTrue);
        expect(leaf.discriminatorValue, 'zfa_button_node');
        expect(leaf.directSubTypes, isEmpty);

        // Both the middle node and the leaf are reachable from the root,
        // transitively, through the same single graph.
        expect(root.superTypes, isEmpty);
        expect(middle.superTypes.map((n) => n.cleanName), ['UiNode']);
        expect(leaf.superTypes.map((n) => n.cleanName), [
          'InteractiveUiNode',
          'UiNode',
        ]);
        expect(root.allConcreteLeaves.map((n) => n.cleanName), [
          'ZfaButtonNode',
        ]);
      },
    );

    test('a 1-level hierarchy is a root with one direct leaf', () async {
      final ir = await _resolve({
        'nodes.dart':
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyValue()
abstract class \$Money {
  int get cents;
}

@ZorphyValue()
abstract class \$Usd implements \$Money {
  int get cents;
}
''',
      });

      final root = ir.rootFor('Money')!;
      expect(root.isSealedRoot, isTrue);
      expect(root.directSubTypes.map((n) => n.cleanName), ['Usd']);
      expect(root.allConcreteLeaves.map((n) => n.cleanName), ['Usd']);
      expect(root.directSubTypes.single.superTypes.map((n) => n.cleanName), [
        'Money',
      ]);
    });

    test('two sibling leaves share one root', () async {
      final ir = await _resolve({
        'nodes.dart':
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyValue()
abstract class \$Shape {
  double get area;
}

@ZorphyValue()
abstract class \$Circle implements \$Shape {
  double get area;
}

@ZorphyValue()
abstract class \$Square implements \$Shape {
  double get area;
}
''',
      });

      final root = ir.rootFor('Shape')!;
      expect(root.directSubTypes.map((n) => n.cleanName).toSet(), {
        'Circle',
        'Square',
      });
      expect(root.allConcreteLeaves.map((n) => n.cleanName).toSet(), {
        'Circle',
        'Square',
      });
      expect(ir.roots, hasLength(1));
    });
  });

  group('multi-file hierarchies', () {
    test('a subtype in another library joins the same hierarchy', () async {
      final root = Directory('test/.polymorphic_ir_tmp').absolute.path;
      Directory(root).createSync(recursive: true);
      final fixture = Directory(root).createTempSync('multifile_');
      File('${fixture.path}/base_node.dart').writeAsStringSync(
        '$_annotationImport'
        '''
part 'base_node.zorphy.dart';

@ZorphyState()
abstract class \$UiNode {
  String get id;
}
''',
      );
      File('${fixture.path}/button_node.dart').writeAsStringSync(
        '$_annotationImport'
        '''
import 'base_node.dart';

part 'button_node.zorphy.dart';

@ZorphyState()
abstract class \$ZfaButtonNode implements \$UiNode {
  String get label;
}
''',
      );
      final basePath = '${fixture.path}/base_node.dart';
      final buttonPath = '${fixture.path}/button_node.dart';
      final collection = AnalysisContextCollection(
        includedPaths: [fixture.path],
      );
      final base =
          await collection
                  .contextFor(basePath)
                  .currentSession
                  .getResolvedLibrary(basePath)
              as ResolvedLibraryResult;
      final button =
          await collection
                  .contextFor(buttonPath)
                  .currentSession
                  .getResolvedLibrary(buttonPath)
              as ResolvedLibraryResult;

      final ir = HierarchyResolver.resolveLibraries([
        base.element,
        button.element,
      ]);
      await collection.dispose();

      final rootNode = ir.rootFor('UiNode')!;
      expect(rootNode.allConcreteLeaves.map((n) => n.cleanName), [
        'ZfaButtonNode',
      ]);
      expect(rootNode.directSubTypes.single.cleanName, 'ZfaButtonNode');
    });
  });

  group('@ZorphyUnion lowering', () {
    test('union variants lower to synthetic concrete leaves', () async {
      final ir = await _resolve({
        'nodes.dart':
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class \$AsyncStatus {
  factory \$AsyncStatus.loading() = \$Loading;
  factory \$AsyncStatus.ready(String value) = \$Ready;
}

@ZorphyValue()
abstract class \$Loading {
  String get kind;
}

@ZorphyValue()
abstract class \$Ready {
  String get kind;
  String get value;
}
''',
      });

      final union = ir.rootFor('AsyncStatus');
      expect(union, isNotNull);
      expect(union!.isSealedRoot, isTrue);
      expect(union.archetype, ArchetypeKind.value);
      expect(union.directSubTypes.map((n) => n.cleanName).toSet(), {
        'Loading',
        'Ready',
      });
      expect(union.allConcreteLeaves, hasLength(2));
    });

    test('union and implements forms produce the same structure', () async {
      final viaImplements = await _resolve({
        'nodes.dart':
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyValue()
abstract class \$Status {
  String get kind;
}

@ZorphyValue()
abstract class \$Loading implements \$Status {
  String get kind;
}
''',
      });
      final viaUnion = await _resolve({
        'nodes.dart':
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyUnion()
abstract class \$Status {
  factory \$Status.loading() = \$Loading;
}

@ZorphyValue()
abstract class \$Loading {
  String get kind;
}
''',
      }, libraryName: 'nodes.dart');

      String shape(PolymorphicIr ir) => ir.roots
          .map(
            (root) =>
                '${root.cleanName}(${root.archetype.name}){'
                'sealed=${root.isSealedRoot},'
                'leaves=${root.allConcreteLeaves.map((n) => n.cleanName).toList()}'
                '}',
          )
          .join(',');

      expect(shape(viaUnion), shape(viaImplements));
    });
  });

  group('inherited principalKey', () {
    test('a subtype inherits the root principalKey', () async {
      final ir = await _resolve({
        'nodes.dart':
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyEntity(principalKey: #id)
abstract class \$Product {
  String get id;
  String get name;
}

@ZorphyEntity()
abstract class \$Book implements \$Product {
  String get title;
}
''',
      });

      final root = ir.rootFor('Product')!;
      expect(root.principalKey, 'id');
      final leaf = root.allConcreteLeaves.single;
      expect(leaf.principalKey, 'id');
      expect(ir.diagnostics.where((d) => d.isError), isEmpty);
    });

    test(
      'ZORPHY_E001: an entity root without principalKey is an error',
      () async {
        final ir = await _resolve({
          'nodes.dart':
              '$_annotationImport'
              '''
part 'nodes.zorphy.dart';

@ZorphyEntity()
abstract class \$Product {
  String get id;
}
''',
        });

        expect(
          ir.diagnostics.map((d) => d.code),
          contains(ZorphyDiagnosticCode.e001MissingPrincipalKey),
        );
      },
    );

    test('ZORPHY_E001: a nullable principalKey field is an error', () async {
      final ir = await _resolve({
        'nodes.dart':
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyEntity(principalKey: #id)
abstract class \$Product {
  String? get id;
}
''',
      });

      expect(
        ir.diagnostics.map((d) => d.code),
        contains(ZorphyDiagnosticCode.e001MissingPrincipalKey),
      );
    });

    test(
      'ZORPHY_E001: a non-String/int principalKey field is an error',
      () async {
        final ir = await _resolve({
          'nodes.dart':
              '$_annotationImport'
              '''
part 'nodes.zorphy.dart';

@ZorphyEntity(principalKey: #id)
abstract class \$Product {
  double get id;
}
''',
        });

        expect(
          ir.diagnostics.map((d) => d.code),
          contains(ZorphyDiagnosticCode.e001MissingPrincipalKey),
        );
      },
    );
  });

  group('replaySafe resolution', () {
    test('a sealed intent root baseline is overridden by a leaf', () async {
      final ir = await _resolve({
        'nodes.dart':
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyIntent(replaySafe: false)
abstract class \$Command {
  String get id;
}

@ZorphyIntent(replaySafe: true)
abstract class \$Undo implements \$Command {
  String get target;
}
''',
      });

      final root = ir.rootFor('Command')!;
      expect(root.replaySafe, isFalse);
      expect(root.allConcreteLeaves.single.replaySafe, isTrue);
    });
  });

  group('compile-time diagnostics', () {
    test(
      'ZORPHY_E002: mixing archetypes in one hierarchy is an error',
      () async {
        final ir = await _resolve({
          'nodes.dart':
              '$_annotationImport'
              '''
part 'nodes.zorphy.dart';

@ZorphyValue()
abstract class \$Money {
  int get cents;
}

@ZorphyEntity(principalKey: #id)
abstract class \$Price implements \$Money {
  String get id;
}
''',
        });

        expect(
          ir.diagnostics.map((d) => d.code),
          contains(ZorphyDiagnosticCode.e002MixedArchetypes),
        );
      },
    );

    test(
      'ZORPHY_E003: duplicate discriminatorValue in a hierarchy is an error',
      () async {
        final ir = await _resolve({
          'nodes.dart':
              '$_annotationImport'
              '''
part 'nodes.zorphy.dart';

// `AB` and `aB` both snake_case to `a_b`, so the two leaves collide.
@ZorphyValue()
abstract class \$Root {
  String get kind;
}

@ZorphyValue()
abstract class \$AB implements \$Root {
  String get kind;
}

@ZorphyValue()
abstract class \$aB implements \$Root {
  String get kind;
}
''',
        });

        expect(
          ir.diagnostics.map((d) => d.code),
          contains(ZorphyDiagnosticCode.e003DuplicateDiscriminator),
        );
      },
    );
  });

  group('discriminator', () {
    test('the root discriminator key is inherited by every node', () async {
      final ir = await _resolve({
        'nodes.dart':
            '$_annotationImport'
            '''
part 'nodes.zorphy.dart';

@ZorphyState(discriminator: 'variant')
abstract class \$Node {
  String get id;
}

@ZorphyState()
abstract class \$Leaf implements \$Node {
  String get label;
}
''',
      });

      final root = ir.rootFor('Node')!;
      expect(root.discriminatorKey, 'variant');
      expect(root.allConcreteLeaves.single.discriminatorKey, 'variant');
    });
  });
}
