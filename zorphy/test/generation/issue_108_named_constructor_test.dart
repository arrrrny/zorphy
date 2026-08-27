// Test for issue #108: named constructors with custom bodies.

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/analysis/class_analyzer.dart';
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/class_declaration_generator.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/generation_config.dart';
import 'package:zorphy/src/models/named_constructor_info.dart';

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
  List<NamedConstructorInfo> namedConstructors = const [],
}) {
  return ClassMetadata(
    originalName: name,
    cleanName: name,
    isAbstract: false,
    isSealed: false,
    nonSealed: false,
    hasConstConstructor: false,
    docComment: '',
    generics: const [],
    interfaces: const [],
    allValueTInterfaces: const [],
    allFields: fields,
    ownFieldNames: fields.map((f) => f.name).toSet(),
    factoryMethods: const [],
    explicitSubtypes: const [],
    isInParentExplicitSubtypes: false,
    classElement: _StubClassElement(name),
    allAnnotatedClasses: const {},
    namedConstructors: namedConstructors,
  );
}

GenerationConfig _bareConfig() {
  return const GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.valueObject,
    autoId: false,
    generateJson: false,
    explicitToJson: true,
    generateCopyWith: true,
    generateCopyWithFn: false,
    generateCompareTo: false,
    generatePatch: false,
    hidePublicConstructor: false,
    generateFilter: false,
    generatePropertyHelpers: false,
    generateEqualsToString: false,
    generateChangeTo: false,
    nonSealed: false,
    factoryMethods: [],
    ownFields: {},
  );
}

String _emitClass(Class cls) {
  final lib = Library((b) => b.body.add(cls));
  return lib
      .accept(DartEmitter(allocator: Allocator.simplePrefixing()))
      .toString();
}

void main() {
  group('Issue #108 named constructors', () {
    test('generates a single named constructor with body', () {
      final meta = _concreteMeta(
        name: 'ContentWorld',
        fields: [NameTypeClassComment('name', 'String', 'ContentWorld')],
        namedConstructors: [
          const NamedConstructorInfo(
            name: 'world',
            body: r"assert(!name.startsWith('WINDOW-ID-'));",
          ),
        ],
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = ClassDeclarationGenerator().generateSpec(context);
      expect(specs, hasLength(1));
      expect(specs.first, isA<Class>());
      final code = _emitClass(specs.first as Class);
      // Default constructor uses 'this.name'
      expect(code, contains('ContentWorld({'));
      expect(code, contains('this.name'));
      // Named constructor with custom body
      expect(code, contains('ContentWorld.world('));
      expect(code, contains("assert(!name.startsWith('WINDOW-ID-'))"));
    });

    test('generates multiple named constructors', () {
      final meta = _concreteMeta(
        name: 'Port',
        fields: [NameTypeClassComment('port', 'int', 'Port')],
        namedConstructors: [
          const NamedConstructorInfo(name: 'http', body: 'assert(port == 80);'),
          const NamedConstructorInfo(
            name: 'https',
            body: 'assert(port == 443);',
          ),
        ],
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = ClassDeclarationGenerator().generateSpec(context);
      final code = _emitClass(specs.first as Class);
      expect(code, contains('Port.http('));
      expect(code, contains('assert(port == 80)'));
      expect(code, contains('Port.https('));
      expect(code, contains('assert(port == 443)'));
    });

    test('named constructor params match default constructor', () {
      final meta = _concreteMeta(
        name: 'Config',
        fields: [
          NameTypeClassComment('host', 'String', 'Config'),
          NameTypeClassComment('port', 'int', 'Config'),
        ],
        namedConstructors: [
          const NamedConstructorInfo(
            name: 'secure',
            body: 'assert(port == 443);',
          ),
        ],
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = ClassDeclarationGenerator().generateSpec(context);
      final code = _emitClass(specs.first as Class);
      expect(code, contains('Config.secure('));
      expect(code, contains('this.host'));
      expect(code, contains('this.port'));
    });

    test('no named constructors when list is empty', () {
      final meta = _concreteMeta(
        name: 'Simple',
        fields: [NameTypeClassComment('value', 'String', 'Simple')],
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = ClassDeclarationGenerator().generateSpec(context);
      final code = _emitClass(specs.first as Class);
      expect(code, contains('Simple({'));
      // No extra dot-names constructor (except Simple() itself)
      expect(code, isNot(contains('Simple.secure')));
    });

    test('factory named constructor emits a factory with plain params', () {
      final meta = _concreteMeta(
        name: 'ContentWorld',
        fields: [NameTypeClassComment('name', 'String', 'ContentWorld')],
        namedConstructors: [
          const NamedConstructorInfo(
            name: 'world',
            body: r'return ContentWorld(name: name);',
            factory: true,
          ),
        ],
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = ClassDeclarationGenerator().generateSpec(context);
      final code = _emitClass(specs.first as Class);
      // Factory keyword present; the factory ctor uses a plain `name` param
      // (no field formal `this.name`), and the body constructs the instance.
      expect(
        code,
        contains('factory ContentWorld.world({required String name})'),
      );
      expect(
        code,
        isNot(contains('ContentWorld.world({required String this.name})')),
      );
      expect(code, contains('return ContentWorld(name: name)'));
    });

    test('name validation rejects invalid / reserved / duplicate names', () {
      final seen = <String>{};
      // Valid name registers without throwing.
      ClassAnalyzer.validateNamedConstructorName(
        name: 'world',
        className: 'Content',
        seenNames: seen,
        classElement: _StubClassElement('Content'),
      );
      // Duplicate name is rejected.
      expect(
        () => ClassAnalyzer.validateNamedConstructorName(
          name: 'world',
          className: 'Content',
          seenNames: seen,
          classElement: _StubClassElement('Content'),
        ),
        throwsArgumentError,
      );
      // Non-identifier name is rejected.
      expect(
        () => ClassAnalyzer.validateNamedConstructorName(
          name: '1bad',
          className: 'Content',
          seenNames: <String>{},
          classElement: _StubClassElement('Content'),
        ),
        throwsArgumentError,
      );
      // Reserved generated constructor name is rejected.
      expect(
        () => ClassAnalyzer.validateNamedConstructorName(
          name: 'copyWith',
          className: 'Content',
          seenNames: <String>{},
          classElement: _StubClassElement('Content'),
        ),
        throwsArgumentError,
      );
      // Class-name shadowing is rejected.
      expect(
        () => ClassAnalyzer.validateNamedConstructorName(
          name: 'Content',
          className: 'Content',
          seenNames: <String>{},
          classElement: _StubClassElement('Content'),
        ),
        throwsArgumentError,
      );
    });
  });
}
