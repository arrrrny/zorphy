/// The IR-native `<Entity>Fields` emitter (arrrrny/zorphy#247).
///
/// For every concrete, non-generic `@ZorphyEntity` / `@ZorphyValue` node this
/// emitter declares a top-level
///
/// ```dart
/// abstract final class <Name>Fields {
///   static const price = ZorphyField<Name, double>(
///     name: 'price', jsonKey: 'price', pointer: '/price',
///     get: _getPrice, set: _setPrice,
///   );
///   ...
///   static const List<ZorphyField<Name, Object?>> all = [id, price, ...];
/// }
/// ```
///
/// — one [ZorphyField] constant per payload field (own fields first, then
/// each ancestor's, the first declaration of a name winning), the private
/// static tear-off helpers those constants reference (the getter reads the
/// field; the setter routes through the class's own `copyWith`), and the
/// `all` registry list the wire round-trip resolves pointers against.
///
/// The emission is 100% `package:code_builder` — no StringBuffer anywhere —
/// and follows the shape [LensEmitter] established for the v3 surface
/// (ISSUE-0230): it reads a [ZorphyNodeIr] and declines abstract roots and
/// intermediates (they have no `copyWith` to rebuild through). The
/// `<Name>Fields` class stays OUT of the entity itself: it is `abstract`
/// and cannot be instantiated, so the surface is static-only
/// (`ProductFields.price`), exactly the issue's shape.
library;

import 'package:code_builder/code_builder.dart';

import '../ast/type_ref.dart';
import '../parser/polymorphic_ir.dart';
import 'emission_name_helpers.dart';

/// Emits the `<Name>Fields` descriptor classes for entity and value nodes.
final class EntityFieldsGenerator {
  /// Creates a fields emitter.
  const EntityFieldsGenerator();

  /// The top-level `<Name>Fields` class for every concrete, non-generic
  /// entity/value node with at least one payload field, as specs the composer
  /// appends to the library fragment.
  List<Spec> fieldsClasses(PolymorphicIr ir) {
    final specs = <Spec>[];
    for (final node in ir.nodes.values) {
      if (!_emittable(node)) continue;
      final fields = _payloadFields(node);
      if (fields.isEmpty) continue;
      specs.add(_buildFieldsClass(node.cleanName, fields));
    }
    return specs;
  }

  /// Only the archetypes the issue names (`@ZorphyEntity`, `@ZorphyValue`),
  /// and only nodes a caller can instantiate and rebuild through `copyWith`:
  /// a concrete, non-generic leaf.
  bool _emittable(ZorphyNodeIr node) =>
      (node.archetype == ArchetypeKind.entity ||
          node.archetype == ArchetypeKind.value) &&
      node.isConcreteLeaf &&
      node.typeParameters.isEmpty;

  /// The node's whole payload — own fields first, then each ancestor's, the
  /// first declaration of a name winning (a covariant redeclaration keeps the
  /// leaf's narrowed type).
  List<ZorphyFieldIr> _payloadFields(ZorphyNodeIr node) {
    final seen = <String>{};
    final fields = <ZorphyFieldIr>[];
    for (final owner in <ZorphyNodeIr>[node, ...node.superTypes]) {
      for (final field in owner.fields) {
        if (!seen.add(field.name)) continue;
        fields.add(field);
      }
    }
    return fields;
  }

  Class _buildFieldsClass(String className, List<ZorphyFieldIr> fields) {
    // Member names already taken — by the payload fields themselves and by
    // every helper and registry allocated below — so the `all` list and the
    // `_get` / `_set` tear-offs never collide with a field sharing their
    // name (`title` / `Title` included).
    final usedNames = <String>{for (final field in fields) field.name};

    // The tear-off helper names, allocated once so the constants and the
    // method declarations reference the SAME (uniqued) spellings.
    final helpers = <String, (String, String)>{
      for (final field in fields)
        field.name: (
          _uniqueHelperName('get', field.name, usedNames),
          _uniqueHelperName('set', field.name, usedNames),
        ),
    };

    // The aggregate registry list is `all` — unless a payload field is named
    // `all`, then it moves to `allFields` (then `$$all`), the same
    // rename-instead-of-collide rule the lens registry applies. A field
    // occupying every candidate loses the registry, not a compiling class.
    String? registryName;
    for (final candidate in const ['all', 'allFields', r'$$all']) {
      if (!usedNames.contains(candidate)) {
        registryName = candidate;
        break;
      }
    }

    final fieldNames = [for (final field in fields) field.name];

    return Class((c) {
      c.name = '${className}Fields';
      c.abstract = true;
      c.modifier = ClassModifier.final$;
      c.docs.add('/// Typed field descriptors over [$className] — one');
      c.docs.add('/// `ZorphyField` per payload field, inherited fields');
      c.docs.add('/// included (issue #247).');
      c.docs.add('///');
      c.docs.add('/// Query with the predicate methods, sort with `asc` /');
      if (registryName == null) {
        c.docs.add('/// `desc`.');
      } else {
        c.docs.add('/// `desc`, resolve wire pointers through');
        c.docs.add('/// `${className}Fields.$registryName`.');
      }

      for (final field in fields) {
        final fieldType = _emittedType(field);
        final (getter, setter) = helpers[field.name]!;
        c.fields.add(
          Field((f) {
            f.name = field.name;
            f.static = true;
            f.modifier = FieldModifier.constant;
            f.type = referType('ZorphyField<$className, $fieldType>');
            f.assignment = Code(
              'ZorphyField<$className, $fieldType>('
              "name: '${field.name}', "
              "jsonKey: '${field.name}', "
              "pointer: '/${field.name}', "
              'get: $getter, set: $setter)',
            );
          }),
        );
      }

      if (registryName != null) {
        c.fields.add(
          Field((f) {
            f.name = registryName;
            f.static = true;
            // `final`, not `const`: each entry is the typed constant with its
            // value type erased (`asObject`), a getter-built descriptor — and
            // only an erased entry can be written through from this
            // `Object?`-typed slot (zorphy#301). A typed `ZorphyField<T, V>`
            // placed here directly compiles and throws on the first `.set`.
            // The LIST is unmodifiable so a caller cannot remove an entry and
            // break later `byPointer` lookups; writes THROUGH the erased
            // descriptors remain supported.
            f.modifier = FieldModifier.final$;
            f.type = referType('List<ZorphyField<$className, Object?>>');
            f.assignment = Code(
              'List.unmodifiable(['
              '${fieldNames.map((n) => '$n.asObject').join(', ')}])',
            );
          }),
        );
      }

      for (final field in fields) {
        final fieldType = _emittedType(field);
        final (getter, setter) = helpers[field.name]!;

        c.methods.add(
          Method((m) {
            m.name = getter;
            m.static = true;
            m.returns = referType(fieldType);
            m.requiredParameters.add(
              Parameter((p) {
                p.name = 'root';
                p.type = referType(className);
              }),
            );
            m.lambda = true;
            m.body = Code('root.${field.name}');
          }),
        );

        c.methods.add(
          Method((m) {
            m.name = setter;
            m.static = true;
            m.returns = referType(className);
            m.requiredParameters.add(
              Parameter((p) {
                p.name = 'root';
                p.type = referType(className);
              }),
            );
            m.requiredParameters.add(
              Parameter((p) {
                p.name = 'value';
                p.type = referType(fieldType);
              }),
            );
            m.lambda = true;
            m.body = Code('root.copyWith(${field.name}: value)');
          }),
        );
      }
    });
  }

  /// The field's declared type, `$`-stripped, nullability spelled out.
  String _emittedType(ZorphyFieldIr field) =>
      concreteTypeName(field.emitsQuestionMark ? '${field.type}?' : field.type);

  /// Allocates a helper name (`_get<X>` / `_set<X>`) no member already uses,
  /// registered in [used] as it is claimed.
  String _uniqueHelperName(String prefix, String fieldName, Set<String> used) {
    var candidate = '_$prefix${pascalCase(fieldName)}';
    while (used.contains(candidate)) {
      candidate = '_$candidate';
    }
    used.add(candidate);
    return candidate;
  }
}
