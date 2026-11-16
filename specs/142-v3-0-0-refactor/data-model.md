# Data Model: zorphy 3.0.0

## Entities

### SharedPartBuilder (new, `zorphy/lib/src/shared_part_builder.dart`)
- `inputLibrary: LibraryElement` — the resolved input library.
- `sink: LibrarySourceSink?` — from `buildStep.librarySourceSink`.
- `generatedParts: List<String>` — per-entity source blocks (no directives).
- `build()`:
  - resolve library; if no `@Zorphy`/`@Zorphy2` annotations → return (no output).
  - for each generator output block: `sink?.add(block)` if sink != null; else legacy write.
  - if sink == null and outputs non-empty → write legacy `.zorphy.dart` (defensive fallback + warning).

### LeanFlavorProposal (new, `zorphy_migrator/lib/src/lean_detector.dart`)
- `className: String` — annotated class name.
- `currentPreset: ZorphyPreset` + `currentFlags: Map<String,bool>`.
- `referencedFeatures: Set<LeanFeature>` — {copyWith, patch, filter, copyWithFn, json, comparators} detected in package.
- `proposedPreset: ZorphyPreset` — `lean` unless a feature forces higher.
- `proposedFlags: Map<String,bool>` — explicit `generateX: true` for referenced features only.
- `estimatedLinesSaved: int`.

### LeanFeature (enum)
`copyWith, patch, filter, copyWithFn, json, comparators`

### LeanReport
- `proposals: List<LeanFlavorProposal>`.
- `totalLinesSaved: int`.
- `renderDiff()` → unified diff via `Rewriter`.

## Preset → feature mapping

| Feature | lean | standard | full |
|---|---|---|---|
| copyWith | ✓ | ✓ | ✓ |
| equality/comparators | ✓ | ✓ | ✓ |
| patch | — | ✓ | ✓ |
| filter | — | ✓ | ✓ |
| json (toJson/fromJson) | opt-in | opt-in | opt-in |
| copyWithFn | — | — | ✓ |

## Detection rules (conservative, FR-5)

For each feature F, F is "referenced" if any of:
- `copyWith`: `.copyWith(` appears on the class or its instances.
- `patch`: `.patch(` or `Patch` type usage.
- `filter`: `.filter(` or `Filter` type usage.
- `copyWithFn`: `copyWithFn` identifier or function-tearoff usage.
- `json`: `toJson`/`fromJson` invocation, or `json_serializable` annotation on the class.
- `comparators`: `compareTo`/`operator ==` reliance beyond identity.

If NO features beyond lean-default are referenced → `proposedPreset = lean`, no flags.
If features referenced → `proposedPreset = lean` + `generateX: true` for each (keeps output minimal but functional).