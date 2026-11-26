/// Reads the v3 archetype annotations of one class element.
///
/// This is the only place the parser touches `ConstantReader`: every value is
/// read with `peek()` so an unset argument stays `null` instead of throwing,
/// exactly like `AnnotationParser` does for the legacy annotations.
///
/// A class carries at most ONE archetype annotation; when it carries more,
/// the first match in [ZorphyArchetype.all] wins.
library;

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'polymorphic_ir.dart';

/// A member body's source and whether it was an expression body (`=>`).
final class ZorphyMemberBody {
  final String source;
  final bool isLambda;
  const ZorphyMemberBody(this.source, this.isLambda);
}

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

  /// The redirecting variant factories of a `@ZorphyUnion` root, in
  /// declaration order (issue #271).
  ///
  /// A union declares its variants with redirecting factories
  /// (`factory $AppFailure.network({...}) = $NetworkFailure;`); each becomes a
  /// [ZorphyVariantFactoryIr] the sealed root re-emits as a redirecting const
  /// factory. A body factory (`factory $AppFailure.from(...) { ... }`) has no
  /// `redirectedConstructor` and is NOT a variant — it is a user member.
  static List<ZorphyVariantFactoryIr> unionVariantFactories(
    ClassElement element,
  ) {
    final factories = <ZorphyVariantFactoryIr>[];
    for (final constructor in element.constructors) {
      if (!constructor.isFactory) continue;
      final target = constructor.redirectedConstructor?.enclosingElement;
      if (target is! ClassElement) continue;
      final name = constructor.name;
      if (name == null || name.isEmpty) continue;
      factories.add(
        ZorphyVariantFactoryIr(
          name: name,
          variantClassName: target.name ?? '',
          parameters: constructor.firstFragment.formalParameters
              .map(_userParam)
              .toList(),
          // A real analyzer element backs every parameter list built here —
          // including the EMPTY list of `factory $State.idle() = $Idle`. That
          // distinction is what keeps the emitter from re-deriving the list
          // from the variant's fields (#291).
          hasDeclaredParameters: true,
        ),
      );
    }
    return factories;
  }

  /// The user-declared `static` methods and body `factory` constructors of a
  /// `@ZorphyUnion` root, in declaration order (issue #271).
  ///
  /// The signature is read from the analyzer element (lossless); the body is
  /// read from the compilation-unit AST by [classMemberBodies] and spliced by
  /// the emitter. A body factory (`factory $AppFailure.from(...) { ... }`) has
  /// no `redirectedConstructor`; a redirecting factory is a variant, not a user
  /// member.
  /// The clean names of [variants] whose SOURCE class declares no `fromTrusted`
  /// constructor (issue #293).
  ///
  /// The variants arrive as the union's hierarchy children — the `implements
  /// $Union` edges — not as redirecting-factory targets, because a union may
  /// declare every variant as a BODY factory (zuraffa's `AppFailure` does) and
  /// then has no redirect to read. Constructors are inspected by name, never by
  /// source text. A variant that already declares `fromTrusted` is left out so
  /// its forwarded constructor calls keep the plain `$Variant` → `Variant`
  /// lowering.
  static Set<String> unionVariantsWithoutFromTrusted(
    Iterable<ClassElement> variants,
  ) {
    final names = <String>{};
    for (final variant in variants) {
      final hasFromTrusted = variant.constructors.any(
        (constructor) => constructor.name == 'fromTrusted',
      );
      if (!hasFromTrusted) {
        names.add((variant.name ?? '').replaceAll(r'$', ''));
      }
    }
    return names;
  }

  static List<ZorphyUserMemberIr> unionUserMembers(
    ClassElement element,
    Map<String, ZorphyMemberBody> bodyByName,
  ) {
    final members = <ZorphyUserMemberIr>[];
    for (final method in element.methods) {
      if (!method.isStatic) continue;
      final name = method.name;
      if (name == null || name.isEmpty) continue;
      final body = bodyByName[name];
      if (body == null) continue;
      members.add(
        _userMember(
          name: name,
          isFactory: false,
          returnType: method.returnType.getDisplayString(),
          typeParameters: List.unmodifiable(
            method.typeParameters.map((p) => p.toString()),
          ),
          parameters: method.firstFragment.formalParameters
              .map(_userParam)
              .toList(),
          body: body,
        ),
      );
    }
    for (final constructor in element.constructors) {
      if (!constructor.isFactory) continue;
      // A redirecting factory is a variant, not a user member.
      if (constructor.redirectedConstructor != null) continue;
      final name = constructor.name ?? '';
      final body = bodyByName[name];
      if (body == null) continue;
      members.add(
        _userMember(
          name: name,
          isFactory: true,
          returnType: null,
          typeParameters: const [],
          parameters: constructor.firstFragment.formalParameters
              .map(_userParam)
              .toList(),
          body: body,
        ),
      );
    }
    return members;
  }

  static ZorphyUserMemberIr _userMember({
    required String name,
    required bool isFactory,
    required String? returnType,
    required List<String> typeParameters,
    required List<ZorphyUserParamIr> parameters,
    required ZorphyMemberBody body,
  }) {
    return ZorphyUserMemberIr(
      name: name,
      isFactory: isFactory,
      returnType: returnType,
      typeParameters: typeParameters,
      parameters: parameters,
      bodySource: body.source,
      bodyIsLambda: body.isLambda,
    );
  }

  static ZorphyUserParamIr _userParam(FormalParameterFragment fragment) {
    final p = fragment.element;
    // The parameter type KEEPS its `?`: a user member's signature is spliced
    // verbatim, so `StackTrace? st` must stay nullable (unlike a field, whose
    // nullability the emitter re-applies from a separate flag).
    return ZorphyUserParamIr(
      name: p.name ?? '',
      type: p.type.getDisplayString(),
      isNamed: p.isNamed,
      isRequired: p.isRequired,
      isOptionalPositional: p.isOptionalPositional,
      defaultValue: p.defaultValueCode,
    );
  }

  /// Reads the ORIGINAL body source of [element]'s class members, keyed by
  /// source name — a method by its name, a constructor by its name (`''` for an
  /// unnamed one).
  ///
  /// The analyzer's element model in this SDK is fragment-based and does not
  /// expose a lossless `toSource()` on members, so the body is read from the
  /// parsed compilation unit: a block body yields its statements' source (the
  /// outer braces are re-added by the emitter), an expression body yields the
  /// expression source WITHOUT the leading `=>` / trailing `;`. A library that
  /// cannot be parsed yields an empty map, and the caller then carries no user
  /// members (fail closed, never a half-rewritten member).
  static Map<String, ZorphyMemberBody> classMemberBodies(ClassElement element) {
    final bodies = <String, ZorphyMemberBody>{};
    final session = element.session;
    if (session == null) return bodies;
    final SomeParsedLibraryResult parsed;
    try {
      parsed = session.getParsedLibraryByElement(element.library);
    } on Object {
      return bodies;
    }
    if (parsed is! ParsedLibraryResult) return bodies;
    for (final unit in parsed.units) {
      for (final declaration in unit.unit.declarations) {
        if (declaration is! ClassDeclaration) continue;
        if (declaration.namePart.typeName.lexeme != element.name) continue;
        for (final member in declaration.body.members) {
          if (member is MethodDeclaration) {
            bodies[member.name.lexeme] = _bodyOf(member.body);
          } else if (member is ConstructorDeclaration) {
            bodies[member.name?.lexeme ?? ''] = _bodyOf(member.body);
          }
        }
      }
    }
    return bodies;
  }

  /// The source of a [FunctionBody]: a block's statements joined by newlines
  /// (braces re-added downstream), or an expression body's expression text
  /// (no `=>` / `;`). An empty body yields an empty block.
  static ZorphyMemberBody _bodyOf(FunctionBody body) {
    if (body is BlockFunctionBody) {
      final statements = body.block.statements;
      if (statements.isEmpty) return const ZorphyMemberBody('', false);
      return ZorphyMemberBody(
        statements.map((s) => s.toSource()).join('\n'),
        false,
      );
    }
    if (body is ExpressionFunctionBody) {
      return ZorphyMemberBody(body.expression.toSource(), true);
    }
    return const ZorphyMemberBody('', false);
  }
}
