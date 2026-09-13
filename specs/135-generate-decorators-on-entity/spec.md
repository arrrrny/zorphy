# Feature Specification: Preserve custom decorators on generated entities

**Feature Branch**: `feat/135-generate-decorators-on-entity`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "Zorphy code generator recognizes custom decorators on raw entity classes and ports them onto generated entity classes; decorator arguments (positional, named, const) are preserved; no behavioural change when no custom decorators are present."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Custom decorator survives generation (Priority: P1)

A developer writes a raw entity class annotated with a custom decorator (for example `@Cacheable(ttl: Duration(hours: 1))`) in addition to `@Zorphy`. When zorphy generates the entity classes, the generated abstract entity class carries the custom decorator, so downstream layers can read the same contract decorator from the generated entity instead of only from the user-authored class.

**Why this priority**: This is the core value of the feature. Without decorator preservation, the contract between layers expressed through decorators is silently lost during generation, which is the bug being fixed.

**Independent Test**: Run the generator over a library containing a raw entity with one custom decorator; assert the emitted output contains that decorator applied to the generated abstract entity class.

**Acceptance Scenarios**:

1. **Given** a raw entity `@Cacheable(ttl: Duration(hours: 1)) @Zorphy(generateJson: true) abstract class Task`, **When** the zorphy generator runs, **Then** the generated abstract class `$Task` is preceded by the annotation `@Cacheable(ttl: Duration(hours: 1))`.
2. **Given** a raw entity with a parameterless custom decorator such as `@Immutable()`, **When** the generator runs, **Then** the generated abstract class carries `@Immutable()`.
3. **Given** a raw entity with multiple custom decorators, **When** the generator runs, **Then** all of them appear on the generated abstract class in their original source order.

---

### User Story 2 - Decorator arguments are preserved verbatim (Priority: P1)

A developer writes a custom decorator with arguments — positional, named, nested const expressions, or a mix. The generated output reproduces those arguments exactly as written, because the generator ports the decorator source text rather than re-synthesising it.

**Why this priority**: A decorator that loses its arguments changes semantics (e.g. a cache TTL). Argument fidelity is what makes porting safe.

**Independent Test**: Run the generator over a raw entity whose decorator mixes positional and named arguments and nested const expressions; assert the emitted annotation text matches the source text character-for-character.

**Acceptance Scenarios**:

1. **Given** `@Throttle(30, per: Duration(seconds: 5))`, **When** the generator runs, **Then** the emitted annotation is `@Throttle(30, per: Duration(seconds: 5))` — positional argument and named argument both present.
2. **Given** `@Endpoint(const ['a', 'b'], name: 'x')`, **When** the generator runs, **Then** the emitted annotation preserves the const list literal and the named argument exactly.
3. **Given** a decorator with no arguments `@Audited`, **When** the generator runs, **Then** the emitted annotation is `@Audited` with no synthesised empty parentheses.

---

### User Story 3 - Generated concrete entity also carries the decorator (Priority: P2)

The generated output contains both an abstract contract class (`$Task`) and a concrete implementation class (`Task`). The custom decorator is ported to the concrete generated class as well, so tooling reading either generated artefact observes the same contract.

**Why this priority**: Secondary to US1 because the abstract contract class is the primary carrier of layer contracts; porting to the concrete class is completeness so no generated artefact diverges.

**Independent Test**: Run the generator over a raw entity with a custom decorator; assert the emitted concrete class also carries the decorator.

**Acceptance Scenarios**:

1. **Given** a raw entity `@Cacheable(...) abstract class Task`, **When** the generator runs, **Then** the generated concrete `class Task` is also preceded by `@Cacheable(...)`.
2. **Given** the concrete class also receives the generator-added `@JsonSerializable(...)` annotation, **When** both are present, **Then** the custom decorator and `@JsonSerializable(...)` coexist on the concrete class without corrupting either annotation.

---

### User Story 4 - Generator directives are not re-emitted (Priority: P2)

The generator's own directive annotations (`@Zorphy`, `@Zorphy2`) are consumed as instructions and must NOT be copied onto generated classes: generated classes live in a part of the same library, so a re-emitted `@Zorphy` on `$Task` would be picked up by the next build pass and generate a recursive `$$Task`, `$$$Task`, ... cascade. `@JsonSerializable` is likewise excluded from class-level porting because the generator already synthesises it on the concrete class and re-emitting it on abstract generated classes would change json_serializable's build behaviour.

**Why this priority**: This is a correctness guardrail rather than user-facing value, but it is what makes the feature safe to ship; it ranks with the core story because breaking the build would outweigh the feature's benefit.

**Independent Test**: Run the generator over a raw entity with `@Zorphy` plus a custom decorator; assert the emitted output contains the custom decorator and contains no `@Zorphy` annotation on generated classes.

**Acceptance Scenarios**:

1. **Given** a raw entity `@Zorphy(generateJson: true) abstract class Task`, **When** the generator runs, **Then** neither `$Task` nor the concrete `Task` carries an `@Zorphy` annotation.
2. **Given** a second build pass over a library whose generated part file exists on disk, **When** the generator runs again, **Then** generation output is stable (no `$$Task` class appears, no duplicate class errors).

---

### User Story 5 - No behavioural change without custom decorators (Priority: P1)

Every existing zorphy user with plain `@Zorphy` entities gets byte-identical generated output after this change. When the raw class carries no class-level annotations beyond `@Zorphy`, the generator emits exactly what it emitted before.

**Why this priority**: Non-regression is the hard constraint of the issue; the feature must be a pure additive capability.

**Independent Test**: Generate output for a library with no custom decorators before and after the change; assert the outputs are identical. Additionally, run the existing test suite unchanged.

**Acceptance Scenarios**:

1. **Given** a raw entity with only `@Zorphy(...)` and no other class-level annotations, **When** the generator runs, **Then** the generated output contains no class-level annotations beyond what the generator already emitted before this feature (e.g. `@JsonSerializable(...)` on the concrete class when JSON generation is enabled).
2. **Given** the full existing test suite, **When** it runs after the change, **Then** no previously passing test fails.

## Requirements

### Functional Requirements

- **FR-1**: The generator SHALL inspect the class-level metadata (annotations/decorators) of every raw entity class it processes.
- **FR-2**: The generator SHALL port each non-directive class-level decorator to the generated abstract entity class and the generated concrete entity class, preserving source order.
- **FR-3**: The generator SHALL preserve decorator arguments verbatim: positional arguments, named arguments, default-value omissions, trailing commas absence, and const expressions are reproduced exactly as in the source.
- **FR-4**: The generator SHALL exclude its own directive annotations (`Zorphy`, `Zorphy2`) and `JsonSerializable` from class-level porting (see US4).
- **FR-5**: When a raw class carries no class-level decorators beyond directives, the generator SHALL produce output identical to its pre-feature output (no added blank lines, no empty annotation slots).
- **FR-6**: Decorators whose identifier is import-prefixed (e.g. `@meta.Cacheable(...)`) SHALL be ported with the prefix intact, since generated output is a part of the same library and resolves the same import prefixes.
- **FR-7**: The feature SHALL be implemented entirely within the code generator package (`zorphy`); the `zorphy_annotation` package, the runtime behaviour of generated code, and the `@Zorphy` annotation contract SHALL NOT change.

### Key Entities

- **Raw entity class**: user-authored abstract class annotated with `@Zorphy(...)`; source of truth for decorators.
- **Generated abstract entity class**: the `$`-prefixed abstract class emitted by `ClassDeclarationGenerator._buildAbstractClassSpec`; porting target.
- **Generated concrete entity class**: the implementation class emitted by `ClassDeclarationGenerator._buildConcreteClassSpec`; porting target.
- **Directive annotation**: an annotation consumed by a build step (`Zorphy`, `Zorphy2`, `JsonSerializable`) that must not be re-emitted at class level.

## Success Criteria *(measurable)*

- **SC-1**: A raw entity decorated with `@Cacheable(ttl: Duration(hours: 1))` produces a generated abstract class preceded by exactly `@Cacheable(ttl: Duration(hours: 1))` (automated assertion).
- **SC-2**: A decorator mixing positional and named arguments (`@Throttle(30, per: Duration(seconds: 5))`) is reproduced character-for-character in the generated output (automated assertion).
- **SC-3**: A raw entity with N≥1 custom decorators yields generated abstract and concrete classes each carrying all N decorators in source order (automated assertion).
- **SC-4**: For inputs with zero custom decorators, the generated output is unchanged relative to the pre-feature generator (automated no-op assertion plus full existing test suite green).
- **SC-5**: Generated output for the documented examples contains no `@Zorphy`/`@Zorphy2` annotation on any generated class (automated assertion).
- **SC-6**: `dart analyze` reports no new warnings on changed files; the new tests and the existing suite pass.

## Assumptions and Deliberate Deviations

- The issue's illustrative example shows `@Zorphy(generateJson: true)` re-emitted on the generated `$Task`. This spec deliberately deviates: re-emitting the generator directive would make the generated class itself look like an input entity on the next build pass (generated classes are elements of the same library), triggering a recursive `$$Task` generation cascade. Directives are therefore consumed, not ported (US4). All *custom* decorators, which is what the feature is about, are preserved.
- Decorators are ported as source text captured from the analyzer (`ElementAnnotation.toSource()` with the leading `@` stripped; code_builder re-adds `@` when emitting). This guarantees argument fidelity (SC-2) and import-prefix safety (FR-6) without re-synthesising ASTs.
- Field-level and method-level annotations are already handled by existing zorphy mechanisms (`@JsonKey`, additional annotations); this feature covers **class-level** decorators only.
