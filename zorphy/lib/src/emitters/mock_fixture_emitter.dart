/// Emits `<Name>MockData` trusted seed builders (ISSUE-015, #190).
///
/// A mock-first consumer seeds a `ZfaStore` backend, a golden fixture, or a
/// screenshot harness from generated data instead of hand-writing it. This
/// emitter produces that data as a `<Name>MockData` class per node, built
/// entirely from `package:code_builder` specs and formatted by
/// [ZorphyEmitter] — no preset, no `generate*` toggle, per the issue's §5 gate.
///
/// The emitted surface, straight from the issue's §2:
///
/// ```dart
/// class ProductMockData {
///   ProductMockData._();
///
///   static Product single({int seed = 0}) => Product.fromTrusted(
///     id: 'id-${seed}',
///     name: 'name@example.com',
///     price: 19.99,
///   );
///
///   static List<Product> list({int count = 10}) =>
///       List<Product>.generate(count, (index) => single(seed: index));
///
///   static ProductPatch samplePatch() {
///     var patch = ProductPatch();
///     patch = patch.withId('id-${0}');
///     patch = patch.withPrice(19.99);
///     return patch;
///   }
/// }
/// ```
///
/// and, for a polymorphic root with concrete leaves,
///
/// ```dart
/// class NotificationMockData {
///   NotificationMockData._();
///
///   static Notification single({int seed = 0}) => switch (seed % 2) {
///     0 => OrderNotificationMockData.single(seed: seed),
///     1 => PriceDropNotificationMockData.single(seed: seed),
///     _ => throw StateError('seed outside the rotation'),
///   };
///
///   static List<Notification> list({int count = 10}) =>
///       List<Notification>.generate(count, (index) => single(seed: index));
/// }
/// ```
///
/// ## Determinism
///
/// Every seed value is a pure function of `(seed, field name, field type)`, so
/// the same seed yields the same value on every run and every machine — the
/// property a golden fixture needs. Nothing reads a clock or `Random`, and the
/// per-field offset is derived from the field NAME rather than a hash code
/// (which is not stable across processes).
///
/// The polymorphic rotation is `seed % leaves.length`, so `list(count: n)`
/// walks every registered subtype in declaration order and each element's
/// principal key (`<field>-<seed>`) is unique — §5's heterogeneity and
/// uniqueness criteria both fall out of it.
///
/// ## `@ZorphyMock` field hints
///
/// A field annotated `@ZorphyMock(preset: ...)` seeds from the reserved preset
/// table ([ZorphyMockPresets]); `@ZorphyMock(example: ...)` seeds from that
/// literal verbatim. A hint wins over the type-derived default.
///
/// The producer reads the annotations off its own class elements and hands them
/// in through [emit]'s `mockSeeds`, because the IR deliberately carries no
/// annotation data. A preset name outside the reserved set is a
/// consumer-defined seed this emitter cannot know, so it falls through to the
/// type default rather than emitting a literal it would have to invent.
///
/// ## Output shape
///
/// The result is a PART-FILE BODY: class declarations with no `import`/`part`
/// directives, exactly like `IntentEmitter`'s output. The Owning library
/// supplies the imports the fragment names — at minimum the annotation library
/// for `@ZorphyMock`, and the entity's own library for the classes it
/// constructs and patches it builds.
library;

import 'package:code_builder/code_builder.dart';
import 'package:zorphy_annotation/zorphy_annotation.dart';

import '../ast/type_ref.dart';
import '../emission/emitter.dart';
import '../parser/polymorphic_ir.dart';

/// Emits `<Name>MockData` classes for the nodes of a resolved hierarchy.
final class MockFixtureEmitter {
  /// The shared spec-emission pipeline, so page width and the formatter are
  /// owned in ONE place ([ZorphyEmitter]).
  final ZorphyEmitter _emitter;

  /// Creates an emitter that formats through [ZorphyEmitter] at [pageWidth]
  /// (the shared `defaultPageWidth` by default).
  MockFixtureEmitter({int pageWidth = ZorphyEmitter.defaultPageWidth})
    : _emitter = ZorphyEmitter.withPageWidth(pageWidth);

  /// Emits one `<Name>MockData` class per node of [root]'s hierarchy — the
  /// root and every concrete leaf below it, in depth-first pre-order — so a
  /// root's rotation arms resolve against classes emitted by the same call.
  ///
  /// [mockSeeds] maps a FIELD name to its `@ZorphyMock` hint; the hint applies
  /// wherever that name is seeded in this hierarchy.
  String emit(
    ZorphyNodeIr root, {
    Map<String, ZorphyMock> mockSeeds = const {},
  }) {
    final specs = <Spec>[];
    void walk(ZorphyNodeIr node) {
      specs.add(_classSpec(node, mockSeeds));
      for (final child in node.directSubTypes) {
        walk(child);
      }
    }

    walk(root);
    return _emitter.emitSpecs(specs);
  }

  /// Emits the `<Name>MockData` class for [node] alone.
  ///
  /// A node with subtypes emits the rotation across them, so the caller must
  /// also emit those leaves for the arms to resolve — use [emit] for a whole
  /// hierarchy, or compose the per-node results into one library.
  String emitForNode(
    ZorphyNodeIr node, {
    Map<String, ZorphyMock> mockSeeds = const {},
  }) => _emitter.emitSpecs([_classSpec(node, mockSeeds)]);

  /// The `<Name>MockData` class of [node].
  Class _classSpec(ZorphyNodeIr node, Map<String, ZorphyMock> mockSeeds) {
    final leaves = leavesOf(node);
    final isDispatch = leaves.isNotEmpty && !node.isConcreteLeaf;
    final payload = payloadFields(node);

    return Class((c) {
      c.name = mockDataName(node);
      // A namespace of static builders: a private constructor keeps it
      // uninstantiable without an analyzer-visible `abstract` on a class that
      // only ever holds statics.
      c.constructors.add(Constructor((k) => k.name = '_'));

      c.methods.add(
        _single(
          node: node,
          payload: payload,
          leaves: leaves,
          isDispatch: isDispatch,
          mockSeeds: mockSeeds,
        ),
      );
      c.methods.add(_list(node));

      if (node.archetype == ArchetypeKind.entity) {
        c.methods.add(
          _samplePatch(
            node: node,
            payload: payload,
            leaves: leaves,
            isDispatch: isDispatch,
            mockSeeds: mockSeeds,
          ),
        );
      }
    });
  }

  /// `static Foo single({int seed = 0}) => …`
  ///
  /// A dispatch node rotates across its concrete leaves; anything else
  /// constructs itself through its own `fromTrusted`, seeded field by field.
  Method _single({
    required ZorphyNodeIr node,
    required List<ZorphyFieldIr> payload,
    required List<ZorphyNodeIr> leaves,
    required bool isDispatch,
    required Map<String, ZorphyMock> mockSeeds,
  }) {
    return Method((m) {
      m
        ..name = 'single'
        ..static = true
        ..returns = referType(node.cleanName)
        ..optionalParameters.add(_seedParameter());

      if (isDispatch) {
        final arms = [
          for (var index = 0; index < leaves.length; index++)
            '$index => ${mockDataName(leaves[index])}.single(seed: seed),',
        ];
        m.body = Code(
          'return switch (seed % ${leaves.length}) { ${arms.join(' ')} '
          "_ => throw StateError('seed outside the rotation'), };",
        );
        return;
      }

      if (payload.isEmpty) {
        // A fieldless node's generated `const` constructor takes no arguments.
        m.body = Code('return const ${node.cleanName}();');
        return;
      }

      final arguments = <String, Expression>{
        for (final field in payload)
          field.name: _seedValue(
            field: field,
            seedExpression: refer('seed'),
            hint: mockSeeds[field.name],
          ),
      };
      m.body = Block.of([
        referType(node.cleanName)
            .newInstanceNamed('fromTrusted', const [], arguments)
            .returned
            .statement,
      ]);
    });
  }

  /// `static List<Foo> list({int count = 10}) => List<Foo>.generate(…)`
  ///
  /// Every element is `single(seed: index)`, so a list is the same sequence of
  /// values on every run and every principal key in it is unique.
  Method _list(ZorphyNodeIr node) {
    return Method((m) {
      m
        ..name = 'list'
        ..static = true
        ..returns = referType('List<${node.cleanName}>')
        ..optionalParameters.add(
          Parameter((p) {
            p
              ..name = 'count'
              ..named = true
              ..type = referType('int')
              ..defaultTo = const Code('10');
          }),
        )
        ..body = Code(
          'return List<${node.cleanName}>.generate'
          '(count, (index) => single(seed: index));',
        );
    });
  }

  /// `static FooPatch samplePatch()` — one seeded change per field.
  ///
  /// The patch is built through the field's own fluent builder (ISSUE-007), so
  /// the sample is a real, applicable patch rather than a hand-assembled map. A
  /// field whose patch side carries something other than a raw value — a nested
  /// Zorphy reference carries a sub-patch — is skipped rather than emitted as a
  /// call that would not type-check.
  ///
  /// A dispatch node returns a LEAF's patch rather than its own: a sealed root
  /// patch is implicitly abstract, so the root's class cannot be instantiated
  /// directly. Its concrete subtype patches extend it, so the result is still
  /// typed `<Root>Patch` and applies to any leaf of the hierarchy.
  Method _samplePatch({
    required ZorphyNodeIr node,
    required List<ZorphyFieldIr> payload,
    required List<ZorphyNodeIr> leaves,
    required bool isDispatch,
    required Map<String, ZorphyMock> mockSeeds,
  }) {
    final patchName = '${node.cleanName}Patch';
    return Method((m) {
      m
        ..name = 'samplePatch'
        ..static = true
        ..returns = referType(patchName);

      if (isDispatch) {
        m.body = Code('return ${mockDataName(leaves.first)}.samplePatch();');
        return;
      }

      final statements = <Code>[Code('var patch = $patchName();')];
      for (final field in payload) {
        if (!hasFluentBuilder(field)) continue;
        final value = _seedValue(
          field: field,
          seedExpression: literalNum(0),
          hint: mockSeeds[field.name],
        );
        statements.add(
          Code(
            'patch = patch.with${_capitalize(memberName(field.name))}'
            '(${_render(value)});',
          ),
        );
      }
      statements.add(const Code('return patch;'));
      m.body = Block.of(statements);
    });
  }

  /// The seed [Expression] for one field.
  ///
  /// Precedence: a `@ZorphyMock(example: …)` literal, then a reserved
  /// `@ZorphyMock(preset: …)`, then the type-derived default. [seedExpression]
  /// is spliced into the default so the value varies with the caller's seed,
  /// while a hint stays constant — a preset names a SHAPE, not a sequence.
  Expression _seedValue({
    required ZorphyFieldIr field,
    required Expression seedExpression,
    ZorphyMock? hint,
  }) {
    if (hint != null) {
      final example = hint.example;
      if (example != null) return _exampleLiteral(example);
      final preset = hint.preset;
      if (preset != null && ZorphyMockPresets.all.contains(preset)) {
        return _presetLiteral(preset, field);
      }
      // An unrecognized preset is a consumer-defined seed: fall through.
    }
    return _defaultSeedValue(field, seedExpression);
  }

  /// The literal for a `@ZorphyMock(example: …)` hint, element-wise for a
  /// collection so it types against the field it seeds.
  Expression _exampleLiteral(Object? example) {
    if (example is List) {
      return literalList(example.map(_scalarLiteral));
    }
    if (example is Map) {
      return literalMap({
        for (final entry in example.entries)
          entry.key.toString(): _scalarLiteral(entry.value),
      });
    }
    return _scalarLiteral(example);
  }

  Expression _scalarLiteral(Object? value) {
    if (value == null) return literalNull;
    if (value is String) return literalString(value);
    if (value is num) return literalNum(value);
    if (value is bool) return literalBool(value);
    return literalString(value.toString());
  }

  /// The reserved preset's literal for [field].
  ///
  /// Only the two name-derived presets vary by field; the other two are
  /// constants because the shape they name has one canonical example.
  Expression _presetLiteral(String preset, ZorphyFieldIr field) {
    final fieldSlug = slug(field.name);
    return switch (preset) {
      ZorphyMockPresets.email => literalString('$fieldSlug@example.com'),
      ZorphyMockPresets.uuid => literalString(uuidSeed(fieldSlug, 0)),
      ZorphyMockPresets.price => literalNum(defaultMockPrice),
      ZorphyMockPresets.url => literalString('https://example.com/$fieldSlug'),
      _ => literalNum(0),
    };
  }

  /// The type-derived default seed for [field].
  ///
  /// Total: an unrecognized type seeds as a string, the only value that can be
  /// handed to a field this emitter knows nothing about. Collections recurse so
  /// `List<String>` gets a real element rather than an empty list.
  Expression _defaultSeedValue(ZorphyFieldIr field, Expression seed) {
    final bare = field.type.trim().replaceAll('?', '');

    return switch (bare) {
      'String' => _stringSeed(field.name, seed),
      'int' ||
      'num' => _code('${_render(seed)} % 97 + ${_stableOffset(field.name)}'),
      'double' => _code(
        '(${_render(seed)} % 97 + ${_stableOffset(field.name)}).toDouble()'
        ' + 0.5',
      ),
      'bool' => _code(
        '(${_render(seed)} + ${_stableOffset(field.name)}) % 2 == 0',
      ),
      'DateTime' => _code(
        'DateTime.utc(2026, 1, 1).add'
        '(Duration(hours: ${_render(seed)} + ${_stableOffset(field.name)}))',
      ),
      'Duration' => _code(
        'Duration(hours: ${_render(seed)} + ${_stableOffset(field.name)})',
      ),
      _ => _structuredSeed(bare, field, seed),
    };
  }

  /// `'<field>-${seed}'` — the seed a `String` field takes with no hint.
  ///
  /// Interpolated rather than `+`-concatenated, because `String + int` does not
  /// type-check.
  Expression _stringSeed(String fieldName, Expression seed) =>
      _code("'${slug(fieldName)}-\${${_render(seed)}}'");

  /// A seed for a collection or an unrecognized type.
  ///
  /// `List<T>` and `Set<T>` seed one element — the minimum a page or a decoder
  /// can render — and `Map<K, V>` one entry. Anything else falls back to its
  /// type name as the string seed.
  Expression _structuredSeed(
    String type,
    ZorphyFieldIr field,
    Expression seed,
  ) {
    if (type.startsWith('List<') && type.endsWith('>')) {
      final element = type.substring('List<'.length, type.length - 1);
      return literalList([_elementSeed(element, field, seed)]);
    }
    if (type.startsWith('Set<') && type.endsWith('>')) {
      final element = type.substring('Set<'.length, type.length - 1);
      return literalSet([_elementSeed(element, field, seed)]);
    }
    if (type.startsWith('Map<') && type.endsWith('>')) {
      final args = type.substring('Map<'.length, type.length - 1);
      final comma = _topLevelComma(args);
      if (comma > 0) {
        final valueType = args.substring(comma + 1).trim();
        return literalMap({
          literalString(slug(field.name)): _elementSeed(valueType, field, seed),
        });
      }
    }
    return _stringSeed(field.name, seed);
  }

  /// A seed for one collection element of [type].
  Expression _elementSeed(String type, ZorphyFieldIr field, Expression seed) =>
      _defaultSeedValue(ZorphyFieldIr(name: field.name, type: type), seed);

  /// The index of the first top-level comma in a type-argument list, or `-1`.
  static int _topLevelComma(String args) {
    var depth = 0;
    for (var i = 0; i < args.length; i++) {
      final char = args[i];
      if (char == '<') depth++;
      if (char == '>') depth--;
      if (char == ',' && depth == 0) return i;
    }
    return -1;
  }

  /// Wraps already-rendered Dart source as a code_builder expression.
  ///
  /// The one seam where this emitter hands pre-rendered text to the pipeline:
  /// an arithmetic seed is an operator tree over both a caller-supplied
  /// [Expression] and a generated constant, and rendering that tree as source
  /// keeps ONE formatting authority (the [ZorphyEmitter] that formats the whole
  /// method body) instead of building a parallel AST per operator.
  static Expression _code(String source) => CodeExpression(Code(source));

  /// [expression] as Dart source, through code_builder's own emitter.
  static String _render(Expression expression) =>
      expression.accept(DartEmitter()).toString();

  /// `{int seed = 0}` — the one parameter `single` takes.
  static Parameter _seedParameter() => Parameter((p) {
    p
      ..name = 'seed'
      ..named = true
      ..type = referType('int')
      ..defaultTo = const Code('0');
  });

  /// The `<Name>MockData` class name for [node].
  static String mockDataName(ZorphyNodeIr node) => '${node.cleanName}MockData';

  /// Whether [field]'s patch carries a raw value through a `with<Name>`
  /// builder.
  ///
  /// A `$`-prefixed nested reference carries a `PatchNested` instead, and an
  /// abstract/sealed form (`$$Node`) has no concrete patch to instantiate, so
  /// neither has a builder this sample can call.
  static bool hasFluentBuilder(ZorphyFieldIr field) {
    final type = field.type.trim();
    if (type.isEmpty) return false;
    if (type.contains('Function')) return false;
    if (type.startsWith(r'$')) return false;
    return true;
  }

  /// The whole payload of [node], nearest declaration first: its own fields,
  /// then each ancestor's, with the first declaration of a name winning.
  static List<ZorphyFieldIr> payloadFields(ZorphyNodeIr node) {
    final seen = <String>{};
    final payload = <ZorphyFieldIr>[];
    for (final owner in <ZorphyNodeIr>[node, ...node.superTypes]) {
      for (final field in owner.fields) {
        if (seen.add(field.name)) payload.add(field);
      }
    }
    return payload;
  }

  /// Every concrete leaf at or below [node], depth-first — the rotation order.
  ///
  /// A node that is itself a leaf answers `[node]`, so a non-polymorphic
  /// entity still sees a non-empty list and the caller can tell "no hierarchy"
  /// from "empty hierarchy".
  static List<ZorphyNodeIr> leavesOf(ZorphyNodeIr node) {
    final out = <ZorphyNodeIr>[];
    void walk(ZorphyNodeIr current) {
      if (current.isConcreteLeaf) {
        out.add(current);
        return;
      }
      for (final child in current.directSubTypes) {
        walk(child);
      }
    }

    walk(node);
    return out;
  }

  /// The field name as a patch member: a private field's underscore is dropped
  /// by the fluent builders, so the sample addresses the same name they do.
  static String memberName(String name) =>
      name.startsWith('_') ? name.substring(1) : name;

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);

  /// A lowercase identifier fragment derived from [name].
  ///
  /// Deliberately allocation-light and free of `StringBuffer`, matching the
  /// issue's structural gate.
  static String slug(String name) => memberName(name)
      .split('')
      .map(
        (char) =>
            RegExp('[A-Za-z0-9]').hasMatch(char) ? char.toLowerCase() : '-',
      )
      .join();

  /// A stable per-field offset so two fields of the same type do not collide.
  ///
  /// Derived from the field name only — never from `Object.hashCode`, which is
  /// not stable across processes and would make a golden fixture churn.
  static int _stableOffset(String fieldName) {
    var sum = 0;
    for (var i = 0; i < fieldName.length; i++) {
      sum = (sum * 31 + fieldName.codeUnitAt(i)) % 1000;
    }
    return sum;
  }
}

/// The default monetary amount the `price` preset renders.
///
/// A constant rather than a seed-derived value: a price names a SHAPE ("a
/// monetary amount with minor units"), and a varying one would make a golden
/// fixture churn without telling its reader anything.
const num defaultMockPrice = 19.99;

/// A deterministic identifier for [slug] at [seed].
///
/// Shaped like a UUID (8-4-4-4-12) so a consumer that parses ids keeps working,
/// but derived purely from its inputs — never from `Random`, whose sequence is
/// not part of this contract.
String uuidSeed(String slug, int seed) {
  var hash = 0xcbf29ce484222325;
  for (final unit in '$slug-$seed'.codeUnits) {
    hash = (hash ^ unit) * 0x100000001b3;
    hash &= 0xFFFFFFFFFFFFFFFF;
  }
  final hex = hash.toRadixString(16).padLeft(16, '0');
  final tail = ((hash >> 8) & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
  final block = (hash >> 16) & 0xFFFFFFFF;
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4'
      '${hex.substring(12, 15)}-a${block.toRadixString(16).padLeft(4, '0')}'
      '-$tail${hex.substring(0, 4)}';
}
