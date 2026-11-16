# Quickstart: zorphy 3.0.0

## For consumers (shared parts)

1. Upgrade `zorphy: ^3.0.0` and `zorphy_annotation: ^3.0.0`.
2. Ensure `analysis_options.yaml` enables the experiment if your build uses imports in shared parts:
   ```yaml
   analyzer:
     enable-experiment:
       - enhanced-parts
   ```
3. Run `dart run build_runner build --delete-conflicting-outputs`.
4. Output: one `<library>.zorphy.part` per library (was many `.zorphy.dart` files). Add `**/*.zorphy.part` to `analysis_options.yaml` exclude if desired.

## For consumers (lean migration)

1. Preview reductions (no changes written):
   ```bash
   dart run zorphy_migrator lean --dry-run
   ```
   Prints a unified diff: `@Zorphy(preset: standard, ...)` → `@Zorphy(preset: lean, generatePatch: true, ...)` for classes that use patch but not filter/json/comparators.
2. Apply:
   ```bash
   dart run zorphy_migrator lean --apply
   dart run build_runner build --delete-conflicting-outputs
   dart test
   ```
3. Report: per-class current→proposed preset, estimated lines saved.

## For contributors

```bash
cd zorphy && dart pub get && dart test -j 2 && dart analyze
cd ../zorphy_migrator && dart pub get && dart test -j 2 && dart analyze
./scripts/local_ci.sh
```

## Smoke against real consumers

```bash
# zik_zak
cd ~/Developer/zik_zak && dart run build_runner build --delete-conflicting-outputs && dart analyze
dart run zorphy_migrator lean --dry-run
```