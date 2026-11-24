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

import '../cli/utils/naming_utils.dart';
import '../lints/no_bool_flags_lint.dart';
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
      resolveLibraries([element.library]);

  /// Resolves a set of libraries as ONE graph, so a subtype declared in a
  /// second library joins the root declared in the first (the cross-library
  /// shape issue #142 established must keep working).
  static PolymorphicIr resolveLibraries(Iterable<LibraryElement> libraries) {
    final declarations = <ClassElement, _Declaration>{};
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
                  explicitSubTypes: const <ClassElement>[],
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
    // Records every parent that was requested for a child but refused because
    // the child already had one — a union variant that also `implements`
    // another root is the case that matters (finding: silently dropped edge).
    final refusedParents = <ClassElement, ClassElement>{};
    void link(ClassElement child, ClassElement parent) {
      if (identical(child, parent)) return;
      if (parents.containsKey(child)) {
        refusedParents.putIfAbsent(child, () => parents[child]!);
        return;
      }
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
    // that parent — the refused second edge is reported as a diagnostic
    // rather than dropped silently.
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
    // The wired children of each element, kept as declarations so Phase 3
    // can carry the real `ClassElement` down instead of re-deriving it from
    // a name string (which cannot see another library's classes).
    final wiredChildren = <ClassElement, List<_Declaration>>{};

    _Declaration wire(ClassElement element) {
      final existing = wired[element];
      if (existing != null) return existing;

      final definition = declarations[element]!;
      final wiredChildrenList = <_Declaration>[
        for (final child in children[element] ?? const <ClassElement>[])
          wire(child),
      ];
      wiredChildren[element] = wiredChildrenList;
      final leaves = <ZorphyNodeIr>[
        for (final child in wiredChildrenList)
          if (child.node.isConcreteLeaf)
            child.node
          else
            ...child.node.allConcreteLeaves,
      ];

      final node = definition.node.copyWith(
        superTypes: _transitiveStubs(element, parents, declarations),
        directSubTypes: List.unmodifiable([
          for (final child in wiredChildrenList) child.node,
        ]),
        allConcreteLeaves: List.unmodifiable(leaves),
        isSealedRoot: !parents.containsKey(element),
        isAbstractIntermediate:
            parents.containsKey(element) && wiredChildrenList.isNotEmpty,
        isConcreteLeaf:
            wiredChildrenList.isEmpty && !definition.element.isAbstract,
      );
      final result = _Declaration(element, node);
      wired[element] = result;
      return result;
    }

    final wiredRoots = <_Declaration>[
      for (final element in roots) wire(element),
    ];

    // Phase 3 — inheritance resolution. Two passes:
    //   3a resolves each subtree bottom-up (children before parent), so a
    //      parent's leaf list is built from already-resolved children.
    //   3b walks each root top-down to (a) rewrite `superTypes` from the
    //      fully-resolved ancestor nodes and (b) stamp `root` on every
    //      node — neither can be done in 3a because the parent/root node is
    //      not resolved until after its children.
    final diagnostics = <ZorphyDiagnostic>[];
    final resolved = <ClassElement, _Declaration>{};
    for (final root in wiredRoots) {
      _resolveSubtree(
        root,
        null,
        null,
        null,
        parents,
        wiredChildren,
        unionVariants,
        diagnostics,
        resolved,
      );
    }
    for (final root in wiredRoots) {
      _finalizeNode(root.element, null, parents, resolved);
    }

    final resolvedRoots = <ZorphyNodeIr>[
      for (final root in wiredRoots) resolved[root.element]!.node,
    ];

    // Phase 4 — duplicate discriminator values within one hierarchy.
    for (final root in resolvedRoots) {
      _checkDuplicateDiscriminators(root, diagnostics);
    }

    // Phase 4b — intent payload checks. An intent's payload is replayed across
    // a trust boundary, so a field that cannot be canonicalized, or one whose
    // name collides with the wire discriminator, must fail GENERATION rather
    // than emit a method that compiles and then throws (or silently loses the
    // wire tag) at call time.
    for (final root in resolvedRoots) {
      _checkIntentPayload(root, diagnostics);
    }

    // Phase 4c — `ZORPHY_LINT_NO_BOOL_FLAGS` (ISSUE-005, #180). A behavioral
    // or lifecycle `bool` on a state/intent/union node flattens a polymorphic
    // variant back into a flag, so it is reported here alongside the other
    // generation-blocking diagnostics instead of being emitted and discovered
    // at runtime. The rule itself lives in `lints/no_bool_flags_lint.dart` so
    // it can be unit-tested without a build step.
    diagnostics.addAll(
      NoBoolFlagsLint.check(
        PolymorphicIr(
          nodes: const {},
          roots: List.unmodifiable(resolvedRoots),
          diagnostics: const [],
        ),
      ),
    );

    // A union variant that also declares its own `implements` parent was
    // refused its union edge in Phase 1 — report it rather than letting the
    // union silently lose a declared variant.
    for (final entry in refusedParents.entries) {
      final unionRoot = unionVariants[entry.key];
      if (unionRoot == null) continue;
      diagnostics.add(
        ZorphyDiagnostic(
          code: ZorphyDiagnosticCode.e002MixedArchetypes,
          nodeName: _cleanName(unionRoot.name ?? ''),
          message:
              '${_cleanName(entry.key.name)} is a variant of '
              '${_cleanName(unionRoot.name ?? '')} but also implements '
              '${_cleanName(entry.value.name ?? '')}; the union edge is '
              'dropped',
        ),
      );
    }

    // `nodes` is keyed by qualified name so two libraries may declare
    // same-named classes without one silently winning (finding: keying by
    // `className` collapsed them).
    return PolymorphicIr(
      nodes: Map.unmodifiable({
        for (final declaration in resolved.values)
          _qualifiedName(declaration.element): declaration.node,
      }),
      roots: List.unmodifiable(resolvedRoots),
      diagnostics: List.unmodifiable(diagnostics),
    );
  }

  static ZorphyNodeIr _nodeFor(
    ClassElement element,
    ArchetypeDeclaration declaration, {
    required bool isSyntheticLeaf,
    bool isUnion = false,
  }) {
    final className = element.name ?? '';
    final cleanName = className.replaceAll(r'$', '');
    return ZorphyNodeIr(
      className: className,
      qualifiedName: _qualifiedName(element),
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
      isUnion: isUnion || declaration.isUnion,
      fields: _declaredFields(element),
      typeParameters: List.unmodifiable(
        element.typeParameters.map((parameter) => parameter.toString()),
      ),
    );
  }

  /// The fields [element] declares itself, in declaration order.
  ///
  /// Getters are the shape every archetype fixture uses (`String get id;`);
  /// real fields are read too so an annotated class that mixes both forms
  /// still round-trips. A declaration that inherits its payload from a
  /// supertype declares nothing here, and the leaf walk asks the ancestors —
  /// which is why this list is the node's OWN fields only.
  ///
  /// `@ZorphyDomainBool()` is read here (getter annotation, then any
  /// annotation on the same source field) so the lint downstream never has to
  /// touch an element.
  static List<ZorphyFieldIr> _declaredFields(ClassElement element) {
    final fields = <ZorphyFieldIr>[];
    final seen = <String>{};
    for (final getter in element.getters) {
      if (getter.isStatic) continue;
      final name = getter.name ?? '';
      if (name.isEmpty || !seen.add(name)) continue;
      final type = getter.returnType;
      // A real field ALSO surfaces here as its implicit getter, so this loop
      // claims the name first and the `element.fields` loop below — the only
      // branch that reads the field's own annotation — would be skipped. The
      // `@ZorphyDomainBool()` escape hatch sits on the FIELD for a real field,
      // so resolve the declaring field and read its annotation too; otherwise
      // an author who annotates a real field gets a generation error telling
      // them to annotate the thing they already annotated.
      FieldElement? declaringField;
      for (final f in element.fields) {
        if (!f.isStatic && f.name == name) {
          declaringField = f;
          break;
        }
      }
      fields.add(
        ZorphyFieldIr(
          name: name,
          type: _typeText(type),
          isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
          isDomainBool:
              _isDomainBool(getter) ||
              (declaringField != null && _isDomainBool(declaringField)),
        ),
      );
    }
    for (final field in element.fields) {
      if (field.isStatic) continue;
      final name = field.name ?? '';
      if (name.isEmpty || !seen.add(name)) continue;
      final type = field.type;
      fields.add(
        ZorphyFieldIr(
          name: name,
          type: _typeText(type),
          isNullable: type.nullabilitySuffix == NullabilitySuffix.question,
          isDomainBool: _isDomainBool(field),
        ),
      );
    }
    return List.unmodifiable(fields);
  }

  /// Whether [element] carries `@ZorphyDomainBool()`.
  ///
  /// An abstract getter's annotation sits on the getter element; on a real
  /// field it sits on the field. Both are checked because a fixture may
  /// declare either shape.
  static bool _isDomainBool(Element element) =>
      zorphyDomainBoolChecker.hasAnnotationOf(element);

  /// A field type as source text, WITHOUT a trailing `?`.
  ///
  /// [DartType.getDisplayString] carries the nullability suffix itself; the
  /// IR keeps nullability in [ZorphyFieldIr.isNullable] so the emitter decides
  /// where the `?` goes (a type argument's `?` is not the field's).
  static String _typeText(DartType type) {
    final text = type.getDisplayString();
    return text.endsWith('?') ? text.substring(0, text.length - 1) : text;
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
  ///
  /// Phase 2 builds these from the PRE-wiring stub nodes so the E001/E002
  /// checks have a `superTypes` to inspect; Phase 3a overwrites them with
  /// the fully-resolved ancestor nodes (finding: superTypes carried stubs).
  static List<ZorphyNodeIr> _transitiveStubs(
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

  /// Every declared ancestor of [element], nearest first — the transitive
  /// `$Parent` chain the issue calls `superTypes`.
  ///
  /// Only the ELEMENTS are collected here; the nodes are resolved in Phase 3
  /// so a caller reading `node.superTypes` sees the fully-resolved ancestor
  /// nodes, not the pre-wiring stubs (finding: superTypes carried stubs).
  static List<ClassElement> _transitiveSupertypeElements(
    ClassElement element,
    Map<ClassElement, ClassElement> parents,
  ) {
    final result = <ClassElement>[];
    final seen = <ClassElement>{element};
    var current = parents[element];
    while (current != null && seen.add(current)) {
      result.add(current);
      current = parents[current];
    }
    return List.unmodifiable(result);
  }

  /// Phase 3a — resolves [declaration] and its subtree bottom-up into
  /// [resolved].
  ///
  /// [inheritedPrincipalKey], [inheritedReplaySafe] and
  /// [inheritedDiscriminatorKey] are what the walk carries DOWN; the node's
  /// own value wins where it has one. `root` is stamped in a separate
  /// top-down pass (Phase 3b) because the root's final node is not built
  /// until its children resolve here.
  static void _resolveSubtree(
    _Declaration declaration,
    String? inheritedPrincipalKey,
    bool? inheritedReplaySafe,
    String? inheritedDiscriminatorKey,
    Map<ClassElement, ClassElement> parents,
    Map<ClassElement, List<_Declaration>> wiredChildren,
    Map<ClassElement, ClassElement> unionVariants,
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

    // Resolve each child first (bottom-up), from its wired declaration — the
    // element is already in hand, so a subtype in another library is found
    // without a name scan (finding: cross-library children never resolved).
    final resolvedChildren = <ZorphyNodeIr>[];
    for (final child
        in wiredChildren[declaration.element] ?? const <_Declaration>[]) {
      _resolveSubtree(
        child,
        principalKey,
        replaySafe,
        discriminatorKey,
        parents,
        wiredChildren,
        unionVariants,
        diagnostics,
        resolved,
      );
      resolvedChildren.add(resolved[child.element]!.node);
    }

    // `superTypes` is rewritten from the RESOLVED ancestor map, so a caller
    // reading `node.superTypes.first.allConcreteLeaves` sees the real leaf
    // list rather than a stub (finding: superTypes carried pre-wiring stubs).
    final resolvedSuperTypes = <ZorphyNodeIr>[
      for (final superElement in _transitiveSupertypeElements(
        declaration.element,
        parents,
      ))
        if (resolved[superElement] != null) resolved[superElement]!.node,
    ];

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
        superTypes: List.unmodifiable(resolvedSuperTypes),
        directSubTypes: List.unmodifiable(resolvedChildren),
        allConcreteLeaves: List.unmodifiable(leaves),
        // `isSyntheticLeaf` is decided by membership in the union variant set,
        // so declaration order cannot flip it (finding: order-dependent flag).
        isSyntheticLeaf: unionVariants.containsKey(declaration.element),
        // A union VARIANT belongs to the union hierarchy even when it carries
        // no `@ZorphyUnion` of its own, so the lint can treat every member of
        // the hierarchy as in scope.
        isUnion: node.isUnion || unionVariants.containsKey(declaration.element),
      ),
    );
  }

  /// Phase 3b — walks [element]'s subtree top-down, finalizing each node:
  ///  - rewrites `superTypes` from the fully-resolved ancestor nodes (now
  ///    available because 3a resolved the whole tree), and
  ///  - stamps `root` (the root's own node, or `null` on the root itself).
  ///
  /// After recursing into children, the node is rebuilt once more so its
  /// `directSubTypes` reference the FINALIZED child nodes (each child's
  /// `superTypes` now points at this node's first-pass version — the
  /// immutable `copyWith` cannot make both sides `identical` at once, and
  /// the second rebuild is the authoritative one for the parent's edges).
  static void _finalizeNode(
    ClassElement element,
    ZorphyNodeIr? root,
    Map<ClassElement, ClassElement> parents,
    Map<ClassElement, _Declaration> resolved,
  ) {
    final declaration = resolved[element];
    if (declaration == null) return;
    final node = declaration.node;

    // Rewrite `superTypes` from the resolved ancestor nodes.
    final resolvedSuperTypes = <ZorphyNodeIr>[
      for (final superElement in _transitiveSupertypeElements(element, parents))
        if (resolved[superElement] != null) resolved[superElement]!.node,
    ];

    final stamped = node.copyWith(
      superTypes: List.unmodifiable(resolvedSuperTypes),
      root: root,
    );
    resolved[element] = _Declaration(element, stamped);

    // Recurse into children, passing this node as their `root`.
    final finalizedChildren = <ZorphyNodeIr>[];
    for (final child in node.directSubTypes) {
      final childElement = _elementForChild(child, resolved);
      if (childElement == null) {
        finalizedChildren.add(child);
        continue;
      }
      _finalizeNode(childElement, stamped, parents, resolved);
      finalizedChildren.add(resolved[childElement]!.node);
    }

    // Rebuild once more so `directSubTypes` references the finalized children.
    final finalNode = stamped.copyWith(
      directSubTypes: List.unmodifiable(finalizedChildren),
      allConcreteLeaves: List.unmodifiable(<ZorphyNodeIr>[
        for (final child in finalizedChildren)
          if (child.isConcreteLeaf) child else ...child.allConcreteLeaves,
      ]),
    );
    resolved[element] = _Declaration(element, finalNode);
  }

  /// The element whose resolved node is [child], found by className.
  static ClassElement? _elementForChild(
    ZorphyNodeIr child,
    Map<ClassElement, _Declaration> resolved,
  ) {
    for (final declaration in resolved.values) {
      if (declaration.node.className == child.className) {
        return declaration.element;
      }
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

  /// ZORPHY_E004/E005 — every `@ZorphyIntent` node's assembled payload must be
  /// safely replayable: every field type must have a canonical JSON form, and
  /// no field may be named after the hierarchy's `discriminatorKey` (it would
  /// collide with the wire tag in `toWire()`).
  ///
  /// The payload is the nearest-first walk `IntentEmitter` performs (the node's
  /// own fields, then each ancestor's), so the check sees exactly the fields the
  /// emitted `toWire`/`intentDigest` will reference.
  static void _checkIntentPayload(
    ZorphyNodeIr root,
    List<ZorphyDiagnostic> diagnostics,
  ) {
    void walk(ZorphyNodeIr node) {
      if (node.archetype == ArchetypeKind.intent) {
        final seen = <String>{};
        final payload = <ZorphyFieldIr>[
          for (final owner in <ZorphyNodeIr>[node, ...node.superTypes])
            for (final field in owner.fields)
              if (seen.add(field.name)) field,
        ];
        for (final field in payload) {
          if (field.name == node.discriminatorKey) {
            diagnostics.add(
              ZorphyDiagnostic(
                code: ZorphyDiagnosticCode.e005DiscriminatorCollision,
                nodeName: node.className,
                message:
                    'intent field "${field.name}" collides with the '
                    'discriminator key "${node.discriminatorKey}"; the wire '
                    'tag would be lost — rename the field or set a different '
                    'discriminator on @ZorphyIntent',
              ),
            );
          }
          if (!_hasCanonicalJsonForm(field.type)) {
            diagnostics.add(
              ZorphyDiagnostic(
                code: ZorphyDiagnosticCode.e004FieldNotEncodable,
                nodeName: node.className,
                message:
                    'intent field "${field.name}" has type "${field.type}" '
                    'with no canonical JSON form; an intent field must be '
                    'null, bool, num, String, Map<String, Object?> or a List '
                    'of those (DateTime and custom classes are not)',
              ),
            );
          }
        }
      }
      for (final child in node.directSubTypes) {
        walk(child);
      }
    }

    walk(root);
  }

  /// Whether [type] (source text, no trailing `?`) names one of the canonical
  /// JSON forms `ZorphyIntentDigest` can hash: a core scalar, `Object`/
  /// `dynamic`, or a `Map`/`List`/`Iterable` (whose *contents* are checked
  /// recursively at runtime). A deliberately conservative allowlist: anything
  /// not provably canonical is rejected at generation rather than trusted.
  static bool _hasCanonicalJsonForm(String type) {
    final base = type.split('<').first.trim();
    const canonical = <String>{
      'bool',
      'int',
      'double',
      'num',
      'String',
      'Object',
      'Object?',
      'dynamic',
      'Map',
      'Map<String, Object?>',
      'List',
      'Iterable',
    };
    return canonical.contains(base) || canonical.contains(type);
  }

  static String _qualifiedName(ClassElement element) {
    final name = element.name ?? '';
    final uri = element.library.uri.toString();
    return '$uri#$name';
  }

  static String _cleanName(String? name) => (name ?? '').replaceAll(r'$', '');

  static String _archetypeLabel(ArchetypeKind kind) => switch (kind) {
    ArchetypeKind.entity => 'Entity',
    ArchetypeKind.state => 'State',
    ArchetypeKind.intent => 'Intent',
    ArchetypeKind.value => 'Value',
  };
}

/// PascalCase / camelCase to snake_case, delegating to
/// `NamingUtils.toSnakeCase` so the resolver and the CLI share ONE source of
/// truth for the wire value (`ZfaButtonNode` -> `zfa_button_node`,
/// `Ui_Node` -> `ui_node`).
String snakeCaseName(String name) => NamingUtils.toSnakeCase(name);
