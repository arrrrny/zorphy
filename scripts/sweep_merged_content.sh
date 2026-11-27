#!/usr/bin/env bash
# sweep_merged_content.sh — post-merge orphan sweep (issue #315).
#
# The backstop to the pre-push gate: for every PR closed-as-merged in the last
# 90 days, assert its merge commit is an ancestor of the base branch (master).
# Any PR whose merge commit is NOT on master is an ORPHANED MERGE — GitHub shows
# "MERGED" but the content never reached the default branch (the 3.0.0-dev.4 /
# #304 failure). The sweep files (or reopens) an issue per orphan so it is
# re-landed immediately.
#
# Runs in CI on a weekly cron and on release, and can be run by hand:
#   GH_PR_LIST_JSON='<json lines>' scripts/sweep_merged_content.sh   # offline
#   scripts/sweep_merged_content.sh                                  # via gh
#
# The merged-PR inventory comes from `gh pr list` by default; tests inject
# GH_PR_LIST_JSON (JSON Lines: {number, mergeCommit:{oid}, baseRefName}).
#
# Exit: 0 = every merged PR's content is on the base branch, 1 = orphan(s)
# found (an issue is filed/reopened for each).

set -euo pipefail

BASE="${SWEEP_BASE:-master}"
DAYS="${SWEEP_DAYS:-90}"

pr_json="${GH_PR_LIST_JSON:-$(gh pr list --state merged --limit 300 \
  --json number,title,mergeCommit,baseRefName --jq '.[]' 2>/dev/null || true)}"

if [ -z "$pr_json" ]; then
  echo "sweep_merged_content: no merged PRs found (gh unavailable or none) — OK"
  exit 0
fi

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
        print("%s\t%s\t%s" % (d.get("number", "?"), oid, d.get("title", "")))
')"

if [ -z "$pr_pairs" ]; then
  echo "sweep_merged_content: no merged PRs carry a merge commit — OK"
  exit 0
fi

is_ancestor() {
  git merge-base --is-ancestor "$1" "$BASE" 2>/dev/null
}

# file_orphan_issue <number> <title> — file a new issue, or reopen the existing
# open/closed one, so an orphan is never silently dropped. Idempotent: a PR that
# already has an "orphaned merge: #N" issue is left alone.
file_orphan_issue() {
  local number="$1" title="$2"
  local issue_title="orphaned merge: #$number content not on $BASE"
  if [ -z "${GH_PR_LIST_JSON:-}" ] && command -v gh >/dev/null 2>&1; then
    if gh issue list --search "$issue_title" --state all --limit 1 \
        --json number --jq '.[0].number' 2>/dev/null | grep -q .; then
      echo "  issue already exists for #$number — leaving it"
      return
    fi
    gh issue create \
      --title "$issue_title" \
      --body "PR #$number ($title) is shown as MERGED but its merge commit is not an ancestor of \`$BASE\`. Its content was orphaned by a force-push of the stack base branch (issue #315). Re-land it immediately." \
      >/dev/null 2>&1 || echo "  ⚠️ could not file issue for #$number"
  fi
}

orphans=()
while IFS=$'\t' read -r number oid title; do
  [ -z "${oid:-}" ] && continue
  if ! is_ancestor "$oid"; then
    orphans+=("#$number")
    echo "orphaned merge: #$number ($title) — $oid not on $BASE" >&2
    file_orphan_issue "$number" "$title"
  fi
done <<< "$pr_pairs"

if [ "${#orphans[@]}" -eq 0 ]; then
  echo "sweep_merged_content: OK — every merged PR's content is on $BASE"
  exit 0
fi

unique_orphans="$(printf '%s\n' "${orphans[@]}" | awk '!seen[$0]++')"
echo "❌ sweep_merged_content: ${unique_orphans//$'\n'/ } orphaned merge(s) — re-land immediately" >&2
exit 1