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
