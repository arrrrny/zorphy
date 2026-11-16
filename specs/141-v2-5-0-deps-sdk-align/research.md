# Phase 0 — Research: zorphy 2.5.0 SDK-Floor & Dependency Alignment

All NEEDS CLARIFICATION items from the plan's Technical Context are resolved here.

## D1 — Published SDK floor = `>=3.11.0` (not `^3.13.0`, not `>=3.8.0`)

**Decision**: Set `environment: sdk` to `">=3.11.0 <4.0.0"` in `zorphy` and `zorphy_migrator`.

**Rationale**: Verified from the pub.dev API (`/api/packages/<pkg>` → `pubspec.environment.sdk`):
- analyzer `14.0.0` → `^3.11.0` (14.1–14.5 also `^3.11.0`); only the **locked** `14.7.0` → `^3.13.0`.
- source_gen `4.3.1` → `^3.11.0`; build `5.0.0` → `^3.11.0`; dart_style `3.1.14` → `^3.11.0`; code_builder `4.13.0` → `^3.10.0`.
- A Dart 3.11 consumer can resolve the whole declared set (picking analyzer 14.0.0–14.5.x inside `^14.0.0`). The binding minimum is therefore 3.11.0. This matches the sibling `zuraffa` pubspec policy (its floor stays `^3.11.0` for the same reason).

**Alternatives considered**:
- `^3.13.0` — rejected: that is only the locked analyzer 14.7.0's floor; it would break Dart 3.11/3.12 consumers who legitimately resolve an older analyzer within `^14.0.0`.
- Keep `>=3.8.0` — rejected: unsatisfiable (no declared dependency supports 3.8–3.10) and misleading.

## D2 — Do NOT tighten dependency constraints

**Decision**: Leave `analyzer`, `build`, `source_gen`, `code_builder`, `dart_style`, `build_runner` constraints exactly as in 2.4.6. Only `environment: sdk` and `version` change.

**Rationale**: Repository `dependency-bump-rule` — "Do not raise every constraint to the locked version… preserve the supported lower bound otherwise." The declared constraints already resolve to the latest majors (`dart pub outdated` = up-to-date). Tightening (e.g. `^14.0.0` → `^14.7.0`) would narrow consumer compatibility for no benefit.

**Alternatives considered**: align constraints to locked majors — rejected per the rule.

## D3 — Lockfile stays committed and drift-free

**Decision**: Keep `pubspec.lock` committed; verify `dart pub get --no-example` produces zero lockfile changes (use `--no-example` because `example/` depends on the Flutter SDK).

**Rationale**: CI resolves with `--enforce-lockfile`; a drifted lock must fail loudly (repo policy). The lock is the tested baseline.

**Alternatives considered**: delete/ignore lock — rejected (repo commits locks intentionally).

## D4 — Analyze-clean regression gate design

**Decision**: Add a test in the **default fast tier** that (a) generates `.zorphy.dart` for the standard fixture entities into a temp dir, (b) runs `dart analyze` on the generated files using the pinned analyzer (spawned child process, matching existing `spawn`-tagged suites), and (c) asserts zero diagnostics. Reuse the repo's existing "generate then analyze" test pattern if one exists; otherwise spawn `dart analyze` on the generated temp package.

**Rationale**: analyzer 14.6 replaced `undefined_getter` with the `undefined_*_read`/`undefined_*_write` family — the exact breakage that hit `zuraffa` (#1980). Goldens alone do not re-analyze output under the new diagnostics; a live analyze gate is the durable guard that keeps 2.5.0 "aligned to latest".

**Alternatives considered**:
- Rely on downstream consumer builds — rejected (reactive).
- Golden-file comparison only — rejected (does not exercise the new diagnostics).

## D5 — Byte-identical output verification

**Decision**: Prove no output change by running the existing golden/characterization tests unchanged and asserting zero diffs. Do NOT regenerate goldens.

**Rationale**: 2.5.0 must be non-breaking; regenerating goldens would mask accidental drift.

**Alternatives considered**: regenerate goldens — rejected.

## D6 — Version bump scope

**Decision**: `zorphy` 2.4.6 → 2.5.0 **and** `zorphy_annotation` 2.4.6 → 2.5.0 (parity enforced by `scripts/check_version_sync.sh`). `zorphy_migrator` stays on its own 2.0.0 line but receives the same SDK-floor fix.

**Rationale**: `check_version_sync.sh` compares only zorphy vs zorphy_annotation. The migrator is independently versioned.

**Alternatives considered**: bump migrator to 2.5.0 — rejected (separate line, not required, would be misleading).

## D7 — Semver treatment of the floor change

**Decision**: Treat `>=3.8.0 → >=3.11.0` as a non-breaking correctness fix and ship as **2.5.0 (MINOR)**; document clearly in the CHANGELOG.

**Rationale**: Dart 3.8–3.10 consumers could not resolve zorphy 2.4.6 anyway (no declared dependency supports those SDKs), so raising the floor breaks no working consumer. This matches the user's two-part release intent (2.5.0 non-breaking, 3.0.0 breaking).

**Alternatives considered**: classify as MAJOR — rejected (no practical breakage; user's explicit intent).

## D8 — No `writeDescriptions` / output-affecting API adoption in 2.5.0

**Decision**: Do not adopt `PartBuilder(writeDescriptions: false)` or any API that alters emitted headers/bytes. Deferred to 3.0.0.

**Rationale**: Such changes would violate the byte-identical requirement (FR-006).

**Alternatives considered**: adopt now — rejected (output drift).