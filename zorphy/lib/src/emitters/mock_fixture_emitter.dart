/// Emits `<Name>MockData` trusted seed builders (ISSUE-015, #190) and
/// `<Name>WireFixtures` boundary test fixtures (ISSUE-016, #191).
///
/// A mock-first consumer seeds a `ZfaStore` backend, a golden fixture, or a
/// screenshot harness from generated data instead of hand-writing it. This
/// emitter produces that data as a `<Name>MockData` class per node, built
/// entirely from `package:code_builder` specs and formatted by
/// [ZorphyEmitter] — no preset, no `generate*` toggle, per the issue's §5 gate.
///
/// It also emits `<Name>WireFixtures` for `@ZorphyEntity` and `@ZorphyIntent`,
/// providing `validMap({int seed = 0})` and `corruptMaps()`.
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
/// type default rather than emitting a literal it would have to invent. A
/// KNOWN preset or example that does not fit the field's declared type falls
/// through the same way: a `price` on an `int` field is not a licence to hand
/// a `double` to an `int` parameter.
///
/// ## Seedability — a type this emitter cannot seed is never fabricated
///
/// `single()` constructs through the node's own `fromTrusted`, whose
/// non-nullable parameters are `required`. So a field of a type outside the
/// seeder's surface — a nested `$Entity` (bare or inside a `List`/`Set`/`Map`),
/// an enum, `Uint8List`, `Uri`, a type variable — has no honest literal: the
/// old catch-all handed every one of them a `String`, and the emitted source
/// then did not compile. The rule now is that the per-field seeder answers
/// `null` for such a type, and the callers decide:
///
/// - a NULLABLE field is simply omitted from the `fromTrusted` arguments (the
///   parameter is optional, and the value stays `null`);
/// - a non-nullable field makes the node's `single()` unseedable, so it throws
///   a documented `UnsupportedError` instead of emitting a call that cannot
///   compile;
/// - `samplePatch()` skips the field either way, since its fluent builder
///   carries something other than a raw seeded value.
///
/// A node whose class name carries type parameters (`Box<T>`) is not emitted at
/// all, matching the generator's own posture for generic hierarchies
/// (`PatchGenerator.shouldGenerate` withholds a generic sealed root).
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
import '../emission/wire_kind.dart';
import '../parser/polymorphic_ir.dart';

/// Emits `<Name>MockData` classes for the nodes of a resolved hierarchy.
final class MockFixtureEmitter {
  /// The field kinds this emitter's seed classifier branches handle.
  ///
  /// Exposed so the wire-capability matrix's drift gate can derive its
  /// expected kind set from the emitters instead of a duplicate literal.
  static Set<WireKind> get classifiedKinds => seedClassifiedKinds;

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
  /// A node whose declaration carries type parameters is SKIPPED, along with
  /// everything below it: `Box<T>MockData` and `Box<T>.fromTrusted(...)` are
  /// not legal Dart, and `T` is not a type this seeder can produce a value for.
  /// That is the same fail-closed posture the generator takes for a generic
  /// hierarchy (`PatchGenerator.shouldGenerate`), and it is why a generator
  /// calling this per node never sees a class it cannot compile.
  ///
  /// [mockSeeds] maps a FIELD name to its `@ZorphyMock` hint; the hint applies
  /// wherever that name is seeded in this hierarchy.
  String emit(
    ZorphyNodeIr root, {
    Map<String, ZorphyMock> mockSeeds = const {},
  }) {
    final specs = <Spec>[];
    void walk(ZorphyNodeIr node) {
      if (node.typeParameters.isNotEmpty) return;
      specs.add(_classSpec(node, mockSeeds));
      if (_supportsWireFixtures(node)) {
        specs.add(_wireFixturesClassSpec(node));
      }
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
  ///
  /// A GENERIC node emits nothing (an empty string, like
  /// `PolymorphicPatchEmitter.emitRoot` for an unemittable root): there is no
  /// legal declaration to produce, and silently approximating one would hand
  /// the caller source that does not compile.
  String emitForNode(
    ZorphyNodeIr node, {
    Map<String, ZorphyMock> mockSeeds = const {},
  }) {
    if (node.typeParameters.isNotEmpty) return '';
    final specs = <Spec>[_classSpec(node, mockSeeds)];
    if (_supportsWireFixtures(node)) {
      specs.add(_wireFixturesClassSpec(node));
    }
    return _emitter.emitSpecs(specs);
  }

  /// The `<Name>MockData` class of [node].
  Class _classSpec(ZorphyNodeIr node, Map<String, ZorphyMock> mockSeeds) {
    // Only leaves this emitter actually emits can be rotation arms: a generic
    // leaf is skipped, so naming its MockData would reference an undefined
    // class.
    final leaves = [
      for (final leaf in leavesOf(node))
        if (leaf.typeParameters.isEmpty) leaf,
    ];
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
  ///
  /// A field this emitter cannot seed is left out of the argument map when it
  /// is NULLABLE (`fromTrusted`'s nullable parameters are optional, so the
  /// value stays `null`), and makes the whole builder throw a documented
  /// [UnsupportedError] when it is not — a required parameter has no value
  /// this emitter could honestly supply, and a fabricated `String` would not
  /// compile at the call site.
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

      if (!node.isConcreteLeaf && leaves.isEmpty) {
        // Every subtype below this node is one this emitter cannot emit, so
        // there is no arm to rotate into and the node cannot construct itself.
        m.body = _unsupported(
          node,
          'no concrete subtype is emittable (a generic subtype is skipped)',
        );
        return;
      }

      if (payload.isEmpty) {
        // A fieldless LEAF's generated constructor takes no arguments. An
        // intent's constructor is not const (IntentEmitter emits no const
        // factory), so only the other archetypes may use the const form.
        m.body = Code(
          node.archetype == ArchetypeKind.intent
              ? 'return ${node.cleanName}();'
              : 'return const ${node.cleanName}();',
        );
        return;
      }

      final arguments = <String, Expression>{};
      ZorphyFieldIr? blockedBy;
      for (final field in payload) {
        final value = _seedValue(
          field: field,
          seedExpression: refer('seed'),
          hint: mockSeeds[field.name],
        );
        if (value != null) {
          arguments[field.name] = value;
          continue;
        }
        if (!field.isNullable) blockedBy ??= field;
      }

      final blocked = blockedBy;
      if (blocked != null) {
        m.body = _unsupported(
          node,
          '${blocked.name} is ${blocked.type}, '
          'which this emitter cannot seed',
        );
        return;
      }

      // An intent constructs through its plain named-parameter constructor
      // (#232): it carries no `fromTrusted` for the mock to call.
      final construct = node.archetype == ArchetypeKind.intent
          ? referType(node.cleanName).newInstance(const [], arguments)
          : referType(node.cleanName)
                .newInstanceNamed('fromTrusted', const [], arguments);
      m.body = Block.of([construct.returned.statement]);
    });
  }

  /// The body of a builder that refuses to emit a value: a documented
  /// [UnsupportedError] naming the node and why.
  ///
  /// A throw beats a call that does not compile, and it keeps the emitted
  /// class usable for its other members (`list()` and `samplePatch()` still
  /// resolve, and a `samplePatch()` covers whatever it can seed).
  static Code _unsupported(ZorphyNodeIr node, String reason) {
    final message = '${mockDataName(node)} has no seedable value: $reason'
        .replaceAll(r'$', r'\$');
    return Code("throw UnsupportedError('$message');");
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
        // A field whose type has no seed is skipped on the patch side too: its
        // builder takes a value, and there is none to give it.
        if (value == null) continue;
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

  /// The seed [Expression] for one field, or `null` when the field's type is
  /// outside the surface this emitter can seed.
  ///
  /// Precedence: a `@ZorphyMock(example: …)` literal, then a reserved
  /// `@ZorphyMock(preset: …)`, then the type-derived default. [seedExpression]
  /// is spliced into the default so the value varies with the caller's seed,
  /// while a hint stays constant — a preset names a SHAPE, not a sequence.
  ///
  /// A hint is only used when it fits the field's declared type
  /// ([_presetFitsType] / [_exampleFitsType]): a `price` on an `int` field, an
  /// `email` on a `bool`, or an example of the wrong shape falls through to the
  /// type default rather than emitting a literal the parameter would reject.
  Expression? _seedValue({
    required ZorphyFieldIr field,
    required Expression seedExpression,
    ZorphyMock? hint,
  }) {
    final defaultSeed = _defaultSeedValue(field, seedExpression);
    if (defaultSeed == null) return null;

    if (hint != null) {
      final example = hint.example;
      if (example != null && _exampleFitsType(example, field.type)) {
        return _exampleLiteral(example);
      }
      final preset = hint.preset;
      if (preset != null &&
          ZorphyMockPresets.all.contains(preset) &&
          _presetFitsType(preset, field.type)) {
        return _presetLiteral(preset, field);
      }
      // An unrecognized preset is a consumer-defined seed, and a recognized
      // one that does not fit the field is unusable: both fall through.
    }
    return defaultSeed;
  }

  /// Whether the reserved [preset] can seed a field declared as [type].
  ///
  /// The presets name a SHAPE with a fixed literal kind — an address, an id, a
  /// URL and a monetary amount are all text except the price — so a preset on
  /// a field of another kind would emit a literal the constructor rejects.
  /// `url` is `String`-only: a `Uri` field would need a `Uri.parse(...)`
  /// expression this emitter does not build, so the type default (which is
  /// `null` for `Uri`, i.e. skipped) is the honest answer.
  static bool _presetFitsType(String preset, String type) {
    final bare = _bareType(type);
    return switch (preset) {
      ZorphyMockPresets.email ||
      ZorphyMockPresets.uuid ||
      ZorphyMockPresets.url => bare == 'String',
      ZorphyMockPresets.price => bare == 'num' || bare == 'double',
      _ => false,
    };
  }

  /// Whether a `@ZorphyMock(example: …)` literal can seed a field declared as
  /// [type].
  ///
  /// The check is on the literal's runtime KIND against the declared type, and
  /// it recurses into a collection so a `List<String>` example is not emitted
  /// into a `Set<int>` field. Three rules added with the empty-collection
  /// fallback (#285 review):
  /// * a `null` example fits only a NULLABLE declared type — the old early
  ///   `return true` let `{'first': null}` into a `Map<String, Status>`;
  /// * the collection KIND is checked before the elements — an empty `List`
  ///   cannot seed a `Set` field;
  /// * only the OUTER `?` is stripped, so inner element nullability survives
  ///   the recursion and `Map<String, Status?>` still accepts a null value.
  static bool _exampleFitsType(Object? example, String type) {
    final trimmed = type.trim();
    final acceptsNull = trimmed.endsWith('?');
    if (example == null) return acceptsNull;
    final structural = acceptsNull
        ? trimmed.substring(0, trimmed.length - 1).trim()
        : trimmed;
    final bare = _bareType(structural);
    if (bare.startsWith('List<') || bare.startsWith('Set<')) {
      final isList = bare.startsWith('List<');
      if (isList ? example is! List : example is! Set) return false;
      final element = structural.substring(
        structural.indexOf('<') + 1,
        structural.length - 1,
      );
      final items = isList ? example as List : example as Set;
      return items.every((item) => _exampleFitsType(item, element));
    }
    if (bare.startsWith('Map<')) {
      if (example is! Map) return false;
      final args = structural.substring('Map<'.length, structural.length - 1);
      final comma = _topLevelComma(args);
      if (comma <= 0) return false;
      final keyType = args.substring(0, comma).trim();
      final valueType = args.substring(comma + 1).trim();
      return example.entries.every(
        (entry) =>
            _exampleFitsType(entry.key, keyType) &&
            _exampleFitsType(entry.value, valueType),
      );
    }
    return switch (bare) {
      'String' => example is String,
      'int' => example is int,
      'num' || 'double' => example is num,
      'bool' => example is bool,
      _ => false,
    };
  }

  /// [type] with its nullability marker and any surrounding whitespace gone.
  static String _bareType(String type) =>
      type.trim().replaceAll('?', '').trim();

  /// The literal for a `@ZorphyMock(example: …)` hint, element-wise for a
  /// collection so it types against the field it seeds.
  ///
  /// Collection literals recurse: once a nullable collection field reaches the
  /// hint path through the empty-collection fallback, an `example: [[]]` on a
  /// `List<List<Status>>` must stay a nested list instead of having its inner
  /// list passed to [_scalarLiteral] and rendered as `'[]'` (#285 review).
  /// A map key keeps its own Dart type rather than being stringified:
  /// `Map<int, int>` with an example `{1: 10}` must render `{1: 10}`, not the
  /// `Map<String, int>`-shaped `{'1': 10}`.
  Expression _exampleLiteral(Object? example) {
    if (example is List) {
      return literalList(example.map(_exampleLiteral));
    }
    if (example is Set) {
      return literalSet(example.map(_exampleLiteral));
    }
    if (example is Map) {
      return literalMap({
        for (final entry in example.entries)
          _exampleLiteral(entry.key): _exampleLiteral(entry.value),
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

  /// The type-derived default seed for [field], or `null` when the type has no
  /// honest seed.
  ///
  /// Total over the seeder's surface — `String`, `int`/`num`, `double`, `bool`,
  /// `DateTime`, `Duration`, and a `List`/`Set`/`Map` of those — and `null`
  /// everywhere else. A nested Zorphy reference (bare, or as a collection
  /// element), an enum, `Uint8List`, `Uri` and a type variable all land in that
  /// `null`: this emitter cannot construct one, and the old catch-all
  /// pretending it was a `String` is what made the emitted source fail to
  /// compile. The callers decide what to do with a `null` (see the
  /// seedability note on the library).
  Expression? _defaultSeedValue(ZorphyFieldIr field, Expression seed) {
    final bare = _bareType(field.type);

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

  /// A seed for a collection, or `null` for any other unrecognized type.
  ///
  /// `List<T>` and `Set<T>` seed one element — the minimum a page or a decoder
  /// can render — and `Map<K, V>` one entry, each only when the element/value
  /// type itself has a seed. Anything else is not seedable (the caller decides
  /// whether the field is merely omitted or blocks the node).
  Expression? _structuredSeed(
    String type,
    ZorphyFieldIr field,
    Expression seed,
  ) {
    if (type.startsWith('List<') && type.endsWith('>')) {
      final element = type.substring('List<'.length, type.length - 1);
      final seeded = _elementSeed(element, field, seed);
      // An unseedable element type seeds an EMPTY list rather than blocking
      // the node: an empty list is a valid value, so a variant whose only
      // unseedable field is a `List<...>` stays in the mock rotation instead
      // of throwing UnsupportedError and dropping out of `list()` (#284).
      return seeded == null ? literalList(const []) : literalList([seeded]);
    }
    if (type.startsWith('Set<') && type.endsWith('>')) {
      final element = type.substring('Set<'.length, type.length - 1);
      final seeded = _elementSeed(element, field, seed);
      return seeded == null ? literalSet(const []) : literalSet([seeded]);
    }
    if (type.startsWith('Map<') && type.endsWith('>')) {
      final args = type.substring('Map<'.length, type.length - 1);
      final comma = _topLevelComma(args);
      if (comma > 0) {
        final keyType = args.substring(0, comma).trim();
        final valueType = args.substring(comma + 1).trim();
        final seeded = _elementSeed(valueType, field, seed);
        // A map with an unseedable value type seeds EMPTY (a valid map) so the
        // variant stays in rotation (#284).
        if (seeded == null) return literalMap(const {});
        // The key keeps its declared type too: a `Map<int, int>` must not be
        // seeded with a `String` key.
        final key = _defaultSeedValue(
          ZorphyFieldIr(name: field.name, type: keyType),
          seed,
        );
        if (key == null) return literalMap(const {});
        return literalMap({key: seeded});
      }
    }
    return null;
  }

  /// A seed for one collection element of [type], or `null` when it has none.
  Expression? _elementSeed(String type, ZorphyFieldIr field, Expression seed) =>
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
  /// neither has a builder this sample can call. The `$` test is on the
  /// RESOLVED type, not on the leading character: `List<$CategoryNode>` and
  /// `Map<String, $Tag>` are the common shapes, and a `startsWith(r'$')` gate
  /// let them through to a `List<String>` seed the field would reject.
  static bool hasFluentBuilder(ZorphyFieldIr field) {
    final type = field.type.trim();
    if (type.isEmpty) return false;
    if (type.contains('Function')) return false;
    if (_namesZorphyType(type)) return false;
    return true;
  }

  /// Whether [type] names a Zorphy reference anywhere inside it — the type
  /// itself (`$Box`), or an element/value argument of a collection
  /// (`List<$Box>`, `Map<String, $Box>`, `List<Map<String, $Box>>`).
  ///
  /// Every `$` in a field type is a Zorphy reference: `$` is not legal in an
  /// ordinary Dart identifier, so no false positive is possible and no
  /// wrapper-stripping grammar is needed.
  static bool _namesZorphyType(String type) => type.contains(r'$');

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

  static bool _supportsWireFixtures(ZorphyNodeIr node) =>
      node.archetype == ArchetypeKind.entity ||
      node.archetype == ArchetypeKind.intent;

  /// The `<Name>WireFixtures` class name for [node].
  static String wireFixturesName(ZorphyNodeIr node) =>
      '${node.cleanName}WireFixtures';

  /// The `<Name>WireFixtures` class of [node].
  Class _wireFixturesClassSpec(ZorphyNodeIr node) {
    return Class((c) {
      c.name = wireFixturesName(node);
      c.constructors.add(Constructor((k) => k.name = '_'));

      c.methods.add(
        Method((m) {
          m
            ..name = 'validMap'
            ..static = true
            ..returns = refer('Map<String, Object?>')
            ..optionalParameters.add(_seedParameter())
            ..body = Code(
              'return ${mockDataName(node)}.single(seed: seed).toWire();',
            );
        }),
      );

      c.methods.add(
        Method((m) {
          m
            ..name = 'corruptMaps'
            ..static = true
            ..returns = refer('List<Map<String, Object?>>')
            ..body = _corruptMapsBody(node);
        }),
      );
    });
  }

  static Code _corruptMapsBody(ZorphyNodeIr node) {
    final leaves = [
      for (final leaf in leavesOf(node))
        if (leaf.typeParameters.isEmpty) leaf,
    ];
    final isDispatch = leaves.isNotEmpty && !node.isConcreteLeaf;

    final statements = <Code>[
      const Code('final base = validMap();'),
      const Code('final maps = <Map<String, Object?>>[];'),
    ];

    // A node's `fromWire` validates the discriminator IFF it is a dispatch
    // node (`!node.isConcreteLeaf`) — exactly the split the boundary codec
    // makes (`_dispatchFromWireBody` vs `_leafFromWireBody`). A concrete
    // leaf's `fromWire` never reads the tag, so a missing/unknown tag would
    // still decode and break §5's "100% of corruptMaps return BoundaryErr"
    // gate; the corruption is emitted only where the decoder checks it.
    final isPolymorphicRoot = !node.isConcreteLeaf;

    if (isPolymorphicRoot && node.discriminatorKey.isNotEmpty) {
      final key = node.discriminatorKey;
      statements.add(
        Code(
          "maps.add(Map<String, Object?>.of(base)..remove('$key')); // missing discriminator",
        ),
      );
      statements.add(
        Code(
          "maps.add(Map<String, Object?>.of(base)..[ '$key' ] = '__unknown_discriminator__'); // unknown discriminator",
        ),
      );
    }

    // Every emittable leaf is a rotation arm of `single(seed:)`, so a base
    // per leaf index covers EVERY concrete payload in the hierarchy from the
    // root fixtures class — not just `leaves.first`. A consumer driving a
    // boundary gate from the root class alone then gets one corrupted payload
    // per required field across all leaves.
    final targets = isDispatch ? leaves : <ZorphyNodeIr>[node];
    for (var targetIndex = 0; targetIndex < targets.length; targetIndex++) {
      final baseName = targetIndex == 0 ? 'base' : 'base$targetIndex';
      if (targetIndex > 0) {
        statements.add(Code('final $baseName = validMap(seed: $targetIndex);'));
      }
      for (final field in payloadFields(targets[targetIndex])) {
        if (!field.isNullable) {
          statements.add(
            Code(
              "maps.add(Map<String, Object?>.of($baseName)..remove('${field.name}'));",
            ),
          );
        }
        final corruptVal = _corruptValueForType(field.type);
        // An unrecognized type cannot be corrupted honestly: the codec
        // classifies `Object`/`dynamic` as scalar and would accept a numeric
        // literal. Skipping the wrong-type map keeps the "100% BoundaryErr"
        // gate true; the missing-key map still covers required fields.
        if (corruptVal != null) {
          statements.add(
            Code(
              "maps.add(Map<String, Object?>.of($baseName)..[ '${field.name}' ] = $corruptVal);",
            ),
          );
        }
      }
    }

    statements.add(const Code('return maps;'));
    return Block.of(statements);
  }

  /// A wrong-typed literal for [declaredType], or `null` when no honest
  /// corruption is possible (e.g. `Object` / `dynamic` / unknown types).
  static String? _corruptValueForType(String declaredType) {
    final type = declaredType.replaceAll('?', '').trim();
    if (type == 'String') {
      return '12345';
    } else if (type == 'int') {
      return "'not-an-int'";
    } else if (type == 'double' || type == 'num') {
      return "'not-a-number'";
    } else if (type == 'bool') {
      return "'not-a-bool'";
    } else if (type == 'DateTime') {
      return "'not-a-datetime'";
    } else if (type.startsWith('List') || type.startsWith('Set')) {
      return "'not-a-list'";
    } else if (type.startsWith('Map')) {
      return "'not-a-map'";
    } else {
      // `Object` / `dynamic` (and any type this emitter cannot classify) is
      // decoded by `_boundaryAs<Object>`, where `12345 is Object` passes — a
      // fabricated numeric "corruption" would decode to BoundaryOk.
      return null;
    }
  }

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
///
/// Every group is a fixed-width slice of the hash rendered in UNSIGNED space:
/// Dart's `int` is 64-bit SIGNED, so `hash & 0xFFFFFFFFFFFFFFFF` is a no-op
/// (`0xFFFFFFFFFFFFFFFF == -1`) and `toRadixString(16)` then renders a leading
/// `-`. Masking with `0x7FFFFFFFFFFFFFFF` keeps the high bit clear, and
/// `padLeft` per group keeps each slice its declared width — a consumer that
/// validates ids with the canonical regex depends on both.
String uuidSeed(String slug, int seed) {
  var hash = 0xcbf29ce484222325;
  for (final unit in '$slug-$seed'.codeUnits) {
    hash = (hash ^ unit) * 0x100000001b3;
    hash &= 0xFFFFFFFFFFFFFFFF;
  }
  final bits = hash & 0x7FFFFFFFFFFFFFFF;
  final hex = bits.toRadixString(16).padLeft(16, '0');
  final tail = (bits & 0xFFFFFFFF).toRadixString(16).padLeft(8, '0');
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4'
      '${hex.substring(12, 15)}-8'
      '${((bits >> 12) & 0x3FF).toRadixString(16).padLeft(3, '0')}'
      '-$tail${hex.substring(0, 4)}';
}
