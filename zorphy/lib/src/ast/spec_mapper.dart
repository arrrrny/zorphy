/// SpecMapper: bridges Zorphy analyzer models to code_builder specs.
///
/// Converts [ClassMetadata], [FieldMetadata], [InterfaceMetadata], and
/// [GenericParameterMetadata] into their [code_builder] equivalents
/// ([Class], [Field], [TypeReference], [TypeParameter]).
///
/// Downstream generator migrations (P3) will call these functions to
/// build specs instead of concatenating strings.
library;

import 'package:code_builder/code_builder.dart';

import '../models/class_metadata.dart';
import '../models/field_metadata.dart';
import '../models/interface_metadata.dart';
import 'type_ref.dart';

// ────────────────────────────────────────────────────────────────────
// Class mapping
// ────────────────────────────────────────────────────────────────────

/// Maps a [ClassMetadata] to a code_builder [Class] spec.
///
/// Handles:
/// - **Modifiers**: `abstract`, `sealed`, plain concrete.
///   A class that is both abstract and sealed gets `sealed`; an abstract
///   class that is NOT sealed gets `abstract`. Concrete classes get no
///   modifier.
/// - **Type parameters**: [ClassMetadata.generics] are mapped via
///   [mapGenericParameter].
/// - **Implements clauses**: [ClassMetadata.interfaces] are mapped via
///   [mapInterfaceToTypeReference].
///
/// The returned [Class] only contains the **structural shape** (name,
/// modifiers, type params, implements).  Fields and methods are NOT
/// included — downstream generators add those per their own migration.
Class mapClass(ClassMetadata meta) {
  return Class((c) {
    c.name = meta.cleanName;

    // ── Modifiers ──────────────────────────────────────────────────
    if (meta.isSealed) {
      c.sealed = true;
    } else if (meta.isAbstract) {
      c.abstract = true;
    }
    // concrete: no modifier needed

    // ── Type parameters ────────────────────────────────────────────
    for (final g in meta.generics) {
      c.types.add(mapGenericParameter(g));
    }

    // ── Implements clauses ─────────────────────────────────────────
    for (final iface in meta.interfaces) {
      c.implements.add(mapInterfaceToTypeReference(iface));
    }

    // ── Doc comment ────────────────────────────────────────────────
    if (meta.docComment.isNotEmpty) {
      c.docs.add(meta.docComment);
    }
  });
}

// ────────────────────────────────────────────────────────────────────
// Field mapping
// ────────────────────────────────────────────────────────────────────

/// Maps a [FieldMetadata] (= [NameTypeClassComment]) to a code_builder
/// [Field] spec.
///
/// The field's type string is resolved through [referType] so that
/// generics (e.g. `List<int>`, `Map<String, dynamic>?`) are correctly
/// represented as nested [TypeReference]s.
///
/// Notes:
/// - `final` is inferred from the Zorphy convention (all generated
///   fields are final). If the field has `isGetterOnly`, no `final`
///   keyword is added.
/// - Annotations from [JsonKeyInfo] are attached as raw [Code] specs.
Field mapField(FieldMetadata field) {
  return Field((f) {
    f.name = field.name;
    f.type = field.type != null ? referType(field.type!) : referType('dynamic');

    // Zorphy fields are final unless they are getter-only.
    f.modifier = field.isGetterOnly ? FieldModifier.var$ : FieldModifier.final$;

    // Doc comment
    if (field.comment != null && field.comment!.isNotEmpty) {
      f.docs.add(field.comment!);
    }

    // JsonKey annotation
    if (field.jsonKeyInfo != null && field.jsonKeyInfo!.hasAnnotations) {
      f.annotations.add(
        CodeExpression(Code(field.jsonKeyInfo!.toAnnotationString())),
      );
    }

    // Additional annotations (e.g. @JsonSerializable, custom ones)
    for (final ann in field.additionalAnnotations) {
      // code_builder's DartEmitter adds the '@' prefix for annotations,
      // so the source string must NOT include it (m.toSource() includes
      // it, which produced '@@override' before).
      final cleaned = ann.startsWith('@') ? ann.substring(1) : ann;
      f.annotations.add(CodeExpression(Code(cleaned)));
    }
  });
}

// ────────────────────────────────────────────────────────────────────
// Interface mapping
// ────────────────────────────────────────────────────────────────────

/// Maps an [InterfaceMetadata] to a [TypeReference] suitable for an
/// `implements` clause.
///
/// Handles generic type arguments — e.g. `Comparable<T>` becomes
/// `TypeReference(symbol: 'Comparable', types: [refer('T')])`.
TypeReference mapInterfaceToTypeReference(InterfaceMetadata iface) {
  final name = iface.interfaceName;
  final typeRefs = iface.typeParams.where((tp) => tp.name.isNotEmpty).map((tp) {
    if (tp.type != null && tp.type!.isNotEmpty) {
      return referType('${tp.name}<${tp.type}>');
    }
    return referType(tp.name);
  }).toList();

  if (typeRefs.isEmpty) {
    return referType(name);
  }

  return TypeReference((t) {
    t.symbol = name;
    t.types.addAll(typeRefs);
  });
}

// ────────────────────────────────────────────────────────────────────
// Generic parameter mapping
// ────────────────────────────────────────────────────────────────────

/// Maps a [GenericParameterMetadata] to a code_builder [TypeReference]
/// suitable for a class `types` list.
///
/// In code_builder 4.x, type parameters with bounds are represented as
/// [TypeReference] with the [TypeReference.bound] set.
///
/// ```dart
/// // GenericParameterMetadata(name: 'T', bound: 'num')
/// //   => TypeReference(symbol: 'T', bound: referType('num'))
/// ```
TypeReference mapGenericParameter(GenericParameterMetadata g) {
  return TypeReference((t) {
    t.symbol = g.name;
    if (g.bound != null) {
      t.bound = referType(g.bound!);
    }
  });
}
