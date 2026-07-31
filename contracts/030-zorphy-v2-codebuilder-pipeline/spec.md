# [v2.0] P1 — Scaffolding: code_builder Emission Pipeline

> **For**: AI agent tasked with implementing the code_builder emission pipeline for Zorphy v2.0
> **Date**: 2026-07-30
> **Goal**: Install the `code_builder` emission pipeline as the new foundation for all code generation (strangler root pattern — byte-identical replacement path alongside existing string pipeline)

> ⚠️ **FIRST STEP**: Read `/workspace/AGENTS.md` before doing anything else.

---

## 1. Environment Access

### Daytona Sandbox (Linux x64)

Full sandbox with Flutter SDK, Dart 3.11.0, and repos pre-installed.

**Public API**: `https://daytona.zuzu.dev/api`
**Proxy (toolbox + MCP)**: `https://proxy.zuzu.dev`
**API Key**: `dtn_b887a6c815c2c9e1bfe4d819523e1ca724ee60a0d9f9a608cc0d4d4ab523f565`
**Sandbox ID**: `a4cdd172-7a7f-499d-bc1d-2ff880568443`

### SSH Access (Primary — Full Shell)

```bash
ssh -J root@ssh-mac.zuzu.dev -p 2222 4pX55LEiOyyJ2PTWLa0upkv3e7JSq8kJ@localhost
```

The jump host provides public SSH access. Token is valid for 6 hours.

### WebSocket Exec (Programmatic — No REST API)

```bash
pip3 install websockets 2>/dev/null
python3 -c "
import asyncio, json, websockets
async def run(cmd):
    async with websockets.connect(f'wss://proxy.zuzu.dev/toolbox/a4cdd172-7a7f-499d-bc1d-2ff880568443/process/exec/connect?token=4pX55LEiOyyJ2PTWLa0upkv3e7JSq8kJ') as ws:
        await ws.send(json.dumps({'type':'start','command':cmd}))
        while True:
            msg = await ws.recv(); frame = json.loads(msg)
            if 'data' in frame: print(frame['data'], end='')
            elif frame.get('exitCode') is not None: break
asyncio.run(open('/workspace/AGENTS.md').read() if False else run('echo ready'))
" 2>&1
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

| Tool | Version |
|------|---------|
| Flutter | 3.41.1 at `/opt/flutter/bin/flutter` |
| Dart | 3.11.0 at `/opt/flutter/bin/dart` |
| Git | `/usr/bin/git` |
| Workspace | `/workspace/` |

### GitHub Access

The sandbox has a GitHub PAT in `~/.zshenv` as `GITHUB_TOKEN`.
- **Contents**: Read & Write
- **Pull requests**: Read & Write
- Source `~/.zshenv` first to load it (`source ~/.zshenv`)

### Existing Code in Sandbox

- `/workspace/zuraffa/` — Zuraffa CLI + MCP server (development branch)
- `/workspace/zorphy/` — **Zorphy code generator** (development branch) ← THIS IS THE TARGET REPO

---

## 2. Task Description

Install the `code_builder` emission pipeline as the new foundation for all code generation in Zorphy.

This is the **strangler root** — a byte-identical replacement path that runs alongside the existing string pipeline without breaking anything.

### Tasks (from issue #30)

#### T001 — Snapshot PR-22 example output as byte-compat reference

Create `specs/002-v2-codebuilder-plugin-pipeline/golden-pr22/` directory at the repo root with the current generated output of `zorphy/example` so later migrations can verify byte-identical output.

**How**: Run `dart run bin/zorphy.dart example` (or the example regeneration command), capture output files, and commit them as the golden reference.

#### T002 — Create `zorphy/lib/src/ast/type_ref.dart`

Escape-free type-reference helpers with these functions:
- `referType(String type)` → `TypeReference` from `code_builder`
- `referZorphyClass(String name)` → references a Zorphy-generated class
- `referZorphySealedBase(String name)` → references a sealed class base
- `referSibling(String name)` → references a class in the same library
- `withLibrary(String library)` → wraps a refer with a library import

These should produce zero-escape `TypeReference` objects suitable for `code_builder` Specs.

#### T003 — Create `zorphy/lib/src/emission/emitter.dart`

A `ZorphyEmitter` class that takes a `Library` spec and emits formatted Dart code:

```dart
class ZorphyEmitter {
  String emit(Library library) {
    // Use DartEmitter + DartFormatter(pageWidth: 120)
  }
}
```

#### T004 — Add `SpecGenerator` interface to generators

In `base_generator.dart` (or wherever generators are defined), add:

```dart
abstract class SpecGenerator {
  List<Spec> generateSpec();
}
```

The existing `CodeGenerator` gets a default adapter:

```dart
List<Spec> generateSpec() => [Code(generate(ctx))];
```

This ensures all generators immediately produce a spec — no migration needed yet.

#### T005 — Switch `Orchestrator.generate` to emit via spec pipeline

Modify the `Orchestrator` to:
1. Collect `generateSpec()` from all generators into a single `Library`
2. Emit the library via `ZorphyEmitter`
3. Keep the temporary string-pass for `_assembleCode` (no breaking changes)

**Result**: All generators still use the string path — the adapter ensures byte-identical output vs the PR-22 snapshot.

### Verification

- `cd /workspace/zorphy && dart analyze` — zero issues
- `cd /workspace/zorphy && dart test` — all green
- Generated output matches golden snapshot byte-for-byte

---

## 3. Deliverable

Create a Pull Request on the `arrrrny/zorphy` repository:

1. **Base branch**: `development`
2. **Create a feature branch**: `feat/v2-codebuilder-pipeline`
3. **Implement** all 5 tasks (T001–T005) described above
4. **Verify**: `dart analyze`, `dart test`, golden snapshot comparison
5. **Commit and push** your changes
6. **Open a PR** using the GitHub API or `gh` CLI:

```bash
source ~/.zshenv
curl -s -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/arrrrny/zorphy/pulls \
  -d '{"title":"feat: v2 code_builder emission pipeline","head":"feat/v2-codebuilder-pipeline","base":"development","body":"Closes #30\n\n## Summary\nInstalled the code_builder emission pipeline as the new foundation for all code generation.\n\n### Tasks\n- T001: Snapshot PR-22 example output as byte-compat reference\n- T002: Created type_ref.dart with escape-free type helpers\n- T003: Created emitter.dart with ZorphyEmitter\n- T004: Added SpecGenerator interface with CodeGenerator adapter\n- T005: Switched Orchestrator to emit via spec pipeline\n\n## Verification\n- dart analyze: green\n- dart test: green\n- Output matches golden snapshot byte-for-byte"}'
```

---

## 4. Important Notes

- **Read `/workspace/AGENTS.md` first** — contains critical GOTCHAs
- Source `~/.zshenv` before using dart/git commands: `source ~/.zshenv`
- Flutter/Dart are at `/opt/flutter/bin/` (already in `~/.zshenv`)
- Always pull latest `development` before creating your feature branch
- The sandbox auto-stops after 6 hours of inactivity
- **`code_builder` package**: Add `code_builder` and `dart_style` as dependencies in `pubspec.yaml`
- PR title format: `{type}: {short description}` (e.g. `feat: v2 code_builder emission pipeline`)
- Close the issue with `Closes #30` in the PR body
