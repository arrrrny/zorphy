---
feature: 135-generate-decorators-on-entity
branch: feat/135-generate-decorators-on-entity
stack: dart
test_command: "cd zorphy && dart test test/generation/decorator_preservation_test.dart"
full_suite_command: "cd zorphy && dart test"
e2e_build_command: "cd zorphy/example && dart run build_runner build --delete-conflicting-outputs"
e2e_test_command: "cd zorphy && dart test test/generation/decorator_preservation_e2e_test.dart"
analyzer_command: "cd zorphy && dart analyze lib/src/models/class_metadata.dart lib/src/analysis/class_analyzer.dart lib/src/common/helpers.dart lib/src/generators/class_declaration_generator.dart test/generation/decorator_preservation_test.dart test/generation/decorator_preservation_e2e_test.dart"
status: in-progress
---

# Test List — 135: Preserve custom decorators on generated entities

Every behavior traced to a success criterion (SC) in `spec.md`. States:
`pending → red → green → refactored`. Evidence per cycle lives in
`tdd/cycle-log.md` (append-only).

## Outer (acceptance) behaviors

| ID | Behavior | Traces to | State |
|----|----------|-----------|-------|
| A1 | E2E: raw entity `@Cacheable(ttl: Duration(hours: 1)) @Zorphy(generateJson: true) abstract class $Task` generates a single concrete `class Task` preceded by `@Cacheable(ttl: Duration(hours: 1))` in the real build_runner artifact | SC-1, SC-3, US1, US3 | green |
| A2 | E2E: generated artifact contains no `@Zorphy`/`@Zorphy2` annotation on any generated class | SC-5, US4 | green |
| A3 | E2E: raw entity without custom decorators (`$Plain`) emits the generated concrete `class Plain` with no ported class-level annotation (no-op output) | SC-4, US5 | green |
| A4 | Unit: import-prefixed decorator `@dep.Tagged('x')` ports verbatim with the prefix intact (no e2e fixture carries an import prefix) | FR-6 | green |
| A5 | E2E: raw entity `$Report` with mixed decorators emits `@Throttle(30, per: Duration(seconds: 5))` then `@Audited()` in source order, ahead of the generator-added `@JsonSerializable(...)` | SC-2, SC-3 | green |
| A6 | E2E: `$$Character` (with `@Audited()`) emits `sealed class Character` carrying `@Audited()`, and `$Hero` (with `@Cacheable(ttl: Duration(minutes: 5))`) emits `class Hero` carrying it | SC-3, US1, US3 | green |

## Inner (unit) behaviors

| ID | Behavior | Traces to | State |
|----|----------|-----------|-------|
| U1 | `extractClassDecorators` returns `[]` for null element and for stub element that throws on `.metadata` | FR-5, FR-2 robustness | green |
| U2 | `extractClassDecorators` captures a custom decorator source with `@` stripped, arguments verbatim | SC-1, SC-2, FR-3 | green |
| U3 | `extractClassDecorators` filters directives `Zorphy`, `Zorphy2`, `JsonSerializable` but keeps custom ones, preserving order | SC-3, SC-5, FR-4 | green |
| U4 | Generated abstract/sealed base class carries ported decorator(s) in source order, emitted above the class declaration | SC-1, SC-3, US1 | green |
| U5 | Generated concrete `Task` carries ported decorator(s), before the generator-added `@JsonSerializable(...)` | US3 | green |
| U6 | Mixed positional+named args `@Throttle(30, per: Duration(seconds: 5))` reproduced character-for-character | SC-2, FR-3 | green |
| U7 | Const expression args `@Endpoint(const ['a','b'], name: 'x')` reproduced verbatim | SC-2, FR-3 | green |
| U8 | Parameterless decorator `@Audited` emitted without synthesised parentheses | US2.3 | green |
| U9 | Directives on the raw class never reach generated output (abstract + concrete) | SC-5, US4.1 | green |
| U10 | Empty `classDecorators` → emitted spec contains no annotation entries (byte-level no-op for decorator-free entities) | SC-4, FR-5, US5.1 | green |
| U10b | Empty-source annotation entries are skipped safely during capture | FR-2 robustness | green |
| U11 | Analyzer wiring: `ClassAnalyzer.analyze` populates `classDecorators` from real elements — covered at e2e level by A1/A4 (real build_runner pipeline resolves real annotations; unit stubs cannot host resolvable elements) | FR-1 | green (via A1, A4) |

## Notes

- Unit tests follow the repo's stub-element pattern (no `build_test` dependency).
- A1–A4 require `e2e_build_command` first; tests fail loudly with the build
  command if the artifact is missing (pattern from `issue_109_extends_test.dart`).
- Mutation spot-check (verify phase): disable the directive filter and confirm
  U3/U9/A2 fail; drop the concrete-class emission and confirm U5/A1 fail.
