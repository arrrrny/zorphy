/// Reads the v3 archetype annotations of one class element.
///
/// This is the only place the parser touches `ConstantReader`: every value is
/// read with `peek()` so an unset argument stays `null` instead of throwing,
/// exactly like `AnnotationParser` does for the legacy annotations.
///
/// A class carries at most ONE archetype annotation; when it carries more,
/// the first match in [ZorphyArchetype.all] wins.
library;

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'polymorphic_ir.dart';

/// The five v3 archetype annotations, as analyzable type checkers.
///
/// `ZorphyUnion` lowers to [ArchetypeKind.value]: a union carries no
/// principal key and its variants are value nodes.
final class ZorphyArchetype {
  const ZorphyArchetype._(this.kind, this.checker);

  /// The archetype a node with this annotation lowers to.
  final ArchetypeKind kind;

  /// The source-level annotation this archetype is detected by.
  final TypeChecker checker;

  /// `@ZorphyEntity(principalKey: #id, ...)`.
  static const entity = ZorphyArchetype._(
    ArchetypeKind.entity,
    TypeChecker.fromUrl(
      'package:zorphy_annotation/src/archetypes.dart#ZorphyEntity',
    ),
  );

  /// `@ZorphyState()`.
  static const state = ZorphyArchetype._(
    ArchetypeKind.state,
    TypeChecker.fromUrl(
      'package:zorphy_annotation/src/archetypes.dart#ZorphyState',
    ),
  );

  /// `@ZorphyUnion()` — lowers to [ArchetypeKind.value].
  static const union = ZorphyArchetype._(
    ArchetypeKind.value,
    TypeChecker.fromUrl(
      'package:zorphy_annotation/src/archetypes.dart#ZorphyUnion',
    ),
  );

  /// `@ZorphyIntent(replaySafe: ...)`.
  static const intent = ZorphyArchetype._(
    ArchetypeKind.intent,
    TypeChecker.fromUrl(
      'package:zorphy_annotation/src/archetypes.dart#ZorphyIntent',
    ),
  );

  /// `@ZorphyValue()`.
  static const value = ZorphyArchetype._(
    ArchetypeKind.value,
    TypeChecker.fromUrl(
      'package:zorphy_annotation/src/archetypes.dart#ZorphyValue',
    ),
  );

  /// Every archetype, in detection order.
  ///
  /// `ZorphyUnion` and `ZorphyValue` share [ArchetypeKind.value], and a union
  /// is tested after `ZorphyValue` because a class can only carry one of the
  /// five — the order is therefore arbitrary between them, and `isUnion`
  /// records which annotation actually matched.
  static const all = <ZorphyArchetype>[entity, state, intent, value, union];
}

/// `@ZorphyDomainBool()` — the field-level escape hatch from
/// `ZORPHY_LINT_NO_BOOL_FLAGS` (ISSUE-005, #180).
///
/// Read here rather than in the lint because this file is the ONE place the
/// parser touches annotation objects; the lint consumes the lowered
/// [ZorphyFieldIr.isDomainBool] flag and never sees an element.
const TypeChecker zorphyDomainBoolChecker = TypeChecker.fromUrl(
  'package:zorphy_annotation/src/archetypes.dart#ZorphyDomainBool',
);

/// The parsed annotation values of one archetype-annotated class.
final class ArchetypeDeclaration {
  /// The archetype annotation found on the class.
  final ZorphyArchetype archetype;

  /// `ZorphyEntity.principalKey` as a field name, or `null` when unset.
  final String? principalKey;

  /// When `true`, the class was declared with `@ZorphyUnion`.
  final bool isUnion;

  /// `discriminator` — the wire key, default `'kind'`.
  final String discriminator;

  /// `replaySafe` for a `@ZorphyIntent`, `null` for every other archetype.
  final bool? replaySafe;

  /// The explicit subtypes declared on the annotation (`List<Type>`), lowered
  /// to class elements. These are the subtypes the generator cannot infer from
  /// the same library — the cross-library escape hatch.
  final List<ClassElement> explicitSubTypes;

  const ArchetypeDeclaration({
    required this.archetype,
    required this.principalKey,
    required this.isUnion,
    required this.discriminator,
    required this.replaySafe,
    required this.explicitSubTypes,
  });

  /// The lowered archetype kind.
  ArchetypeKind get kind => archetype.kind;
}

/// Reads archetype declarations off class elements.
final class ArchetypeParser {
  const ArchetypeParser._();

  /// Parses [element]'s archetype annotation, or `null` when the class
  /// carries none of the five v3 annotations.
  static ArchetypeDeclaration? parse(ClassElement element) {
    for (final archetype in ZorphyArchetype.all) {
      final annotation = archetype.checker.firstAnnotationOf(element);
      if (annotation == null) continue;
      return _read(annotation, archetype);
    }
    return null;
  }

  /// Every class of [library] that carries one of the five annotations,
  /// in declaration order.
  static List<ClassElement> annotatedClasses(LibraryElement library) {
    return [
      for (final element in library.classes)
        if (parse(element) != null) element,
    ];
  }

  static ArchetypeDeclaration _read(
    DartObject annotation,
    ZorphyArchetype archetype,
  ) {
    final reader = ConstantReader(annotation);
    final symbol = reader.peek('principalKey');
    final principalKey = symbol == null || symbol.isNull
        ? null
        : symbol.objectValue.toSymbolValue();

    return ArchetypeDeclaration(
      archetype: archetype,
      principalKey: principalKey,
      isUnion: identical(archetype, ZorphyArchetype.union),
      discriminator: reader.peek('discriminator')?.stringValue ?? 'kind',
      replaySafe: reader.peek('replaySafe')?.boolValue,
      explicitSubTypes: _readExplicitSubTypes(reader),
    );
  }

  /// Reads the `explicitSubTypes` (`List<Type>`) of an annotation into class
  /// elements, or an empty list when unset. Each entry must name a class.
  static List<ClassElement> _readExplicitSubTypes(ConstantReader reader) {
    final list = reader.peek('explicitSubTypes');
    if (list == null || list.isNull) return const <ClassElement>[];
    final types = <ClassElement>[];
    for (final value in list.listValue) {
      final type = value.toTypeValue();
      final element = type?.element;
      if (element is ClassElement) types.add(element);
    }
    return types;
  }

  /// The `@ZorphyUnion` factory targets of [element], as class elements.
  ///
  /// A union declares its variant set with redirecting factories
  /// (`factory $AsyncStatus.loading() = $Loading;`), so the targets are read
  /// from the constructor elements' `redirectedConstructor` — no source text
  /// is scanned.
  static List<ClassElement> unionVariants(ClassElement element) {
    final variants = <String, ClassElement>{};
    for (final constructor in element.constructors) {
      if (!constructor.isFactory) continue;
      final target = constructor.redirectedConstructor?.enclosingElement;
      if (target is ClassElement) variants[target.name ?? ''] = target;
    }
    return variants.values.toList();
  }
}
