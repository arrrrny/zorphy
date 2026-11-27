#!/usr/bin/env bash
# install_hooks.sh — wire the stacked-PR integrity pre-push hook into a clone.
#
# Git does not track hooks, so every clone needs this once:
#   ./scripts/install_hooks.sh
#
# It points core.hooksPath at the tracked scripts/git-hooks directory, so the
# pre-push gate (scripts/check_stacked_pr_integrity.sh) runs on every push
# without each clone re-installing anything. The hook itself is a thin wrapper
# that execs the gate, which is where the logic and the tests live.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

git config core.hooksPath scripts/git-hooks
echo "✅ core.hooksPath -> scripts/git-hooks (pre-push: check_stacked_pr_integrity.sh)"
echo "   Bypass once with: STACK_REBASE_OK=1 git push --force-with-lease …"