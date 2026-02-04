# Publish Script Quick Reference

## One Command to Publish Both Packages

```bash
./publish.sh <version> [description] [--type]
```

## Examples

```bash
# Standard release
./publish.sh 1.0.0 "Initial release"

# With category
./publish.sh 1.1.0 "Added new feature" --feat
./publish.sh 1.1.1 "Fixed bug" --fix

# Promote [Unreleased] section
./publish.sh 1.2.0
```

## What It Does

1. **Publishes zorphy_annotation** (tag: `annotation-vX.Y.Z`)
   - Updates version in pubspec.yaml
   - Updates CHANGELOG.md
   - Commits changes
   - Creates git tag
   - Publishes to pub.dev

2. **Publishes zorphy** (tag: `vX.Y.Z`)
   - Updates version in pubspec.yaml
   - Updates CHANGELOG.md
   - Updates zorphy_annotation dependency
   - Commits changes
   - Runs tests
   - Creates git tag
   - Publishes to pub.dev

## Change Types

| Flag | Category | Use When |
|------|----------|----------|
| `--feat` | Feat | New features |
| `--fix` | Fix | Bug fixes |
| `--docs` | Docs | Documentation changes |
| `--style` | Style | Code style changes |
| `--refactor` | Refactor | Code refactoring |
| `--perf` | Perf | Performance improvements |
| `--test` | Test | Adding/updating tests |
| `--build` | Build | Build system changes |
| `--ci` | CI | CI configuration changes |
| `--chore` | Chore | Maintenance tasks |

## Version Format

Must be semantic versioning: `X.Y.Z`

```bash
✅ 1.0.0
✅ 2.3.15
✅ 10.20.30

❌ 1.0
❌ v1.0.0
❌ 1.0.0-beta
❌ 1.0.0-alpha.1
```

## CHANGELOG Workflow

### During Development

```markdown
## [Unreleased]

### Added
- New feature X

### Fixed
- Bug Y
```

### At Release

```bash
./publish.sh 1.0.0
```

### Result

```markdown
## [Unreleased]

## [1.0.0] - 2025-02-04

### Added
- New feature X

### Fixed
- Bug Y
```

## Output

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
  ✓ Published

✅ Successfully published zorphy_annotation version 1.0.0!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Step 2/2: Publishing zorphy
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[... similar output for zorphy ...]

🎉 Publish Complete!

Version: 1.0.0
Date: 2025-02-04
Description: Initial release

📦 Published Packages:
   • zorphy_annotation: https://pub.dev/packages/zorphy_annotation/1.0.0
   • zorphy:            https://pub.dev/packages/zorphy/1.0.0

🏷️  Git Tags:
   • annotation-v1.0.0
   • v1.0.0

✨ All done!
```

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Invalid version format | Use X.Y.Z format |
| No [Unreleased] found | Provide description or add [Unreleased] |
| Tests fail | Fix tests, then re-run |
| Publish fails mid-way | Script commits after each package, safe to re-run |

## Requirements

- Bash shell (macOS/Linux)
- Git
- Dart SDK
- `gh` CLI (optional, for PR creation)

## Safety Features

- ✅ `set -e` - Stops on errors
- ✅ Version validation
- ✅ Git commits before publishing
- ✅ Tests before zorphy publish
- ✅ Separate git tags

## Files Modified

1. `zorphy_annotation/pubspec.yaml` - version
2. `zorphy_annotation/CHANGELOG.md` - release entry
3. `zorphy/pubspec.yaml` - version + dependency
4. `zorphy/CHANGELOG.md` - release entry

## Git Tags Created

1. `annotation-vX.Y.Z` - zorphy_annotation
2. `vX.Y.Z` - zorphy

## Links After Publish

- zorphy_annotation: `https://pub.dev/packages/zorphy_annotation/X.Y.Z`
- zorphy: `https://pub.dev/packages/zorphy/X.Y.Z`

## See Also

- [PUBLISH_GUIDE.md](PUBLISH_GUIDE.md) - Detailed guide
