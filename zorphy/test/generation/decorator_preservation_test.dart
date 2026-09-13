// Feature #135: preserve custom decorators on generated entities.
//
// Unit tests (stub analyzer elements, following the repo's
// spec_pipeline_constructor_this_prefix_test.dart pattern) for:
//
//  - helpers.extractClassDecorators: capture of class-level decorator
//    source text, directive filtering (@Zorphy/@Zorphy2/@JsonSerializable),
//    order preservation, robustness against unreadable metadata.
//  - ClassDeclarationGenerator: porting of captured decorators onto the
//    generated abstract ($Task) and concrete (Task) class specs, ahead of
//    the generator-added @JsonSerializable on the concrete class.
//
// End-to-end coverage over the real build_runner pipeline lives in
// decorator_preservation_e2e_test.dart.

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/common/helpers.dart' as common_helpers;
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/class_declaration_generator.dart';
import 'package:zorphy/src/models/agent_directive_info.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/generation_config.dart';

// ────────────────────────────────────────────────────────────────────
// Analyzer stubs
// ────────────────────────────────────────────────────────────────────

/// Minimal fake [Element] carrying only a name (e.g. the annotation
/// class `Cacheable` behind a `@Cacheable(...)` annotation).
class _FakeAnnotationElement implements Element {
  @override
  final String? name;

  _FakeAnnotationElement(this.name);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Minimal fake [ElementAnnotation] with a canned `toSource()` (what the
/// real analyzer produces from the user's source text) and an optional
/// resolved [element].
class _FakeAnnotation implements ElementAnnotation {
  final String _source;
  final Element? _element;

  _FakeAnnotation(this._source, {Element? element}) : _element = element;

  @override
  String toSource() => _source;

  @override
  Element? get element => _element;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// [ClassElement] stub; returns [metadataValue] for the `metadata`
/// getter so the dual-API shim in helpers is exercised, and `null`
/// (via noSuchMethod) for everything else — same robustness contract
/// as the repo's other stubs.
class _StubClassElement implements ClassElement {
  @override
  final String name;

  final Object? metadataValue;

  _StubClassElement(this.name, {this.metadataValue});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter && invocation.memberName == #metadata) {
      return metadataValue;
    }
    return null;
  }
}

// ────────────────────────────────────────────────────────────────────
// Metadata / config builders
// ────────────────────────────────────────────────────────────────────

ClassMetadata _meta({
  required String name,
  required bool isAbstract,
  List<String> classDecorators = const [],
  List<NameTypeClassComment> fields = const [],
}) {
  return ClassMetadata(
    originalName: name,
    cleanName: name,
    isAbstract: isAbstract,
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
    agentDirectiveInfo: const AgentDirectiveInfo(),
    namedConstructors: const [],
    allAnnotatedClasses: const {},
    classDecorators: classDecorators,
  );
}

GenerationConfig _config({bool generateJson = false}) {
  return GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.entity,
    autoId: false,
    generateJson: generateJson,
    explicitToJson: true,
    generateCopyWith: false,
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

String _emitClass(Class spec) {
  final lib = Library((b) => b.body.add(spec));
  return lib.accept(DartEmitter(useNullSafetySyntax: true)).toString();
}

// ────────────────────────────────────────────────────────────────────
// Tests
// ────────────────────────────────────────────────────────────────────

void main() {
  group('#135 extractClassDecorators — capture', () {
    test('returns empty for null element', () {
      expect(common_helpers.extractClassDecorators(null), isEmpty);
    });

    test('returns empty when metadata is unreadable (stub, null)', () {
      final element = _StubClassElement('Task');
      expect(common_helpers.extractClassDecorators(element), isEmpty);
    });

    test(
      'captures custom decorator with @ stripped and arguments verbatim',
      () {
        final element = _StubClassElement(
          'Task',
          metadataValue: [
            _FakeAnnotation(
              '@Cacheable(ttl: Duration(hours: 1))',
              element: _FakeAnnotationElement('Cacheable'),
            ),
          ],
        );
        expect(common_helpers.extractClassDecorators(element), [
          'Cacheable(ttl: Duration(hours: 1))',
        ]);
      },
    );

    test('captures parameterless decorator without synthesising parens', () {
      final element = _StubClassElement(
        'Task',
        metadataValue: [
          _FakeAnnotation(
            '@Audited',
            element: _FakeAnnotationElement('Audited'),
          ),
        ],
      );
      expect(common_helpers.extractClassDecorators(element), ['Audited']);
    });

    test('preserves multiple decorators in source order', () {
      final element = _StubClassElement(
        'Task',
        metadataValue: [
          _FakeAnnotation(
            '@Cacheable(ttl: Duration(hours: 1))',
            element: _FakeAnnotationElement('Cacheable'),
          ),
          _FakeAnnotation(
            '@Immutable()',
            element: _FakeAnnotationElement('Immutable'),
          ),
          _FakeAnnotation('@Audited', element: _FakeAnnotationElement('Audited')),
        ],
      );
      expect(common_helpers.extractClassDecorators(element), [
        'Cacheable(ttl: Duration(hours: 1))',
        'Immutable()',
        'Audited',
      ]);
    });

    test('keeps import prefix intact', () {
      final element = _StubClassElement(
        'Task',
        metadataValue: [
          _FakeAnnotation(
            "@dep.Tagged('x')",
            element: _FakeAnnotationElement('Tagged'),
          ),
        ],
      );
      expect(common_helpers.extractClassDecorators(element), [
        "dep.Tagged('x')",
      ]);
    });

    test('handles Metadata-object style metadata (new analyzer API)', () {
      // Some analyzer versions expose element.metadata as a Metadata
      // object with .annotations instead of a List. The dual-API shim
      // must handle both.
      final element = _StubClassElement(
        'Task',
        metadataValue: _FakeMetadataObject([
          _FakeAnnotation(
            '@Cacheable(ttl: Duration(hours: 1))',
            element: _FakeAnnotationElement('Cacheable'),
          ),
        ]),
      );
      expect(common_helpers.extractClassDecorators(element), [
        'Cacheable(ttl: Duration(hours: 1))',
      ]);
    });
  });

  group('#135 extractClassDecorators — directive filter', () {
    test('filters Zorphy, Zorphy2 and JsonSerializable directives', () {
      final element = _StubClassElement(
        'Task',
        metadataValue: [
          _FakeAnnotation(
            '@Zorphy(generateJson: true)',
            element: _FakeAnnotationElement('Zorphy'),
          ),
          _FakeAnnotation(
            '@Cacheable(ttl: Duration(hours: 1))',
            element: _FakeAnnotationElement('Cacheable'),
          ),
          _FakeAnnotation(
            '@JsonSerializable(explicitToJson: true)',
            element: _FakeAnnotationElement('JsonSerializable'),
          ),
          _FakeAnnotation(
            '@Zorphy2()',
            element: _FakeAnnotationElement('Zorphy2'),
          ),
        ],
      );
      expect(common_helpers.extractClassDecorators(element), [
        'Cacheable(ttl: Duration(hours: 1))',
      ]);
    });

    test('filters directives by source fallback when element is null', () {
      final element = _StubClassElement(
        'Task',
        metadataValue: [
          const _SourceOnlyAnnotation('@Zorphy(generateJson: true)'),
          const _SourceOnlyAnnotation('@Immutable()'),
        ],
      );
      expect(common_helpers.extractClassDecorators(element), ['Immutable()']);
    });

    test('returns empty for directive-only raw class', () {
      final element = _StubClassElement(
        'Task',
        metadataValue: [
          _FakeAnnotation(
            '@Zorphy(generateJson: true)',
            element: _FakeAnnotationElement('Zorphy'),
          ),
        ],
      );
      expect(common_helpers.extractClassDecorators(element), isEmpty);
    });

    test('filters directives addressed through named constructors', () {
      // @Zorphy.named() resolves to a ConstructorElement named 'named'
      // whose ENCLOSING element is Zorphy — the filter must look at the
      // enclosing class name too.
      final element = _StubClassElement(
        'Task',
        metadataValue: [
          _FakeAnnotation(
            '@Zorphy.named()',
            element: _FakeNamedConstructorElement('named', 'Zorphy'),
          ),
          _FakeAnnotation(
            '@Audited',
            element: _FakeAnnotationElement('Audited'),
          ),
        ],
      );
      expect(common_helpers.extractClassDecorators(element), ['Audited']);
    });
  });

  group('#135 ClassDeclarationGenerator — abstract class porting', () {
    final generator = ClassDeclarationGenerator();

    test(r'generated $Task carries the ported decorator', () {
      final meta = _meta(
        name: 'Task',
        isAbstract: true,
        classDecorators: ['Cacheable(ttl: Duration(hours: 1))'],
        fields: [
          NameTypeClassComment('id', 'String', 'Task'),
          NameTypeClassComment('title', 'String', 'Task'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config(generateJson: false)),
      );
      final emitted = _emitClass(specs.first as Class);

      expect(emitted, contains('@Cacheable(ttl: Duration(hours: 1))'));
      expect(emitted, contains(r'class $Task'));
    });

    test('decorators appear in source order above the class declaration', () {
      final meta = _meta(
        name: 'Task',
        isAbstract: true,
        classDecorators: ['Cacheable(ttl: Duration(hours: 1))', 'Immutable()'],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config(generateJson: false)),
      );
      final emitted = _emitClass(specs.first as Class);

      expect(emitted, contains('@Cacheable(ttl: Duration(hours: 1))'));
      expect(emitted, contains('@Immutable()'));
      expect(
        emitted.indexOf('@Cacheable'),
        lessThan(emitted.indexOf('@Immutable()')),
      );
    });

    test('empty classDecorators emits no annotations (no-op contract)', () {
      final meta = _meta(
        name: 'Task',
        isAbstract: true,
        fields: [NameTypeClassComment('id', 'String', 'Task')],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config(generateJson: false)),
      );
      final emitted = _emitClass(specs.first as Class);

      expect(emitted, isNot(contains('@')));
    });

    test(r'sealed-base $$Task shape: decorators port to sealed Task', () {
      // Production shape: a raw `$$Task` base produces a generated
      // sealed class named `Task` (cleanName). Decorators from the raw
      // base must port there.
      final meta = ClassMetadata(
        originalName: r'$$Task',
        cleanName: 'Task',
        isAbstract: true,
        isSealed: true,
        nonSealed: false,
        hasConstConstructor: false,
        docComment: '',
        generics: const [],
        interfaces: const [],
        allValueTInterfaces: const [],
        allFields: const [NameTypeClassComment('id', 'String', 'Task')],
        ownFieldNames: const {'id'},
        factoryMethods: const [],
        explicitSubtypes: const [],
        isInParentExplicitSubtypes: false,
        classElement: _StubClassElement(r'$$Task'),
        agentDirectiveInfo: const AgentDirectiveInfo(),
        namedConstructors: const [],
        allAnnotatedClasses: const {},
        classDecorators: ['Audited()'],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config(generateJson: false)),
      );
      final emitted = _emitClass(specs.first as Class);

      expect(emitted, contains('@Audited()'));
      expect(emitted, contains('sealed class Task'));
    });
  });

  group('#135 ClassDeclarationGenerator — concrete class porting', () {
    final generator = ClassDeclarationGenerator();

    test('generated concrete Task carries the ported decorator', () {
      final meta = _meta(
        name: 'Task',
        isAbstract: false,
        classDecorators: ['Cacheable(ttl: Duration(hours: 1))'],
        fields: [
          NameTypeClassComment('id', 'String', 'Task'),
          NameTypeClassComment('title', 'String', 'Task'),
        ],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config(generateJson: true)),
      );
      final emitted = _emitClass(specs.first as Class);

      expect(emitted, contains('@Cacheable(ttl: Duration(hours: 1))'));
      expect(emitted, contains('@JsonSerializable('));
    });

    test('ported decorator precedes generator-added JsonSerializable', () {
      final meta = _meta(
        name: 'Task',
        isAbstract: false,
        classDecorators: ['Cacheable(ttl: Duration(hours: 1))'],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config(generateJson: true)),
      );
      final emitted = _emitClass(specs.first as Class);

      expect(
        emitted.indexOf('@Cacheable'),
        lessThan(emitted.indexOf('@JsonSerializable')),
      );
    });

    test(
      'argument fidelity: mixed positional + named and const expressions',
      () {
        final meta = _meta(
          name: 'Task',
          isAbstract: false,
          classDecorators: [
            'Throttle(30, per: Duration(seconds: 5))',
            "Endpoint(const ['a', 'b'], name: 'x')",
          ],
        );
        final specs = generator.generateSpec(
          GenerationContext(
            metadata: meta,
            config: _config(generateJson: true),
          ),
        );
        final emitted = _emitClass(specs.first as Class);

        expect(emitted, contains('@Throttle(30, per: Duration(seconds: 5))'));
        expect(emitted, contains("@Endpoint(const ['a', 'b'], name: 'x')"));
      },
    );

    test('parameterless decorator emitted without synthesised parens', () {
      final meta = _meta(
        name: 'Task',
        isAbstract: false,
        classDecorators: ['Audited'],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config(generateJson: false)),
      );
      final emitted = _emitClass(specs.first as Class);

      expect(emitted, contains('@Audited'));
      expect(emitted, isNot(contains('@Audited()')));
    });

    test('no directives and no decorators on decorator-free class', () {
      final meta = _meta(
        name: 'Task',
        isAbstract: false,
        fields: [NameTypeClassComment('id', 'String', 'Task')],
      );
      final specs = generator.generateSpec(
        GenerationContext(metadata: meta, config: _config(generateJson: false)),
      );
      final emitted = _emitClass(specs.first as Class);

      expect(emitted, isNot(contains('@')));
    });
  });
}

// ────────────────────────────────────────────────────────────────────
// Additional fakes
// ────────────────────────────────────────────────────────────────────

/// Stand-in for the new analyzer `Metadata` object style
/// (`element.metadata.annotations` instead of a bare List).
class _FakeMetadataObject {
  final List<ElementAnnotation> annotations;
  _FakeMetadataObject(this.annotations);
}

/// Annotation with no resolvable element — the helper must fall back to
/// the source text for its name (directive filtering still applies).
class _SourceOnlyAnnotation implements ElementAnnotation {
  final String _source;
  const _SourceOnlyAnnotation(this._source);

  @override
  String toSource() => _source;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Fake constructor element (name + enclosing class) for annotations
/// like `@Zorphy.named()`.
class _FakeNamedConstructorElement implements Element {
  @override
  final String? name;
  final String enclosingName;

  _FakeNamedConstructorElement(this.name, this.enclosingName);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #enclosingElement) {
      return _FakeAnnotationElement(enclosingName);
    }
    return null;
  }
}
