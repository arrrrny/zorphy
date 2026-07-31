# Quickstart: Verifying the v2.0 Foundation + Migrator

## 1. Analyzer 14 resolution

```bash
cd zorphy && dart pub get && dart analyze && dart test
# CI matrix leg: analyzer 14 with temporary pubspec_overrides.yaml for json_serializable
```

## 2. Single-pass builder

```bash
grep -c "builder_factories" zorphy/build.yaml   # → 1
grep -rn "static final Map" zorphy/lib/src/zorphy_generator.dart zorphy/lib/builder2.dart  # → empty
cd zorphy/example && dart run build_runner build --delete-conflicting-outputs
git diff --stat   # no unexpected changes to existing generated files
```

## 3. Presets

```dart
// test fixture
@Zorphy(preset: ZorphyPreset.lean, generateJson: true)
abstract class $User { String get id; String get name; }
```

```bash
cd zorphy && dart test test/generation/preset_lean_test.dart
cd zorphy && dart test test/generation/standard_byte_compat_test.dart
```

## 4. Migrator

```bash
cd zorphy_migrator && dart pub get && dart analyze && dart test
dart run zorphy_migrator migrate test/fixtures --dry-run          # diff only, no writes
dart run zorphy_migrator migrate test/fixtures --apply --report MIGRATION.md
```

## 5. Docs

```bash
cd zorphy/example && dart analyze   # covers extracted comparison snippets
grep -n "Zorphy vs Freezed" README.md
ls website/docs/ | grep -i "freezed\|migration"
```
