# Phase 1 — Quickstart: validating zorphy 2.5.0

Run from the repository root (`/Users/arrrrny/Developer/zorphy`) unless noted. These are the end-to-end checks that prove the release is correct and non-breaking. All must pass before opening the PR.

## Prerequisites

- Dart SDK ≥ 3.13 on the dev/CI machine (to honor the committed lock's analyzer 14.7.0). The *published* floor is 3.11.0.
- `--no-example` for resolution: the `example/` packages depend on the Flutter SDK.

## 1. Lockfile is the tested baseline (zero drift)

```bash
(cd zorphy_annotation && dart pub get) &&
(cd zorphy && dart pub get --no-example) &&
(cd zorphy_migrator && dart pub get) &&
git diff --exit-code -- zorphy/pubspec.lock zorphy_annotation/pubspec.lock zorphy_migrator/pubspec.lock
```
**Expected**: no diff (exit 0). Each resolution is chained with `&&`, so a
failed `dart pub get` stops the check instead of letting `git diff` report a
clean tree.

## 2. Direct dependencies are current

```bash
(cd zorphy && dart pub outdated)
```
**Expected**: "direct dependencies: all up-to-date."

## 3. Core + migrator analyze clean

```bash
(cd zorphy && dart analyze lib)
(cd zorphy_migrator && dart analyze lib)
```
**Expected**: "No issues found!" for both.

## 4. Full suite green (includes the new analyze-clean gate)

```bash
(cd zorphy && dart test --concurrency=2)
```
**Expected**: all tests pass. The analyze-clean gate generates `.zorphy.dart` for the standard fixtures, analyzes the output, and asserts zero diagnostics.

## 5. Version sync

```bash
./scripts/check_version_sync.sh
```
**Expected**: "OK: both packages at version 2.5.0".

## 6. Generated output is byte-identical to 2.4.6

Covered by the golden/characterization tests in step 4 (they must pass with no golden regeneration). If a dedicated diff check exists, run it; otherwise the unchanged goldens are the proof.

## 7. Local CI gate

```bash
RUNNER_TEMP="${TMPDIR:-/tmp}" ./scripts/local_ci.sh
```
**Expected**: exit 0 (every executed step passes).

## Notes / deferred

See [research.md](./research.md) D1–D8 for the decisions behind these checks. Shared parts, primary constructors, migrator AST rework, and the lean-flavor migration tool are **out of scope** for 2.5.0 (3.0.0).