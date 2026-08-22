/// Agent-centric architecture annotations for zorphy.
///
/// These annotations let developers declaratively control how zuraffa's
/// AgentPlugin exposes entities/usecases as MCP tools. Annotations
/// compile into an [AgentDirective] const in the generated `.zorphy.dart`
/// file, which AgentPlugin consumes at analysis time.
///
/// See: https://github.com/arrrrny/zorphy/issues/114

// ─────────────────────────────────────────────────────────────────
// Risk tier
// ─────────────────────────────────────────────────────────────────

/// Risk tier for agent-exposed tools.
///
/// - [safe]: no confirmation required.
/// - [confirm]: requires UI confirmation before execution.
/// - [admin]: restricted to admin users; excluded from public manifests.
enum AgentRiskTier { safe, confirm, admin }

// ─────────────────────────────────────────────────────────────────
// Class-level annotations
// ─────────────────────────────────────────────────────────────────

/// Override the generated MCP tool identity for an entity or usecase.
///
/// ```dart
/// @AgentTool(name: 'create_user', namespace: 'users', description: 'Create a new user')
/// @zorphy
/// abstract class $CreateUser { ... }
/// ```
class AgentTool {
  /// Optional tool name override. When null, the class name is used.
  final String? name;

  /// Optional namespace grouping for the tool (e.g. `'users'`).
  final String? namespace;

  /// Optional description shown in the tool schema.
  final String? description;

  /// Creates an agent tool identity override.
  const AgentTool({this.name, this.namespace, this.description});
}

/// Declares the risk tier for an agent-exposed entity or usecase.
///
/// ```dart
/// @AgentRisk(AgentRiskTier.confirm)
/// @zorphy
/// abstract class $DeleteAccount { ... }
/// ```
class AgentRisk {
  /// The risk tier for this entity/usecase.
  final AgentRiskTier value;

  /// Creates an agent risk annotation.
  const AgentRisk(this.value);
}

/// Sugar for `@AgentRisk(AgentRiskTier.admin)`.
///
/// Marks the entity/usecase as internal: restricted to admin users
/// and excluded from public manifests.
///
/// ```dart
/// @AgentInternal
/// @zorphy
/// abstract class $SystemConfig { ... }
/// ```
class AgentInternal {
  /// Creates an agent-internal annotation.
  const AgentInternal();
}

/// Marks an entity or usecase so it never becomes an MCP tool.
///
/// ```dart
/// @AgentExclude
/// @zorphy
/// abstract class $InternalHelper { ... }
/// ```
class AgentExclude {
  /// Creates an agent-exclude annotation.
  const AgentExclude();
}

// ─────────────────────────────────────────────────────────────────
// Field-level annotations
// ─────────────────────────────────────────────────────────────────

/// Provides a description for a field when it appears as a tool parameter
/// in the MCP inputSchema.
///
/// ```dart
/// @AgentToolParam(description: 'The user\'s display name')
/// String get displayName;
/// ```
class AgentToolParam {
  /// Description for this parameter in the tool schema.
  final String? description;

  /// Creates an agent tool parameter annotation.
  const AgentToolParam({this.description});
}

// ─────────────────────────────────────────────────────────────────
// Directive data class (emitted as const in generated files)
// ─────────────────────────────────────────────────────────────────

/// Typed directive consumed by zuraffa's AgentPlugin.
///
/// Zorphy emits a top-level `const agentDirective = AgentDirective(...)`
/// in the generated `.zorphy.dart` file when any agent annotation is
/// present on the abstract class. AgentPlugin scans for this const
/// via AST analysis.
///
/// When no agent annotations are present, no directive is emitted.
class AgentDirective {
  /// Tool identity override (null when not annotated with @AgentTool).
  final AgentToolDirective? tool;

  /// Risk tier for the entity/usecase.
  final AgentRiskTier risk;

  /// Whether the entity/usecase is excluded from tool generation.
  final bool exclude;

  /// Whether this is an internal (admin-only) entity/usecase.
  final bool internal;

  /// Per-field parameter descriptions, keyed by field name.
  final Map<String, AgentParamDirective> params;

  /// Creates an agent directive.
  const AgentDirective({
    this.tool,
    this.risk = AgentRiskTier.safe,
    this.exclude = false,
    this.internal = false,
    this.params = const {},
  });
}

/// Tool identity information within an [AgentDirective].
class AgentToolDirective {
  /// Optional tool name override.
  final String? name;

  /// Optional namespace grouping.
  final String? namespace;

  /// Optional tool description.
  final String? description;

  /// Creates an agent tool directive.
  const AgentToolDirective({this.name, this.namespace, this.description});
}

/// Per-parameter metadata within an [AgentDirective].
class AgentParamDirective {
  /// Description for this parameter in the tool schema.
  final String? description;

  /// Creates an agent param directive.
  const AgentParamDirective({this.description});
}
