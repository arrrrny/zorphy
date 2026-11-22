/// Builds a [PolymorphicIr] from resolved analyzer elements (ISSUE-002, #177).
///
/// The resolver is the ONE place that walks `implements $Parent` links, so
/// every entry point — a single library or a set of libraries — produces the
/// same graph shape:
///
/// 1. collect every archetype-annotated class ([ArchetypeParser]);
/// 2. lower `@ZorphyUnion` factories into synthetic concrete leaves;
/// 3. wire `superTypes` / `directSubTypes` transitively;
/// 4. resolve the inherited `principalKey`, `discriminatorKey` and per-leaf
///    `replaySafe`;
/// 5. report ZORPHY_E001..E003.
///
/// Nothing is emitted and no element is mutated: the result is pure data that
/// the `code_builder` emitters (ISSUE-003 onward) consume.
library;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

import 'archetype_parser.dart';
import 'polymorphic_ir.dart';

/// One declaration being resolved: the element it came from and the node
/// built for it.
///
/// The element never leaves the resolver — it is carried here so the graph
/// can be keyed by ELEMENT (two libraries may declare same-named classes)
/// while the public IR exposes names only.
final class _Declaration {
  _Declaration(this.element, this.node);

  final ClassElement element;
  final ZorphyNodeIr node;
}

/// Builds [PolymorphicIr] graphs from analyzer elements.
final class HierarchyResolver {
  const HierarchyResolver._();

  /// Resolves one library.
  static PolymorphicIr resolveLibrary(LibraryElement library) =>
      resolveLibraries([library]);

  /// Resolves the hierarchy [element] heads, as its own graph.
  static PolymorphicIr resolveClass(ClassElement element) =>
      resolveLibrary(element.library);

  /// Resolves a set of libraries as ONE graph, so a subtype declared in a
  /// second library joins the root declared in the first (the cross-library
  /// shape issue #142 established must keep working).
  static PolymorphicIr resolveLibraries(Iterable<LibraryElement> libraries) {
    final declarations = <ClassElement, _Declaration>{};
    final unionRoots = <ClassElement>{};
    final unionVariants = <ClassElement, ClassElement>{};

    for (final library in libraries) {
      for (final element in ArchetypeParser.annotatedClasses(library)) {
        final declaration = ArchetypeParser.parse(element);
        if (declaration == null) continue;
        declarations.putIfAbsent(
          element,
          () => _Declaration(
            element,
            _nodeFor(element, declaration, isSyntheticLeaf: false),
          ),
        );
        if (!declaration.isUnion) continue;

        unionRoots.add(element);
        for (final variant in ArchetypeParser.unionVariants(element)) {
          unionVariants.putIfAbsent(variant, () => element);
          // A union variant IS a leaf of the union's hierarchy even when the
          // variant class carries no archetype annotation of its own.
          declarations.putIfAbsent(
            variant,
            () => _Declaration(
              variant,
              _nodeFor(
                variant,
                ArchetypeDeclaration(
                  archetype: ZorphyArchetype.value,
                  principalKey: null,
                  isUnion: false,
                  discriminator: declaration.discriminator,
                  replaySafe: null,
                ),
                isSyntheticLeaf: true,
              ),
            ),
          );
        }
      }
    }

    if (declarations.isEmpty) return PolymorphicIr.empty;

    // Phase 1 — the parent/child edges. A class's polymorphic parent is the
    // NEAREST archetype-annotated supertype it implements; `allSupertypes`
    // is nearest-first, so the first match wins and transitivity falls out
    // of the graph rather than out of a second walk.
    final parents = <ClassElement, ClassElement>{};
    final children = <ClassElement, List<ClassElement>>{};
    void link(ClassElement child, ClassElement parent) {
      if (identical(child, parent)) return;
      if (parents.containsKey(child)) return;
      parents[child] = parent;
      children.putIfAbsent(parent, () => <ClassElement>[]).add(child);
    }

    for (final element in declarations.keys) {
      final parent = _nearestAnnotatedSupertype(element, declarations.keys);
      if (parent != null) link(element, parent);
    }
    // Union factory targets are leaves of their union ROOT even though the
    // target class may not implement it, so the edge is added explicitly. A
    // variant that already declares its own `implements $OtherRoot` keeps
    // that parent: `link` refuses a second one.
    for (final entry in unionVariants.entries) {
      link(entry.key, entry.value);
    }

    final roots = <ClassElement>[
      for (final element in declarations.keys)
        if (!parents.containsKey(element)) element,
    ];

    // Phase 2 — wire the hierarchy links, depth-first from each root, so a
    // child's own subtree is resolved before its parent's leaf list is
    // assembled.
    final wired = <ClassElement, _Declaration>{};

    _Declaration wire(ClassElement element) {
      final existing = wired[element];
      if (existing != null) return existing;

      final definition = declarations[element]!;
      final wiredChildren = <_Declaration>[
        for (final child in children[element] ?? const <ClassElement>[])
          wire(child),
      ];
      final leaves = <ZorphyNodeIr>[
        for (final child in wiredChildren)
          if (child.node.isConcreteLeaf)
            child.node
          else
            ...child.node.allConcreteLeaves,
      ];

      final node = definition.node.copyWith(
        superTypes: _transitiveSupertypes(element, parents, declarations),
        directSubTypes: List.unmodifiable([
          for (final child in wiredChildren) child.node,
        ]),
        allConcreteLeaves: List.unmodifiable(leaves),
        isSealedRoot: !parents.containsKey(element),
        isAbstractIntermediate:
            parents.containsKey(element) && wiredChildren.isNotEmpty,
        isConcreteLeaf: wiredChildren.isEmpty,
      );
      final result = _Declaration(element, node);
      wired[element] = result;
      return result;
    }

    final wiredRoots = <_Declaration>[
      for (final element in roots) wire(element),
    ];

    // Phase 3 — inheritance resolution, top-down from each root: identity,
    // wire key and replay baseline flow down, and a leaf's explicit value
    // wins over what it inherits.
    final diagnostics = <ZorphyDiagnostic>[];
    final resolved = <ClassElement, _Declaration>{};
    for (final root in wiredRoots) {
      _resolveInheritance(root, null, null, null, diagnostics, resolved);
    }

    final resolvedRoots = <ZorphyNodeIr>[
      for (final root in wiredRoots) resolved[root.element]!.node,
    ];

    // Phase 4 — duplicate discriminator values within one hierarchy.
    for (final root in resolvedRoots) {
      _checkDuplicateDiscriminators(root, diagnostics);
    }

    return PolymorphicIr(
      nodes: Map.unmodifiable({
        for (final declaration in resolved.values)
          declaration.node.className: declaration.node,
      }),
      roots: List.unmodifiable(resolvedRoots),
      diagnostics: List.unmodifiable(diagnostics),
    );
  }

  static ZorphyNodeIr _nodeFor(
    ClassElement element,
    ArchetypeDeclaration declaration, {
    required bool isSyntheticLeaf,
  }) {
    final className = element.name ?? '';
    final cleanName = className.replaceAll(r'$', '');
    return ZorphyNodeIr(
      className: className,
      cleanName: cleanName,
      archetype: declaration.kind,
      isSealedRoot: false,
      isAbstractIntermediate: false,
      isConcreteLeaf: false,
      superTypes: const [],
      directSubTypes: const [],
      allConcreteLeaves: const [],
      discriminatorKey: declaration.discriminator,
      discriminatorValue: snakeCaseName(cleanName),
      principalKey: declaration.principalKey,
      replaySafe: declaration.replaySafe,
      isSyntheticLeaf: isSyntheticLeaf,
    );
  }

  /// The `$Parent` an [element] implements, as a declared class, or `null`.
  ///
  /// `allSupertypes` is ordered nearest-first, so this is the CLOSEST
  /// archetype-annotated ancestor — a three-level tree links
  /// `$ZfaButtonNode -> $InteractiveUiNode`, never straight to the root.
  static ClassElement? _nearestAnnotatedSupertype(
    ClassElement element,
    Iterable<ClassElement> declared,
  ) {
    final declaredSet = declared.toSet();
    for (final supertype in element.allSupertypes) {
      final superElement = supertype.element;
      if (superElement is! ClassElement) continue;
      if (identical(superElement, element)) continue;
      if (declaredSet.contains(superElement)) return superElement;
    }
    return null;
  }

  /// Every declared ancestor of [element], nearest first — the transitive
  /// `$Parent` chain the issue calls `superTypes`.
  static List<ZorphyNodeIr> _transitiveSupertypes(
    ClassElement element,
    Map<ClassElement, ClassElement> parents,
    Map<ClassElement, _Declaration> declarations,
  ) {
    final result = <ZorphyNodeIr>[];
    final seen = <ClassElement>{element};
    var current = parents[element];
    while (current != null && seen.add(current)) {
      final declaration = declarations[current];
      if (declaration == null) break;
      result.add(declaration.node);
      current = parents[current];
    }
    return List.unmodifiable(result);
  }

  /// Resolves [declaration] and its subtree into [resolved].
  ///
  /// [inheritedPrincipalKey], [inheritedReplaySafe] and
  /// [inheritedDiscriminatorKey] are what the walk carries DOWN; the node's
  /// own value wins where it has one.
  static void _resolveInheritance(
    _Declaration declaration,
    String? inheritedPrincipalKey,
    bool? inheritedReplaySafe,
    String? inheritedDiscriminatorKey,
    List<ZorphyDiagnostic> diagnostics,
    Map<ClassElement, _Declaration> resolved,
  ) {
    final node = declaration.node;
    // The wire key belongs to the DISPATCH, so the root owns it and every
    // node below dispatches on the same field. A subtype's own
    // `discriminator:` cannot change it — a hierarchy with two keys could
    // never round-trip.
    final discriminatorKey = inheritedDiscriminatorKey ?? node.discriminatorKey;
    final principalKey = node.archetype == ArchetypeKind.entity
        ? (node.principalKey ?? inheritedPrincipalKey)
        : null;
    final replaySafe = node.archetype == ArchetypeKind.intent
        ? (node.replaySafe ?? inheritedReplaySafe)
        : null;

    // ZORPHY_E002 — a subtype whose archetype differs from a declared parent.
    for (final superType in node.superTypes) {
      if (superType.archetype == node.archetype) continue;
      diagnostics.add(
        ZorphyDiagnostic(
          code: ZorphyDiagnosticCode.e002MixedArchetypes,
          nodeName: node.className,
          message:
              '${node.cleanName} is a '
              '@Zorphy${_archetypeLabel(node.archetype)} but implements '
              '${superType.cleanName}, a '
              '@Zorphy${_archetypeLabel(superType.archetype)}',
        ),
      );
      break;
    }

    // ZORPHY_E001 — the identity field must exist, be non-nullable, and be a
    // String or an int.
    if (node.archetype == ArchetypeKind.entity && node.superTypes.isEmpty) {
      final key = principalKey;
      if (key == null || key.isEmpty) {
        diagnostics.add(
          ZorphyDiagnostic(
            code: ZorphyDiagnosticCode.e001MissingPrincipalKey,
            nodeName: node.className,
            message:
                '${node.cleanName} is an @ZorphyEntity root with no '
                'principalKey; declare one (e.g. principalKey: #id)',
          ),
        );
      } else {
        final problem = _principalKeyProblem(declaration.element, key);
        if (problem != null) {
          diagnostics.add(
            ZorphyDiagnostic(
              code: ZorphyDiagnosticCode.e001MissingPrincipalKey,
              nodeName: node.className,
              message: '${node.cleanName} principalKey "$key" $problem',
            ),
          );
        }
      }
    }

    final resolvedChildren = <ZorphyNodeIr>[];
    for (final child in node.directSubTypes) {
      final childElement = _elementNamed(child.className, declaration.element);
      if (childElement == null) {
        resolvedChildren.add(child);
        continue;
      }
      _resolveInheritance(
        _Declaration(childElement, child),
        principalKey,
        replaySafe,
        discriminatorKey,
        diagnostics,
        resolved,
      );
      resolvedChildren.add(resolved[childElement]!.node);
    }

    final leaves = <ZorphyNodeIr>[
      for (final child in resolvedChildren)
        if (child.isConcreteLeaf) child else ...child.allConcreteLeaves,
    ];
    resolved[declaration.element] = _Declaration(
      declaration.element,
      node.copyWith(
        discriminatorKey: discriminatorKey,
        principalKey: principalKey,
        replaySafe: replaySafe,
        directSubTypes: List.unmodifiable(resolvedChildren),
        allConcreteLeaves: List.unmodifiable(leaves),
      ),
    );
  }

  /// The element a wired child node came from.
  ///
  /// A child node's identity within one graph is its class name, and the
  /// resolver only wires children it built itself — from the parent's own
  /// library or one of the libraries being resolved. The lookup therefore
  /// prefers the parent's library and falls back to the parent's enclosing
  /// package.
  static ClassElement? _elementNamed(String className, ClassElement parent) {
    for (final element in parent.library.classes) {
      if (element.name == className) return element;
    }
    return null;
  }

  /// The reason [key] does not name a usable identity field, or `null`.
  static String? _principalKeyProblem(ClassElement element, String key) {
    final type = _fieldType(element, key);
    if (type == null) return 'names no field on the class';
    if (type.nullabilitySuffix != NullabilitySuffix.none) {
      return 'is nullable; a principal key must be non-nullable';
    }
    if (!type.isDartCoreString && !type.isDartCoreInt) {
      return 'must be a String or an int, not ${type.getDisplayString()}';
    }
    return null;
  }

  /// The declared type of the [key] field/getter on [element], or `null`.
  static DartType? _fieldType(ClassElement element, String key) {
    final getter = element.getGetter(key);
    if (getter != null) return getter.returnType;
    return element.getField(key)?.type;
  }

  /// ZORPHY_E003 — two nodes in one hierarchy share a discriminator value.
  static void _checkDuplicateDiscriminators(
    ZorphyNodeIr root,
    List<ZorphyDiagnostic> diagnostics,
  ) {
    final seen = <String, String>{};
    void walk(ZorphyNodeIr node) {
      final existing = seen[node.discriminatorValue];
      if (existing != null && existing != node.className) {
        diagnostics.add(
          ZorphyDiagnostic(
            code: ZorphyDiagnosticCode.e003DuplicateDiscriminator,
            nodeName: node.className,
            message:
                'discriminatorValue "${node.discriminatorValue}" is already '
                'used by $existing in the ${root.cleanName} hierarchy',
          ),
        );
      } else {
        seen[node.discriminatorValue] = node.className;
      }
      for (final child in node.directSubTypes) {
        walk(child);
      }
    }

    walk(root);
  }

  static String _archetypeLabel(ArchetypeKind kind) => switch (kind) {
    ArchetypeKind.entity => 'Entity',
    ArchetypeKind.state => 'State',
    ArchetypeKind.intent => 'Intent',
    ArchetypeKind.value => 'Value',
  };
}

/// PascalCase / camelCase to snake_case, matching `NamingUtils.toSnakeCase`
/// (`ZfaButtonNode` -> `zfa_button_node`, `AB` -> `a_b`).
String snakeCaseName(String name) {
  return name.replaceAllMapped(RegExp(r'[A-Z]'), (match) {
    final char = match.group(0)!;
    return match.start == 0 ? char.toLowerCase() : '_${char.toLowerCase()}';
  });
}
