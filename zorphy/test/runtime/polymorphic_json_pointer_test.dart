// Issue #186 — polymorphic, zero-reflection JSON-Pointer resolution.
//
// Every generated Zorphy class exposes
// `static ZorphyLens<T, Object?>? resolvePath(String pointer)`, a
// compile-time switch table over the class's own JSON-Pointer segments.
// A pointer that names a field returns a lens whose `get` dispatches on the
// RUNTIME subtype, so:
//
//  * a pointer naming a shared interface field (`/contractId`) resolves for a
//    node of ANY subtype in the hierarchy, and
//  * a pointer naming a subtype-specific field (`/enabled`) resolves through
//    runtime dispatch and answers `null` — never throws — on a subtype that
//    does not carry it.
//
// Resolution is O(path depth): one switch step per segment, no regex, no
// `dart:mirrors`, and no reflective field lookup.
//
// The pipeline is driven end-to-end (resolved ClassElement -> ClassAnalyzer ->
// Orchestrator.generate), so this pins the REAL generator, not a hand-built
// spec. The emitted parts are additionally handed to the analyzer, so a
// `resolvePath` that does not compile can never reach consumers.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/analysis/annotation_parser.dart';
import 'package:zorphy/src/analysis/class_analyzer.dart';
import 'package:zorphy/src/analysis/class_graph.dart';
import 'package:zorphy/src/models/generation_config.dart';
import 'package:zorphy/src/orchestrator.dart';

const _zorphyChecker = TypeChecker.fromUrl(
  'package:zorphy_annotation/src/annotations.dart#Zorphy',
);

/// The issue's exact hierarchy shape: a shared root carrying `/contractId`,
/// an intermediate node adding `/enabled`, and a leaf that is a SIBLING of the
/// interactive branch (so `/enabled` is inapplicable to it).
const _hierarchy = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'ui_node.zorphy.dart';

@Zorphy(explicitSubTypes: [\$InteractiveUiNode, \$ZfaTextNode])
abstract class \$UiNode {
  String get contractId;
}

@Zorphy(explicitSubTypes: [\$ZfaButtonNode])
abstract class \$InteractiveUiNode implements \$UiNode {
  bool get enabled;
}

@Zorphy()
abstract class \$ZfaButtonNode implements \$InteractiveUiNode {
  String get label;
}

@Zorphy()
abstract class \$ZfaTextNode implements \$UiNode {
  String get text;
}

@Zorphy()
abstract class \$EditDraft {
  String get title;
  double get price;
}

@Zorphy()
abstract class \$ProductUiState {
  EditDraft get editDraft;
  int get selectedTab;
}
''';

/// A SEALED root with its own fields — the shape that reaches
/// `_coversEverySubtype`, `_emit`'s writerless-root branch and the
/// inherited-field writer coverage all at once.
///
/// `$$` roots never generate a `copyWith` of their own, so `/id` used to be
/// dropped from the table entirely, and each subtype-only field used to drop
/// the `default:` that kept its switch exhaustive.
const _sealedSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'sealed.zorphy.dart';

@Zorphy(explicitSubTypes: [\$LeafA, \$LeafB])
abstract class \$\$Root {
  String get id;
}

@Zorphy()
abstract class \$LeafA implements \$\$Root {
  String get onlyOnA;
}

@Zorphy()
abstract class \$LeafB implements \$\$Root {
  String get other;
}
''';

/// A generic annotated class: a static member cannot reference `T`, so the
/// resolver must be declined rather than emitted.
const _genericSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'generic.zorphy.dart';

@Zorphy()
abstract class \$Box<T> {
  T get value;
}
''';

/// A subtype-only field whose type is ANOTHER annotated class, and a nested
/// type whose own resolver is declined because it generates no `copyWith`.
const _nestedSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'nested.zorphy.dart';

@Zorphy(explicitSubTypes: [\$EditNode, \$TextNode])
abstract class \$\$UiNode {
  String get contractId;
}

@Zorphy()
abstract class \$EditNode implements \$\$UiNode {
  \$Draft get draft;
}

@Zorphy()
abstract class \$TextNode implements \$\$UiNode {
  String get text;
}

@Zorphy()
abstract class \$Draft {
  String get title;
}

@Zorphy(generateCopyWith: false)
abstract class \$Frozen {
  String get label;
}

@Zorphy()
abstract class \$Holder {
  Frozen get frozen;
}
''';

/// Generates every `@Zorphy` class of ONE fixture library and returns the
/// emitted source per class, keyed by clean class name.
/// Finding fixtures from the post-fix review round on #206.
///
/// `_nullableSource` pins the explicit-null write: `copyWith` is
/// `field ?? this.field`, so only the generated Patch can clear a nullable
/// field. `_genericSubtypeSource` pins a GENERIC subtype of a nongeneric root:
/// its `T`-typed field cannot be named from a static member, so the segment
/// must not be advertised at all. `_siblingNestedSource` pins two siblings
/// typing the SAME segment differently, which must dispatch on the runtime
/// subtype rather than on whichever sibling was visited first.
const _nullableSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'nullable.zorphy.dart';

@Zorphy()
abstract class \$Note {
  String get id;
  String? get note;
}
''';

const _genericSubtypeSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'generic_subtype.zorphy.dart';

@Zorphy(explicitSubTypes: [\$Leaf])
abstract class \$\$Root {
  String get id;
}

@Zorphy()
abstract class \$Leaf<T> implements \$\$Root {
  T get value;
}
''';

/// A composite list field: the pointer setter must use the repo's checked
/// element-wise conversion (issue #148), never a hard `value as List<Map<…>>`.
const _compositeListSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'composite_list.zorphy.dart';

@Zorphy()
abstract class \$TaggedResult {
  List<Map<String, String>> get tags;
}
''';

const _siblingNestedSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'sibling_nested.zorphy.dart';

@Zorphy(explicitSubTypes: [\$PlainNode, \$DraftNode])
abstract class \$\$Node {
  String get id;
}

@Zorphy()
abstract class \$PlainNode implements \$\$Node {
  String get payload;
}

@Zorphy()
abstract class \$DraftNode implements \$\$Node {
  \$Draft get payload;
}

@Zorphy()
abstract class \$Draft {
  String get title;
}
''';

/// A COVARIANT redeclaration of a nested field on a sealed root: a legal Dart
/// narrowing (`$Child.payload` is a `$DraftB`, a subtype of `$DraftA`) records
/// more than one nested target for a field that is still VISIBLE on the root.
/// The single-target composition's `.single` threw `Bad state: Too many
/// elements` here, so the whole codegen build failed on an ordinary hierarchy
/// (review finding on PR #201, json_pointer_generator.dart:855). The target is
/// only knowable per-declarer, so the generator must fall through rather than
/// assume one.
const _covariantNestedSource = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'covariant_nested.zorphy.dart';

@Zorphy()
abstract class \$DraftA {
  String get title;
}

@Zorphy()
abstract class \$DraftB implements \$DraftA {
  String get title;
  String get extra;
}

@Zorphy(explicitSubTypes: [\$Child])
abstract class \$\$Node {
  \$DraftA get payload;
}

@Zorphy()
abstract class \$Child implements \$\$Node {
  \$DraftB get payload;
}
''';

Future<Map<String, String>> _generateHierarchy(Directory fixtureDir) =>
    _generate(fixtureDir, 'ui_node', _hierarchy);

Future<Map<String, String>> _generate(
  Directory fixtureDir,
  String libraryName,
  String source,
) async {
  final sourceFile = File('${fixtureDir.path}/$libraryName.dart')
    ..writeAsStringSync(source);
  final collection = AnalysisContextCollection(
    includedPaths: [sourceFile.path],
  );
  final outputs = <String, String>{};
  try {
    final result =
        await collection
                .contextFor(sourceFile.path)
                .currentSession
                .getResolvedUnit(sourceFile.path)
            as ResolvedUnitResult;
    final graph = ClassGraph.fromLibraryClasses(
      result.libraryElement.classes.toList(),
      library: result.libraryElement,
    );
    for (final element in result.libraryElement.classes) {
      final annotation = _zorphyChecker.firstAnnotationOf(element);
      if (annotation == null) continue;
      final reader = ConstantReader(annotation);
      final metadata = ClassAnalyzer.analyze(
        element,
        reader,
        graph.annotated,
        graph.classesInExplicitSubtypes,
      );
      final ownFields = element.children
          .whereType<FieldElement>()
          .where((f) => f.name != 'hashCode' && f.name != 'runtimeType')
          .map((f) => f.name ?? '')
          .toSet();
      final config = GenerationConfig.fromAnnotationOptions(
        AnnotationParser.parse(reader),
        outputExtension: '.zorphy.dart',
        factoryMethods: metadata.factoryMethods,
        ownFields: ownFields,
      );
      final name = (element.name ?? element.displayName).replaceAll(r'$', '');
      outputs[name] = Orchestrator.generate(
        element,
        reader,
        graph.annotated,
        config,
        graph.classesInExplicitSubtypes,
      );
    }
  } finally {
    await collection.dispose();
  }
  return outputs;
}

/// Analyzer diagnostics for the fixture library, so an emitted `resolvePath`
/// that does not compile fails here instead of at a consumer's `dart analyze`.
Future<List<String>> _diagnostics(String libraryPath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [Directory(libraryPath).parent.path],
  );
  final diagnostics = <String>[];
  try {
    final library =
        await collection
                .contextFor(libraryPath)
                .currentSession
                .getResolvedLibrary(libraryPath)
            as ResolvedLibraryResult;
    for (final unit in library.units) {
      for (final diagnostic in unit.diagnostics) {
        diagnostics.add(
          '${libraryPath.split('/').last}: '
          '${diagnostic.diagnosticCode.lowerCaseName} — '
          '${diagnostic.problemMessage.messageText(includeUrl: false)}',
        );
      }
    }
  } finally {
    await collection.dispose();
  }
  return diagnostics;
}

void main() {
  late Directory fixtureDir;
  late Map<String, String> outputs;

  setUpAll(() async {
    final base = Directory('test/.issue_186_tmp').absolute.path;
    Directory(base).createSync(recursive: true);
    fixtureDir = Directory(base).createTempSync('fixture_');
    outputs = await _generateHierarchy(fixtureDir);
  });

  tearDownAll(() {
    if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
    final tmp = Directory('test/.issue_186_tmp');
    if (tmp.existsSync() && tmp.listSync().isEmpty) tmp.deleteSync();
  });

  String outputFor(String className) {
    final output = outputs[className];
    expect(
      output,
      isNotNull,
      reason: 'no generated output for $className; got ${outputs.keys}',
    );
    return output!;
  }

  group('resolvePath — emitted contract', () {
    test('every class in the hierarchy declares the static entry point', () {
      for (final className in const [
        'UiNode',
        'InteractiveUiNode',
        'ZfaButtonNode',
        'ZfaTextNode',
      ]) {
        expect(
          outputFor(className),
          contains(
            'static ZorphyLens<$className, Object?>? resolvePath('
            'String pointer)',
          ),
          reason: '$className must expose the issue\'s exact signature',
        );
      }
    });

    test('shared interface pointers resolve on every subtype', () {
      // `/contractId` is declared on $UiNode, so every subtype's table must
      // answer it — that is what makes `UiNode.resolvePath('/contractId')`
      // work for a button and a text node alike.
      for (final className in const [
        'UiNode',
        'InteractiveUiNode',
        'ZfaButtonNode',
        'ZfaTextNode',
      ]) {
        expect(
          outputFor(className),
          contains("'/contractId' =>"),
          reason: '$className must resolve the shared `/contractId` pointer',
        );
      }
    });

    test(
      'subtype-specific pointers resolve only where they are applicable',
      () {
        // A button carries `label`, and `/enabled` belongs to the interactive
        // branch; a text node carries `text` and nothing interactive.
        expect(outputFor('ZfaButtonNode'), contains("'/label' =>"));
        expect(outputFor('ZfaButtonNode'), contains("'/enabled' =>"));
        expect(outputFor('ZfaTextNode'), contains("'/text' =>"));
        expect(
          outputFor('ZfaTextNode'),
          isNot(contains("'/enabled' =>")),
          reason: 'a text node is not interactive — it must not advertise it',
        );
        expect(outputFor('ZfaTextNode'), isNot(contains("'/label' =>")));
      },
    );

    test('runtime dispatch answers null on an inapplicable subtype', () {
      // The switch must dispatch on the RUNTIME subtype, not assume the
      // receiver is the class that declared the segment: resolving
      // `/enabled` through the `UiNode` table on a text node answers null
      // rather than throwing.
      expect(
        outputFor('UiNode'),
        contains("'/enabled' =>"),
        reason: 'the root table dispatches interactive segments too',
      );
      expect(
        outputFor('UiNode'),
        matches(RegExp(r"'/enabled' => [\s\S]{0,600}?default:\s*return null;")),
        reason: 'the interactive branch must fall through to null',
      );
    });

    test('unknown pointers answer null instead of throwing', () {
      for (final className in const ['UiNode', 'ZfaTextNode']) {
        expect(
          outputFor(className),
          contains('_ => null,'),
          reason: '$className must answer null for an unmatched pointer',
        );
      }
    });
  });

  group('resolvePath — zero-reflection and zero-regex', () {
    test('no dart:mirrors, no RegExp in any emitted table', () {
      for (final entry in outputs.entries) {
        expect(
          entry.value,
          isNot(contains('dart:mirrors')),
          reason: '${entry.key} emitted reflection',
        );
        expect(
          entry.value,
          isNot(contains('RegExp')),
          reason: '${entry.key} emitted a regex',
        );
      }
    });

    test('nested segments delegate to the nested type', () {
      // The issue's O(depth) contract: `editDraft/price` resolves
      // `editDraft` here and hands `/price` to `EditDraft`'s own table via
      // `then`, so each level pays one switch step.
      final nested = outputFor('ProductUiState');
      expect(
        nested,
        contains('.then('),
        reason: 'a nested segment must delegate through the child lens',
      );
      expect(
        nested,
        contains('EditDraft.resolvePath('),
        reason: 'the remainder must be handed to the nested type',
      );
    });
  });

  group('resolvePath — the emitted parts analyze clean', () {
    test('no analyzer diagnostics for the generated hierarchy', () async {
      // The real builder emits ONE shared part per library, so the fixture's
      // `part 'ui_node.zorphy.dart'` must receive every class's output
      // concatenated — writing a file per class would leave the directive
      // dangling and prove nothing about the emitted `resolvePath`.
      // The real builder prefixes its shared part with these two lint
      // headers (`_withLintHeader` in shared_part_builder.dart): generated
      // `value as String` casts are unavoidable in this API shape and are
      // suppressed fleet-wide, so the fixture carries the same headers or the
      // gate would fail on a diagnostic no real consumer ever sees.
      final diagnostics = await _analyzeFixture(fixtureDir, 'ui_node', outputs);
      expect(diagnostics, isEmpty, reason: diagnostics.join('\n'));
    });

    // The shapes below are the ones a non-sealed, non-generic fixture cannot
    // reach. Each asserts on ALL diagnostics, never a filtered subset: the
    // #159 gate filters by diagnostic code, which is exactly how a
    // `non_exhaustive_switch_statement` used to sail through it.
    for (final entry in {
      'a sealed root with explicit subtypes': (
        'sealed',
        _sealedSource,
        ['Root', 'LeafA', 'LeafB'],
      ),
      'a generic annotated class': ('generic', _genericSource, ['Box']),
      'subtype-only and resolverless nested types': (
        'nested',
        _nestedSource,
        ['UiNode', 'EditNode', 'TextNode', 'Draft', 'Frozen', 'Holder'],
      ),
    }.entries) {
      test('${entry.key} emits parts that analyze clean', () async {
        final (libraryName, source, classes) = entry.value;
        final dir = Directory('${fixtureDir.path}/${libraryName}_fixture')
          ..createSync(recursive: true);
        final generated = await _generate(dir, libraryName, source);
        expect(
          generated.keys,
          containsAll(classes),
          reason: 'every class of the fixture must generate',
        );
        final diagnostics = await _analyzeFixture(dir, libraryName, generated);
        expect(diagnostics, isEmpty, reason: diagnostics.join('\n'));
      });
    }
  });

  group('resolvePath — shapes the flat fixture cannot reach', () {
    late Map<String, String> sealed;
    late Map<String, String> generic;
    late Map<String, String> nested;

    setUpAll(() async {
      sealed = await _generate(
        Directory('${fixtureDir.path}/sealed_shape')
          ..createSync(recursive: true),
        'sealed',
        _sealedSource,
      );
      generic = await _generate(
        Directory('${fixtureDir.path}/generic_shape')
          ..createSync(recursive: true),
        'generic',
        _genericSource,
      );
      nested = await _generate(
        Directory('${fixtureDir.path}/nested_shape')
          ..createSync(recursive: true),
        'nested',
        _nestedSource,
      );
    });

    test('a sealed root still resolves its OWN fields', () {
      // `$$Root` never generates `copyWith`, so `/id` used to be dropped from
      // the table and `Root.resolvePath('/id')` answered null for a pointer
      // every Root demonstrably carries. The write dispatches to the concrete
      // subtypes that DID generate a writer.
      final root = sealed['Root']!;
      expect(root, contains("'/id' =>"));
      expect(
        root,
        matches(RegExp(r"'/id' => [\s\S]{0,400}?case LeafA _node:")),
      );
      expect(
        root,
        matches(RegExp(r"'/id' => [\s\S]{0,400}?case LeafB _node:")),
      );
    });

    test('a subtype-only field keeps its fallback and never drops an arm', () {
      // `onlyOnA` covers one of two subtypes, so the `default:` that answers
      // null (read) / the receiver (write) must stay — dropping it was four
      // `non_exhaustive_switch_statement` errors.
      final root = sealed['Root']!;
      expect(
        root,
        matches(RegExp(r"'/onlyOnA' => [\s\S]{0,400}?default:\s*return null;")),
      );
      expect(
        root,
        matches(RegExp(r"'/onlyOnA' => [\s\S]{0,600}?default:\s*return root;")),
      );
      // The shared field is covered by both leaves, so its switch must NOT
      // carry a dead default (`unreachable_switch_default`).
      expect(root, isNot(matches(RegExp(r"'/id' => [\s\S]{0,400}?default:"))));
    });

    test('a generic class emits no resolver at all', () {
      // A static member cannot reference the class's type parameters
      // (`type_parameter_referenced_by_static`), so emitting one is a compile
      // error for every consumer of a generic model.
      expect(generic['Box'], isNot(contains('resolvePath')));
    });

    test('a subtype-only nested field casts with the concrete type', () {
      // The raw analyzer type is `$Draft`, which is an interface, not a value
      // type: `copyWith(draft: value as $Draft)` does not compile.
      final node = nested['UiNode']!;
      expect(node, contains('as Draft'));
      expect(node, isNot(contains('as \$Draft')));
      expect(node, isNot(contains('ZorphyLens<UiNode, \$Draft>')));
    });

    test('a nested type without a resolver is not called statically', () {
      // `Frozen` generates no `copyWith`, so its own `resolvePath` was
      // declined — a `Frozen.resolvePath(remainder)` here would reference a
      // member that does not exist.
      final holder = nested['Holder']!;
      expect(holder, isNot(contains('Frozen.resolvePath')));
      expect(holder, contains("'/frozen' =>"));
    });
  });

  // The post-fix review round on #206. Each finding is pinned by the EXACT
  // emission its fix produces, so a regression fails here instead of at a
  // consumer's `dart analyze`.
  group('resolvePath — post-fix review findings', () {
    late Map<String, String> nullable;
    late Map<String, String> genericSubtype;
    late Map<String, String> siblingNested;
    late Map<String, String> taggedList;

    setUpAll(() async {
      nullable = await _generate(
        Directory('${fixtureDir.path}/nullable_shape')
          ..createSync(recursive: true),
        'nullable',
        _nullableSource,
      );
      genericSubtype = await _generate(
        Directory('${fixtureDir.path}/generic_subtype_shape')
          ..createSync(recursive: true),
        'generic_subtype',
        _genericSubtypeSource,
      );
      siblingNested = await _generate(
        Directory('${fixtureDir.path}/sibling_nested_shape')
          ..createSync(recursive: true),
        'sibling_nested',
        _siblingNestedSource,
      );
      taggedList = await _generate(
        Directory('${fixtureDir.path}/composite_list_shape')
          ..createSync(recursive: true),
        'composite_list',
        _compositeListSource,
      );
    });

    test('a nullable field writes an explicit null through the Patch', () {
      // `copyWith` is `note: note ?? this.note`, which can never clear the
      // field; the generated Patch gates on `containsKey`, so it can.
      final note = nullable['Note']!;
      expect(
        note,
        matches(
          RegExp(
            r'if \(value == null\) \{\s*return root\.patchWithNote\('
            r'NotePatch\(\)\.\.withNote\(null\)\);',
          ),
        ),
        reason: 'an explicit null must reach the null-capable writer',
      );
      // The ordinary write is still present for every non-null value, and it
      // casts with the PROMOTED type — null is already gone above.
      expect(
        _resolvePathBody(note),
        contains('return root.copyWith(note: value as String);'),
      );
    });

    test('a composite list field casts element-wise, never hard', () {
      // A raw `jsonDecode` payload arrives as `List<dynamic>`, so a hard
      // `value as List<Map<…>>` throws a TypeError (issue #148). The checked
      // conversion is the repo's sanctioned shape, and with a null branch
      // above it must use the NON-nullable form — a nullable `is` test on an
      // `Object?` parameter does not promote, so the then-branch would stay
      // `Object?` and fail to compile.
      // Scoped to `resolvePath`: the class also carries the pre-existing
      // `copyWithField`, whose nullable conversion legitimately stays
      // null-aware and would mask the setter's own shape.
      final tagged = _resolvePathBody(taggedList['TaggedResult']!);
      expect(tagged, isNot(contains('value as List<Map')));
      expect(
        tagged,
        matches(RegExp(r'value is List<Map<String, String>>\s*\? value')),
        reason: 'the fast path must carry the promoted (non-null) type',
      );
      expect(
        tagged,
        contains('Map<String, String>.from'),
        reason: 'entries are converted element-wise, not cast',
      );
    });

    test('a generic subtype contributes no type-parameter arm', () {
      // A static member cannot name `T`, so `_node.copyWith(value: value as T)`
      // was `cast_to_non_type`. The segment is not advertised for that subtype;
      // the shared field still resolves.
      final root = genericSubtype['Root']!;
      expect(root, isNot(contains('as T')));
      expect(root, isNot(contains("'/value' =>")));
      expect(root, contains("'/id' =>"));
    });

    test('siblings typing one segment differently dispatch on the subtype', () {
      // `PlainNode.payload` is a `String` and `DraftNode.payload` is a `$Draft`,
      // so the delegation target is only knowable from the runtime subtype.
      final node = siblingNested['Node']!;
      expect(node, contains('Draft.resolvePath(remainder)'));
      expect(
        node,
        matches(
          RegExp(r'case DraftNode _node:\s*final nested = Draft\.resolvePath'),
        ),
        reason: 'only the Draft-bearing sibling may delegate',
      );
      expect(
        node,
        isNot(matches(RegExp(r'case PlainNode _node:\s*final nested = '))),
        reason: 'the String-bearing sibling must not delegate',
      );
    });

    test('a covariant redeclaration on a sealed root no longer throws', () async {
      // `$Child.payload` narrows `$DraftA` to `$DraftB`, so the visible `payload`
      // field on the sealed root records TWO nested targets. `_fieldTypeName`'s
      // `.single` threw `Bad state: Too many elements` and failed the whole
      // build; generation now completes and the target is resolved per-declarer.
      final dir = Directory('${fixtureDir.path}/covariant_nested_shape')
        ..createSync(recursive: true);
      final covariant = await _generate(
        dir,
        'covariant_nested',
        _covariantNestedSource,
      );
      expect(
        covariant.keys,
        containsAll(<String>['Node', 'Child', 'DraftA', 'DraftB']),
        reason: 'every class of the covariant hierarchy must generate',
      );
      // The root still resolves its own nested segment rather than dropping it.
      expect(covariant['Node'], contains("'/payload' =>"));
      final diagnostics = await _analyzeFixture(
        dir,
        'covariant_nested',
        covariant,
      );
      expect(
        diagnostics,
        isEmpty,
        reason:
            'the covariant hierarchy must analyze clean:\n'
            '${diagnostics.join('\n')}',
      );
    });

    test('every post-fix fixture emits parts that analyze clean', () async {
      for (final entry in {
        'nullable': ('nullable', _nullableSource, nullable),
        'generic subtype': (
          'generic_subtype',
          _genericSubtypeSource,
          genericSubtype,
        ),
        'sibling nested': (
          'sibling_nested',
          _siblingNestedSource,
          siblingNested,
        ),
        'composite list': ('composite_list', _compositeListSource, taggedList),
      }.entries) {
        final (libraryName, source, outputs) = entry.value;
        final dir = Directory('${fixtureDir.path}/${libraryName}_verify')
          ..createSync(recursive: true);
        await _generate(dir, libraryName, source);
        final diagnostics = await _analyzeFixture(dir, libraryName, outputs);
        expect(diagnostics, isEmpty, reason: diagnostics.join('\n'));
      }
    });
  });
}

/// The `resolvePath` method body of one generated class, so an assertion can
/// name the pointer table without matching the class's other members (the
/// pre-existing `copyWithField` legitimately keeps a null-aware conversion).
///
/// The body is taken from the method's first line to the LAST closing brace
/// before the class ends — a nested `}` at two-space indent appears inside the
/// closures, so the first one is not the boundary.
String _resolvePathBody(String classOutput) {
  final start = classOutput.indexOf('resolvePath(String pointer)');
  if (start < 0) return '';
  return classOutput.substring(start);
}

/// Writes [outputs] into [libraryName]'s shared part and returns every
/// analyzer diagnostic for that library.
Future<List<String>> _analyzeFixture(
  Directory dir,
  String libraryName,
  Map<String, String> outputs,
) async {
  final part = StringBuffer()
    ..writeln('// ignore_for_file: UNNECESSARY_CAST')
    ..writeln('// ignore_for_file: type=lint')
    ..writeln("part of '$libraryName.dart';");
  for (final output in outputs.values) {
    part.writeln(output);
  }
  File('${dir.path}/$libraryName.zorphy.dart')
      .writeAsStringSync(part.toString());
  return _diagnostics('${dir.path}/$libraryName.dart');
}
