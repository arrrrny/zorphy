# Scripts

This directory contains utility scripts for the Zorphy monorepo.

## Available Scripts

### `publish.sh`

**Publish both zorphy_annotation and zorphy packages to pub.dev**

```bash
./scripts/publish.sh <version> [description] [--type]
```

**Examples:**

```bash
# Standard release
./scripts/publish.sh 1.0.0 "Initial release"

# With category
./scripts/publish.sh 1.1.0 "Added feature" --feat
./scripts/publish.sh 1.1.1 "Fixed bug" --fix

# Promote [Unreleased] section from CHANGELOG
./scripts/publish.sh 1.0.1
```

**What it does:**

1. Publishes `zorphy_annotation` (tag: `annotation-vX.Y.Z`)
2. Publishes `zorphy` (tag: `vX.Y.Z`)

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
- ✅ Runs tests before publishing
- ✅ Publishes to pub.dev

**Safety:**

- Validates version format (X.Y.Z)
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
