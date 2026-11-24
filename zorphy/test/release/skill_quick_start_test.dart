import 'dart:io';

import 'package:test/test.dart';

/// Regression guard for issue #217: the `SKILL.md` Quick Start must teach a
/// tool that is actually registered and a CLI form a consumer can run.
///
/// The Quick Start block is isolated from the rest of the file so these
/// assertions track the onboarding commands only, not prose elsewhere.
String _quickStartSection(String skill) {
  final start = skill.indexOf('## Quick Start');
  expect(
    start,
    isNonNegative,
    reason: 'SKILL.md must have a Quick Start section',
  );
  final after = skill.indexOf('\n## ', start + 1);
  return after == -1 ? skill.substring(start) : skill.substring(start, after);
}

void main() {
  group('SKILL.md Quick Start (#217)', () {
    late String section;

    setUpAll(() {
      final skill = File('SKILL.md').readAsStringSync();
      section = _quickStartSection(skill);
    });

    test('CLI uses the consumer-resolvable executable form', () {
      // `dart run zorphy create` only resolves inside the zorphy package
      // itself; a consumer depending on zorphy_annotation must use the
      // declared `zorphy:zorphy_cli` executable.
      expect(
        section,
        contains('dart run zorphy:zorphy_cli create'),
        reason: 'Quick Start must show the consumer CLI form',
      );
      expect(
        section,
        isNot(contains('dart run zorphy create')),
        reason: '`dart run zorphy create` does not resolve for consumers',
      );
    });

    test('MCP does not teach the nonexistent generate tool', () {
      expect(
        section,
        isNot(contains('mcp__zuraffa__generate')),
        reason: 'no MCP server registers a `generate` tool',
      );
    });

    test('MCP teaches a tool that is actually registered', () {
      // zorphy's server registers `create_entity`; zuraffa's registers
      // `zuraffa_entity_create`. At least one real tool must be shown.
      final namesRealTool =
          section.contains('create_entity') ||
          section.contains('zuraffa_entity_create');
      expect(
        namesRealTool,
        isTrue,
        reason: 'Quick Start must reference a registered MCP tool',
      );
      expect(
        section,
        isNot(contains('generate_json')),
        reason: 'arg is `generateJson` (zorphy) / `json` (zuraffa)',
      );
      expect(
        section,
        contains('generateJson'),
        reason: 'zorphy `create_entity` takes a `generateJson` argument',
      );
    });
  });
}
