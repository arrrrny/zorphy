import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/emission/emitter.dart';
import 'package:zorphy/src/factory_method.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/agent_directive_info.dart';
import 'package:zorphy/src/models/generation_config.dart';
import 'package:zorphy/src/models/interface_metadata.dart';
import 'package:zorphy/zorphy_plugin.dart';

/// A test double plugin that adds a `_telemetry` field.
class _TelemetryPlugin extends ZorphyPlugin {
  @override
  String get name => 'telemetry';

  @override
  Spec transformClass(Spec spec, PluginContext context) {
    if (spec is! Class) return spec;
    return Class((c) {
      c.name = spec.name;
      c.abstract = spec.abstract;
      c.sealed = spec.sealed;
      c.extend = spec.extend;
      c.types.addAll(spec.types);
      c.implements.addAll(spec.implements);
      c.mixins.addAll(spec.mixins);
      c.annotations.addAll(spec.annotations);
      c.docs.addAll(spec.docs);
      c.fields.addAll(spec.fields);
      c.methods.addAll(spec.methods);
      c.constructors.addAll(spec.constructors);
      // Add the telemetry field.
      c.fields.add(
        Field((f) {
          f.name = r'_$telemetry';
          f.type = refer('Map<String, dynamic>');
          f.modifier = FieldModifier.final$;
        }),
      );
    });
  }

  @override
  Spec transformField(Spec spec, PluginContext context) => spec;
}

void main() {
  group('Plugin pipeline', () {
    test('plugin adds field and import to emitted code', () {
      final classSpec = Class((c) {
        c.name = 'User';
        c.fields.add(
          Field((f) {
            f.name = 'name';
            f.type = refer('String');
          }),
        );
      });

      final registry = PluginRegistry();
      registry.register(_TelemetryPlugin());

      final context = _TestPluginContext();

      // Run plugin transform.
      final ordered = registry.ordered();
      Spec result = classSpec;
      for (final plugin in ordered) {
        result = plugin.transformClass(result, context);
      }

      // Verify the plugin added the field.
      expect(result, isA<Class>());
      final cls = result as Class; // ignore: unnecessary_cast
      expect(cls.fields.any((f) => f.name == r'_$telemetry'), isTrue);

      // Verify the plugin context accumulated the import.
      context.addImport('package:telemetry/telemetry.dart');
      expect(context.imports.length, 1);
      expect(
        context.imports.first.toString(),
        contains('package:telemetry/telemetry.dart'),
      );

      // Emit the class with the import in a Library and verify.
      final library = Library((b) {
        for (final imp in context.imports) {
          b.directives.add(imp);
        }
        b.body.add(cls);
      });

      final emitter = ZorphyEmitter();
      final code = emitter.emit(library);

      expect(code, contains(r'_$telemetry'));
      expect(code, contains("import 'package:telemetry/telemetry.dart'"));
    });

    test('empty registry produces no changes', () {
      final registry = PluginRegistry();
      expect(registry.isEmpty, isTrue);
      expect(registry.ordered(), isEmpty);
    });

    test('plugin context accumulates diagnostics', () {
      final context = _TestPluginContext();
      context.diagnostic('test message');
      context.diagnostic('warning', level: PluginDiagnosticLevel.warning);
      expect(context.diagnostics.length, 2);
      expect(context.diagnostics[0].level, PluginDiagnosticLevel.info);
      expect(context.diagnostics[1].level, PluginDiagnosticLevel.warning);
    });
  });
}

/// Minimal test-only context with faked metadata.
class _TestPluginContext extends PluginContext {
  _TestPluginContext()
      : super(
          metadata: _FakeClassMetadata(),
          config: _FakeConfig(),
        );
}

class _FakeClassMetadata extends ClassMetadata {
  _FakeClassMetadata()
      : super(
          originalName: '\$User',
          cleanName: 'User',
          isAbstract: false,
          isSealed: false,
          nonSealed: false,
          hasConstConstructor: false,
          docComment: '',
          generics: <GenericParameterMetadata>[],
          interfaces: <InterfaceMetadata>[],
          allValueTInterfaces: <Interface>[],
          allFields: <NameTypeClassComment>[],
          ownFieldNames: <String>{},
          factoryMethods: <FactoryMethodInfo>[],
          explicitSubtypes: <Interface>[],
          isInParentExplicitSubtypes: false,
          classElement: _FakeClassElement(),
          agentDirectiveInfo: const AgentDirectiveInfo(),
          namedConstructors: const [],
      allAnnotatedClasses: <String, ClassElement>{},
        );
}

class _FakeConfig extends GenerationConfig {
  _FakeConfig() : super.test();
}

/// Minimal ClassElement fake that satisfies the interface.
class _FakeClassElement implements ClassElement {
  const _FakeClassElement();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
