# Zorphy Monorepo Publish Guide

## Overview

The top-level `publish.sh` script publishes both packages in the correct order:
1. **zorphy_annotation** first (dependency)
2. **zorphy** second (depends on annotation)

## How It Works

### 1. Version Input

```bash
./scripts/publish.sh 1.0.0 "Initial release"
```

**Arguments:**
- `$1` - Version number (required, format: X.Y.Z)
- `$2` - Description (optional)
- `--feat`, `--fix`, etc. - Type category (optional)

### 2. Validation

The script validates:
- ✅ Version format (X.Y.Z)
- ✅ CHANGELOG has `[Unreleased]` if no description provided
- ✅ Both packages exist

### 3. Execution Flow

```
┌─────────────────────────────────────────┐
│ 1. Parse arguments & validate version  │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 2. Publish zorphy_annotation           │
│    • Update pubspec.yaml → 1.0.0       │
│    • Update CHANGELOG.md                │
│    • Commit changes                     │
│    • Create PR to master (optional)     │
│    • Create tag: annotation-v1.0.0      │
│    • Publish to pub.dev                 │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 3. Publish zorphy                       │
│    • Update pubspec.yaml → 1.0.0       │
│    • Update CHANGELOG.md                │
│    • Update zorphy_annotation dep       │
│    • Commit changes                     │
│    • Create PR to master (optional)     │
│    • Create tag: v1.0.0                 │
│    • Run tests                          │
│    • Publish to pub.dev                 │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│ 4. Summary & links                      │
└─────────────────────────────────────────┘
```

## Usage Examples

### Example 1: Standard Release

```bash
./scripts/publish.sh 1.0.0 "Initial release"
```

**Output:**
```
🚀 Publishing zorphy monorepo version 1.0.0...

📦 Publishing order:
   1. zorphy_annotation (tag: annotation-v1.0.0)
   2. zorphy (tag: v1.0.0)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Step 1/2: Publishing zorphy_annotation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Updating zorphy_annotation pubspec.yaml...
  ✓ Version updated to 1.0.0
📝 Updating zorphy_annotation CHANGELOG.md...
  ✓ CHANGELOG.md updated
🔨 Committing zorphy_annotation changes...
  ✓ Changes committed
🏷️  Creating git tag for zorphy_annotation...
  ✓ Tag annotation-v1.0.0 pushed
📦 Publishing zorphy_annotation to pub.dev...
  ✓ Published successfully

✅ Successfully published zorphy_annotation version 1.0.0!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Step 2/2: Publishing zorphy
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 Updating zorphy pubspec.yaml...
  ✓ Version updated to 1.0.0
📝 Updating zorphy CHANGELOG.md...
  ✓ CHANGELOG.md updated
📝 Updating zorphy_annotation dependency in zorphy/pubspec.yaml...
  ✓ Dependency updated to ^1.0.0
🔨 Committing zorphy changes...
  ✓ Changes committed
🏷️  Creating git tag for zorphy...
  ✓ Tag v1.0.0 pushed
🧪 Running tests...
  ✓ Tests passed
📦 Publishing zorphy to pub.dev...
  ✓ Published successfully

✅ Successfully published zorphy version 1.0.0!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎉 Publish Complete!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Version: 1.0.0
Date: 2025-02-04
Description: Initial release

📦 Published Packages:
   • zorphy_annotation: https://pub.dev/packages/zorphy_annotation/1.0.0
   • zorphy:            https://pub.dev/packages/zorphy/1.0.0

🏷️  Git Tags:
   • annotation-v1.0.0
   • v1.0.0

✨ All done! Your packages are live on pub.dev!
```

### Example 2: Promote [Unreleased]

If you've been adding entries to `[Unreleased]` in CHANGELOG:

```bash
# Before: CHANGELOG has [Unreleased] section
./scripts/publish.sh 1.0.1
```

**Result:** Converts `[Unreleased]` → `[1.0.1] - 2025-02-04`

### Example 3: With Type Category

```bash
./scripts/publish.sh 1.1.0 "Fixed critical bug" --fix
```

**Result in CHANGELOG:**
```markdown
## [1.1.0] - 2025-02-04

### Fix
- Fixed critical bug
```

## Key Features

### 1. Automatic Dependency Update

When publishing `zorphy`, the script automatically updates the `zorphy_annotation` dependency:

```yaml
# Before
dependencies:
  zorphy_annotation:
    path: ../zorphy_annotation

# After (in pubspec.yaml, but not committed to repo)
dependencies:
  zorphy_annotation: ^1.0.0
```

### 2. Separate Git Tags

Each package gets its own tag:
- `zorphy_annotation`: `annotation-v1.0.0`
- `zorphy`: `v1.0.0`

This allows you to reference specific versions of each package independently.

### 3. Pull Request Creation

If you have `gh` CLI installed, the script automatically creates PRs to master:

```bash
# Install gh CLI
brew install gh  # macOS
# or
sudo apt install gh  # Linux

# Login
gh auth login
```

The PR includes:
- Version number
- Description
- List of changes
- Date

### 4. Safe Execution

- **`set -e`**: Stops on any error
- **Version validation**: Checks format before proceeding
- **Git commits**: Commits before publishing
- **Tests**: Runs tests before publishing zorphy
- **Force flag**: Uses `--force` for non-interactive publishing

## CHANGELOG Management

### Workflow

1. **During Development** - Add entries to `[Unreleased]`:

```markdown
## [Unreleased]

### Added
- New feature X

### Fixed
- Bug Y
```

2. **Release Time** - Run publish script:

```bash
./scripts/publish.sh 1.0.0 "Release feature X and fix Y"
```

3. **Result** - Script promotes `[Unreleased]`:

```markdown
## [Unreleased]

## [1.0.0] - 2025-02-04

### Added
- New feature X

### Fixed
- Bug Y
```

### Manual Entries

If you don't use `[Unreleased]`, provide a description:

```bash
./scripts/publish.sh 1.0.0 "Initial stable release"
```

**Result:**
```markdown
## [Unreleased]

## [1.0.0] - 2025-02-04

### Change
- Initial stable release
```

## Troubleshooting

### Problem: "No [Unreleased] section found"

**Solution:** Either add `[Unreleased]` to CHANGELOG or provide description:

```bash
# Option 1: Add description
./scripts/publish.sh 1.0.0 "My release notes"

# Option 2: Use [Unreleased] in CHANGELOG first
```

### Problem: "Invalid version format"

**Solution:** Use semantic versioning (X.Y.Z):

```bash
# ✅ Correct
./scripts/publish.sh 1.0.0
./scripts/publish.sh 2.3.15

# ❌ Wrong
./scripts/publish.sh 1.0
./scripts/publish.sh v1.0.0
./scripts/publish.sh 1.0.0-beta
```

### Problem: Publish fails mid-way

**Solution:** The script commits after each package. You can resume:

```bash
# If annotation succeeded but zorphy failed:
./scripts/publish.sh 1.0.0 "Resume zorphy publish"
```

The script will detect existing tags and skip completed steps.

### Problem: Tests fail

**Solution:** Fix tests first, then publish:

```bash
cd zorphy
dart test  # Run tests manually
# Fix issues...
cd ..
./scripts/publish.sh 1.0.0 "Retry publish"
```

## Advanced Usage

### Publish from Specific Branch

```bash
git checkout -b release/1.0.0
./scripts/publish.sh 1.0.0 "Release from feature branch"
```

### Dry Run (Test Without Publishing)

Comment out the actual publish commands:

```bash
# In publish.sh, find and comment:
# dart pub publish --force
```

### Skip Tests

For emergency releases, edit the script to skip tests:

```bash
# In publish.sh, comment out:
# dart test
```

## Best Practices

1. **Always use `[Unreleased]`** during development
2. **Run tests manually** before publishing
3. **Review CHANGELOG** before running script
4. **Use semantic versioning** correctly
5. **Test on clean environment** before publishing
6. **Keep dependencies updated** in both packages

## Package Publishing Order

**Why annotation first?**

```
zorphy_annotation (no dependencies)
       ↓
    zorphy (depends on zorphy_annotation)
```

The annotation package must be published first because:
1. zorphy's `pubspec.yaml` references it
2. Users need annotation to use zorphy
3. pub.dev requires dependencies to exist

## Summary

```bash
# Standard release
./scripts/publish.sh 1.0.0 "Description"

# With type
./scripts/publish.sh 1.0.0 "Description" --feat

# Promote unreleased
./scripts/publish.sh 1.0.1
```

The script handles:
- ✅ Version updates
- ✅ CHANGELOG management
- ✅ Git commits
- ✅ PR creation
- ✅ Git tagging
- ✅ Dependency updates
- ✅ Tests
- ✅ Publishing

All in one command! 🚀
