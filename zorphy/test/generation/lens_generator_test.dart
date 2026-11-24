// Issue #185 — the generated lens surface.
//
// Every generated Zorphy class exposes a `<Name>Lenses` accessor class with
// one `ZorphyLens<Root, Field>` per field, and registers it on itself as
// `static const <Name>Lenses lenses`. This file pins that contract twice:
//
//  1. the emitted SOURCE (so a rename or a dropped registry fails loudly), and
//  2. the analyzer's own verdict on the emitted part (a `set` that does not
//     compile — e.g. one routed through a copyWith parameter that does not
//     exist — must not reach users).
//
// The pipeline is driven end-to-end (resolved ClassElement -> ClassAnalyzer ->
// Orchestrator.generate), same as the analyze-clean release gate, so this is
// the real generator and not a hand-built spec.

import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/analysis/annotation_parser.dart';
import 'package:zorphy/src/analysis/class_analyzer.dart';
import 'package:zorphy/src/analysis/class_graph.dart';
import 'package:zorphy/src/ast/ast.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/lens_generator.dart';
import 'package:zorphy/src/models/agent_directive_info.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/generation_config.dart';
import 'package:zorphy/src/orchestrator.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart' hide Field;

const _zorphyChecker = TypeChecker.fromUrl(
  'package:zorphy_annotation/src/annotations.dart#Zorphy',
);

/// A two-level state tree — the shape the issue names
/// (`ProductUiState.lenses.editDraft.then(...)`).
const _fixture = '''
import 'package:zorphy_annotation/zorphy_annotation.dart';

part 'lens_fixture.zorphy.dart';

@Zorphy()
abstract class \$EditDraft {
  String get title;
  double get price;
  String? get note;
}

@Zorphy()
abstract class \$ProductUiState {
  EditDraft get editDraft;
  int get selectedTab;
}
''';

class _StubClassElement implements ClassElement {
  @override
  final String name;

  _StubClassElement(this.name);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ClassMetadata _concreteMeta({
  required String name,
  required List<NameTypeClassComment> fields,
  List<GenericParameterMetadata> generics = const [],
}) {
  return ClassMetadata(
    originalName: name,
    cleanName: name,
    isAbstract: false,
    isSealed: false,
    nonSealed: false,
    hasConstConstructor: false,
    docComment: '',
    generics: generics,
    interfaces: const [],
    allValueTInterfaces: const [],
    allFields: fields,
    ownFieldNames: fields.map((f) => f.name).toSet(),
    factoryMethods: const [],
    explicitSubtypes: const [],
    isInParentExplicitSubtypes: false,
    classElement: _StubClassElement(name),
    agentDirectiveInfo: const AgentDirectiveInfo(),
    namedConstructors: const [],
    allAnnotatedClasses: const {},
  );
}

GenerationConfig _config({
  bool generateCopyWith = true,
  bool generatePatch = false,
}) {
  return GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.entity,
    autoId: false,
    generateJson: false,
    explicitToJson: true,
    generateCopyWith: generateCopyWith,
    generateCopyWithFn: false,
    generateCompareTo: false,
    generatePatch: generatePatch,
    hidePublicConstructor: false,
    generateFilter: false,
    generatePropertyHelpers: false,
    generateEqualsToString: false,
    generateChangeTo: false,
    nonSealed: false,
    factoryMethods: const [],
    ownFields: const {},
  );
}

String _emitSpecs(List<Spec> specs) {
  final library = Library((b) {
    Class? primary;
    final memberFields = <Field>[];
    final others = <Spec>[];
    for (final spec in specs) {
      if (spec is Class && primary == null) {
        primary = spec;
      } else if (spec is ClassMemberCode) {
        if (spec.field != null) memberFields.add(spec.field!);
      } else {
        others.add(spec);
      }
    }
    if (primary != null) {
      final base = primary;
      b.body.add(
        Class((c) {
          c.name = base.name;
          c.abstract = base.abstract;
          c.modifier = base.modifier;
          c.types.addAll(base.types);
          c.docs.addAll(base.docs);
          c.fields.addAll(base.fields);
          c.fields.addAll(memberFields);
          c.methods.addAll(base.methods);
          c.constructors.addAll(base.constructors);
        }),
      );
    }
    for (final spec in others) {
      b.body.add(spec);
    }
  });
  // Emit through the real pipeline so assertions see formatted output,
  // exactly what a consumer's generated part contains.
  return ZorphyEmitter().emit(library);
}

/// Generates every `@Zorphy` class of the library at [libraryPath].
Future<Map<String, String>> _generateLibrary(String libraryPath) async {
  final collection = AnalysisContextCollection(
    includedPaths: [Directory(libraryPath).parent.path],
  );
  final outputs = <String, String>{};
  try {
    final result =
        await collection
                .contextFor(libraryPath)
                .currentSession
                .getResolvedUnit(libraryPath)
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

Future<List<String>> _diagnostics(List<String> libraryPaths) async {
  final collection = AnalysisContextCollection(
    includedPaths: [Directory(libraryPaths.first).parent.path],
  );
  final diagnostics = <String>[];
  try {
    for (final path in libraryPaths) {
      final library =
          await collection
                  .contextFor(path)
                  .currentSession
                  .getResolvedLibrary(path)
              as ResolvedLibraryResult;
      for (final unit in library.units) {
        for (final diagnostic in unit.diagnostics) {
          diagnostics.add(
            '${path.split('/').last}: '
            '${diagnostic.diagnosticCode.lowerCaseName} — '
            '${diagnostic.problemMessage.messageText(includeUrl: false)}',
          );
        }
      }
    }
  } finally {
    await collection.dispose();
  }
  return diagnostics;
}

void main() {
  group('LensGenerator — spec level', () {
    final generator = LensGenerator();

    test('emits a <Name>Lenses accessor class and the static registry', () {
      final meta = _concreteMeta(
        name: 'Draft',
        fields: [
          NameTypeClassComment('title', 'String', 'Draft'),
          NameTypeClassComment('price', 'double', 'Draft'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config()),
      );

      final lensesClass = specs.whereType<Class>().single;
      expect(lensesClass.name, 'DraftLenses');
      expect(lensesClass.modifier, ClassModifier.final$);

      // The registry rides the class body, not the library scope.
      final memberCode = specs.whereType<ClassMemberCode>().toList();
      expect(
        memberCode,
        hasLength(1),
        reason: 'the registry must be injected into the generated class',
      );
      final emitted = _emitSpecs(specs);
      expect(emitted, contains('const DraftLenses lenses = DraftLenses()'));
      expect(emitted, contains('ZorphyLens<Draft, String> get title'));
      expect(emitted, contains("path: '/title'"));
    });

    test('a nullable field yields a nullable lens value type', () {
      final meta = _concreteMeta(
        name: 'Draft',
        fields: [NameTypeClassComment('note', 'String?', 'Draft')],
      );
      final emitted = _emitSpecs(
        generator.generateSpec(
          GenerationContext(metadata: meta, config: _config()),
        ),
      );
      expect(emitted, contains('ZorphyLens<Draft, String?> get note'));
    });

    // Finding A (zuraffa/coderabbit, lens_generator.dart:154) — a nullable
    // field's `set(root, null)` must actually clear it. `copyWith` is
    // `note: note ?? this.note`, so only a Patch-routed write can express an
    // explicit null. Pinned at the emission level, exactly as the json-pointer
    // twin (#206) is, because the value is the generated source itself.
    test('a nullable field routes set(null) through the Patch', () {
      final meta = _concreteMeta(
        name: 'Draft',
        fields: [
          NameTypeClassComment('title', 'String', 'Draft'),
          NameTypeClassComment('note', 'String?', 'Draft'),
        ],
      );
      final emitted = _emitSpecs(
        generator.generateSpec(
          GenerationContext(
            metadata: meta,
            config: _config(generatePatch: true),
          ),
        ),
      );
      expect(
        emitted,
        matches(
          RegExp(
            r'if \(value == null\) \{\s*'
            r'return root\.patchWithDraft\(DraftPatch\(\)\.\.withNote\(null\)\);',
          ),
        ),
        reason: 'an explicit null must reach the null-capable Patch writer',
      );
      // The ordinary non-null write survives for the nullable field (inside the
      // block body), and a non-nullable field keeps its plain copyWith write.
      expect(emitted, contains('return root.copyWith(note: value);'));
      expect(emitted, contains('root.copyWith(title: value)'));
    });

    test('without generatePatch a nullable field keeps the plain copyWith '
        'write', () {
      // No Patch exists, so there is no null-capable writer — the branch must
      // not be emitted against a method that does not exist.
      final meta = _concreteMeta(
        name: 'Draft',
        fields: [NameTypeClassComment('note', 'String?', 'Draft')],
      );
      final emitted = _emitSpecs(
        generator.generateSpec(
          GenerationContext(metadata: meta, config: _config()),
        ),
      );
      expect(emitted, isNot(contains('patchWithDraft')));
      expect(emitted, contains('root.copyWith(note: value)'));
    });

    // Finding B (zuraffa/coderabbit, lens_generator.dart:52/58) — a model that
    // declares its own `lenses` member cannot carry the static `lenses`
    // registry (conflicting_static_and_instance), so the registry moves to a
    // free name and the field's own lens is preserved.
    test('a `lenses` field moves the static registry to a free name', () {
      final meta = _concreteMeta(
        name: 'Bag',
        fields: [
          NameTypeClassComment('lenses', 'String', 'Bag'),
          NameTypeClassComment('color', 'String', 'Bag'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config()),
      );
      expect(
        specs.whereType<ClassMemberCode>(),
        hasLength(1),
        reason: 'the registry is renamed, not dropped',
      );
      final emitted = _emitSpecs(specs);
      expect(
        emitted,
        isNot(contains('static const BagLenses lenses =')),
        reason: 'a static `lenses` would clash with the instance field',
      );
      expect(
        emitted,
        contains('static const BagLenses lensesView = BagLenses()'),
      );
      // The model's own `lenses` field still gets its lens.
      expect(emitted, contains('ZorphyLens<Bag, String> get lenses'));
    });

    // Finding C (coderabbit, lens_generator.dart:104) — two fields that differ
    // only in their first letter (`title` / `Title`) map to the same `_getTitle`
    // / `_setTitle` helper, emitting duplicate methods that do not compile.
    // The helpers are allocated uniquely; the public getters are unchanged.
    test('fields differing only by first letter get unique helpers', () {
      final meta = _concreteMeta(
        name: 'Odd',
        fields: [
          NameTypeClassComment('title', 'String', 'Odd'),
          NameTypeClassComment('Title', 'String', 'Odd'),
        ],
      );
      final emitted = _emitSpecs(
        generator.generateSpec(
          GenerationContext(metadata: meta, config: _config()),
        ),
      );
      // Both public getters are present and keep the field's own name.
      expect(emitted, contains('ZorphyLens<Odd, String> get title'));
      expect(emitted, contains('ZorphyLens<Odd, String> get Title'));
      // The first field keeps `_getTitle` / `_setTitle`; the second is
      // deduplicated to a `_`-prefixed variant — never a second `_getTitle`.
      expect(emitted, contains('String _getTitle('));
      expect(emitted, contains('String __getTitle('));
      expect(emitted, contains('Odd _setTitle('));
      expect(emitted, contains('Odd __setTitle('));
    });

    test('getter-only fields are skipped — copyWith cannot write them', () {
      final meta = _concreteMeta(
        name: 'Draft',
        fields: [
          NameTypeClassComment('title', 'String', 'Draft'),
          NameTypeClassComment(
            'computed',
            'String',
            'Draft',
            isGetterOnly: true,
          ),
        ],
      );
      final emitted = _emitSpecs(
        generator.generateSpec(
          GenerationContext(metadata: meta, config: _config()),
        ),
      );
      expect(emitted, contains('get title'));
      expect(emitted, isNot(contains('get computed')));
    });

    test('generic classes emit no lens surface — a static const cannot be '
        'generic', () {
      final meta = _concreteMeta(
        name: 'Box',
        fields: [NameTypeClassComment('value', 'T', 'Box')],
        generics: const [GenericParameterMetadata(name: 'T')],
      );
      expect(
        generator.generateSpec(
          GenerationContext(metadata: meta, config: _config()),
        ),
        isEmpty,
      );
      expect(
        generator.shouldGenerate(
          GenerationContext(metadata: meta, config: _config()),
        ),
        isFalse,
      );
    });

    test('abstract classes emit no lens surface — they cannot be '
        'instantiated, so no copyWith exists to write through', () {
      final meta = _concreteMeta(
        name: 'Shape',
        fields: [NameTypeClassComment('area', 'double', 'Shape')],
      );
      final abstractMeta = ClassMetadata(
        originalName: r'$$Shape',
        cleanName: 'Shape',
        isAbstract: true,
        isSealed: true,
        nonSealed: false,
        hasConstConstructor: false,
        docComment: '',
        generics: const [],
        interfaces: const [],
        allValueTInterfaces: const [],
        allFields: meta.allFields,
        ownFieldNames: meta.ownFieldNames,
        factoryMethods: const [],
        explicitSubtypes: const [],
        isInParentExplicitSubtypes: false,
        classElement: _StubClassElement('Shape'),
        agentDirectiveInfo: const AgentDirectiveInfo(),
        namedConstructors: const [],
        allAnnotatedClasses: const {},
      );
      expect(
        generator.generateSpec(
          GenerationContext(metadata: abstractMeta, config: _config()),
        ),
        isEmpty,
      );
    });

    test('no copyWith means no lens surface — set has nothing to write '
        'through', () {
      final meta = _concreteMeta(
        name: 'Draft',
        fields: [NameTypeClassComment('title', 'String', 'Draft')],
      );
      expect(
        generator.generateSpec(
          GenerationContext(
            metadata: meta,
            config: _config(generateCopyWith: false),
          ),
        ),
        isEmpty,
      );
    });
  });

  group('generated lens surface — end to end', () {
    late Directory fixtureDir;
    late Map<String, String> generated;

    setUpAll(() async {
      final root = Directory('test/.lens_tmp').absolute
        ..createSync(recursive: true);
      fixtureDir = root.createTempSync('fixture_');

      final path = '${fixtureDir.path}/lens_fixture.dart';
      File(path).writeAsStringSync(_fixture);
      generated = await _generateLibrary(path);
      expect(
        generated.keys,
        containsAll(<String>['EditDraft', 'ProductUiState']),
        reason: 'fixture classes must both generate',
      );
      File('${fixtureDir.path}/lens_fixture.zorphy.dart').writeAsStringSync(
        "part of 'lens_fixture.dart';\n\n"
        '${generated.values.join('\n\n')}',
      );
    });

    tearDownAll(() {
      if (fixtureDir.existsSync()) fixtureDir.deleteSync(recursive: true);
    });

    test('each class exposes its own registry', () {
      expect(
        generated['EditDraft'],
        contains('static const EditDraftLenses lenses = EditDraftLenses()'),
      );
      expect(
        generated['ProductUiState'],
        contains(
          'static const ProductUiStateLenses lenses = ProductUiStateLenses()',
        ),
      );
    });

    test('each field gets a lens typed against the generated root class', () {
      final state = generated['ProductUiState']!;
      expect(
        state,
        contains('ZorphyLens<ProductUiState, EditDraft> get editDraft'),
      );
      expect(
        state,
        contains('ZorphyLens<ProductUiState, int> get selectedTab'),
      );
      expect(state, contains("path: '/editDraft'"));
      expect(state, contains("path: '/selectedTab'"));
    });

    test(
      'the composed lens chain the issue names resolves at compile time',
      () async {
        final probe = File('${fixtureDir.path}/probe.dart')
          ..writeAsStringSync('''
import 'lens_fixture.dart';

void main() {
  final state = ProductUiState(
    editDraft: EditDraft(title: 'widget', price: 10.0),
    selectedTab: 2,
  );

  final price = ProductUiState.lenses.editDraft.then(EditDraft.lenses.price);

  // Path concatenation, read-through and write-through in one chain.
  assert(price.path == '/editDraft/price');
  assert(price.get(state) == 10.0);
  final updated = price.set(state, 4.5);
  assert(updated.editDraft.price == 4.5);
  assert(updated.editDraft.title == 'widget');
  assert(updated.selectedTab == 2);

  // Lens laws on the real generated surface.
  assert(price.get(price.set(state, 7.25)) == 7.25);
  assert(price.set(state, price.get(state)) == state);
  print('lens probe ok');
}
''');

        final diagnostics = await _diagnostics([
          '${fixtureDir.path}/lens_fixture.dart',
          probe.path,
        ]);
        expect(
          diagnostics,
          isEmpty,
          reason:
              'The generated lens surface (and a caller composing it) must '
              'analyze clean:\n${diagnostics.join('\n')}',
        );
      },
    );
  });
}
