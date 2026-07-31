# [v2.0] P3 — Migrate Core Generators to code_builder Specs

> **For**: AI agent tasked with migrating the core generators to code_builder specs
> **Date**: 2026-07-31
> **Goal**: Migrate the 5 structural "core" generators from `StringBuffer` string paths to `code_builder` specs, preserving byte-identical output vs the T001 golden baseline.

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
ssh -J root@ssh-mac.zuzu.dev -p 2222 clp7qsQ4ExGFGdhxVTPdTZC5cNjo77xD@ssh-mac.zuzu.dev
```

The jump host provides public SSH access. Token valid for 6 hours.

### WebSocket Exec (Programmatic — No REST API)

```bash
pip3 install websockets 2>/dev/null
python3 -c "
import asyncio, json, websockets
async def run(cmd):
    async with websockets.connect(f'wss://proxy.zuzu.dev/toolbox/a4cdd172-7a7f-499d-bc1d-2ff880568443/process/exec/connect?token=clp7qsQ4ExGFGdhxVTPdTZC5cNjo77xD') as ws:
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
curl -s -X POST "https://proxy.zuzu.dev/toolbox/a4cdd172-7a7f-499d-bc1d-2ff880568443/mcp" \
  -H "Authorization: Bearer dtn_b887a6c815c2c9e1bfe4d819523e1ca724ee60a0d9f9a608cc0d4d4ab523f565" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"exec_command","arguments":{"command":"echo hello"}}}'
```

**MCP tools**: `exec_command`, `fs_read_file`, `fs_write_file`, `fs_list_files`

### Sandbox Environment

| Tool | Version |
|------|---------|
| Flutter | 3.41.1 at `/opt/flutter/bin/flutter` |
| Dart | 3.11.0 at `/opt/flutter/bin/dart` |
| Git | `/usr/bin/git` |
| Workspace | `/workspace/` |

### GitHub Access

The sandbox has a GitHub PAT in `~/.zshenv` as `GITHUB_TOKEN` (verified working).
- **Contents**: Read & Write
- **Pull requests**: Read & Write
- Source `~/.zshenv` first to load it: `source ~/.zshenv`

### Existing Code in Sandbox

- `/workspace/zuraffa/` — Zuraffa CLI + MCP server (development branch)
- `/workspace/zorphy/` — **Zorphy code generator** (development branch) ← TARGET REPO

---

## 2. Task Description

Migrate the 5 structural "core" generators from `StringBuffer` string paths to `code_builder` specs.

### ⚠️ CRITICAL DEPENDENCY — Read this first

This task (P3) **depends on P2 (#29 — SpecMapper)**. The `spec_mapper.dart` file does NOT exist in the current `development` branch yet.

**Before starting, check if `zorphy/lib/src/ast/spec_mapper.dart` exists:**

```bash
ls /workspace/zorphy/zorphy/lib/src/ast/spec_mapper.dart
```

- **If it exists** (P2 was merged): use it — map metadata → specs via `SpecMapper`, then migrate each generator.
- **If it does NOT exist** (P2 not merged yet): **implement the generators by hand-building specs** using `code_builder` primitives and the `type_ref.dart` helpers (which DO exist from P1). Do NOT block on P2 — each generator's `generateSpec()` just needs to produce specs that emit byte-identical output vs the string path. If P2's PR becomes available during your work, prefer using its `SpecMapper` if convenient.

### Context: What exists from P1 (merged, PR #32)

- `zorphy/lib/src/emission/emitter.dart` — `ZorphyEmitter.emit(Library)` → formatted Dart
- `zorphy/lib/src/ast/type_ref.dart` — `referType`, `referZorphyClass`, etc.
- `zorphy/lib/src/generators/base_generator.dart` — `SpecGenerator` interface + `CodeGeneratorSpecAdapter` (wraps string output in `Code` spec)
- `specs/002-v2-codebuilder-plugin-pipeline/golden-pr22/` — golden snapshot baseline (byte-compat reference)

### Tasks (from issue #25)

#### T008 — Migrate `ClassDeclarationGenerator` → returns `Class` spec
The critical path join point. All member generators attach to this Class.

#### T009 — Migrate `EqualsToStringGenerator` → `Method` specs
Emit `==`, `hashCode`, `toString` as `Method` specs.

#### T010 — Migrate `CopyWithGenerator` → `Method` spec
Emit `copyWith` as a `Method` spec.

#### T011 — Migrate `FactoryMethodGenerator` → `Method`/`Constructor` specs
Emit constructors as `Constructor` specs.

#### T012 — Migrate `PropertyHelperGenerator` → `Method` specs
Emit property helpers as `Method` specs.

### Migration strategy (from the issue)

Each generator:
1. Override `generateSpec()` with real specs
2. Verify byte-compat vs the T001 golden snapshot
3. Remove the `generate()` string path once byte-identical

All generators after T008 (the join point) can be migrated in parallel since they produce independent member specs.

### Verification

For each migrated generator:
- `cd /workspace/zorphy && dart analyze` — zero issues
- `cd /workspace/zorphy && dart test` — green between each migration (strangler invariant)
- `zorphy/example` regenerates **byte-identical** vs T001 golden snapshot (`specs/002-v2-codebuilder-plugin-pipeline/golden-pr22/`)

---

## 3. Deliverable

Create a Pull Request on the `arrrrny/zorphy` repository:

1. **Base branch**: `development`
2. **Create a feature branch**: `feat/migrate-core-generators`
3. **Implement** T008–T012 described above
4. **Verify**: `dart analyze`, `dart test`, golden snapshot byte-comparison
5. **Commit and push** your changes
6. **Open a PR**:

> 🚨 **MANDATORY**: The PR body MUST start with `Closes #25` on its own line.
> This auto-closes the issue when the PR merges. Without it, the issue stays open forever.

```bash
source ~/.zshenv
curl -s -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/arrrrny/zorphy/pulls \
  -d '{"title":"feat: migrate core generators to code_builder specs","head":"feat/migrate-core-generators","base":"development","body":"Closes #25\n\n## Summary\nMigrated the 5 core generators from StringBuffer string paths to code_builder specs.\n\n### Tasks\n- T008: ClassDeclarationGenerator returns Class spec\n- T009: EqualsToStringGenerator emits ==/hashCode/toString as Method specs\n- T010: CopyWithGenerator emits copyWith as Method spec\n- T011: FactoryMethodGenerator emits constructors as Constructor specs\n- T012: PropertyHelperGenerator emits helpers as Method specs\n\n## Verification\n- dart analyze: green\n- dart test: green\n- Golden snapshot: byte-identical"}'
```

---

## 4. Important Notes

- **Read `/workspace/AGENTS.md` first** — contains critical GOTCHAs
- Source `~/.zshenv` before using dart/git: `source ~/.zshenv`
- Flutter/Dart at `/opt/flutter/bin/` (already in `~/.zshenv` PATH)
- **Strangler invariant**: `dart test` must stay green between EACH generator migration
- **Byte-identical**: the golden snapshot is the source of truth — regenerate and diff against it
- If `spec_mapper.dart` (P2) is missing, hand-build specs with `code_builder` primitives + `type_ref.dart` helpers — do not block
- Always pull latest `development` before creating your feature branch
- The sandbox auto-stops after 6 hours of inactivity
- 🚨 **MANDATORY**: PR body must start with `Closes #25`
