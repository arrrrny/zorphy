# Plan: zorphy master-merge CI — curated individual PRs with tests

## Context

The user wants to establish a CI gate for zorphy where every PR to master goes through:
- Individual review (kimi.com)
- Full test suite
- CI green before merge

**Current state** (verified):
- Default branch: `master` (already correct)
- Development branch: Does NOT exist on remote (404) — already cleaned up
- Existing CI (`.github/workflows/dart.yml`): Has analyze, test, analyzer_compat, migrator jobs
- Test suite: 275 passing, 2 failing (setUpAll fixture issues)
- Formatting: 81 files not properly formatted
- Analysis: 23 issues in example/tool/issue_131_behavior_check.dart

## Changes Required

### 1. Update CI Workflow (`.github/workflows/dart.yml`)

**Remove `development` from triggers:**
```yaml
on:
  push:
    branches: [master]
  pull_request:
    branches: [master]
```

**Add formatting check job:**
```yaml
format:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: dart-lang/setup-dart@v1
      with:
        sdk: stable
    - name: Check formatting
      run: dart format --output=none --set-exit-if-changed .
      working-directory: zorphy
```

**Add explicit build_runner smoke test job:**
```yaml
build_runner_smoke:
  runs-on: ubuntu-latest
  needs: version_sync
  steps:
    - uses: actions/checkout@v4
    - uses: dart-lang/setup-dart@v1
      with:
        sdk: stable
    - name: Install dependencies (zorphy_annotation)
      run: dart pub get
      working-directory: zorphy_annotation
    - name: Install dependencies (zorphy)
      run: dart pub get
      working-directory: zorphy
    - name: Install dependencies (example)
      run: dart pub get
      working-directory: zorphy/example
    - name: Run build_runner (example)
      run: dart run build_runner build --delete-conflicting-outputs
      working-directory: zorphy/example
    - name: Verify generated code analyzes clean
      run: dart analyze
      working-directory: zorphy/example
```

**Update analyze_and_test to depend on format:**
```yaml
analyze_and_test:
  runs-on: ubuntu-latest
  needs: [version_sync, format]
```

### 2. Fix Existing Issues

**Fix 2 failing tests:**
- `test/generation/interface_copywithfield_test.dart` (setUpAll)
- `test/generation/issue_131_copywithfield_test.dart` (setUpAll)
- Root cause: Missing generated fixtures (need to run build_runner first)

**Fix 23 dart analyze issues:**
- All in `example/tool/issue_131_behavior_check.dart`
- Missing type imports for `WalkthroughStep`, `ProgressBox`

**Fix formatting:**
- Run `dart format .` in zorphy directory (81 files need reformatting)

### 3. Update AGENTS.md

Add branch strategy section:
```markdown
## Branch Strategy

- **Default base for all PRs:** `master`
- **Feature/fix branches:** Branch off master → PR to master
- **development branch:** Scratch/backlog only (optional); NOT a merge target
- **Release flow:** Merge to master with version bump + CHANGELOG = release
- **CI requirements:** All jobs green + 1 review approval before merge
```

### 4. Branch Protection (Manual GitHub Step)

Configure via GitHub UI or CLI:
- Require status checks: `version_sync`, `format`, `analyze_and_test`, `build_runner_smoke`, `analyzer_compat`, `migrator`
- Require 1 approving review
- Require branches to be up to date before merging

## Implementation Order

1. Fix formatting (`dart format .`)
2. Fix analyze issues in example
3. Fix failing tests (ensure build_runner runs before tests)
4. Update CI workflow (remove development, add format job, add build_runner_smoke)
5. Update AGENTS.md
6. Create test PR to verify CI runs correctly

## Verification

1. Push changes to a feature branch
2. Create PR to master
3. Verify all CI jobs run and pass
4. Verify merge is blocked until CI green + review
5. Merge PR and verify master remains green
