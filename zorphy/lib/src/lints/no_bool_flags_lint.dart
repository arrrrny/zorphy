/// `ZORPHY_LINT_NO_BOOL_FLAGS` — reject behavioral mode switches and
/// lifecycle flags modelled as booleans (ISSUE-005, arrrrny/zorphy#180).
///
/// A boolean that selects BEHAVIOUR, or that narrates a lifecycle, is the
/// shape the v3 archetypes exist to delete:
///
/// * `isLoading` / `hasError` on a `@ZorphyState` re-introduces the
///   null-flag matrix that `AsyncSlice<T>` replaces with a closed union —
///   every consumer then has to remember which combination is impossible;
/// * `forceRefresh` / `silent` / `skipValidation` on a `@ZorphyIntent`
///   collapses two distinct commands into one node whose meaning depends on
///   its own payload, so a replay cannot be read off the type.
///
/// Both are rejected at GENERATION time with a message naming the field and
/// the replacement, because the alternative — emit, ship, and discover the
/// ambiguity at runtime — is exactly the failure the rule exists to prevent.
///
/// The escape hatch is `@ZorphyDomainBool()`: a genuine domain boolean
/// (`Product.inStock`, `InteractiveUiNode.enabled`) is not a flag, and its
/// author says so once, at the declaration.
///
/// The rule is deliberately name-based and archetype-scoped:
///
/// * `@ZorphyState` and `@ZorphyIntent` nodes are checked everywhere in their
///   hierarchies, and every member of a `@ZorphyUnion` hierarchy is checked —
///   the union exists to replace exactly the flags its variants must not carry;
/// * a plain `@ZorphyEntity` / `@ZorphyValue` hierarchy is NOT checked: a
///   boolean on an entity or a value is a domain fact by construction, so no
///   annotation is needed there;
/// * a non-`bool` field is never a match (`String get isLoading` is allowed);
/// * the behavioral set matches by PREFIX (`force*`, `skip*`, `bypass*`), so
///   `forceRefresh` and `forceReload` are both caught, while `reinforced` is
///   not.
///
/// Nothing here emits code: the checks are pure data over [PolymorphicIr] so
/// they can be unit-tested without a build step.
library;

import 'package:source_gen/source_gen.dart';

import '../parser/polymorphic_ir.dart';

/// Rejects behavioral/lifecycle boolean flags across the v3 archetypes.
///
/// See the library doc for the rule set and its rationale.
final class NoBoolFlagsLint {
  const NoBoolFlagsLint._();

  /// The stable diagnostic code this rule emits — `ZORPHY_LINT_NO_BOOL_FLAGS`.
  static const String code = 'ZORPHY_LINT_NO_BOOL_FLAGS';

  /// Lifecycle names that describe an `AsyncSlice<T>` state on the wire.
  ///
  /// A state (or union variant) carrying one has flattened a union back into
  /// a flag matrix.
  static const Set<String> lifecycleFlags = <String>{
    'isLoading',
    'isFetching',
    'isCreating',
    'isUpdating',
    'isDeleting',
    'hasError',
    'isError',
  };

  /// Behavioral mode-switch names that select a variant of a command.
  ///
  /// These are exact names; the prefixes below are matched with
  /// [String.startsWith].
  static const Set<String> behavioralFlags = <String>{
    'isRetry',
    'silent',
    'noCache',
  };

  /// Prefixes that make a name a behavioral mode switch (`forceRefresh`).
  static const List<String> behavioralPrefixes = <String>[
    'force',
    'skip',
    'bypass',
  ];

  /// Every flag this rule rejects in [ir], in discovery order.
  ///
  /// The walk is depth-first over each root's subtree, and each field is
  /// checked against the archetype of the node that DECLARES it — a subtype of
  /// a state hierarchy is itself checked, so a flag introduced one level down
  /// is caught where it was written.
  static List<ZorphyDiagnostic> check(PolymorphicIr ir) {
    final diagnostics = <ZorphyDiagnostic>[];
    final visited = <String>{};

    void walk(ZorphyNodeIr node) {
      // A node is reachable twice in a multi-root graph; report it once.
      if (!visited.add(node.className)) return;
      if (_isChecked(node)) {
        for (final field in node.fields) {
          if (!field.isBool || field.isDomainBool) continue;
          if (lifecycleFlags.contains(field.name)) {
            diagnostics.add(
              ZorphyDiagnostic(
                code: ZorphyDiagnosticCode.lintNoBoolFlags,
                nodeName: node.className,
                message: _lifecycleMessage(node, field.name),
              ),
            );
          } else if (_isBehavioralFlag(field.name)) {
            diagnostics.add(
              ZorphyDiagnostic(
                code: ZorphyDiagnosticCode.lintNoBoolFlags,
                nodeName: node.className,
                message: _behavioralMessage(node, field.name),
              ),
            );
          }
        }
      }
      for (final child in node.directSubTypes) {
        walk(child);
      }
    }

    for (final root in ir.roots) {
      walk(root);
    }
    return diagnostics;
  }

  /// Throws an actionable [InvalidGenerationSourceError] when [ir] violates
  /// the rule, and returns normally otherwise.
  ///
  /// The generator calls this before emitting, so a flagged hierarchy fails
  /// generation instead of producing a node whose booleans are meaningless.
  static void enforce(PolymorphicIr ir) {
    final hits = check(ir);
    if (hits.isEmpty) return;
    throw InvalidGenerationSourceError(
      hits.map((hit) => hit.render()).join('\n'),
      todo:
          'Model the variants as polymorphic subtypes (or an AsyncSlice<T> '
          'state) instead of boolean flags, or annotate a genuine domain '
          'boolean with @ZorphyDomainBool().',
    );
  }

  /// Whether [node]'s booleans are in scope.
  ///
  /// Entities and plain values are exempt by design: a boolean on them is a
  /// domain fact, and demanding an annotation for `inStock` would make the
  /// escape hatch the rule. A union hierarchy IS in scope even though
  /// `@ZorphyUnion` lowers to [ArchetypeKind.value] — the union is the
  /// replacement the rule points authors at, so its members must be clean.
  static bool _isChecked(ZorphyNodeIr node) => switch (node.archetype) {
    ArchetypeKind.state || ArchetypeKind.intent => true,
    ArchetypeKind.value => node.isUnion,
    ArchetypeKind.entity => false,
  };

  static bool _isBehavioralFlag(String name) =>
      behavioralFlags.contains(name) || behavioralPrefixes.any(name.startsWith);

  static String _lifecycleMessage(ZorphyNodeIr node, String field) =>
      'boolean "$field" on ${node.className} is a lifecycle flag; model the '
      'pending, ready and failed variants as AsyncSlice<T> (or as polymorphic '
      'subtypes) instead of flags, or annotate a genuine domain boolean with '
      '@ZorphyDomainBool()';

  static String _behavioralMessage(ZorphyNodeIr node, String field) =>
      'boolean "$field" on ${node.className} is a behavioral mode switch; a '
      'command that behaves differently must be a distinct polymorphic subtype '
      '(e.g. ForceRefreshProducts), not a flag — or annotate a genuine domain '
      'boolean with @ZorphyDomainBool()';
}
