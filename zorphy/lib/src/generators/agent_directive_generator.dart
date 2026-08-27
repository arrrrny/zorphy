import 'package:code_builder/code_builder.dart';

import '../models/agent_directive_info.dart';
import '../ast/type_ref.dart';
import 'base_generator.dart';

/// Generates a top-level `const agentDirective = AgentDirective(...)`
/// when agent annotations are present on the annotated class.
///
/// The emitted const is consumed by zuraffa's AgentPlugin via AST scan.
class AgentDirectiveGenerator extends UniversalGenerator {
  /// Creates an agent directive generator.
  AgentDirectiveGenerator();

  @override
  List<Spec> generateSpec(GenerationContext context) {
    final info = context.metadata.agentDirectiveInfo;
    if (!info.hasAgentAnnotations) return [];

    final fields = _buildFields(info);
    final directive = Field((f) {
      f.name = 'agentDirective';
      f.modifier = FieldModifier.final$;
      f.type = referType('AgentDirective');
      f.assignment = Code(fields);
    });

    return [directive];
  }

  @override
  bool shouldGenerate(GenerationContext context) {
    return context.metadata.agentDirectiveInfo.hasAgentAnnotations;
  }

  /// Builds the AgentDirective constructor argument string.
  String _buildFields(AgentDirectiveInfo info) {
    final parts = <String>[];

    // tool parameter
    if (info.toolName != null ||
        info.toolNamespace != null ||
        info.toolDescription != null) {
      final toolParts = <String>[];
      if (info.toolName != null)
        toolParts.add("name: '${_escape(info.toolName!)}'");
      if (info.toolNamespace != null)
        toolParts.add("namespace: '${_escape(info.toolNamespace!)}'");
      if (info.toolDescription != null)
        toolParts.add("description: '${_escape(info.toolDescription!)}'");
      parts.add('tool: const AgentToolDirective(${toolParts.join(', ')}),');
    }

    // risk
    if (info.risk != 'safe') {
      parts.add('risk: AgentRiskTier.${info.risk},');
    }

    // exclude
    if (info.exclude) {
      parts.add('exclude: true,');
    }

    // internal
    if (info.internal) {
      parts.add('internal: true,');
    }

    // params
    if (info.paramDescriptions.isNotEmpty) {
      final paramEntries = info.paramDescriptions.entries
          .map((e) {
            return "'${_escape(e.key)}': const AgentParamDirective(description: '${_escape(e.value)}')";
          })
          .join(', ');
      parts.add('params: {$paramEntries},');
    }

    if (parts.isEmpty) {
      return 'const AgentDirective()';
    }
    return 'const AgentDirective(\n    ${parts.join('\n    ')}\n  )';
  }

  /// Escapes single quotes in a string.
  String _escape(String s) => s.replaceAll("'", "\\'");
}
