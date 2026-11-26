<!-- fleet-agents-pointer:begin -->
# ⚠️ FLEET RULES — LOAD ~/.agents/AGENTS.md FIRST

Before applying any rule in this file, load and follow `~/.agents/AGENTS.md`
— the fleet-level rules file every machine carries (synced from
`arrrrny/skills`, the single source of truth, by `sync-skills` inside
`kimi-code-update`, 3x/day). It owns the fleet-wide HARD RULES: the
skills-sync rule (every merge-PR task must check the repo's exposed skills —
create or update them on exported-behavior changes — and auto-PR them to
`arrrrny/skills`), the English-only response rule, the GitHub account
spelling (`arrrrny` = a + exactly 4 r's + ny), and the machine bootstrap
contract (`arrrrny/scripts` + `arrrrny/skills`). Future fleet-wide rule
changes are made ONCE in that file — never by editing every repo. Where this
file and the fleet file disagree, the fleet file wins unless this file is
MORE restrictive for this repo.
<!-- fleet-agents-pointer:end -->

> **Fleet-governance rules:** The `misfire-rule`, `pool-pr`, `tmp-clone`,
> `local-ci`, `test-concurrency` and `dependency-bump-rule` blocks that were
> copied into this file are intentionally not duplicated in this constitution.
> They are owned by `~/.agents/AGENTS.md` (synced from `arrrrny/skills`), which
> every agent loads first per the pointer above — the local copy of those rules
> is not lost by this rewrite.
# AGENTS.md — zorphy 3.0.0-dev.3 -> 3.0.0 Closure & Emitter Improvements Constitution

> **Status:** Authoritative Remediation & Improvement Constitution for `arrrrny/zorphy` (`zorphy_annotation`, `zorphy`, `zorphy_migrator`)  
> **Baseline:** Built on empirical inspection of `zorphy` / `zorphy_annotation` `3.0.0-dev.2` (`polymorphic_class_emitter.dart`, `boundary_codec_emitter.dart:296,774`, and downstream `zuraffa#2149` analyzer output).  
> **Release Strategy:** Cut synchronized **`3.0.0-dev.3`** across all **3** packages (`zorphy_annotation`, `zorphy`, `zorphy_migrator`), verify downstream `zuraffa` v8 green, then promote all 3 packages to **`3.0.0`** final without burning `4.0.0`.

---

## 1. Empirical Evidence & New Gaps Found in `3.0.0-dev.2`

Inspection of `zorphy 3.0.0-dev.2` and downstream `zuraffa#2149` revealed three high-impact emitter gaps alongside the remaining closure items:

1. **Gap A — `@ZorphyUnion` Sealed Root Drops Variant Redirecting Factories & Root Static/Factory Members (`ZRP-008`, #271):**
   * *Evidence (`polymorphic_class_emitter.dart`):* `@ZorphyUnion()` emits `const AppFailure();`, abstract getters, final variant classes (`NetworkFailure.fromTrusted(...)`), and static `fromWire`/`toWire` on the root—but **drops** the source's redirecting factories (`factory $AppFailure.network(...) = $NetworkFailure;`) and **drops** user-declared `static` methods / body `factory` constructors (such as `AppFailure.from(error, [st])`).
   * *Impact:* Forces consumers (`AppFailure`, `CachePolicy`, `AsyncSlice`, `MockScenarioPolicy`) into verbose variant-class imports or hand-written top-level wrapper functions, breaking Dart 3 dot-shorthand (`.network(...)`, `.staleWhileRevalidate(...)`, `.ready(...)`).
   * *Fix:* Emit `const factory AppFailure.network({...}) = NetworkFailure.fromTrusted;` redirecting factories on the generated `sealed` root for every variant, AND copy user-declared `static` methods and body `factory` constructors from `$Union` onto the generated `sealed` root (rewriting `$Variant` -> `Variant`).
2. **Gap B — `BoundaryCodecEmitter` Skips Generic Nodes Instead of Emitting Codec-Parameterized `toWire`/`fromWire` (`ZRP-009`, #272):**
   * *Evidence (`boundary_codec_emitter.dart:296,774`):* `if (current.typeParameters.isNotEmpty) return; // "a generic node … receives no codec"`.
   * *Impact:* Every generic wrapper class (`QueryParams<T>`, `CreateParams<T>`, `UpdateParams<T>`, `AsyncSlice<T>`) loses `toWire` and `fromWire`, forcing downstream packages to hand-write serialization boilerplate.
   * *Fix:* For generic nodes `<T, ...>`, emit **codec-parameterized** `Map<String, Object?> toWire(Map<String, Object?> Function(T) encodeT)` and `static Foo<T> fromWire<T>(Map<String, Object?> raw, ZorphyBoundaryResult<T> Function(Map<String, Object?>) decodeT)` (with built-in primitive fast paths when `T` is bounded to `String`/`int`/`double`/`bool`).
3. **Gap C — Nullable Generic Type Parameters Emit `T?` Causing `unnecessary_question_mark` (`ZRP-010`, #273):**
   * *Evidence (`toggle_params.part.dart` in `zuraffa#2149`):* For `class ToggleParams<I>` (where `I`'s implicit bound `Object?` is already nullable), emitting `I? id` triggers Dart analyzer warning `unnecessary_question_mark`, failing `dart analyze --fatal-infos`.
   * *Fix:* Check `typeSystem.isNullable(typeParam.bound)` in the emitter; when `true`, emit `I fieldName` instead of `I? fieldName`.
4. **Closure Items and Their Tracking Issues (`ZRP-001` – `ZRP-011`):**
   * *Shipped in the `3.0.0-dev.2` batch:* `ZRP-001` `<Entity>Fields` (`ZorphyField<T, V>`) + `ZorphyFilter<T>` / `ZorphySort<T>` (#247); `ZRP-002` `ZorphyPatch<T>` `changedPaths`, `conflictingPaths()`, `composePatches()`, and atomic list replacement (#248); `ZRP-003` `ZorphyEntityDescriptor<T>` (`<Entity>.descriptor`) for reflection-free generic `ZfaStore` (#251); `ZRP-004` `.zorphy.dart` directive stripping and file deletion, shipped as `dart run zorphy:migrate_v3` inside the `zorphy` package (#249); `ZRP-005` 3-package SemVer prerelease sync & publish (#250); `ZRP-006` `README.md` `#v3-migration`, website pages, `#236` notes, and deterministic structural CI guards (#252).
   * *Open in the `3.0.0-dev.3` batch (epic #270):* `ZRP-008` (#271), `ZRP-009` (#272), `ZRP-010` (#273), `ZRP-011` codemod and `package:meta` gaps reported by the downstream `zuraffa#2149` adoption (#274), the `ZRP-006` follow-up docs pass (#275), and `ZRP-007` publishing `3.0.0-dev.3` (#276). Promotion to `3.0.0` final stays on #254.

---

## 2. Workspace Package Topology (All 3 Packages Version-Locked)

```text
zorphy/ (monorepo)
├── zorphy_annotation/    # Annotations, ZorphyField<T, V>, ZorphyFilter, ZorphySort, ZorphyEntityDescriptor<T>, ZorphyBoundaryResult<T>
├── zorphy/               # 100% code_builder AST generator (polymorphic_class_emitter, boundary_codec_emitter, fields, patch, descriptor)
├── zorphy_migrator/      # Codemod for legacy freezed / @Zorphy2 sources (the v2 -> v3 `migrate_v3` codemod ships in the `zorphy` package)
├── scripts/
│   ├── check_version_sync.sh # Enforces identical versions AND matching zorphy_annotation constraints across ALL 3 packages
│   └── publish.sh            # Publishes zorphy_annotation -> zorphy -> zorphy_migrator (supports -dev.N prereleases; --dry-run prints the plan and changes nothing)
└── website/                  # Documentation site (all v2 guides updated to v3)
```

---

## 3. Non-Negotiable Rules

1. **100% `package:code_builder` Emission — ZERO `StringBuffer`.**
2. **Clean `dart analyze --fatal-infos` on Generated `.g.dart`:** Emitted code must never trigger `unnecessary_question_mark`, `unused_import`, or `unnecessary_cast`.
3. **All 3 Packages Version-Locked:** Never publish `zorphy_annotation` and `zorphy` without `zorphy_migrator` at the exact same version string (`3.0.0-dev.3` -> `3.0.0`).
4. **Deterministic CI Assertions Only:** Gate CI on structural invariants (`changedPaths`, `conflictingPaths`, `resolvePath`, zero `dart:mirrors`) rather than wall-clock latency under host load.
