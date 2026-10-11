<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan
<!-- SPECKIT END -->

## Branch Strategy

- **Default base for all PRs:** `master`
- **Feature/fix branches:** Branch off master → PR to master
- **development branch:** Scratch/backlog only (optional); NOT a merge target
- **Release flow:** Merge to master with version bump + CHANGELOG = release
- **CI requirements:** All jobs green + 1 review approval before merge
- **No bulk dev→master PRs:** Each PR is individually curated with tests

# Shared terminal (Herdr)

Long-running or user-visible commands (e.g. `dart run build_runner build`)
should run in a **Herdr-managed pane** so both the human and agents see the
same terminal. Agents drive it via the `herdr` CLI; load the `herdr` skill
first (`/skill:herdr`) for the full workflow, pane targeting, and safety rules:

```bash
herdr pane split --current --direction right --cwd "$PWD" --no-focus  # create a visible sibling pane
herdr pane run <pane-id> 'cmd'                                       # run a command in that pane (visible to the human)
herdr pane wait-output <pane-id> --match 'expected output' --timeout 120000   # wait until output appears
herdr pane read <pane-id> --source recent-unwrapped --lines 120      # capture the pane's output
```

See the `herdr` skill (`~/.agents/skills/herdr/SKILL.md`) for the full workflow
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

<!-- local-ci:begin -->
## Running CI locally — `scripts/local_ci.sh`

GitHub Actions is billing-blocked on our private repos: every workflow run ends in
~3s with **zero steps executed**, so a red check here means nothing. Run the same
gate locally instead:

```bash
./scripts/local_ci.sh              # every job of the pull_request workflow
./scripts/local_ci.sh --plan       # print every step that would run, run nothing
./scripts/local_ci.sh --list       # workflows, triggers and jobs in this repo
./scripts/local_ci.sh --job <id>   # one job only
./scripts/local_ci.sh --event push # simulate the push-triggered workflow
./scripts/local_ci.sh --keep-going # do not stop at the first failure
./scripts/local_ci.sh -v           # echo each command before running it
```

It reads `.github/workflows/*` at run time and executes that workflow's jobs and
steps in order, so it cannot drift from CI — it is not a second copy of the gate.
Edit the workflow and the local run changes with it. Exit 0 means every executed
step passed.

What it cannot reproduce, and prints on startup instead of guessing:

- **Linux.** CI runs `ubuntu-latest`; this runs on macOS. The step set is the
  same, the platform is not. `sudo apt-get install` steps are mapped to a local
  presence probe rather than silently passed.
- **GitHub context.** A step needing `${{ secrets.* }}`, `${{ inputs.* }}`,
  `${{ vars.* }}`, `${{ steps.* }}` or `${{ github.event.* }}` is SKIPPED with the
  reason printed, never run with a guessed value.
- **`uses:` actions** are not executed. Toolchain setups (`setup-dart`,
  `setup-node`, `flutter-action`, `rust-toolchain`, …) become a version assertion
  against the local tool; checkout/cache/artifact are noted as no-ops; anything
  else is skipped by name. A Windows-runner job is skipped outright.
- **`container:`** jobs run on the host toolchain, not in the declared image.
- **`continue-on-error: true`** steps are advisory locally, exactly as in CI.
- **Local-only checkout state.** CI checks out the committed tree; this checkout
  also has gitignored and untracked paths, which whole-tree commands (e.g.
  `dart analyze .`) see. A step that fails naming only such paths is reported as
  a LOCAL-ONLY failure, not as a CI failure — pass `--strict` to count it anyway.
  A step that would `git clone` over a sibling checkout that already exists here
  is skipped; `--allow-outside-clone` forces it.

Canonical copy: `arrrrny/forklift` → `scripts/local_ci.sh` (reference:
`docs/forklift-scripts.md`).
<!-- local-ci:end -->


