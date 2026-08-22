import 'package:analyzer/dart/element/element.dart';
import 'package:code_builder/code_builder.dart';
import 'package:test/test.dart';
import 'package:zorphy/src/ast/spec_mapper.dart';
import 'package:zorphy/src/common/NameType.dart';
import 'package:zorphy/src/models/class_metadata.dart';
import 'package:zorphy/src/models/agent_directive_info.dart';
import 'package:zorphy/src/models/interface_metadata.dart';

// ────────────────────────────────────────────────────────────────────
// Minimal ClassElement stub for unit testing
// ────────────────────────────────────────────────────────────────────

class _StubClassElement implements ClassElement {
  @override
  final String name;

  _StubClassElement(this.name);

  // No-op implementations for the rest of the ClassElement interface.
  // Only [name] is used by the mapper (for nothing — it's just stored).
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

// ────────────────────────────────────────────────────────────────────
// Helpers
// ────────────────────────────────────────────────────────────────────

/// Creates a minimal [ClassMetadata] for testing the mapper.
/// Only the fields relevant to spec mapping are populated.
ClassMetadata _testMeta({
  required String originalName,
  required bool isAbstract,
  required bool isSealed,
  bool nonSealed = false,
  String docComment = '',
  List<GenericParameterMetadata> generics = const [],
  List<InterfaceMetadata> interfaces = const [],
}) {
  final cleanName = originalName.replaceAll(r'$', '');
  return ClassMetadata(
    originalName: originalName,
    cleanName: cleanName,
    isAbstract: isAbstract,
    isSealed: isSealed,
    nonSealed: nonSealed,
    hasConstConstructor: false,
    docComment: docComment,
    generics: generics,
    interfaces: interfaces,
    allValueTInterfaces: const [],
    allFields: const [],
    ownFieldNames: const {},
    factoryMethods: const [],
    explicitSubtypes: const [],
    isInParentExplicitSubtypes: false,
    classElement: _StubClassElement(cleanName),
    agentDirectiveInfo: const AgentDirectiveInfo(),
      allAnnotatedClasses: const {},
  );
}

/// Creates a minimal [InterfaceMetadata] for testing.
/// Uses a stub [ClassElement].
InterfaceMetadata _testInterface({
  required String name,
  List<NameType> typeParams = const [],
  List<NameType> fields = const [],
}) {
  return InterfaceMetadata(
    name,
    typeParams.map((tp) => tp.type).toList(),
    typeParams.map((tp) => tp.name).toList(),
    fields,
    element: _StubClassElement(name),
  );
}

/// Convenience: emits a [Class] spec to a Dart source string for assertion.
String _emitClass(Class spec) {
  final lib = Library((b) => b.body.add(spec));
  final raw = lib.accept(DartEmitter(useNullSafetySyntax: true)).toString();
  return raw;
}

// ────────────────────────────────────────────────────────────────────
// Tests
// ────────────────────────────────────────────────────────────────────

void main() {
  // ── mapGenericParameter ──────────────────────────────────────────
  group('mapGenericParameter', () {
    test('unbounded type parameter', () {
      final tp = mapGenericParameter(
        const GenericParameterMetadata(name: 'T'),
      );
      expect(tp.symbol, 'T');
      expect(tp.bound, isNull);
    });

    test('bounded type parameter', () {
      final tp = mapGenericParameter(
        const GenericParameterMetadata(name: 'T', bound: 'num'),
      );
      expect(tp.symbol, 'T');
      expect(tp.bound, isNotNull);
      // The bound is a TypeReference; check its symbol.
      final boundStr = tp.bound!.accept(DartEmitter()).toString();
      expect(boundStr, 'num');
    });

    test('bounded type parameter with generic bound', () {
      final tp = mapGenericParameter(
        const GenericParameterMetadata(name: 'K', bound: 'Comparable<K>'),
      );
      expect(tp.symbol, 'K');
      final boundStr = tp.bound!.accept(DartEmitter()).toString();
      expect(boundStr, 'Comparable<K>');
    });
  });

  // ── mapField ──────────────────────────────────────────────────────
  group('mapField', () {
    test('simple field with type', () {
      final field = mapField(
        NameTypeClassComment('name', 'String', 'User'),
      );
      expect(field.name, 'name');
      // Type should be 'String'.
      final typeStr = field.type!.accept(DartEmitter()).toString();
      expect(typeStr, 'String');
      // Should be final by default.
      expect(field.modifier, FieldModifier.final$);
    });

    test('getter-only field is var, not final', () {
      final field = mapField(
        NameTypeClassComment('items', 'List<int>', 'Box', isGetterOnly: true),
      );
      expect(field.modifier, FieldModifier.var$);
    });

    test('nullable field type preserved', () {
      final field = mapField(
        NameTypeClassComment('value', 'int?', 'Item'),
      );
      final typeStr = field.type!.accept(DartEmitter(useNullSafetySyntax: true)).toString();
      expect(typeStr, 'int?');
    });

    test('generic field type preserved', () {
      final field = mapField(
        NameTypeClassComment('data', 'Map<String, dynamic>', 'Record'),
      );
      // Raw emitter output is structurally correct; spacing is a formatter concern.
      final typeStr = field.type!.accept(DartEmitter(useNullSafetySyntax: true)).toString();
      expect(typeStr, contains('Map<String,'));
      expect(typeStr, contains(',dynamic>'));
    });

    test('field with doc comment', () {
      final field = mapField(
        NameTypeClassComment('id', 'String', 'User', comment: 'The unique ID'),
      );
      expect(field.docs, contains('The unique ID'));
    });

    test('field with JsonKey annotation', () {
      const jsonKey = JsonKeyInfo(name: 'user_name');
      final field = mapField(
        NameTypeClassComment('name', 'String', 'User', jsonKeyInfo: jsonKey),
      );
      // Should have one annotation.
      expect(field.annotations.length, 1);
    });

    test('field without type defaults to dynamic', () {
      final field = mapField(
        NameTypeClassComment('anything', null, 'Thing'),
      );
      final typeStr = field.type!.accept(DartEmitter()).toString();
      expect(typeStr, 'dynamic');
    });
  });

  // ── mapInterfaceToTypeReference ────────────────────────────────────
  group('mapInterfaceToTypeReference', () {
    test('simple interface without type params', () {
      final iface = _testInterface(name: 'Serializable');
      final ref = mapInterfaceToTypeReference(iface);
      final str = ref.accept(DartEmitter()).toString();
      expect(str, 'Serializable');
    });

    test('interface with type params', () {
      final iface = _testInterface(
        name: 'Comparable',
        typeParams: [NameType('T', '')],
      );
      final ref = mapInterfaceToTypeReference(iface);
      final str = ref.accept(DartEmitter()).toString();
      expect(str, 'Comparable<T>');
    });
  });

  // ── mapClass ──────────────────────────────────────────────────────
  group('mapClass', () {
    test('abstract class shape (\$\$Shape → abstract class Shape)', () {
      final meta = _testMeta(
        originalName: r'$$Shape',
        isAbstract: true,
        isSealed: false,
      );
      final cls = mapClass(meta);
      expect(cls.name, 'Shape');
      expect(cls.abstract, true);
      expect(cls.sealed, false);

      final emitted = _emitClass(cls);
      expect(emitted, contains('abstract class Shape'));
    });

    test('sealed class shape (\$\$Shape with !nonSealed → sealed class Shape)', () {
      final meta = _testMeta(
        originalName: r'$$Shape',
        isAbstract: true,
        isSealed: true,
      );
      final cls = mapClass(meta);
      expect(cls.name, 'Shape');
      expect(cls.sealed, true);
      // In code_builder, sealed classes are NOT marked abstract separately.
      // The 'sealed' keyword implies abstract.

      final emitted = _emitClass(cls);
      expect(emitted, contains('sealed class Shape'));
    });

    test('concrete class shape (\$User → class User)', () {
      final meta = _testMeta(
        originalName: r'$User',
        isAbstract: false,
        isSealed: false,
      );
      final cls = mapClass(meta);
      expect(cls.name, 'User');
      expect(cls.abstract, false);
      expect(cls.sealed, false);

      final emitted = _emitClass(cls);
      expect(emitted, contains('class User'));
      expect(emitted, isNot(contains('abstract')));
      expect(emitted, isNot(contains('sealed')));
    });

    test('generic class shape (\$Box<T> → class Box<T>)', () {
      final meta = _testMeta(
        originalName: r'$Box',
        isAbstract: false,
        isSealed: false,
        generics: const [
          GenericParameterMetadata(name: 'T'),
        ],
      );
      final cls = mapClass(meta);
      expect(cls.name, 'Box');
      expect(cls.types.length, 1);
      expect(cls.types[0].symbol, 'T');

      final emitted = _emitClass(cls);
      expect(emitted, contains('class Box<T>'));
    });

    test('generic class with bounded type param (Map type param preservation)', () {
      final meta = _testMeta(
        originalName: r'$SortedMap',
        isAbstract: false,
        isSealed: false,
        generics: const [
          GenericParameterMetadata(name: 'K', bound: 'Comparable<K>'),
          GenericParameterMetadata(name: 'V'),
        ],
      );
      final cls = mapClass(meta);
      expect(cls.types.length, 2);
      expect(cls.types[0].symbol, 'K');
      expect(cls.types[1].symbol, 'V');

      final emitted = _emitClass(cls);
      // Raw emitter omits spaces after commas in type param lists.
      expect(emitted, contains('class SortedMap<K extends Comparable<K>,'));
      expect(emitted, contains(',V>'));
    });

    test('class with implements clause', () {
      final meta = _testMeta(
        originalName: r'$User',
        isAbstract: false,
        isSealed: false,
        interfaces: [
          _testInterface(name: 'Serializable'),
          _testInterface(name: 'Comparable', typeParams: [NameType('User', '')]),
        ],
      );
      final cls = mapClass(meta);
      expect(cls.implements.length, 2);

      final emitted = _emitClass(cls);
      expect(emitted, contains('implements Serializable'));
      expect(emitted, contains('Comparable<User>'));
    });

    test('class with doc comment', () {
      final meta = _testMeta(
        originalName: r'$User',
        isAbstract: false,
        isSealed: false,
        docComment: 'A user in the system.',
      );
      final cls = mapClass(meta);
      expect(cls.docs, contains('A user in the system.'));
    });
  });
}
