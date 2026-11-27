# Scripts

This directory contains utility scripts for the Zorphy monorepo.

## Available Scripts

### `publish.sh`

**Publish `zorphy_annotation`, `zorphy` and `zorphy_migrator` to pub.dev**

```bash
./scripts/publish.sh <version> [description] [--dry-run]
```

**Examples:**

```bash
# Standard release
./scripts/publish.sh 1.0.0 "Initial release"

# Prerelease
./scripts/publish.sh 3.0.0-dev.3

# Preview every step without changing anything
./scripts/publish.sh 3.0.0-dev.3 "Closure" --dry-run
```

**What it does:**

1. Publishes `zorphy_annotation` (tag: `annotation-vX.Y.Z`)
2. Publishes `zorphy` (tag: `vX.Y.Z`)
3. Publishes `zorphy_migrator` (tag: `migrator-vX.Y.Z`)

For detailed information, see:
- [PUBLISH_GUIDE.md](../PUBLISH_GUIDE.md) - Complete documentation
- [PUBLISH_QUICKREF.md](../PUBLISH_QUICKREF.md) - Quick reference

**Features:**

- ✅ Updates versions in `pubspec.yaml` files
- ✅ Updates `CHANGELOG.md` with release notes
- ✅ Commits changes to git
- ✅ Creates pull requests (if `gh` CLI is installed)
- ✅ Creates git tags
- ✅ Updates dependencies automatically
- ✅ Publishes to pub.dev

**Safety:**

- `--dry-run` prints the whole release and changes nothing
- Validates version format (X.Y.Z, with an optional prerelease such as `-dev.3`)
- Rejects unknown options
- Stops on errors (`set -e`)
- Commits before publishing
- Separate git tags for each package

**Requirements:**

- Bash shell (macOS/Linux)
- Git
- Dart SDK
- `gh` CLI (optional, for PR creation)

---

**Note:** All paths in the script are relative to the monorepo root, so you can run it from anywhere:
```bash
# From monorepo root
./scripts/publish.sh 1.0.0 "Release"

# From any directory (with full path)
/Users/arrrrny/Developer/zorphy/scripts/publish.sh 1.0.0 "Release"
```

---

### `check_stacked_pr_integrity.sh`

**Pre-push gate against orphaned stacked PRs (issue #315).**

```bash
./scripts/check_stacked_pr_integrity.sh   # reads git's pre-push ref lines on stdin
```

For every ref being pushed with a non-fast-forward (force) update, it lists
merged PRs whose merge commit is an ancestor of the OLD (remote) tip but NOT of
the NEW (local) tip — "this force-push orphans these merged PRs" — and refuses
the push (exit 1). The push is allowed only with `STACK_REBASE_OK=1` exported,
after the orphaned PRs are re-targeted / reopened (or the stack re-merged).

- Wired as the `scripts/git-hooks/pre-push` hook — run `./scripts/install_hooks.sh`
  once per clone to enable it (`core.hooksPath`).
- Also run in CI by the `stacked_pr_integrity` job in `.github/workflows/ci.yaml`.
- The merged-PR inventory comes from `gh pr list`; inject `GH_PR_LIST_JSON`
  (JSON Lines) for offline / test runs.

### `sweep_merged_content.sh`

**Post-merge orphan sweep (issue #315).**

```bash
./scripts/sweep_merged_content.sh   # via gh; or GH_PR_LIST_JSON='…' for offline
```

For every PR closed-as-merged in the last 90 days, asserts its merge commit is
an ancestor of `master` (`SWEEP_BASE`, `SWEEP_DAYS` override). Any orphan gets
an `orphaned merge: #N content not on master` issue filed/reopened, and the
script exits non-zero. Runs from the `Stacked-PR Integrity Sweep` workflow
(weekly cron + on release) and as step 5 of `publish.sh`'s release gate.

### `install_hooks.sh`

Points `core.hooksPath` at the tracked `scripts/git-hooks` directory so the
pre-push gate runs in every clone without per-clone setup.
