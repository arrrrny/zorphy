# Migrating to Zorphy 2.0

Zorphy 2.0 is a major release with a small, deliberate breaking surface.
Most projects upgrade with **zero code changes**.

## 1. Upgrade the packages

```yaml
dependencies:
  zorphy_annotation: ^2.0.0
dev_dependencies:
  zorphy: ^2.0.0
```

The `analyzer` constraint is now `>=13.0.0 <15.0.0`, so projects pinned to
analyzer 14.x (modern Dart toolchains) resolve without overrides. If your
dev dependencies include `json_serializable <6.15`, it currently caps
`analyzer <14.0.0` — either stay on analyzer 13.x until a compatible
json_serializable releases, or add a temporary `dependency_overrides`
entry in your own pubspec (zorphy's published constraint is not held back
by it).

## 2. Regenerate

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Expected output changes

- **`@zorphy` const users (filter descriptors):** the deprecated
  top-level `const zorphy` previously carried `generateFilter: false`
  while the class default was `true`. 2.0 makes both paths consistent
  (`standard` preset → `generateFilter: true`), so files annotated with
  plain `@zorphy` gain a `Fields` class (filter descriptors) on
  regeneration. To keep 1.9.0 output exactly, annotate explicitly:

  ```dart
  @Zorphy(generateFilter: false)
  ```

- **`@zorphy2` users:** the alias keeps working and behaves exactly like
  `@zorphy` — there is no second build pass anymore. Generated output
  lands in `.zorphy.dart` like everything else. The annotation is
  deprecated and will be removed in a later major; migrate at your own
  pace (a simple rename: `@zorphy2` → `@zorphy`, `@Zorphy2` → `@Zorphy`).

- **Fieldless explicit subtypes:** now emit a minimal patch class +
  identity `patchWith`. This only *adds* symbols; existing code is
  unaffected.

## 3. Optionally: slim your output with presets

```dart
// Plain DTO — no patch/filter/compareTo/property-helper machinery
@Zorphy(preset: ZorphyPreset.lean, generateJson: true)
abstract class $User { ... }

// Lean + just the patch API
@Zorphy(preset: ZorphyPreset.lean, generatePatch: true)
abstract class $Todo { ... }

// Everything, including function-based copyWith
@Zorphy(preset: ZorphyPreset.full)
abstract class $Config { ... }
```

Every feature flag is `bool?`: `null` inherits from the preset, an
explicit value overrides it for that feature only.

## 4. Coming from freezed?

Use the [`zorphy_migrator`](zorphy_migrator/) codemod — see the
[migration guide](website/docs/migrating-from-freezed.mdx).
