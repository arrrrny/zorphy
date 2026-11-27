#!/usr/bin/env bash
# check_stacked_pr_integrity.sh — pre-push gate against orphaned stacked PRs.
#
# The failure this prevents (issue #315): a PR merged INTO a stack base branch
# (e.g. #304 merged into `fix/issue-301-…`) is silently orphaned when that base
# branch is force-pushed (rebased) before the PR's content reaches master. The
# merge commit disappears from history, GitHub still shows "MERGED", and the
# content never lands — 3.0.0-dev.4 shipped without `ZorphyField.nested` and a
# downstream PR failed to compile days later.
#
# This gate runs as a git pre-push hook (and in CI). For every ref being pushed
# with a NON-fast-forward (force) update, it lists merged PRs whose merge commit
# is an ancestor of the OLD (remote) tip but NOT of the NEW (local) tip — i.e.
# "this force-push orphans these merged PRs" — and REFUSES the push.
#
# The push is allowed only when STACK_REBASE_OK=1 is exported, which the
# operator must set AFTER re-targeting / reopening the orphaned PRs (or
# re-merging the stack explicitly). The default is to refuse: a force-push that
# drops a merged commit is exactly the dev.4 incident.
#
# stdin (git pre-push protocol): one line per ref
#   <local_ref> <local_sha> <remote_ref> <remote_sha>
#
# The merged-PR list comes from `gh pr list` by default. Tests (and offline
# runs) inject it through GH_PR_LIST_JSON (JSON Lines: one object per line, each
# {number, mergeCommit:{oid}, baseRefName}).
#
# Exit: 0 = push allowed, 1 = orphaning force-push refused.

set -euo pipefail

# Read the git pre-push protocol from stdin up front: one line per ref
#   <local_ref> <local_sha> <remote_ref> <remote_sha>
# An empty stdin means nothing is being pushed, so there is nothing to check —
# allow before any inventory lookup (this is not the fail-open bug: a real push
# with refs still requires a successful inventory below).
stdin_data="$(cat)"
if [ -z "$stdin_data" ]; then
  echo "check_stacked_pr_integrity: no refs on stdin — allowing push"
  exit 0
fi

# The merged-PR inventory: injected JSON Lines (the explicit offline path, used
# verbatim — an empty value is a legitimate "no merged PRs"), or `gh` as the
# fallback. A gh lookup failure FAILS CLOSED (non-zero): a network/auth error
# must never be read as an empty inventory that allows an orphaning force-push
# (issue #322). Using --jq '.[]' keeps it JSON Lines for the parser below.
if [ "${GH_PR_LIST_JSON+x}" = x ]; then
  pr_json="$GH_PR_LIST_JSON"
else
  if ! pr_json="$(gh pr list --state merged --limit 200 \
      --json number,mergeCommit,baseRefName --jq '.[]')"; then
    echo "check_stacked_pr_integrity: gh pr list failed (network/auth) — refusing push (fail closed)" >&2
    exit 1
  fi
fi

if [ -z "$pr_json" ]; then
  echo "check_stacked_pr_integrity: no merged PRs found — allowing push"
  exit 0
fi

# Emit "<number>\t<mergeCommitOid>" for every merged PR that carries a merge
# commit. python3 is present on every host and in CI (ubuntu-latest).
pr_pairs="$(printf '%s\n' "$pr_json" | python3 -c '
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        d = json.loads(line)
    except json.JSONDecodeError:
        continue
    oid = (d.get("mergeCommit") or {}).get("oid") or ""
    if oid:
        print("%s\t%s" % (d.get("number", "?"), oid))
')"

if [ -z "$pr_pairs" ]; then
  echo "check_stacked_pr_integrity: no merged PRs carry a merge commit — allowing push"
  exit 0
fi

# is_ancestor <ancestor> <descendant> — true when <ancestor> is reachable from
# <descendant>. Returns non-zero (false) when either commit is unknown.
is_ancestor() {
  git merge-base --is-ancestor "$1" "$2" 2>/dev/null
}

orphaned=()
while read -r line; do
  [ -z "$line" ] && continue
  local_ref="${line%% *}"; rest="${line#* }"
  local_sha="${rest%% *}"; rest="${rest#* }"
  remote_ref="${rest%% *}"; remote_sha="${rest#* }"

  # Branch deletion (local sha all-zero) or creation (remote sha all-zero):
  # nothing to orphan on a create, and a delete drops no merge commit.
  case "$local_sha" in *[!0]*) ;; *) continue ;; esac
  case "$remote_sha" in *[!0]*) ;; *) continue ;; esac

  # A fast-forward update (old tip reachable from new tip) cannot orphan
  # anything — only a force-push can.
  if is_ancestor "$remote_sha" "$local_sha"; then
    continue
  fi

  # This is a non-fast-forward (force) push of $remote_ref. Find merged PRs
  # whose merge commit was on the OLD tip but is gone from the NEW tip.
  while IFS=$'\t' read -r number oid; do
    [ -z "${oid:-}" ] && continue
    if is_ancestor "$oid" "$remote_sha" && ! is_ancestor "$oid" "$local_sha"; then
      orphaned+=("#$number")
    fi
  done <<< "$pr_pairs"
done <<< "$stdin_data"

if [ "${#orphaned[@]}" -eq 0 ]; then
  echo "check_stacked_pr_integrity: OK — no merged PR content is orphaned by this push"
  exit 0
fi

# Deduplicate while preserving order.
unique_orphans="$(printf '%s\n' "${orphaned[@]}" | awk '!seen[$0]++')"
count="$(printf '%s\n' "$unique_orphans" | grep -c . || true)"

echo "❌ check_stacked_pr_integrity: this force-push orphans $count merged PR(s): $unique_orphans" >&2
echo "   Their merge commits are ancestors of the OLD tip but NOT the new tip —" >&2
echo "   the content would silently evaporate (the 3.0.0-dev.4 / #304 incident)." >&2
echo "   Re-target / reopen those PRs (or re-merge the stack explicitly), then" >&2
echo "   re-run the push with STACK_REBASE_OK=1 to acknowledge." >&2

if [ "${STACK_REBASE_OK:-}" = "1" ]; then
  echo "   STACK_REBASE_OK=1 set — allowing the force-push anyway." >&2
  exit 0
fi

exit 1