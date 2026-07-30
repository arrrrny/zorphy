## [0.1.0] - 2026-07-30

### Feat

- Initial release: freezed → zorphy codemod using resolved AST analysis (`AnalysisContextCollection`, analyzer 14)
- Converts simple classes, sealed unions (`$$Base` + `$Variant` subtypes), `fromJson`/`toJson` (`generateJson: true`), `@Default` (→ `@JsonKey(defaultValue:)`), `@JsonKey` (preserved), and rewrites `$`-prefixed sibling type references
- Lean-preset inference for classes that only use lean features
- CLI: `migrate <path>` with `--dry-run` (default), `--apply`, `--report <file>`, `--fail-on-manual`; exit codes 0/1/2
- Markdown migration report: converted classes, manual-attention items with `file:line`, post-migration instructions
- Golden-fixture test suite + 11-class end-to-end smoke test (migrate → `build_runner build` → `dart analyze` clean against zorphy 2.0)
