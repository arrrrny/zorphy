<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

# Shared terminal (`pallet`)

Long-running or user-visible commands (e.g. `dart run build_runner build`)
should run in the **shared `pallet` tmux session** so both the human and agents
see the same terminal. The human attaches with `pallet up` (in their terminal,
e.g. Zap); agents drive it via the `pallet` CLI or the `pallet` MCP server
(`~/Developer/forklift/scripts/pallet/pallet_mcp_server.dart`):

```bash
pallet ensure                 # create the shared session if missing
pallet run -n 'cmd'           # run in a fresh window (visible to the human)
pallet wait -w N              # wait until that window goes idle
pallet read -w N              # capture the window's output
```

See `~/Developer/forklift/scripts/pallet/README.md` for the full workflow
and CLI reference.

## ⚠️ ZORPHY CODE GENERATION — STRICT HANDLING

### Never modify generated zorphy code files.

**Rationale:** Zorphy code generator produces code that must not be manually edited. Any modifications to generated `.zorphy.dart` files will cause:
- Unpredictable behavior in code generation  
- Build failures due to inconsistent state
- Inability to reproduce results with `zorphy` CLI tools

**If you spot an issue in generated code:**
1. **DO NOT** edit the `.zorphy.dart` file directly
2. **IMMEDIATELY** drop the current task  
3. **Open a GitHub issue** on the `zorphy` repository
5. **Create a new task** with proper tracking once the upstream issue is resolved

This rule ensures code generation integrity and reproducible builds.

-- auto-added by assistant for zorphy code generation integrity
