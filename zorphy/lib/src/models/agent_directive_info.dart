/// Internal model for agent directive data parsed from annotations.
///
/// This is the generator-internal representation. The public-facing
/// contract is [AgentDirective] in `zorphy_annotation`.

class AgentDirectiveInfo {
  /// Tool name override (null = use class name).
  final String? toolName;

  /// Tool namespace override.
  final String? toolNamespace;

  /// Tool description override.
  final String? toolDescription;

  /// Risk tier.
  final String risk;

  /// Whether the entity is excluded from tool generation.
  final bool exclude;

  /// Whether this is an internal (admin-only) entity.
  final bool internal;

  /// Per-field parameter descriptions.
  final Map<String, String> paramDescriptions;

  /// Whether any agent annotation was present (controls emission).
  final bool hasAgentAnnotations;

  /// Creates an agent directive info model.
  const AgentDirectiveInfo({
    this.toolName,
    this.toolNamespace,
    this.toolDescription,
    this.risk = 'safe',
    this.exclude = false,
    this.internal = false,
    this.paramDescriptions = const {},
    this.hasAgentAnnotations = false,
  });
}
