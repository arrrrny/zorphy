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
