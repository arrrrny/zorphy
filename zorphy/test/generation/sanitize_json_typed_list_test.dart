// Regression test for zik_zak#1074 / zorphy issue:
// "_sanitizeJson throws 'List<dynamic>' is not a subtype of
//  'List<Map<String, dynamic>>' on a typed nested list slot"
//
// The generated `_sanitizeJson` list branch used to return
// `json.map((e) => _sanitizeJson(e)).toList()` — a `List<dynamic>`. When the
// enclosing map is a typed map whose value type is `List<Map<String, dynamic>>`
// (e.g. a `Map<String, List<CleaningOptions>>` field), assigning that
// `List<dynamic>` back via `json[key] = ...` throws at runtime.
//
// The fix sanitizes the list IN PLACE and returns the same (typed) list, so
// the value type is preserved. This test asserts the emitted `_sanitizeJson`
// body sanitizes in place and never builds a fresh `List<dynamic>` via
// `.map(...).toList()`.

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';

import 'package:zorphy_annotation/zorphy_annotation.dart';
import 'package:zorphy/src/ast/class_member_code.dart';
import 'package:zorphy/src/generators/base_generator.dart';
import 'package:zorphy/src/generators/json_generator.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/agent_directive_info.dart';
import 'package:zorphy/src/models/generation_config.dart';

class _StubClassElement implements ClassElement {
  @override
  final String name;
  _StubClassElement(this.name);
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ClassMetadata _meta({required String name}) {
  return ClassMetadata(
    originalName: name,
    cleanName: name,
    isAbstract: false,
    isSealed: false,
    nonSealed: true,
    hasConstConstructor: false,
    docComment: '',
    generics: const [],
    interfaces: const [],
    allValueTInterfaces: const [],
    allFields: const [],
    ownFieldNames: const {},
    factoryMethods: const [],
    explicitSubtypes: const [],
    isInParentExplicitSubtypes: false,
    classElement: _StubClassElement(name),
    agentDirectiveInfo: const AgentDirectiveInfo(),
    allAnnotatedClasses: const {},
  );
}

GenerationConfig _jsonConfig() {
  return const GenerationConfig(
    outputExtension: '.zorphy.dart',
    preset: ZorphyPreset.standard,
    kind: ZorphyKind.entity,
    autoId: false,
    generateJson: true,
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
    nonSealed: true,
    factoryMethods: [],
    ownFields: {},
  );
}

/// Emits the generated specs into a single source string.
String _emitSpecs(List<Spec> specs) {
  final constructors = <Constructor>[];
  final methods = <Method>[];
  for (final spec in specs) {
    if (spec is ClassMemberCode) {
      if (spec.constructor != null) constructors.add(spec.constructor!);
      if (spec.method != null) methods.add(spec.method!);
    } else if (spec is Method) {
      methods.add(spec);
    }
  }
  final cls = Class(
    (b) => b
      ..name = 'Synthetic'
      ..constructors.addAll(constructors)
      ..methods.addAll(methods),
  );
  final lib = Library((b) => b.body.add(cls));
  return lib.accept(DartEmitter(useNullSafetySyntax: true)).toString();
}

void main() {
  final generator = JsonGenerator();

  group('_sanitizeJson list branch preserves the typed list', () {
    late String emitted;
    setUp(() {
      final specs = generator.generateSpec(
        GenerationContext(
          metadata: _meta(name: 'VariationsParserOptions'),
          config: _jsonConfig(),
        ),
      );
      emitted = _emitSpecs(specs);
    });

    test('sanitizes list elements without assigning their slots', () {
      // The buggy branch returned `json.map((e) => _sanitizeJson(e)).toList()`.
      expect(
        emitted,
        isNot(contains('json.map((e) => _sanitizeJson(e)).toList()')),
      );
      // The fix walks the list by index and calls the sanitizer on each
      // element WITHOUT reassigning the slot, so an unmodifiable list (or a
      // typed List<Map<String, dynamic>>) survives sanitization. The emitted
      // source assertions are supplementary; the runtime behavior group below
      // executes the generated toJsonLean() to prove the typed list type is
      // preserved (CodeRabbit finding on PR #349).
      expect(emitted, contains('_sanitizeJson(json[i])'));
      expect(emitted, isNot(contains('json[i] = _sanitizeJson(json[i])')));
    });
  });

  group('behavior: generated toJsonLean() preserves the typed list', () {
    test('runtime checks pass in the example package context', () async {
      final runner = File('example/tool/sanitize_json_typed_list_behavior_check.dart');
      final fixture = File(
        'example/lib/various/sanitize_json_typed_list_example.zorphy.dart',
      );
      if (!fixture.existsSync()) {
        fail(
          'Fixture not generated. Run: cd example && '
          'dart run build_runner build',
        );
      }
      if (!runner.existsSync()) {
        fail(
          'Behavior runner missing: '
          'example/tool/sanitize_json_typed_list_behavior_check.dart',
        );
      }
      final result = await Process.run('dart', [
        'run',
        'tool/sanitize_json_typed_list_behavior_check.dart',
      ], workingDirectory: 'example');
      final stdoutText = result.stdout as String;
      expect(stdoutText, contains('ALL CHECKS PASSED'));
      expect(result.exitCode, 0, reason: stdoutText);
    }, timeout: const Timeout(Duration(minutes: 2)));
  });
}
