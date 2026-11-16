# Phase 1 — Contracts: zorphy 2.5.0 Published Contract

zorphy is a published library; its "interfaces" are (1) the package metadata consumers resolve against and (2) the stability of the code it generates. These are the contracts this release must honor. Each contract lists the observable, testable assertion.

## Contract 1 — SDK-floor contract

**Statement**: `zorphy` and `zorphy_migrator` declare `environment: sdk` admitting `>=3.11.0 <4.0.0`, and no declared dependency requires an SDK floor above 3.11.0.

**Assertion**: Parse both pubspecs; assert the sdk constraint admits 3.11.0 and rejects 3.10.9; assert `max(dependency sdk floors) <= 3.11.0`.

## Contract 2 — Output-stability contract

**Statement**: For every standard fixture, generated `.zorphy.dart` is byte-identical to the 2.4.6 golden.

**Assertion**: Existing golden/characterization tests pass with zero diff (goldens not regenerated).

## Contract 3 — Analyze-clean contract

**Statement**: Generated `.zorphy.dart` for the standard fixtures produces zero `dart analyze` diagnostics under the pinned analyzer.

**Assertion**: The analyze-clean gate test generates the fixtures, runs `dart analyze` on the output, and asserts an empty diagnostics list. Runs in the default fast tier.

## Contract 4 — Version-sync contract

**Statement**: `zorphy` and `zorphy_annotation` are both version `2.5.0`.

**Assertion**: `scripts/check_version_sync.sh` exits 0; a test reads both pubspec versions and asserts equality to `2.5.0`.

## Contract 5 — Dependency-freshness contract

**Statement**: `dart pub outdated` reports all direct dependencies up-to-date; `dart pub get --no-example` produces zero lockfile drift.

**Assertion**: Documented in quickstart.md as release-gate commands (executed in CI/local_ci), not a unit test.