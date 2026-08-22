// Test for issue #114: agent annotations.
//
// Verifies that @AgentTool, @AgentRisk, @AgentInternal, @AgentExclude
// produce an AgentDirective const in generated output.

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import "package:zorphy_annotation/zorphy_annotation.dart" hide Field;
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/agent_directive_generator.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/generation_config.dart';
import 'package:zorphy/src/models/agent_directive_info.dart';

class _StubClassElement implements ClassElement {
  @override
  final String name;
  _StubClassElement(this.name);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ClassMetadata _concreteMeta({
  required String name,
  List<NameTypeClassComment> fields = const [],
  AgentDirectiveInfo agentDirectiveInfo = const AgentDirectiveInfo(),
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
    agentDirectiveInfo: agentDirectiveInfo,
  );
}

GenerationConfig _bareConfig() {
  return const GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.entity,
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

String _emitSpecs(List<Spec> specs) {
  final lib = Library((b) {
    for (final spec in specs) {
      if (spec is Field) b.body.add(spec);
    }
  });
  return lib.accept(DartEmitter()).toString();
}

void main() {
  group('Issue #114 agent annotations', () {
    test('no directive when no agent annotations', () {
      final meta = _concreteMeta(name: 'User');
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = AgentDirectiveGenerator().generateSpec(context);
      expect(specs, isEmpty);
    });

    test('shouldGenerate returns false when no agent annotations', () {
      final meta = _concreteMeta(name: 'User');
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      expect(AgentDirectiveGenerator().shouldGenerate(context), isFalse);
    });

    test('emits AgentDirective with risk tier', () {
      final meta = _concreteMeta(
        name: 'DeleteAccount',
        agentDirectiveInfo: const AgentDirectiveInfo(
          risk: 'confirm',
          hasAgentAnnotations: true,
        ),
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = AgentDirectiveGenerator().generateSpec(context);
      expect(specs, hasLength(1));
      final code = _emitSpecs(specs);
      expect(code, contains('agentDirective'));
      expect(code, contains('AgentRiskTier.confirm'));
    });

    test('emits AgentDirective with admin risk', () {
      final meta = _concreteMeta(
        name: 'SystemConfig',
        agentDirectiveInfo: const AgentDirectiveInfo(
          risk: 'admin',
          internal: true,
          hasAgentAnnotations: true,
        ),
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = AgentDirectiveGenerator().generateSpec(context);
      final code = _emitSpecs(specs);
      expect(code, contains('AgentRiskTier.admin'));
      expect(code, contains('internal: true'));
    });

    test('emits AgentDirective with tool override', () {
      final meta = _concreteMeta(
        name: 'CreateUser',
        agentDirectiveInfo: const AgentDirectiveInfo(
          toolName: 'create_user',
          toolNamespace: 'users',
          toolDescription: 'Create a new user',
          hasAgentAnnotations: true,
        ),
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = AgentDirectiveGenerator().generateSpec(context);
      final code = _emitSpecs(specs);
      expect(code, contains("name: 'create_user'"));
      expect(code, contains("namespace: 'users'"));
      expect(code, contains("description: 'Create a new user'"));
      expect(code, contains('AgentToolDirective'));
    });

    test('emits AgentDirective with exclude', () {
      final meta = _concreteMeta(
        name: 'InternalHelper',
        agentDirectiveInfo: const AgentDirectiveInfo(
          exclude: true,
          hasAgentAnnotations: true,
        ),
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = AgentDirectiveGenerator().generateSpec(context);
      final code = _emitSpecs(specs);
      expect(code, contains('exclude: true'));
    });

    test('emits AgentDirective with param descriptions', () {
      final meta = _concreteMeta(
        name: 'SearchQuery',
        agentDirectiveInfo: const AgentDirectiveInfo(
          paramDescriptions: {'query': 'The search query string', 'limit': 'Max results to return'},
          hasAgentAnnotations: true,
        ),
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = AgentDirectiveGenerator().generateSpec(context);
      final code = _emitSpecs(specs);
      expect(code, contains('AgentParamDirective'));
      expect(code, contains("'query'"));
      expect(code, contains("'limit'"));
    });

    test('safe risk tier is omitted from output (default)', () {
      final meta = _concreteMeta(
        name: 'Simple',
        agentDirectiveInfo: const AgentDirectiveInfo(
          hasAgentAnnotations: true,
        ),
      );
      final context = GenerationContext(metadata: meta, config: _bareConfig());
      final specs = AgentDirectiveGenerator().generateSpec(context);
      final code = _emitSpecs(specs);
      expect(code, contains('agentDirective'));
      expect(code, isNot(contains('risk:')));
    });
  });
}
