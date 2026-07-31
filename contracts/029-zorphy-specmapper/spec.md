# [v2.0] P2 — SpecMapper: Analyzer-to-code_builder Spec Bridge

> **For**: AI agent tasked with implementing the SpecMapper bridge for Zorphy v2.0
> **Date**: 2026-07-31
> **Goal**: Create the `SpecMapper` — the bridge between Zorphy's analyzer models (`ClassMetadata`/`FieldMetadata`/`InterfaceMetadata`) and `code_builder` specs (`Class`/`Field`/`Method`). All downstream generator migrations depend on this mapper.

> ⚠️ **FIRST STEP**: Read `/workspace/AGENTS.md` before doing anything else.

---

## 1. Environment Access

### Daytona Sandbox (Linux x64)

Full sandbox with Flutter 3.41.1, Dart 3.11.0, and repos pre-installed.

**Public API**: `https://daytona.zuzu.dev/api`
**Proxy (toolbox + MCP)**: `https://proxy.zuzu.dev`
**API Key**: `dtn_b887a6c815c2c9e1bfe4d819523e1ca724ee60a0d9f9a608cc0d4d4ab523f565`
**Sandbox ID**: `a4cdd172-7a7f-499d-bc1d-2ff880568443`

### SSH Access (Primary — Full Shell)

```bash
ssh -J root@ssh-mac.zuzu.dev -p 2222 fnn3Ca18Us7PdstdDer0NAlXN3dRfo7w@ssh-mac.zuzu.dev
```

The jump host provides public SSH access. Token valid for 6 hours.

### WebSocket Exec (Programmatic — No REST API)

```bash
pip3 install websockets 2>/dev/null
python3 -c "
import asyncio, json, websockets
async def run(cmd):
    async with websockets.connect(f'wss://proxy.zuzu.dev/toolbox/a4cdd172-7a7f-499d-bc1d-2ff880568443/process/exec/connect?token=fnn3Ca18Us7PdstdDer0NAlXN3dRfo7w') as ws:
        await ws.send(json.dumps({'type':'start','command':cmd}))
        while True:
            msg = await ws.recv(); frame = json.loads(msg)
            if 'data' in frame: print(frame['data'], end='')
            elif frame.get('exitCode') is not None: break
asyncio.run(run('echo ready'))
"
```

### MCP (Tool-Calling — No REST API)

```bash
# List tools
curl -s -X POST "https://proxy.zuzu.dev/toolbox/a4cdd172-7a7f-499d-bc1d-2ff880568443/mcp" \
  -H "Authorization: Bearer dtn_b887a6c815c2c9e1bfe4d819523e1ca724ee60a0d9f9a608cc0d4d4ab523f565" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'

# Execute a command
curl -s -X POST "https://proxy.zuzu.dev/toolbox/a4cdd172-7a7f-499d-bc1d-2ff880568443/mcp" \
  -H "Authorization: Bearer dtn_b887a6c815c2c9e1bfe4d819523e1ca724ee60a0d9f9a608cc0d4d4ab523f565" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"exec_command","arguments":{"command":"echo hello"}}}'
```

**MCP tools**: `exec_command`, `fs_read_file`, `fs_write_file`, `fs_list_files`

### Sandbox Environment

| Tool      | Version                              |
| --------- | ------------------------------------ |
| Flutter   | 3.41.1 at `/opt/flutter/bin/flutter` |
| Dart      | 3.11.0 at `/opt/flutter/bin/dart`    |
| Git       | `/usr/bin/git`                       |
| Workspace | `/workspace/`                        |

### GitHub Access

The sandbox has a GitHub PAT in `~/.zshenv` as `GITHUB_TOKEN` (already verified working — used to push PR #32).

- **Contents**: Read & Write
- **Pull requests**: Read & Write
- Source `~/.zshenv` first to load it: `source ~/.zshenv`

### Existing Code in Sandbox

- `/workspace/zuraffa/` — Zuraffa CLI + MCP server (development branch)
- `/workspace/zorphy/` — **Zorphy code generator** (development branch, commit `e4a118f` — PR #32 code_builder pipeline merged) ← TARGET REPO

---

## 2. Task Description

Create the `SpecMapper` — the bridge between Zorphy's analyzer models and `code_builder` specs.

### Context: The v2.0 pipeline

PR #32 (merged) installed the `code_builder` emission pipeline:

- `lib/src/emission/emitter.dart` — `ZorphyEmitter.emit(Library)` → `DartEmitter` + `DartFormatter`
- `lib/src/ast/type_ref.dart` — escape-free type-reference helpers (`referType`, `referZorphyClass`, etc.)
- `base_generator.dart` — `SpecGenerator` interface + `CodeGeneratorSpecAdapter` extension

This issue (P2) builds the **SpecMapper** that downstream generator migrations (P3, P4) will use.

### Tasks (from issue #29)

#### T006 — Create `zorphy/lib/src/ast/spec_mapper.dart`

Map Zorphy analyzer models to `code_builder` specs:

1. **`ClassMetadata` → `Class` spec**
   - Handle modifiers: `abstract` (from `isAbstract`), `sealed` (from `isSealed`), `final` (concrete with `nonSealed`?), plain concrete
   - Preserve type params: `List<GenericParameterMetadata>` → `List<TypeParameter>` (use the existing helpers in `type_ref.dart`)
   - `implements` clauses: `List<InterfaceMetadata>` → `implements: [...]`

2. **`FieldMetadata` → `Field` spec**
   - Name, type (via `referType` from `type_ref.dart`), modifiers (final?), docs

3. **`InterfaceMetadata` → implements clause**
   - Interface name → `TypeReference` for the `implements` clause

4. **`GenericParameterMetadata` → type params**
   - Name, bound → `TypeParameter` spec

#### T007 — Unit test `spec_mapper` (new `test/ast/spec_mapper_test.dart`)

Test on fixtures covering:

- Abstract class shape (e.g., `$$Shape` → `abstract class Shape`)
- Sealed class shape (e.g., `$$Shape` with `!nonSealed` → `sealed class Shape`)
- Concrete class shape (e.g., `$User` → `class User`)
- Final class shape
- Generic class shape (e.g., `$Box<T>` → `class Box<T>` with type param preserved)
- `Map` type param preservation (generics: `Map<K,V>` → `Map` → `Map` type params preserved)

### Reference models (already exist in the codebase)

Read these to understand the input shapes:

- `zorphy/lib/src/models/class_metadata.dart` — `ClassMetadata` (has `isAbstract`, `isSealed`, `nonSealed`, `generics`, `interfaces`, `allFields`)
- `zorphy/lib/src/models/field_metadata.dart` — `FieldMetadata`
- `zorphy/lib/src/models/interface_metadata.dart` — `InterfaceMetadata`

### Reference helpers (already exist from PR #32)

- `zorphy/lib/src/ast/type_ref.dart` — `referType(String)`, `referZorphyClass(String)`, etc.
- `zorphy/lib/src/emission/emitter.dart` — `ZorphyEmitter`

### Verification

- `cd /workspace/zorphy && dart analyze` — zero issues
- `cd /workspace/zorphy && dart test` — all green (15 existing + new spec_mapper tests)

---

## 3. Deliverable

Create a Pull Request on the `arrrrny/zorphy` repository:

1. **Base branch**: `development`
2. **Create a feature branch**: `feat/spec-mapper`
3. **Implement** T006 + T007 described above
4. **Verify**: `dart analyze`, `dart test`
5. **Commit and push** your changes
6. **Open a PR**:

> 🚨 **MANDATORY**: The PR body MUST start with `Closes #29` on its own line.
> This auto-closes the issue when the PR merges. Without it, the issue stays open forever.

```bash
source ~/.zshenv
curl -s -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/arrrrny/zorphy/pulls \
  -d '{"title":"feat: SpecMapper — analyzer-to-code_builder spec bridge","head":"feat/spec-mapper","base":"development","body":"Closes #29\n\n## Summary\nCreated the SpecMapper bridging ClassMetadata/FieldMetadata/InterfaceMetadata to code_builder specs.\n\n### Tasks\n- T006: Created lib/src/ast/spec_mapper.dart\n- T007: Added test/ast/spec_mapper_test.dart covering abstract/sealed/final/concrete/generic shapes\n\n## Verification\n- dart analyze: green\n- dart test: green"}'
```

---

## 4. Important Notes

- **Read `/workspace/AGENTS.md` first** — contains critical GOTCHAs
- Source `~/.zshenv` before using dart/git: `source ~/.zshenv`
- Flutter/Dart at `/opt/flutter/bin/` (already in `~/.zshenv` PATH)
- **Purely additive** — do NOT change existing generators or string-pipeline behavior
- Always pull latest `development` before creating your feature branch
- The sandbox auto-stops after 6 hours of inactivity
- PR title format: `feat: SpecMapper — analyzer-to-code_builder spec bridge`
- 🚨 **MANDATORY**: PR body must start with `Closes #29` — this is what auto-closes the issue on merge
