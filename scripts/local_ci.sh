#!/usr/bin/env bash
# local_ci.sh — run THIS repo's CI gate locally, the same steps GitHub Actions runs.
#
# Why: our private repos have no GitHub Actions budget, so every `ci` run ends in
# ~3s with no steps executed. The red check is noise, not signal. This runs the
# same gate locally, so "is CI green?" has a real answer.
#
# HOW IT STAYS IN SYNC: it does not duplicate the workflow. It parses
# `.github/workflows/*` at run time, picks the workflow that runs for the event
# being simulated (default: pull_request), and executes its jobs and steps in
# order. Edit the workflow and the local run changes with it — there is no second
# copy to drift from.
#
# Usage:
#   ./scripts/local_ci.sh                  run the gate (every job, in order)
#   ./scripts/local_ci.sh --plan           print every step that would run
#   ./scripts/local_ci.sh --list           list workflows, triggers and jobs
#   ./scripts/local_ci.sh --job test       run one job (by job id)
#   ./scripts/local_ci.sh --event push     simulate the push-triggered workflow
#   ./scripts/local_ci.sh --workflow .github/workflows/ci.yml
#   ./scripts/local_ci.sh --keep-going     do not stop at the first failure
#   ./scripts/local_ci.sh -v               echo each command before running it
#   ./scripts/local_ci.sh --allow-outside-clone  also run steps that clone over
#                                         an existing sibling checkout (see below)
#
# What it cannot reproduce, and says so out loud instead of guessing:
#   * Linux. CI runs ubuntu-latest; this runs on the local host. The STEP SET is
#     identical, the platform is not. `sudo apt-get install` is mapped to a local
#     presence probe (APT_EQUIVALENTS) rather than silently passed.
#   * `${{ secrets.* }}`, `${{ inputs.* }}`, `${{ vars.* }}`, `${{ steps.* }}`,
#     `${{ needs.* }}`, `${{ github.event.* }}` — there is no GitHub context
#     locally. A step that needs one is SKIPPED with the reason printed, never
#     run with a guessed value. Secrets are the one context an operator can
#     supply FOR REAL (#708): LOCAL_CI_SECRET_<NAME>=… ./scripts/local_ci.sh
#     resolves ${{ secrets.<NAME> }} to that value, and
#     LOCAL_CI_SECRETS="<NAME>,…" reads each name from the ambient environment.
#     The report says which secrets were real and which were blanked; names
#     are printed, values are never echoed — a value a step prints is masked
#     to *** in the echoed and captured output, as GitHub masks it in a log.
#   * `uses:` actions are not executed. Toolchain setups (setup-dart, setup-node,
#     flutter-action, rust-toolchain, …) become a version ASSERTION against the
#     local tool; known no-op actions (checkout/cache/artifacts) are noted; any
#     other action is skipped by name.
#   * `container:` jobs run on the host, not in the declared image (noted).
#   * `strategy.matrix` is expanded as a cross product; `include` merges into
#     every matching combination (or appends a new one when none match) and
#     `exclude` drops matching combinations, as GitHub does.
#   * `continue-on-error: true` (step- or job-level) failures are advisory
#     locally, exactly as in CI.
#   * A `cargo … --target <triple>` step needs a toolchain that carries that
#     target's standard library. A rustup toolchain carrying EVERY target of the
#     step is used for it — through the rustup proxy, so `cargo +<toolchain>`
#     keeps working; when no local toolchain carries them the step is SKIPPED
#     with the reason printed — a host fact, not a repo failure. A host with no
#     rust toolchain at all is a missing TOOLCHAIN: the step FAILS.
#
# HOST FACTS (forklift#941) are decided before any step runs, because a false red
# on a green PR is worse than a slow one — this is the MERGE GATE for our private
# repos (#659):
#   * every step gets a PRIVATE per-run TMPDIR (`$LOCAL_CI_TMPDIR`, else the
#     first candidate with headroom). The caller's TMPDIR is not inherited: two
#     concurrent gates share it and delete each other's `dart_test.kernel.*`
#     cache mid-suite.
#   * a host carrying a sqlite3 RUNTIME object but no `libsqlite3.so` dev symlink
#     gets that symlink in a private dir prepended to `LD_LIBRARY_PATH`, so
#     package:sqlite3's FFI loader resolves instead of failing 96 store-backed
#     tests. A gap with nothing to point at is named in the banner.
#   * a filesystem under `LOCAL_CI_MIN_FREE_MB` (default 256) free aborts the run
#     with one named `disk full:` verdict and exit 3 — no step runs.
#   * a red whose output carries one of those fingerprints (FFI loader,
#     `dart_test.kernel.*` collision) is reported as LOCAL ONLY, like the
#     checkout-state guard's; `--strict` counts it anyway. `disk-full` stays a
#     failure and only gets named, because a suite can eat a disk.
#
# Exit status: 0 when every executed step passed, 1 when a step failed, 2 on a
# usage error, 3 when the host cannot run the gate at all (no headroom) — 3 is
# deliberately not 1: it is "no verdict about this repo", not "this repo is red".
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "${LOCAL_CI_ROOT:-}" ]; then
  root="$LOCAL_CI_ROOT"
elif root="$(git -C "$here" rev-parse --show-toplevel 2>/dev/null)" && [ -n "$root" ]; then
  : # installed inside a git repo: the repo root is the checkout root CI uses
elif [ -d "$here/../.github/workflows" ]; then
  root="$(cd "$here/.." && pwd)"
else
  root="$here"
fi
LOCAL_CI_ROOT="$root" exec python3 - "$@" <<'LOCAL_CI_PY'
"""Run a GitHub Actions workflow locally, faithfully, and say what it cannot do.

This is deliberately NOT a second copy of the workflow: it reads
.github/workflows/* at run time, selects the workflow that runs for the
simulated event, and executes its jobs and steps in order.
"""
import atexit
import ctypes
import glob
import itertools
import json
import os
import platform
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path

ROOT = Path(os.environ.get("LOCAL_CI_ROOT", ".")).resolve()

# `actions/checkout` with a `path:` input stages the repo at <workspace>/<path>
# instead of the workspace root. Locally the repo IS the root, so the layout is
# mirrored with a self-referential symlink; these are removed when the run ends.
CHECKOUT_LINKS = []


def _remove_checkout_links():
    for link in CHECKOUT_LINKS:
        try:
            if link.is_symlink():
                link.unlink()
        except OSError:
            pass


atexit.register(_remove_checkout_links)

BRIGHT, DIM, RESET = "\033[1m", "\033[2m", "\033[0m"
RED, GREEN, YELLOW, CYAN = "\033[31m", "\033[32m", "\033[33m", "\033[36m"


# ------------------------------------------------------------------ YAML subset
# A small indentation-based YAML reader: mappings, sequences, flow lists/maps,
# block scalars (| and >), quoted and plain scalars, comments. It is deliberately
# not a YAML implementation — it covers the shape GitHub Actions files use. It
# never guesses: anything it cannot read raises YamlError with the line number.

class YamlError(Exception):
    pass


def _indent(line):
    return len(line) - len(line.lstrip(" "))


def _ignorable(line):
    s = line.strip()
    return (not s) or s.startswith("#")


def _strip_comment(s):
    out, q = [], None
    for i, ch in enumerate(s):
        if q:
            out.append(ch)
            if ch == q:
                q = None
        elif ch in "'\"":
            q = ch
            out.append(ch)
        elif ch == "#" and (i == 0 or s[i - 1] in " \t"):
            break
        else:
            out.append(ch)
    return "".join(out).rstrip()


def _unquote(s):
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "'\"":
        return s[1:-1]
    return s


def _split_flow(s):
    parts, depth, q, cur = [], 0, None, []
    for ch in s:
        if q:
            cur.append(ch)
            if ch == q:
                q = None
            continue
        if ch in "'\"":
            q = ch
            cur.append(ch)
            continue
        if ch in "[{":
            depth += 1
        elif ch in "]}":
            depth -= 1
        if ch == "," and depth == 0:
            parts.append("".join(cur).strip())
            cur = []
        else:
            cur.append(ch)
    if "".join(cur).strip():
        parts.append("".join(cur).strip())
    return parts


def _scalar(tok):
    tok = tok.strip()
    if tok == "":
        return None
    low = tok.lower()
    if low == "true":
        return True
    if low == "false":
        return False
    if low in ("null", "~"):
        return None
    if tok[0] == "[" and tok[-1] == "]" and len(tok) >= 2:
        inner = tok[1:-1].strip()
        return [_scalar(x) for x in _split_flow(inner)] if inner else []
    if tok[0] == "{" and tok[-1] == "}" and len(tok) >= 2:
        inner = tok[1:-1].strip()
        out = {}
        for part in _split_flow(inner):
            k, _, v = part.partition(":")
            out[_unquote(k)] = _scalar(v)
        return out
    if len(tok) >= 2 and tok[0] == tok[-1] and tok[0] in "'\"":
        return tok[1:-1]
    return tok


def _looks_like_pair(rest):
    """`key: value` / `key:` — but not a plain scalar that merely contains a colon."""
    if rest[:1] in ("'", '"', "[", "{"):
        return False
    return bool(re.match(r"^[A-Za-z_][\w.\-]*\s*:(?:\s|$)", rest))


def _next_content(lines, i):
    while i < len(lines) and _ignorable(lines[i]):
        i += 1
    return i


def _block_scalar(lines, i, key_indent, style):
    body, j = [], i
    while j < len(lines):
        line = lines[j]
        if line.strip() == "":
            body.append("")
            j += 1
            continue
        if _indent(line) <= key_indent:
            break
        body.append(line)
        j += 1
    while body and body[-1] == "":
        body.pop()
    if not body:
        return "", j
    cut = min(_indent(b) for b in body if b.strip())
    text = "\n".join(b[cut:] if b.strip() else "" for b in body)
    if style[0] == ">":
        text = "\n".join(
            " ".join(x.strip() for x in para.split("\n") if x.strip())
            for para in text.split("\n\n")
        )
    return text, j


def parse_map(lines, i, indent):
    out = {}
    while i < len(lines):
        line = lines[i]
        if _ignorable(line):
            i += 1
            continue
        ind = _indent(line)
        if ind < indent:
            break
        if ind > indent:
            i += 1
            continue
        s = _strip_comment(line.strip())
        if re.match(r"^-(?:\s|$)", s):
            break
        if ":" not in s:
            i += 1
            continue
        key, _, val = s.partition(":")
        key = _unquote(key.strip())
        val = val.strip()
        i += 1
        if val[:1] in ("|", ">"):
            body, i = _block_scalar(lines, i, indent, val)
            out[key] = body
            continue
        if val == "":
            j = _next_content(lines, i)
            same_level_seq = j < len(lines) and _indent(lines[j]) == indent \
                and re.match(r"^-(?:\s|$)", lines[j].strip())
            if j < len(lines) and (_indent(lines[j]) > indent or same_level_seq):
                out[key], i = parse_node(lines, j, _indent(lines[j]))
            else:
                out[key] = None
            continue
        out[key] = _scalar(_strip_comment(val))
    return out, i


def parse_seq(lines, i, indent):
    out = []
    while i < len(lines):
        line = lines[i]
        if _ignorable(line):
            i += 1
            continue
        ind = _indent(line)
        if ind < indent:
            break
        if ind > indent:
            i += 1
            continue
        s = _strip_comment(line.strip())
        if not re.match(r"^-(?:\s|$)", s):
            break
        rest = s[1:].lstrip(" ")
        i += 1
        if rest == "":
            j = _next_content(lines, i)
            same_level_seq = j < len(lines) and _indent(lines[j]) == indent \
                and re.match(r"^-(?:\s|$)", lines[j].strip())
            if j < len(lines) and (_indent(lines[j]) > indent or same_level_seq):
                val, i = parse_node(lines, j, _indent(lines[j]))
                out.append(val)
            else:
                out.append(None)
            continue
        if _looks_like_pair(rest):
            # A compact mapping item: re-indent the first pair and swallow the
            # rest of the item's block, including blank lines inside scalars.
            sub = [" " * (indent + 2) + rest]
            pending, j = [], i
            while j < len(lines):
                l2 = lines[j]
                if _ignorable(l2):
                    pending.append(l2)
                    j += 1
                    continue
                if _indent(l2) <= indent:
                    break
                sub.extend(pending)
                pending = []
                sub.append(l2)
                j += 1
            val, _ = parse_map(sub, 0, indent + 2)
            out.append(val)
            i = j
            continue
        out.append(_scalar(rest))
    return out, i


def parse_node(lines, i, indent):
    if i >= len(lines):
        return None, i
    if re.match(r"^-(?:\s|$)", _strip_comment(lines[i].strip())):
        return parse_seq(lines, i, indent)
    return parse_map(lines, i, indent)


def parse_yaml(text):
    lines = text.split("\n")
    lines = [l for l in lines if l.strip() != "---"]
    i = _next_content(lines, 0)
    if i >= len(lines):
        return {}
    val, _ = parse_node(lines, i, _indent(lines[i]))
    return val if isinstance(val, dict) else {}


def parse_workflow(path):
    try:
        return parse_yaml(path.read_text(errors="replace"))
    except YamlError:
        raise
    except Exception as exc:  # pragma: no cover - defensive
        raise YamlError(f"{path}: {exc}") from exc


# ----------------------------------------------------------------- expressions

# Context a local run genuinely does not have. Steps needing these are skipped.
NO_LOCAL_CONTEXT = ("secrets.", "inputs.", "vars.", "steps.", "needs.",
                    "github.event.", "github.token", "github.actor")

# Secrets the operator can hand the local run for real (issue #708). CI resolves
# `${{ secrets.* }}` on GitHub's side; locally there is no GitHub, and #701
# correctly blanks what cannot be resolved — but blanking also means a repo
# whose registry credential is env-var-backed can never pass `Get dependencies`
# here: the gate blanks the variable, pub demands it, and the run is red behind
# an infrastructure error. The operator running this gate HAS the value — the
# whole difference between local and CI — so it can be passed through:
#
#   LOCAL_CI_SECRET_PUB_ZUZU_TOKEN=… ./scripts/local_ci.sh    # direct value
#   LOCAL_CI_SECRETS="PUB_ZUZU_TOKEN" ./scripts/local_ci.sh   # ambient env
#
# A listed name with no ambient value is a misconfiguration: it is named at
# startup and the secret stays blanked, never guessed. Only NAMES are ever
# printed — a value reaches the step's environment and nothing else.
LOCAL_SECRETS = {}
SECRETS_MISSING = []   # LOCAL_CI_SECRETS names the ambient env cannot back
SECRETS_REAL = []      # secrets resolved from a supplied value, in use order
SECRETS_BLANKED = []   # secrets that resolved to "" for lack of a local value


def _collect_local_secrets():
    direct_prefix = "LOCAL_CI_SECRET_"
    for key, value in sorted(os.environ.items()):
        if key.startswith(direct_prefix):
            name = key[len(direct_prefix):]
            if name and value:
                LOCAL_SECRETS[name] = value
    listed = os.environ.get("LOCAL_CI_SECRETS", "")
    for name in (p.strip() for p in re.split(r"[,\s]+", listed)):
        if not name or name in LOCAL_SECRETS:
            continue
        value = os.environ.get(name, "")
        if value:
            LOCAL_SECRETS[name] = value
        else:
            SECRETS_MISSING.append(name)


_collect_local_secrets()


def local_secret(name):
    """The supplied value for secret `name`, or None.

    GitHub reads secret names case-insensitively (`${{ secrets.foo }}` resolves
    the secret stored as FOO), so a case-insensitive match is honoured after
    the exact one. The matched name travels with the value — the accounting
    records the name the operator supplied, not the reference's spelling.
    """
    if name in LOCAL_SECRETS:
        return name, LOCAL_SECRETS[name]
    upper = {k.upper(): (k, v) for k, v in LOCAL_SECRETS.items()}
    return upper.get(name.upper())


def record_real_secrets(hits):
    """Count (expression, supplied name) pairs whose value actually survives.

    Called where a resolved secret's value is really used — a run: body about
    to execute, an `env:` entry that survived into the child env of a step
    past every skip guard — so a secret resolved into a value that is then
    discarded (a sibling ref in the same entry left it unresolvable, a later
    env layer overrode the key, the step was skipped) is never reported as
    real (#708 review, dart_curl#76 review). First-use order.
    """
    for _e, supplied in hits:
        if supplied not in SECRETS_REAL:
            SECRETS_REAL.append(supplied)


def build_github(slug, branch, event, workflow_name, sha):
    return {
        "workspace": str(ROOT),
        "repository": slug,
        "repository_owner": slug.split("/")[0] if "/" in slug else "",
        "ref_name": branch,
        "ref": f"refs/heads/{branch}",
        "event_name": event,
        "workflow": workflow_name,
        "sha": sha,
        "run_id": "0",
        "run_number": "0",
        "run_attempt": "1",
        "server_url": "https://github.com",
        "api_url": "https://api.github.com",
    }


def _split_top(text, op):
    parts, depth, q, cur = [], 0, None, []
    i = 0
    while i < len(text):
        ch = text[i]
        if q:
            cur.append(ch)
            if ch == q:
                q = None
            i += 1
            continue
        if ch in "'\"":
            q = ch
            cur.append(ch)
            i += 1
            continue
        if ch in "([":
            depth += 1
        elif ch in ")]":
            depth -= 1
        if depth == 0 and text.startswith(op, i):
            parts.append("".join(cur).strip())
            cur = []
            i += len(op)
            continue
        cur.append(ch)
        i += 1
    if "".join(cur).strip():
        parts.append("".join(cur).strip())
    return parts


def resolve_ref(expr, ctx, unresolved):
    """Return the string value of a single `${{ … }}` ref, or None."""
    e = expr.strip()
    if e.startswith("github."):
        rest = e[len("github."):]
        if rest in ctx["github"]:
            return str(ctx["github"][rest])
        if rest.startswith("matrix."):
            key = rest[len("matrix."):]
            matrix = ctx.get("matrix") or {}
            if key in matrix:
                return str(matrix[key])
        unresolved.append(e)
        return None
    if e.startswith("matrix."):
        key = e[len("matrix."):]
        matrix = ctx.get("matrix") or {}
        if key in matrix:
            return str(matrix[key])
        unresolved.append(e)
        return None
    if e.startswith("runner."):
        rest = e[len("runner."):]
        if rest in ctx["runner"]:
            return str(ctx["runner"][rest])
        unresolved.append(e)
        return None
    if e.startswith("env."):
        name = e[len("env."):]
        for src in ctx["env_chain"]:
            if name in src:
                return str(src[name])
        unresolved.append(e)
        return None
    if e.startswith("secrets."):
        # An operator-supplied secret resolves FOR REAL (#708) — the probe
        # stays empty, so a step that would otherwise be skipped for GitHub
        # context runs, and an env: entry carries the value instead of "".
        name = e[len("secrets."):]
        resolved = local_secret(name)
        if resolved is not None:
            supplied, value = resolved
            # Being counted as real does NOT happen here (forklift#708 review):
            # a ref can resolve into a value whose entry is then blanked via
            # another ref, and the value is discarded. The promotion lives
            # where the resolved value survives — record_real_secrets().
            hits = ctx.get("secret_hits")
            if isinstance(hits, list):
                hits.append((e, supplied))
            return value
        if name not in SECRETS_BLANKED:
            SECRETS_BLANKED.append(name)
        unresolved.append(e)
        return None
    if any(e.startswith(p) for p in NO_LOCAL_CONTEXT):
        unresolved.append(e)
        return None
    unresolved.append(e)
    return None


def resolve_value(expr, ctx, unresolved):
    """A `${{ … }}` in a value position: refs and simple == / != comparisons."""
    e = expr.strip()
    if "&&" in e or "||" in e:
        unresolved.append(e)  # a fallback expression; not modelled
        return None
    for op in ("==", "!="):
        if op in e:
            left, _, right = e.partition(op)
            lv, rv = _atom(left, ctx, unresolved), _atom(right, ctx, unresolved)
            if lv is None or rv is None:
                return None
            return "true" if ((lv == rv) if op == "==" else (lv != rv)) else "false"
    return resolve_ref(e, ctx, unresolved)


def _atom(tok, ctx, unresolved):
    t = tok.strip()
    if len(t) >= 2 and t[0] == t[-1] and t[0] in "'\"":
        return t[1:-1]
    if t.startswith("${{") and t.endswith("}}"):
        t = t[3:-2].strip()
    if t in ("true", "false"):
        return t
    if t == "":
        return None
    if not re.match(r"^[A-Za-z_][\w.\-]*$", t):
        return t  # a bare literal (number, path, …)
    return resolve_ref(t, ctx, unresolved)


def eval_condition(text, ctx, unresolved):
    """True / False / None (not modelled — the caller then skips the step)."""
    t = text.strip()
    if t.startswith("${{") and t.endswith("}}"):
        t = t[3:-2].strip()
    if t in ("always()", "!cancelled()", "true"):
        return True
    if t in ("false",):
        return False
    if t == "success()":
        return ctx.get("job_ok", True)
    if t == "failure()":
        return not ctx.get("job_ok", True)
    for op, fn in (("||", any), ("&&", all)):
        parts = _split_top(t, op)
        if len(parts) > 1:
            vals = [eval_condition(p, ctx, unresolved) for p in parts]
            if any(v is None for v in vals):
                return None
            return fn(vals)
    if t.startswith("!"):
        v = eval_condition(t[1:], ctx, unresolved)
        return None if v is None else (not v)
    for op in ("==", "!="):
        if op in t:
            left, _, right = t.partition(op)
            lv, rv = _atom(left, ctx, unresolved), _atom(right, ctx, unresolved)
            if lv is None or rv is None:
                return None
            return (lv == rv) if op == "==" else (lv != rv)
    v = _atom(t, ctx, unresolved)
    if v is None:
        return None
    return v not in ("", "false", "False", "0")


EXPR_RE = re.compile(r"\$\{\{\s*(.*?)\s*\}\}")


def expand(text, ctx, unresolved):
    if not isinstance(text, str):
        text = str(text)

    def repl(m):
        v = resolve_value(m.group(1), ctx, unresolved)
        return m.group(0) if v is None else v

    return EXPR_RE.sub(repl, text)


def has_expr(text):
    return isinstance(text, str) and EXPR_RE.search(text) is not None


# --------------------------------------------------------- local apt equivalents

# A `sudo apt-get install` step cannot run on macOS. It is only honest to skip it
# if the INTENT is checked, so each package we know how to map gets a real local
# probe. An unknown package is a warning, never a silent pass and never a failure.
APT_EQUIVALENTS = {
    "libsqlite3-dev": ("sqlite3 development library", "sqlite3"),
    "libssl-dev": ("OpenSSL development library", "openssl"),
    "pkg-config": ("pkg-config", "pkg-config"),
    "build-essential": ("a C toolchain", "cc"),
    "libsecret-1-dev": ("libsecret (keyring)", "pkg-config"),
    "libwebkit2gtk-4.1-dev": ("WebKitGTK", None),
    "libgtk-3-dev": ("GTK 3", None),
    "sqlite3": ("sqlite3", "sqlite3"),
    "zlib1g-dev": ("zlib development library", None),
}


# ------------------------------------------------------- host environment facts

# The gate runs on the operator's own machine, beside up to three other agents
# (forklift#176), and three facts about THAT machine redden an otherwise green
# suite. None of them is a repository defect, so each is decided BEFORE the
# suite runs — and a fingerprint that still surfaces is reported under its class
# instead of being read as a code failure (arrrrny/forklift#941):
#
#   1. package:sqlite3's FFI loader opens `libsqlite3.so`, the DEV symlink. A
#      host carrying only the runtime package (`libsqlite3.so.0`) fails every
#      store-backed test with "Failed to load dynamic library 'libsqlite3.so'".
#   2. The ambient TMPDIR is shared: two concurrent gates delete each other's
#      `dart_test.kernel.*` cache mid-suite, and the suite reports 12 failures.
#   3. A full filesystem surfaces as `No space left on device` inside dozens of
#      tests instead of as the disk problem it is. And when it IS full, the
#      verdict names the stale `dart_test.kernel.*` parents that filled it
#      (arrrrny/forklift#990): on the Linux worker a 13 GB cache two days old
#      took `/` to 100% mid-publish and the verdict named only the watermark,
#      so the operator had to go hunting with `du` while the release was down.

# Headroom a run needs on the filesystems it writes to. Under it the gate
# refuses to start rather than turning a full disk into 42 "test failures".
DEFAULT_MIN_FREE_MB = 256

# How old a `dart_test.kernel.*` parent must be before the disk-full verdict
# names it as the culprit (arrrrny/forklift#990 ask 2). The gate is the
# sweeper's own — `sweep-dart-test-cache.sh` MAX_AGE_HOURS — so the report
# names exactly what that job would reclaim, never a cache belonging to a gate
# that is running right now. The report only NAMES: nothing here deletes, so
# the age can afford to be the conservative one.
DEFAULT_STALE_CACHE_HOURS = 24
KERNEL_CACHE_GLOB = "dart_test.kernel.*"

# Where a per-run TMPDIR may live, after the operator's own override and the
# ambient temp dir: a host whose /tmp is a small tmpfs can still run the gate.
TMPDIR_FALLBACKS = ("/tmp", "/var/tmp")

SQLITE_FFI_NAME = "libsqlite3.so"

# The failure fingerprints, asked in this order. Each names a fact about the
# machine the gate ran on, so each is reported under its own class.
#
# The FFI prefix is deliberately the BARE name: package:sqlite3's loader opens
# `libsqlite3.so` with no directory, so a path-qualified form (`/usr/lib/…`) is
# a different failure this class does not own — and a class that matched the
# path form would claim a message the loader never emits.
SQLITE_FFI_RE = re.compile(r"Failed to load dynamic library\s+'?"
                           + re.escape(SQLITE_FFI_NAME))
# Anchored to the collision signature, not to "any kernel path": the runner
# failing to OPEN a cache it expected to own is the shared-TMPDIR fact, while a
# path merely printed in a failure (the cache-sweep suite's own fixture names)
# is not. An unanchored match downgraded a real red in exactly the file that
# owns this vocabulary.
KERNEL_CACHE_RE = re.compile(
    r"(?:Cannot open file|Failed to load|PathNotFoundException)[^\n]*"
    r"dart_test\.kernel\.[A-Za-z0-9]{6,}")
DISK_FULL_RE = re.compile(r"No space left on device|errno\s*=\s*28\b")

# The classes a preflight cannot prevent yet that are never a repo defect: the
# suite died because of how the host is provisioned, not because of what the
# commit contains. `disk-full` is deliberately NOT here — a suite CAN eat a
# disk, so that red stays a red and only gets named.
LOCAL_ONLY_HOST_CLASSES = ("sqlite3-ffi", "shared-kernel-cache")


def host_fingerprint(output):
    """`(class, sentence)` for the host fact a failure output carries, or None."""
    text = output or ""
    if SQLITE_FFI_RE.search(text):
        return ("sqlite3-ffi",
                "the host has no libsqlite3.so for package:sqlite3's FFI loader "
                "(install the sqlite3 runtime package, or let the preflight "
                "symlink it)")
    if KERNEL_CACHE_RE.search(text):
        return ("shared-kernel-cache",
                "a concurrent run deleted this gate's dart_test.kernel.* cache — "
                "the ambient TMPDIR was shared")
    if DISK_FULL_RE.search(text):
        return ("disk-full",
                "the filesystem filled up while the step ran")
    return None


def disk_free_kib(path):
    """`(free KiB, mount point)` on the filesystem holding `path`, or None.

    `df -P` is POSIX and never wraps a long device name onto a second line, so
    the LAST row is the filesystem asked for: blocks, used, available, capacity,
    mountpoint.
    """
    try:
        out = subprocess.run(["df", "-Pk", str(path)], capture_output=True,
                             text=True, timeout=30).stdout
    except Exception:
        return None
    rows = [ln for ln in out.split("\n") if ln.strip()]
    if len(rows) < 2:
        return None
    fields = rows[-1].split()
    if len(fields) < 4:
        return None
    try:
        return int(fields[3]), fields[-1]
    except ValueError:
        return None


def tree_kib(path):
    """KiB a directory tree occupies, or None when it cannot be measured.

    `du -sk` is the same measurement the sweeper's log line uses, and it is
    only paid on the ABORT path (a handful of cache dirs, never the disk). A
    timeout is an unknown, not a zero: a 13 GB cache on a loaded host can
    outlast 60s, and reporting it as 0 would rank it last instead of first.
    """
    try:
        # No `--` separator: BSD `du` (macOS) does not accept one, and every
        # path here comes from an absolute glob, so it cannot read as an option.
        out = subprocess.run(["du", "-sk", str(path)],
                             capture_output=True, text=True,
                             timeout=60).stdout
    except Exception:
        return None
    fields = out.split()
    if not fields:
        return None
    try:
        return int(fields[0])
    except ValueError:
        return None


def stale_kernel_caches(max_age_hours=DEFAULT_STALE_CACHE_HOURS, limit=3):
    """`[(path, KiB, age_hours)]` for the biggest STALE kernel caches, biggest first.

    arrrrny/forklift#990 ask 2: the 13 GB that filled `/` on the Linux worker
    was a `dart_test.kernel.*` two days old, and the #941 verdict said only
    "disk full: / has 7M free, the gate needs 256M" — the operator still had
    to hunt the culprit by hand while a publish was down.

    Bounded twice over, because this runs on the abort path of a host that is
    already out of disk: the glob is anchored at the temp candidates (a
    handful of dirs, never a filesystem walk — the #395 rule) and `du` only
    descends the matched cache dirs. The age gate reads the cache dir's OWN
    mtime, exactly what the sweeper's kernel-cache pass reads, so "stale"
    means one thing fleet-wide.
    """
    cutoff = time.time() - max_age_hours * 3600
    found = []
    # Measure at most 4x the report size, biggest-uncertainties first: the
    # abort path runs on a host that is already out of disk, so the `du` that
    # feeds a `limit`-line report must not be paid once per stale cache
    # (#991 review — the 13 GB entry is exactly the one a `du` is slow on).
    max_probe = limit * 4
    for base in tmpdir_candidates():
        for path in sorted(glob.glob(os.path.join(base, KERNEL_CACHE_GLOB))):
            if len(found) >= max_probe:
                break
            try:
                stat = os.stat(path)
            except OSError:
                continue
            if not os.path.isdir(path) or stat.st_mtime > cutoff:
                continue
            kib = tree_kib(path)
            # A timeout/unknown is kept, not dropped: "too large to measure in
            # 60s" is itself the strongest signal an entry can carry, and the
            # sort below ranks it FIRST so the biggest culprit is never the
            # one that vanishes (#991 review).
            found.append((path, kib, (time.time() - stat.st_mtime) / 3600))
        if len(found) >= max_probe:
            break
    found.sort(key=lambda item: (item[1] is None, -(item[1] or 0)))
    return found[:limit]


def watermark_kib():
    """`LOCAL_CI_MIN_FREE_MB` in KiB. A typo is a named error, never a default.

    The fleet's convention: an invalid value is reported, not silently replaced
    — a watermark that quietly fell back would let a full disk through as a red.
    """
    raw = (os.environ.get("LOCAL_CI_MIN_FREE_MB") or "").strip()
    if not raw:
        return DEFAULT_MIN_FREE_MB * 1024
    try:
        mb = int(raw)
    except ValueError:
        raise ValueError(f"LOCAL_CI_MIN_FREE_MB={raw!r} is not a whole number "
                         "of megabytes")
    if mb < 0:
        raise ValueError(f"LOCAL_CI_MIN_FREE_MB={mb} is negative")
    return mb * 1024


def tmpdir_candidates():
    """Temp dirs to choose a per-run TMPDIR from, best claim first."""
    out = []
    for name in ("LOCAL_CI_TMPDIR", "TMPDIR", "TEMP", "TMP"):
        value = (os.environ.get(name) or "").strip()
        if value:
            out.append(value)
    out.extend(TMPDIR_FALLBACKS)
    out.append(str(Path.home() / ".cache"))
    seen, paths = set(), []
    for path in out:
        absolute = os.path.abspath(path)
        if absolute not in seen and os.path.isdir(absolute):
            seen.add(absolute)
            paths.append(absolute)
    return paths


def sqlite3_search_dirs():
    """Where a sqlite3 runtime object may live, the operator's claim first.

    `LOCAL_CI_SQLITE_LIB_DIRS` is the documented override (a Nix store, a
    relocated sysroot); `LD_LIBRARY_PATH` is what the loader would already use.
    The multiarch directories are globbed rather than hardcoded: Debian and
    Ubuntu name them after the machine (`x86_64-linux-gnu`, `aarch64-linux-gnu`)
    and that list grows with every architecture.
    """
    dirs = []

    def add(path):
        if path and os.path.isdir(path) and path not in dirs:
            dirs.append(path)

    for name in ("LOCAL_CI_SQLITE_LIB_DIRS", "LD_LIBRARY_PATH"):
        for path in (os.environ.get(name) or "").split(os.pathsep):
            add(path.strip())
    for pattern in ("/usr/lib/*-linux-gnu*", "/lib/*-linux-gnu*",
                    "/usr/lib64", "/usr/lib", "/lib64", "/lib", "/usr/local/lib"):
        for path in sorted(glob.glob(pattern)):
            add(path)
    return dirs


def sqlite3_candidates(dirs):
    """`libsqlite3.so*` files in `dirs` — the un-suffixed one first, if any."""
    exact, versioned = [], []
    for directory in dirs:
        try:
            names = sorted(os.listdir(directory))
        except OSError:
            continue
        for name in names:
            path = os.path.join(directory, name)
            if name == SQLITE_FFI_NAME:
                exact.append(path)
            elif name.startswith(SQLITE_FFI_NAME + "."):
                versioned.append(path)
    return exact + versioned


def sqlite3_ffi_plan(search_dirs):
    """`("ok"|"remedy"|"gap"|"n-a", payload)` for package:sqlite3's FFI loader.

    The loader opens `libsqlite3.so` — the DEV symlink — so a host with the
    runtime package only has a versioned object no loader will find. When one IS
    there, a private symlink dir repairs it for every child step; when nothing
    is, there is nothing to point at and the gap is reported instead. The probe
    is the loader's own: `ctypes.CDLL` resolves exactly what Dart's
    `DynamicLibrary.open` would, so this is never a guess about a path.
    """
    try:
        ctypes.CDLL(SQLITE_FFI_NAME)
        return "ok", None
    except OSError:
        pass
    except Exception:
        return "n-a", None
    found = sqlite3_candidates(search_dirs)
    if found:
        return "remedy", found[0]
    if sys.platform.startswith("linux"):
        return "gap", None
    return "n-a", None   # macOS/Windows open a .dylib/.dll, not a .so


class HostPreflight:
    """What this host can do for the run — decided before any step runs (#941).

    Three decisions, one place: the per-run TMPDIR (never the caller's), the
    sqlite3 FFI remedy, and the disk verdict. The rules themselves are the pure
    functions above; this class carries their outcome into the banner, the child
    environment and the failure classification, so a red can be named instead of
    guessed at.
    """

    def __init__(self, create=True):
        """`create=False` is the `--plan` mode: measure, never touch the disk.

        A dry run must not mkdtemp a per-run TMPDIR (the wrapper TERMs a plan
        and the atexit handler never runs) and must not gain the exit-3 failure
        mode on a full disk, so the preflight reports what it WOULD do and
        creates nothing.
        """
        self.watermark = watermark_kib()
        self.tmp_base, self.tmp_free, self.tmp_mount, self.verdict = (
            self._plan_disk())
        # The disk-full verdict names the watermark and the filesystem; on its
        # own that still left the operator hunting the 13 GB culprit by hand
        # (#990 ask 2). Measured only when the run is ALREADY aborting, so a
        # normal run never pays for a `du`.
        self.culprits = stale_kernel_caches() if self.verdict else []
        # A per-run dir INSIDE the chosen base, so the run owns one tree and one
        # cleanup: the base is shared (and may be the ambient TMPDIR itself, which
        # the run must never remove), while `tmpdir` dies with the run.
        self.tmpdir = None
        if self.tmp_base and not self.verdict:
            self.tmpdir = tempfile.mkdtemp(prefix="local_ci_", dir=self.tmp_base)
        self.sqlite_state, self.sqlite_payload = sqlite3_ffi_plan(
            sqlite3_search_dirs())
        self.remedy_dir = None
        if self.sqlite_state == "remedy" and self.tmpdir:
            self.remedy_dir = self._make_remedy()
            if self.remedy_dir is None:
                self.sqlite_state, self.sqlite_payload = "gap", None
        if not self.tmpdir and not self.verdict and create:
            # No filesystem could be measured (no `df`, no readable mount). The
            # old behaviour — the ambient temp dir — is the only one left, and it
            # is not worth a verdict of its own.
            self.tmpdir = tempfile.mkdtemp(prefix="local_ci_")

    # ------------------------------------------------------------------ disk

    def _plan_disk(self):
        """`(tmp_base, free, mount, verdict)` — the tightest measured filesystem.

        EVERY filesystem this run writes to is measured: the temp candidates and
        the checkout root. `.dart_tool` and every build artifact land in the
        checkout, so a full checkout root is a full run even when /tmp has room —
        the tighter filesystem names the verdict (FR-007). Measuring the root only
        when every temp candidate was already short is the bug #941 review caught:
        on a normal host the first candidate returns and the root is never read.

        A filesystem too small to be measured (no `df`, no readable mount) is not
        an opinion; an unreadable root is likewise skipped, never treated as full.
        """
        watermark = self.watermark
        measured = []
        for path in tmpdir_candidates():
            m = disk_free_kib(path)
            if m is not None:
                measured.append((path, m[0], m[1]))
        root = disk_free_kib(str(ROOT))
        if root is not None:
            measured.append(("", root[0], root[1]))
        if not measured:
            return None, None, None, None

        # The tightest filesystem names the verdict, whatever its role.
        tightest = min(measured, key=lambda item: item[1])
        # The temp base is the roomiest candidate WITH room: a tight one still
        # names the verdict, but the run writes to the base with the most
        # headroom. A host where nothing has room has no base — the verdict
        # already says so, and the caller falls back to the ambient temp dir.
        with_room = [item for item in measured if item[1] >= watermark]
        chosen = max(with_room, key=lambda item: item[1], default=None)

        if tightest[1] < watermark:
            _, free, mount = tightest
            where = "the checkout root" if not tightest[0] else tightest[0]
            verdict = (f"disk full: {mount} has {free // 1024}M free, the gate "
                       f"needs {watermark // 1024}M ({where}) — free space, or "
                       "point LOCAL_CI_TMPDIR at a filesystem with headroom")
            return None, None, None, verdict
        if chosen is None:
            # Nothing measured has room (every reading was unreadable or short).
            return None, None, None, None
        return chosen[0], chosen[1], chosen[2], None

    # --------------------------------------------------------------- sqlite3

    def _make_remedy(self):
        """A private dir holding `libsqlite3.so` -> the versioned runtime object."""
        directory = os.path.join(self.tmpdir, "sqlite-ffi")
        try:
            os.makedirs(directory, exist_ok=True)
            os.symlink(self.sqlite_payload,
                       os.path.join(directory, SQLITE_FFI_NAME))
        except OSError:
            return None
        return directory

    # ------------------------------------------------------------------ edges

    @property
    def blocked(self):
        return self.verdict

    def culprit_lines(self):
        """The stale kernel-cache parents behind a disk-full verdict (#990)."""
        lines = []
        for path, kib, hours in self.culprits:
            size = "size unknown" if kib is None else f"{kib // 1024}M"
            lines.append(f"  {YELLOW}culprit  : {path} {size}, last "
                         f"written {hours:.0f}h ago — a stale "
                         "dart_test.kernel.* parent "
                         f"(sweep-dart-test-cache.sh reclaims it){RESET}")
        return lines

    def plan_lines(self):
        """The host facts a real run WOULD apply, with no directory created.

        `--plan` is a dry run (forklift#941 review): it measures the host and
        says what a real run would do, but a full disk is not a plan failure —
        a plan that reports the plan is more useful than one that exits 3 on a
        machine that happens to be tight right now.
        """
        if self.verdict:
            return [f"  {YELLOW}disk     : {self.verdict} "
                    f"(a real run would abort){RESET}"] + self.culprit_lines()
        lines = []
        if self.tmp_base:
            lines.append(f"  tmpdir   : {self.tmp_base} would hold a private "
                         f"per-run TMPDIR ({self.tmp_free // 1024}M free) — "
                         "created for a real run, not for a plan")
        if self.sqlite_state == "remedy":
            lines.append(f"  sqlite3  : {SQLITE_FFI_NAME} does not resolve; a "
                         f"real run would symlink {self.sqlite_payload}")
        elif self.sqlite_state == "ok":
            lines.append(f"  sqlite3  : {SQLITE_FFI_NAME} resolves for the FFI "
                         "loader")
        elif self.sqlite_state == "gap":
            lines.append(f"  {YELLOW}sqlite3  : {SQLITE_FFI_NAME} does not "
                         "resolve and no libsqlite3.so.* exists — install the "
                         f"sqlite3 runtime package{RESET}")
        return lines

    def banner_lines(self):
        """The host facts this run applied, one line each (printed at startup)."""
        if self.verdict:
            return [f"  {YELLOW}disk     : {self.verdict}{RESET}"] + \
                self.culprit_lines()
        lines = []
        if self.tmpdir:
            ambient = os.path.abspath(os.environ.get("TMPDIR") or "")
            note = ("" if self.tmp_base == ambient
                    else f"; the ambient TMPDIR ({os.environ.get('TMPDIR') or 'unset'}) "
                         "is not inherited")
            lines.append(f"  tmpdir   : {self.tmpdir} "
                         f"({self.tmp_free // 1024}M free) — private per-run "
                         f"TMPDIR{note}")
        if self.sqlite_state == "remedy":
            lines.append(
                f"  sqlite3  : {SQLITE_FFI_NAME} does not resolve; symlinked "
                f"{self.sqlite_payload} into {self.remedy_dir} and prepended to "
                "LD_LIBRARY_PATH for every step")
        elif self.sqlite_state == "ok":
            lines.append(f"  sqlite3  : {SQLITE_FFI_NAME} resolves for the FFI "
                         "loader")
        elif self.sqlite_state == "gap":
            lines.append(
                f"  {YELLOW}sqlite3  : {SQLITE_FFI_NAME} does not resolve and no "
                "libsqlite3.so.* exists — install the sqlite3 runtime package, or "
                "store-backed suites will die in the FFI loader"
                f"{RESET}")
        return lines

    def child_env(self, env):
        """`env` with this run's host decisions applied to every step.

        TMPDIR is FORCED, not defaulted: the caller's value is exactly what #941
        is about, and an operator's shell TMPDIR is a shared /tmp. TMP/TEMP are
        moved with it only when they were the same directory, so a workflow that
        deliberately pins them somewhere else is not overridden.
        """
        if self.tmpdir:
            ambient = os.environ.get("TMPDIR") or ""
            env["TMPDIR"] = self.tmpdir
            for alias in ("TMP", "TEMP"):
                if env.get(alias) and env.get(alias) == ambient:
                    env[alias] = self.tmpdir
        if self.remedy_dir:
            existing = (env.get("LD_LIBRARY_PATH") or "").strip()
            env["LD_LIBRARY_PATH"] = (
                self.remedy_dir + os.pathsep + existing if existing
                else self.remedy_dir)
        return env


# ------------------------------------------------- forbidden cache-clean steps

# A cache-destroying step has NO honest local equivalent: `flutter clean`
# wipes the flutter tool cache and an app repo's SPM-managed iOS dependencies,
# `flutter/dart pub cache clean` wipes the whole pub cache — 20–30 minutes of
# rebuild on the shared Intel Mac, and on app repos a nuked SPM plugin graph.
# These are HARD FORBIDDEN on the fleet (AGENTS.md), so the step is SKIPPED
# with the reason printed, never executed locally. CI keeps it: on a runner
# the checkout is disposable and the next step re-resolves everything a
# pure-Dart package needs (`pub get`).
# Ported from arrrrrny/zuraffa_ui#71 (PR #74, commit fc559cc) into the
# canonical copy — arrrrrny/forklift#1011 — so the fleet rollout cannot
# silently revert the guard in the repo that first ran into the incident.
FORBIDDEN_CLEAN_RE = re.compile(
    r"^\s*(?:sudo\s+)?(?:(?:flutter|dart)\s+pub\s+cache\s+clean|flutter\s+clean)"
    r"(?:\s+\S.*)?\s*$",
    re.I,
)


def forbidden_clean_commands(body):
    """The forbidden cache-clean commands a step body asks for, verbatim.

    Only a command with the destructive HEAD counts: `flutter clean` as its
    own step (or its own pipeline line) is the destructive act, trailing
    flags included — `flutter clean --verbose` wipes the same caches; a word
    like `clean` inside another command (`flutter test --plain-name clean`,
    `git clean -fdx`) is not.
    """
    out = []
    for argv in _shell_commands(body):
        if not argv:
            continue
        i = 0
        while i < len(argv) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", argv[i]):
            i += 1
        candidate = " ".join(argv[i:])
        if FORBIDDEN_CLEAN_RE.match(candidate):
            out.append(candidate)
    return out


# ------------------------------------------------------- cargo cross targets

# A `cargo … --target <triple>` step needs a toolchain that carries that
# target's standard library. Homebrew's standalone rust ships no cross targets,
# so the step dies with "can't find crate for `core`" — a fact about the HOST's
# toolchain, not about the repository. CI installs a rustup toolchain WITH the
# target (dtolnay/rust-toolchain), so the local run asks the same question the
# apt steps ask: is there a local toolchain that can do this? If yes, use it;
# if no, skip the step with the reason printed — never a red gate that says
# nothing about the repo.
# A rust target triple always carries a dash — `wasm32-wasip2`,
# `x86_64-apple-darwin`, `aarch64-unknown-linux-gnu`. A `--target` value
# without one is not a rust target at all (it belongs to some other tool that
# happens to use the same flag), and reading it as a cross target would skip a
# build that has to run.
TARGET_TRIPLE_RE = re.compile(r"^[A-Za-z0-9_]+-[A-Za-z0-9_.-]+$")

CARGO_COMMANDS = ("cargo", "rustc")


def _strip_comment(line):
    """`line` without its trailing shell comment.

    A commented-out command asks for nothing: reading its `--target` would
    skip a step whose real work is still to be done.
    """
    out = []
    quote = None
    for i, ch in enumerate(line):
        if quote:
            out.append(ch)
            if ch == quote:
                quote = None
            continue
        if ch in ("'", '"'):
            quote = ch
            out.append(ch)
            continue
        if ch == "#" and (i == 0 or line[i - 1] in " \t;&|()"):
            break
        out.append(ch)
    return "".join(out)


def _shell_commands(body):
    """The individual shell commands in `body`, as argv lists.

    Backslash continuations are joined first, so a `--target` that sits on a
    line of its own is read together with the cargo command it belongs to.
    Comments are stripped before the line is split into commands, so a
    commented-out cargo command names no target.
    """
    text = re.sub(r"\\\s*\n", " ", body)
    commands = []
    for line in text.split("\n"):
        line = _strip_comment(line)
        if not line.strip():
            continue
        try:
            lexer = shlex.shlex(line, posix=True, punctuation_chars=True)
            lexer.whitespace_split = True
            lexer.commenters = ""
            tokens = list(lexer)
        except ValueError:
            tokens = line.split()
        current = []
        for token in tokens:
            if token in ("&&", "||", ";", "|", "&"):
                if current:
                    commands.append(current)
                current = []
            else:
                current.append(token)
        if current:
            commands.append(current)
    return commands


def _leading_assignments(argv, env):
    """`env` updated with the `NAME=value` words that lead `argv`."""
    for word in argv:
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", word)
        if not m:
            break
        env[m.group(1)] = m.group(2)
    return env


def _expand_word(word, env):
    """`word` with `$VAR`/`${VAR}` replaced from `env` (unknown names stay)."""
    def repl(m):
        return env.get(m.group(1) or m.group(2), m.group(0))
    return re.sub(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)",
                  repl, word)


def _cargo_argv(argv):
    """The argv of the cargo/rustc command in `argv` (None when there is none).

    Only the command's OWN flags count: a `--target` that belongs to another
    program on the same line (`cargo build && ./deploy --target staging`) is
    that program's flag, not a rust cross target.
    """
    i = 0
    while i < len(argv) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", argv[i]):
        i += 1
    if i >= len(argv):
        return None
    command = os.path.basename(argv[i])
    if command in CARGO_COMMANDS:
        return argv[i + 1:]
    if command == "rustup":
        # `rustup run <toolchain> cargo build …` — the cargo command is in there
        for j in range(i + 1, len(argv)):
            if os.path.basename(argv[j]) in CARGO_COMMANDS:
                return argv[j + 1:]
    return None


def cargo_cross_targets(body):
    """The cross targets the cargo/rustc commands in `body` ask for."""
    targets = []
    env = {}
    for argv in _shell_commands(body):
        env = _leading_assignments(argv, env)
        args = _cargo_argv(argv)
        if args is None:
            continue
        for i, arg in enumerate(args):
            if arg == "--target" and i + 1 < len(args):
                value = args[i + 1]
            elif arg.startswith("--target="):
                value = arg[len("--target="):]
            else:
                continue
            value = _expand_word(value, env)
            if not TARGET_TRIPLE_RE.match(value):
                continue
            targets.append(value)
    return list(dict.fromkeys(targets))


# The probe runs on every step of every job, so the answers it needs from the
# host are asked once and remembered: the toolchain on PATH does not change
# while the gate runs.
_HOST_CACHE = {}


def rustc_exe():
    """The rustc on PATH (None when there is none)."""
    if "rustc" not in _HOST_CACHE:
        _HOST_CACHE["rustc"] = shutil.which("rustc")
    return _HOST_CACHE["rustc"]


def cargo_exe():
    """The cargo on PATH (None when there is none)."""
    if "cargo" not in _HOST_CACHE:
        _HOST_CACHE["cargo"] = shutil.which("cargo")
    return _HOST_CACHE["cargo"]


def rustc_sysroot():
    """The sysroot of the rustc on PATH (empty when there is none)."""
    if "sysroot" in _HOST_CACHE:
        return _HOST_CACHE["sysroot"]
    exe = rustc_exe()
    if not exe:
        _HOST_CACHE["sysroot"] = ""
        return ""
    try:
        out = subprocess.run([exe, "--print", "sysroot"],
                             capture_output=True, text=True, timeout=60)
        value = (out.stdout or "").strip().split("\n")[0].strip()
    except Exception:
        value = ""
    _HOST_CACHE["sysroot"] = value
    return value


def carries_target(sysroot, target):
    """True when `sysroot` holds the standard library for `target`."""
    if not sysroot:
        return False
    return (Path(sysroot) / "lib" / "rustlib" / target / "lib").is_dir()


def rustup_home():
    """The rustup home on this host. RUSTUP_HOME wins, as it does for rustup."""
    if "rustup_home" in _HOST_CACHE:
        return _HOST_CACHE["rustup_home"]
    env = os.environ.get("RUSTUP_HOME")
    if env:
        _HOST_CACHE["rustup_home"] = env
        return env
    for exe in (shutil.which("rustup"),
                os.path.expanduser("~/.cargo/bin/rustup")):
        if not exe or not os.path.exists(exe):
            continue
        try:
            out = subprocess.run([exe, "show", "home"],
                                 capture_output=True, text=True, timeout=60)
        except Exception:
            continue
        home = (out.stdout or "").strip()
        if home:
            _HOST_CACHE["rustup_home"] = home
            return home
    default = os.path.expanduser("~/.rustup")
    value = default if os.path.isdir(default) else ""
    _HOST_CACHE["rustup_home"] = value
    return value


def rustup_proxy_dir():
    """The directory holding rustup's PROXY binaries (cargo, rustc, rustup).

    The proxy is what implements `cargo +<toolchain>` and honours
    RUSTUP_TOOLCHAIN. A toolchain's own `bin` holds the REAL cargo, which
    knows about neither — putting that on PATH breaks `cargo +<toolchain>`.
    """
    if "proxy_dir" in _HOST_CACHE:
        return _HOST_CACHE["proxy_dir"]
    value = ""
    for exe in (shutil.which("rustup"),
                os.path.expanduser("~/.cargo/bin/rustup")):
        if not exe or not os.path.exists(exe):
            continue
        directory = os.path.dirname(os.path.abspath(exe))
        if os.path.exists(os.path.join(directory, "cargo")):
            value = directory
            break
    _HOST_CACHE["proxy_dir"] = value
    return value


def rustup_default_toolchain():
    """The toolchain rustup would pick by default (RUSTUP_TOOLCHAIN wins)."""
    if "default_toolchain" in _HOST_CACHE:
        return _HOST_CACHE["default_toolchain"]
    value = (os.environ.get("RUSTUP_TOOLCHAIN") or "").strip()
    if not value:
        home = rustup_home()
        settings = Path(home) / "settings.toml" if home else None
        if settings and settings.is_file():
            found = re.search(r'^\s*default_toolchain\s*=\s*"([^"]+)"',
                              settings.read_text(errors="replace"), re.M)
            if found:
                value = found.group(1)
    _HOST_CACHE["default_toolchain"] = value
    return value


def toolchain_is(name, wanted):
    """True when the installed toolchain `name` is the `wanted` one."""
    if not wanted:
        return False
    return name == wanted or name.startswith(wanted + "-")


def rustup_toolchains():
    """(name, root) of every installed rustup toolchain."""
    home = rustup_home()
    if not home:
        return []
    root = Path(home) / "toolchains"
    if not root.is_dir():
        return []
    return [(t.name, str(t)) for t in sorted(root.iterdir()) if t.is_dir()]


def rustup_toolchain_carrying(target):
    """(name, root) of an installed rustup toolchain that carries `target`."""
    for name, root in rustup_toolchains():
        if carries_target(root, target):
            return name, root
    return None, None


def select_toolchain(targets, pinned=None):
    """The installed toolchain that carries EVERY target, most specific first.

    The toolchain the workflow pins wins over rustup's default, which wins
    over "any toolchain that happens to have the target": a local build on a
    different compiler than CI's is a silent difference, so the choice is
    made the way CI makes it.

    Returns (name, root, others) — `others` are the other toolchains that
    carry every target too, so the note can say the choice was not the only
    possible one.
    """
    candidates = rustup_toolchains()
    if not candidates:
        return None, None, []
    default = rustup_default_toolchain()

    def rank(item):
        name = item[0]
        if toolchain_is(name, pinned):
            return 0
        if toolchain_is(name, default):
            return 1
        return 2

    ordered = sorted(candidates, key=rank)
    carrying = [(name, root) for name, root in ordered
                if all(carries_target(root, t) for t in targets)]
    if not carrying:
        return None, None, []
    name, root = carrying[0]
    return name, root, [n for n, _ in carrying[1:]]


# -------------------------------------------------------------- toolchain uses

# `uses:` action -> (tool, version-keys, version args). The action is not run;
# instead the local tool is asserted to exist and its version is compared with
# the version the workflow pins.
TOOLCHAIN_ACTIONS = (
    ("setup-dart", "dart", ("sdk", "dart-version", "version"), ("--version",)),
    ("flutter-action", "flutter", ("flutter-version", "version"), ("--version",)),
    ("setup-node", "node", ("node-version", "node-version-file"), ("--version",)),
    ("pnpm/action-setup", "pnpm", ("version",), ("--version",)),
    ("setup-python", "python3", ("python-version",), ("--version",)),
    ("setup-go", "go", ("go-version",), ("version",)),
    ("setup-java", "java", ("java-version", "distribution"), ("-version",)),
    ("setup-dotnet", "dotnet", ("dotnet-version",), ("--version",)),
    ("setup-ruby", "ruby", ("ruby-version",), ("--version",)),
    ("setup-bun", "bun", ("bun-version",), ("--version",)),
    ("setup-swift", "swift", ("swift-version",), ("--version",)),
    ("rust-toolchain", "cargo", ("toolchain",), ("--version",)),
    ("setup-php", "php", ("php-version",), ("--version",)),
)

NOOP_ACTIONS = ("actions/checkout", "actions/cache", "cache/", "upload-artifact",
                "download-artifact", "actions/setup-", "softprops/action-gh-release",
                "actions/github-script", "codecov/", "docker/", "docker/build-push")


class Outcome:
    def __init__(self):
        self.ran = self.checked = 0
        self.targets = 0  # verified rust cross targets — counted apart from steps
        self.skipped, self.advisory, self.failed = [], [], []
        self.local_only = []


class Runner:
    def __init__(self, workflow_path, doc, args):
        self.path = workflow_path
        self.doc = doc
        self.args = args
        self.out = Outcome()
        self.job_ok = True
        # job-level continue-on-error (#775): in GitHub Actions it tolerates
        # the failure of every step in the job — the job reports red, only the
        # run stays green. fail() inherits it as the default for each step's
        # advisory decision.
        self.job_continue = False
        # an unsoftened step failed in this job (#780 review): a failure CI
        # does not record as a successful step — a job-level soft-gate's step
        # or a hard one — fails the job, so its later implicit-success steps
        # are skipped. A step-level continue-on-error failure is recorded as
        # success in CI and does NOT count here.
        self.job_unsoftened = False
        self.stopped = False
        self.current_ctx = None
        self.absent_prefixes = ci_absent_prefixes()
        self.pinned_toolchain = None
        # The host preflight of this run (forklift#941), attached by run() once
        # the disk verdict is known. None on a --list run, which never steps.
        self.host = None

    # ------------------------------------------------------------ job plumbing

    def run(self):
        wf_env = self.doc.get("env") or {}
        jobs = self.doc.get("jobs") or {}
        if not isinstance(jobs, dict) or not jobs:
            sys.exit("local_ci.sh: the workflow declares no jobs")

        selected = list(jobs.items())
        if self.args.get("job"):
            selected = [(k, v) for k, v in selected if k == self.args["job"]]
            if not selected:
                sys.exit(f"local_ci.sh: no job {self.args['job']!r} "
                         f"(have: {', '.join(jobs)})")
        else:
            order = job_order(jobs)
            selected = [(k, jobs[k]) for k in order]

        for job_id, job in selected:
            if self.stopped:
                break
            self.run_job(job_id, job, wf_env)

    def run_job(self, job_id, job, wf_env):
        if not isinstance(job, dict):
            self.skip_job(job_id, "job is not a mapping")
            return
        if job.get("uses"):
            self.skip_job(job_id, f"reusable workflow call ({job['uses']})")
            return
        matrix = (job.get("strategy") or {}).get("matrix")
        combos = expand_matrix(matrix, self.base_ctx(None))
        if combos is None:
            self.skip_job(job_id, "strategy.matrix is dynamic — could not be expanded")
            return
        for combo in combos:
            self.run_combo(job_id, job, wf_env, combo)

    def run_combo(self, job_id, job, wf_env, combo):
        label = job_id if not combo else f"{job_id} [matrix: " + ", ".join(
            f"{k}={v}" for k, v in combo.items()) + "]"
        if job.get("if"):
            probe = []
            verdict = eval_condition(job["if"], self.ctx_for(wf_env, {}, {}, combo), probe)
            if verdict is not True:
                self.skip_job(label, f"if: {job['if']}" +
                              ("" if verdict is None else " (false for this run)"))
                return

        runs_on = job.get("runs-on")
        probe = []
        if has_expr(str(runs_on)):
            runs_on = expand(str(runs_on), self.ctx_for(wf_env, {}, {}, combo), probe)
        runs_on = str(runs_on or "")
        if runs_on.startswith("windows"):
            self.skip_job(label, f"runs-on: {runs_on} — a Windows runner cannot be "
                                 "reproduced on this host")
            return

        print(f"\n{BRIGHT}▶ job {label}{RESET}")
        if runs_on and not runs_on.startswith(("ubuntu-", "macos-")):
            print(f"  {YELLOW}note{RESET} runs-on: {runs_on} (running on this host anyway)")
        if job.get("container"):
            image = job["container"]
            if isinstance(image, dict):
                image = image.get("image", "?")
            print(f"  {YELLOW}note{RESET} CI runs this job in container {image}; "
                  "this run uses the host toolchain")

        job_env = job.get("env") or {}
        defaults = ((job.get("defaults") or {}).get("run") or {})
        job_wd = defaults.get("working-directory") or ""
        steps = job.get("steps") or []
        if not isinstance(steps, list):
            self.skip_job(label, "steps is not a list")
            return
        self.job_ok = True
        self.job_continue = bool(job.get("continue-on-error"))
        self.job_unsoftened = False
        self.pinned_toolchain = None
        for n, step in enumerate(steps, 1):
            if self.stopped:
                return
            if not isinstance(step, dict):
                continue
            self.run_step(job_id, step, n, len(steps), wf_env, job_env, job_wd, combo)

    def ctx_for(self, wf_env, job_env, step_env, combo):
        final = {}
        chain = []
        # An `env:` value that resolves to an unresolvable expression must NOT
        # reach the child environment as its literal text. A `run:` body gets
        # that treatment already (the step is skipped on `probe`), but `env:`
        # is expanded here with the probe discarded — so
        # `PUB_ZUZU_TOKEN: ${{ secrets.X }}` used to be exported verbatim, and
        # `dart pub` then read the literal as the credential and rejected it
        # ("not a valid Bearer token") on a tree that is green in CI.
        #
        # The variable is kept and set to the EMPTY string, not dropped
        # (forklift#701 review): GitHub resolves an undefined secret to `""`,
        # so in CI the variable is present-but-empty. Dropping it makes a step
        # under `set -u` / `${VAR:?}` fail locally while passing in CI — the
        # same inversion, one layer down. A value mixing literal text with the
        # expression (`Bearer ${{ secrets.X }}`) becomes `Bearer ` in CI, which
        # is what stripping the expression yields here.
        unresolved = {}
        secret_env_hits = {}
        for layer in (wf_env, job_env, step_env):
            for k, v in (layer or {}).items():
                ctx = self.base_ctx(combo)
                ctx["env_chain"] = [final] + chain
                hits = []
                ctx["secret_hits"] = hits
                probe = []
                value = expand(v, ctx, probe) if isinstance(v, str) else v
                if probe:
                    unresolved[k] = probe[0]
                    final[k] = EXPR_RE.sub("", v) if isinstance(v, str) else ""
                    # the winner is blanked — a secret it resolved can never
                    # reach the child through this key
                    secret_env_hits.pop(k, None)
                else:
                    final[k] = value
                    unresolved.pop(k, None)
                    # the entry holds real, locally supplied secret(s) (#708).
                    # Claimed here and not in resolve_ref: a ref resolved into
                    # an entry that is blanked via a sibling ref never reaches
                    # the environment. Every expression in the value is named,
                    # not just the first. NOT promoted here (dart_curl#76
                    # review): a later layer may still override the key with a
                    # literal, and the step's `if:` may skip it before any
                    # child materializes the env — the hits are kept per key,
                    # last layer wins, and run_step promotes them where the
                    # child env is final.
                    secret_env_hits[k] = hits
            chain.append(dict(final))
        all_env = dict(os.environ)
        all_env.update({k: str(v) for k, v in final.items() if v is not None})
        ctx = self.base_ctx(combo, env_chain=[final, dict(os.environ)],
                            environ=all_env)
        ctx["unresolved_env"] = unresolved
        secret_env_hits = {k: h for k, h in secret_env_hits.items() if h}
        ctx["secret_env"] = {k: ", ".join(e for e, _ in h)
                             for k, h in secret_env_hits.items()}
        ctx["secret_env_hits"] = secret_env_hits
        return ctx

    def base_ctx(self, combo, env_chain=None, environ=None):
        # GitHub's own name for this platform, so `if: runner.os == 'macOS'`
        # steps behave here exactly as they would on a macOS runner.
        runner_os = {"darwin": "macOS"}.get(sys.platform, "Linux")
        return {
            "github": self.github,
            "runner": {"os": runner_os, "arch": "ARM64" if platform.machine() == "arm64" else "X64",
                       "temp": self.runner_temp, "tool_cache": self.runner_temp},
            "matrix": combo or {},
            "env_chain": env_chain or [dict(os.environ)],
            "environ": environ or dict(os.environ),
            "job_ok": self.job_ok,
        }

    # ------------------------------------------------------------- step runner

    def run_step(self, job_id, step, n, total, wf_env, job_env, job_wd, combo):
        label = step_label(step)
        head = f"[{job_id} {n}/{total}] {label}"
        ctx0 = self.ctx_for(wf_env, job_env, {}, combo)

        if step.get("if"):
            probe = []
            verdict = eval_condition(str(step["if"]), ctx0, probe)
            if verdict is not True:
                why = f"if: {step['if']}" + ("" if verdict is None else " (false)")
                self.skip(head, why)
                return
        elif self.job_unsoftened:
            # CI-fidelity (forklift#780 review): after an unsoftened failed
            # step the job has failed, and a step WITHOUT an `if:` carries an
            # implicit `if: success()` — CI skips it; only `failure()` /
            # `always()` steps run. That holds inside a job-level
            # continue-on-error job too, which softens only the run verdict:
            # the advisory branch of fail() keeps the run green but still
            # marks the job, so this keeps the remaining steps of a
            # soft-gated job in lockstep with CI instead of running side
            # effects CI never performs. A step-level continue-on-error
            # failure does NOT gate this — CI records that step as success
            # and runs the later default steps.
            self.skip(
                head,
                "implicit if: success() — the job already has a failed step, "
                "so CI would skip this step",
            )
            return

        if step.get("uses"):
            self.current_ctx = ctx0
            self.run_uses(step, head, job_id, job_wd)
            return

        body = step.get("run")
        if not isinstance(body, str) or not body.strip():
            self.skip(head, "empty run step")
            return

        probe = []
        ctx = self.ctx_for(wf_env, job_env, step.get("env") or {}, combo)
        body_hits = []  # secrets the run: body resolves (#708)
        ctx["secret_hits"] = body_hits
        body_expanded = expand(body, ctx, probe)
        wd = step.get("working-directory") or job_wd
        wd_probe = []
        wd = expand(str(wd), ctx, wd_probe) if wd else ""
        probe.extend(wd_probe)
        if probe:
            self.skip(head, "needs GitHub context: "
                            + ", ".join(sorted(set(probe))[:3]))
            return
        # The body runs with the values it resolved (#708): claimed here, after
        # the probe check — a body skipped for unresolvable context must not
        # report its secret as real either.
        record_real_secrets(body_hits)

        # An `env:` entry that needed GitHub context is exported EMPTY, never as
        # its literal `${{ … }}` text (forklift#701). Say so on the step, so a
        # variable the step reads as empty is explained rather than mysterious.
        blanked_env = ctx.get("unresolved_env") or {}
        if blanked_env:
            names = ", ".join(f"{k} ({v})" for k, v in sorted(blanked_env.items()))
            print(f"  {YELLOW}note{RESET} env set empty locally: {names}")
        # The honest counterpart (#708): an entry that got a REAL value from a
        # locally supplied secret says so, in the same shape as the blanking
        # note. Names only — the value itself is never echoed.
        real_env = ctx.get("secret_env") or {}
        if real_env:
            names = ", ".join(f"{k} ({v})" for k, v in sorted(real_env.items()))
            print(f"  {CYAN}note{RESET} env set from local secrets: {names}")

        apt = self.apt_step(body_expanded, head)
        if apt is not None:
            return

        # A cache-destroying step is forbidden on the fleet (AGENTS.md): its
        # caches take 20–30 minutes to rebuild on the shared Intel Mac, and on
        # an app repo `flutter clean` also nukes SPM-managed iOS dependencies.
        # CI can have it (disposable runner); locally it is skipped loudly.
        # The check sits BEFORE every other guard, so the step never even
        # reaches a run path (zuraffa_ui#71 — a live run got as far as
        # `dart pub cache clean`'s interactive `Are you sure? (y/N)?` prompt;
        # ported to the canonical copy by forklift#1011).
        banned = forbidden_clean_commands(body_expanded)
        if banned:
            self.skip(head, ", ".join(banned)
                      + " is forbidden locally (fleet hard rule) — CI-only step; "
                      "the caches it destroys take 20–30 min to rebuild on this "
                      "shared host, and the follow-up pub get step re-resolves "
                      "what a pure-Dart package needs")
            return

        cwd = ROOT / wd if wd else ROOT
        if not cwd.is_dir():
            self.fail(head, f"working-directory does not exist: {wd}", step)
            return

        # A CI checkout starts empty, so bootstrapping steps clone sibling repos
        # into ../. Locally those paths are the real sibling checkouts: cloning
        # over one fails, and the follow-up `git -C <sibling> checkout` would move
        # someone else's HEAD. Skip it loudly rather than mangle a working tree.
        if not self.args.get("allow_outside_clone"):
            over = [d for d in clone_targets(body_expanded, cwd)
                    if d.exists() and not str(d.resolve()).startswith(str(ROOT))]
            if over:
                self.skip(head, "would clone over an existing local checkout outside this "
                                f"repo ({over[0]}) — CI clones it, here it already exists. "
                                "Pass --allow-outside-clone to run it anyway")
                return

        # A cargo step that builds for a cross target needs a toolchain that
        # carries that target. Ask the host which one that is BEFORE running
        # the step: a standalone toolchain that cannot build it is a host fact,
        # and a red step about it says nothing about the repository. The
        # verdict comes AFTER the path guards, so a broken working directory
        # still fails the gate instead of hiding behind a skip about a target.
        verdict, payload = self.cross_target_verdict(body_expanded)
        if verdict == "missing_toolchain":
            self.fail(head, "cargo is NOT installed — this step would fail in CI too",
                      step)
            return
        if verdict == "skip":
            missing, sysroot = payload
            names = ", ".join(missing)
            one = len(missing) == 1
            if not sysroot:
                cause = "the rustc on PATH reports no sysroot here"
            else:
                paths = ", ".join(f"{sysroot}/lib/rustlib/{t}" for t in missing)
                cause = (f"the cargo on PATH has no {names} std (no {paths})")
            if any(rustup_toolchain_carrying(t)[0] for t in missing):
                carried = ("no single rustup toolchain here carries every "
                           "target of the step" if one else
                           "no single rustup toolchain here carries all of them")
            else:
                carried = ("no rustup toolchain here has it either" if one
                           else "no rustup toolchain here has them either")
            self.skip(head, f"no local toolchain carries the {names} "
                            f"{'target' if one else 'targets'} ({cause}, and "
                            f"{carried}). CI installs "
                            f"{'it' if one else 'them'} with "
                            f"`rustup target add {' '.join(missing)}` — do the same "
                            f"locally, or put a rustup-managed cargo first on PATH")
            return
        path_prefix = None
        toolchain_env = None
        toolchain_note = None
        if verdict == "override":
            name, root, sysroot, missing, others = payload
            names = ", ".join(missing)
            proxy = rustup_proxy_dir()
            if proxy:
                # The PROXY is what implements `cargo +<toolchain>` and honours
                # RUSTUP_TOOLCHAIN; a toolchain's own `bin` holds the real
                # cargo, which knows about neither.
                path_prefix = proxy
                toolchain_env = name
                driven = ", driven through the rustup proxy"
            else:
                path_prefix = str(Path(root) / "bin")
                driven = ""
            if not sysroot:
                toolchain_note = (f"there is no cargo on PATH here — using the "
                                  f"rustup toolchain {name}, which carries "
                                  f"{names}{driven}")
            else:
                paths = ", ".join(f"{sysroot}/lib/rustlib/{t}" for t in missing)
                toolchain_note = (f"the cargo on PATH does not carry {names} "
                                  f"(no {paths}) — using the rustup toolchain "
                                  f"{name}, which does{driven}")
            if others:
                toolchain_note += f" (also carried by {', '.join(others)})"
            pinned = self.pinned_toolchain
            if pinned and not toolchain_is(name, pinned):
                toolchain_note += (f" — the workflow pins {pinned}, which does "
                                   f"not carry {names} here")

        env = dict(ctx["environ"])
        # The host decisions of THIS run (forklift#941): a private TMPDIR no
        # concurrent gate can delete the kernel cache out of, and the sqlite3 FFI
        # remedy when the host has the runtime object but no dev symlink. Both
        # are forced, not defaulted — the caller's TMPDIR is exactly the defect.
        if self.host is not None:
            env = self.host.child_env(env)
        if path_prefix:
            env["PATH"] = path_prefix + os.pathsep + env.get("PATH", "")
        if toolchain_env:
            env["RUSTUP_TOOLCHAIN"] = toolchain_env
        env.setdefault("CI", "true")
        env.setdefault("GITHUB_ACTIONS", "true")
        # GitHub exports RUNNER_TEMP to every step pointing at the same
        # directory the runner.temp expression resolves to, and workflows
        # hand paths from one spelling to the other (dart_curl#55,
        # forklift#752). Force, not setdefault: an ambient RUNNER_TEMP from
        # the operator's shell is not a runner-provided value, and honoring
        # it would fork the two spellings again.
        #
        # The other `runner.*` values have shell spellings too, and a workflow
        # may read either one — the same fork, three more variables (#757).
        # GitHub exports all of them to every step and none is overridable
        # from a workflow's `env:`, so these are forced the same way. Read
        # from the step's own ctx: it already carries this combo's runner
        # values, so nothing is rebuilt.
        runner_ctx = ctx["runner"]
        env["RUNNER_TEMP"] = str(self.runner_temp)
        env["RUNNER_OS"] = runner_ctx["os"]
        env["RUNNER_ARCH"] = runner_ctx["arch"]
        env["RUNNER_TOOL_CACHE"] = str(runner_ctx["tool_cache"])
        env["GITHUB_WORKSPACE"] = str(ROOT)
        if self.github.get("repository"):
            env["GITHUB_REPOSITORY"] = self.github["repository"]
        env["GITHUB_REF_NAME"] = self.github["ref_name"]
        env["GITHUB_EVENT_NAME"] = self.args.get("event", "pull_request")

        shell = step.get("shell") or "bash"
        if shell not in ("bash", "sh"):
            self.skip(head, f"shell: {shell} (not reproduced locally)")
            return
        flags = ["-e", "-o", "pipefail", "-c"] if shell == "bash" else ["-e", "-c"]
        cmd = [shell, *flags, body_expanded]
        # Every skip guard has passed — the child env below is final and a
        # process is about to run with it (or --plan is about to show it). The
        # env entries' real-secret claims are promoted HERE, not at expansion
        # time (dart_curl#76 review): a step skipped by its `if:` never
        # materializes its env, and an entry a later layer overrode with a
        # literal no longer carries the secret — neither may report it real.
        for hits in (ctx.get("secret_env_hits") or {}).values():
            record_real_secrets(hits)

        if self.args.get("verbose") or self.args.get("plan"):
            where = f" (in {wd})" if wd else ""
            print(f"\n{BRIGHT}{CYAN}▶ {head}{RESET}{DIM}{where}{RESET}")
            print(f"{DIM}$ {mask_secrets(body_expanded)}{RESET}")
        else:
            print(f"\n{BRIGHT}▶ {head}{RESET}")
        if toolchain_note:
            print(f"  {GREEN}✓{RESET} {toolchain_note}")
        if self.args.get("plan"):
            return

        started = time.time()
        code, output = stream_command(cmd, cwd, env)
        took = f"{time.time() - started:5.1f}s"
        if code == 0:
            self.out.ran += 1
            print(f"{GREEN}✓ {took} {head}{RESET}")
            return
        # A failure the HOST explains is named, not counted as a repo defect
        # (forklift#941). The class is read off the output, the same way the
        # checkout-state guard below reads its paths off it.
        host = host_fingerprint(output)
        # CI checks out the COMMITTED tree only. A failure whose every mentioned
        # path lives in a gitignored/untracked path cannot happen in CI, so it is
        # reported as local-only rather than as a red gate — loudly, never silently.
        if not self.args.get("strict"):
            absent = ci_absent_hits(output, self.absent_prefixes)
            if absent:
                self.out.local_only.append(f"{head} (exit {code}; only in {absent})")
                print(f"{YELLOW}⚠ {took} {head} (exit {code}) — LOCAL ONLY: every path in "
                      f"the output is under {absent}, which CI's clean checkout does not "
                      f"have. Not a CI failure. Pass --strict to count it.{RESET}")
                return
            if host and host[0] in LOCAL_ONLY_HOST_CLASSES:
                self.out.local_only.append(f"{head} (exit {code}; {host[0]})")
                print(f"{YELLOW}⚠ {took} {head} (exit {code}) — LOCAL ONLY: "
                      f"{host[1]}. A host fact, not a CI failure. Pass --strict to "
                      f"count it.{RESET}")
                return
        if host:
            self.fail(head, f"exit {code}; host environment: {host[0]} — "
                            f"{host[1]}", step, took)
            return
        self.fail(head, f"exit {code}", step, took)

    def fail(self, head, why, step, took=""):
        self.job_ok = False
        if step is not None and step.get("continue-on-error"):
            # step-level softening: CI records the step's conclusion as
            # success and the job keeps going, so this is NOT an unsoftened
            # failure — later implicit-success steps still run there
            # (#780 review).
            self.out.advisory.append(head)
            print(f"{YELLOW}⚠ {took} {head} ({why}) "
                  f"— continue-on-error: advisory, as in CI{RESET}")
            return
        # An unsoftened step failure — a job-level soft-gate's step or a
        # hard one: in CI the job itself has failed, so its later
        # implicit-success steps are skipped. run_step gates on this.
        self.job_unsoftened = True
        if self.job_continue:
            self.out.advisory.append(head)
            print(f"{YELLOW}⚠ {took} {head} ({why}) "
                  f"— continue-on-error: advisory, as in CI{RESET}")
            return
        self.out.failed.append(f"{head} ({why})")
        print(f"{RED}✗ {took} {head} ({why}){RESET}")
        if not self.args.get("keep_going"):
            self.summary()
            self.stopped = True
            sys.exit(1)

    def skip(self, head, why):
        print(f"\n{YELLOW}▶ {head}{RESET}\n  {YELLOW}SKIP{RESET} {why}")
        self.out.skipped.append(f"{head}: {why}")

    def skip_job(self, job_id, why):
        print(f"\n{YELLOW}▶ job {job_id}{RESET}\n  {YELLOW}SKIP{RESET} {why}")
        self.out.skipped.append(f"job {job_id}: {why}")

    # -------------------------------------------------------------- uses: steps

    def emulate_checkout(self, step, head):
        """`actions/checkout` with a `with: path:` input checks the repository
        out at <workspace>/<path> rather than the workspace root, and the job
        then reaches it through `defaults.run.working-directory: <path>` and
        `uses: ./<path>/...`. The repo already IS the root here, so stage the
        same tree at the same relative path with a symlink (removed at exit);
        without it every `working-directory: <path>` step would fail against a
        directory CI itself creates."""
        rel = str((step.get("with") or {}).get("path") or "").strip()
        if not rel or Path(rel).is_absolute() or ".." in Path(rel).parts:
            print(f"\n{DIM}▶ {head}{RESET}\n  – no-op locally (checkout at the workspace root)")
            self.out.checked += 1
            return
        dest = ROOT / rel
        if dest.exists() or dest.is_symlink():
            print(f"\n{DIM}▶ {head}{RESET}\n  – no-op locally (a real {rel}/ is "
                  f"already here; CI would check the repo out over it)")
            self.out.checked += 1
            return
        try:
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.symlink_to(ROOT, target_is_directory=True)
        except OSError as exc:
            print(f"\n{YELLOW}▶ {head}{RESET}\n  {YELLOW}SKIP{RESET} cannot stage the "
                  f"checkout path {rel}/: {exc}")
            self.out.skipped.append(f"{head}: checkout path {rel}: {exc}")
            return
        CHECKOUT_LINKS.append(dest)
        print(f"\n{DIM}▶ {head}{RESET}\n  – checked out at {rel}/ (symlink to this "
              f"checkout, removed when the run ends)")
        self.out.checked += 1

    def run_uses(self, step, head, job_id, job_wd):
        uses = step["uses"]
        wants = step.get("with") or {}

        if any(uses.startswith(a) or a in uses for a in ("actions/checkout",)):
            self.emulate_checkout(step, head)
            return
        if any(s in uses for s in ("actions/cache", "cache/", "upload-artifact",
                                   "download-artifact", "codecov/",
                                   "actions/github-script")):
            print(f"\n{DIM}▶ {head}{RESET}\n  – no-op locally (cache/artifact/coverage)")
            self.out.checked += 1
            return

        for pattern, tool, version_keys, vargs in TOOLCHAIN_ACTIONS:
            if pattern in uses:
                if pattern == "rust-toolchain":
                    self.note_pinned_toolchain(wants)
                self.assert_toolchain(head, tool, version_keys, vargs, wants, job_wd)
                return

        print(f"\n{YELLOW}▶ {head}{RESET}\n  {YELLOW}SKIP{RESET} action {uses} "
              f"(no local equivalent)")
        self.out.skipped.append(f"{head}: action {uses}")

    def note_pinned_toolchain(self, wants):
        """Remember the toolchain the workflow pins.

        CI builds with it, so the local build must use it too when it carries
        the target — a local build on a different compiler than CI's is a
        silent difference.
        """
        raw = wants.get("toolchain")
        if not raw:
            return
        value = str(raw)
        if has_expr(value):
            probe = []
            ctx = getattr(self, "current_ctx", None) or self.base_ctx(None)
            value = expand(value, ctx, probe)
            if probe:
                return
        value = value.strip()
        if value:
            self.pinned_toolchain = value

    def assert_toolchain(self, head, tool, version_keys, vargs, wants, job_wd):
        print(f"\n{BRIGHT}▶ {head}{RESET}")
        exe = shutil.which(tool)
        got_line = tool_version(exe, vargs)
        got = version_of(got_line) or got_line
        ctx = getattr(self, "current_ctx", None) or self.base_ctx(None)
        wants_version, version_key = None, None
        for key in version_keys:
            if key in wants:
                wants_version, version_key = str(wants[key]), key
                break
        if wants_version and has_expr(wants_version):
            probe = []
            wants_version = expand(wants_version, ctx, probe)
            if probe:
                print(f"  {YELLOW}SKIP{RESET} toolchain version needs GitHub context: "
                      f"{', '.join(sorted(set(probe))[:2])}")
                self.out.skipped.append(f"{head}: dynamic toolchain version")
                return
        if version_key and version_key.endswith("-version-file"):
            rel = expand(str(wants[version_key]), ctx, [])
            path = ROOT / rel
            if path.exists():
                wants_version = path.read_text(errors="replace").strip().split("\n")[0].strip()
            else:
                print(f"  {YELLOW}SKIP{RESET} {version_key} {rel} does not exist here")
                self.out.skipped.append(f"{head}: {version_key} {rel} not found")
                return
        if not exe:
            self.out.failed.append(f"{head} ({tool} not installed)")
            print(f"  {RED}✗{RESET} {tool} is NOT installed — this step would fail in CI too")
            return
        self.report_toolchain_targets(head, tool, wants)
        if not wants_version or wants_version.lower() in ("stable", "beta", "dev",
                                                          "latest", "current"):
            print(f"  {GREEN}✓{RESET} {tool} {got_line} (workflow pins: "
                  f"{wants_version or 'default'})")
            self.out.checked += 1
            return
        verdict = version_matches(wants_version, got)
        if verdict:
            print(f"  {GREEN}✓{RESET} {tool} {got} (workflow pins {wants_version})")
            self.out.checked += 1
        else:
            self.out.advisory.append(f"{head}: local {tool} {got} != CI {wants_version}")
            print(f"  {YELLOW}⚠{RESET} local {tool} is {got or 'missing'}, workflow pins "
                  f"{wants_version} — results may differ from CI")

    # ----------------------------------------------------------------- apt step

    def apt_step(self, body, head):
        if not re.search(r"\bapt(-get)?\b", body):
            return None
        print(f"\n{BRIGHT}▶ {head}{RESET}")
        print(f"  {YELLOW}SKIP{RESET} apt-get is Linux-only; checking the local equivalent")
        names = [a or b or c for a, b, c in
                 re.findall(r"'([\w.+-]+)'|\"([\w.+-]+)\"|([A-Za-z][\w.+-]*-dev)\b", body)]
        for name in dict.fromkeys(names):
            equiv = APT_EQUIVALENTS.get(name)
            if not equiv:
                print(f"  {YELLOW}⚠{RESET} no local mapping for apt package {name!r} — "
                      "not validated here (it may still be needed in CI)")
                continue
            label, tool = equiv
            if tool is None:
                print(f"  {YELLOW}⚠{RESET} {label}: no macOS equivalent to probe — "
                      "not validated here")
                continue
            found = shutil.which(tool)
            if found:
                print(f"  {GREEN}✓{RESET} {label}: {tool} present ({found})")
                self.out.checked += 1
            else:
                print(f"  {YELLOW}⚠{RESET} {label}: {tool} not found locally "
                      "(needed by the CI build)")
                self.out.advisory.append(f"{head}: {label} not probeable locally")
        return True

    # ------------------------------------------------------- cargo cross target

    def cross_target_verdict(self, body):
        """What to do with a step that builds for a cargo cross target.

        Every target the step asks for is verified — a step that builds for two
        targets is only as good as the worst of them.

        "run"      — the toolchain on PATH carries every target.
        "override" — a rustup toolchain here carries them; the payload is
                     (name, its root, the cargo-on-PATH sysroot, the targets
                     the PATH toolchain misses, the other toolchains that
                     carry them too).
        "skip"     — no local toolchain carries one of them; the payload is
                     (the targets that are missing, the cargo-on-PATH sysroot).
        "missing_toolchain" — there is no rust toolchain here at all; the step
                     cannot run, and that is a failure, not a missing target.
        """
        targets = cargo_cross_targets(body)
        if not targets:
            return "run", None
        if not cargo_exe() and not rustc_exe():
            return "missing_toolchain", None
        sysroot = rustc_sysroot()
        missing = [t for t in targets if not carries_target(sysroot, t)]
        if not missing:
            return "run", None
        name, root, others = select_toolchain(targets, self.pinned_toolchain)
        if root:
            return "override", (name, root, sysroot, missing, others)
        return "skip", (missing, sysroot)

    def report_toolchain_targets(self, head, tool, wants):
        """A rust-toolchain action installs the targets it names: say whether
        this host carries them, so a step that needs one is never a surprise."""
        raw = wants.get("targets")
        if tool != "cargo" or not raw:
            return
        for target in str(raw).replace(",", " ").split():
            target = target.strip()
            if not target:
                continue
            sysroot = rustc_sysroot()
            if carries_target(sysroot, target):
                print(f"  {GREEN}✓{RESET} target {target} is installed locally")
                self.out.targets += 1
                continue
            name, _ = rustup_toolchain_carrying(target)
            if name:
                print(f"  {GREEN}✓{RESET} target {target} is installed locally "
                      f"(rustup toolchain {name}; the cargo on PATH does not "
                      f"carry it)")
                self.out.targets += 1
                continue
            print(f"  {YELLOW}⚠{RESET} target {target} is NOT installed locally — "
                  f"steps that build for it are skipped here; install it with "
                  f"`rustup target add {target}`")
            self.out.advisory.append(f"{head}: target {target} not installed locally")

    # ---------------------------------------------------------------- summary

    def summary(self):
        print("\n" + "─" * 64)
        print(f"local_ci: {self.out.ran} step(s) ran, {self.out.checked} checked/pinned, "
              f"{self.out.targets} target(s) verified, "
              f"{len(self.out.skipped)} skipped, {len(self.out.advisory)} advisory, "
              f"{len(self.out.local_only)} local-only, {len(self.out.failed)} failed")
        for f in self.out.failed:
            print(f"  {RED}✗ {f}{RESET}")
        for f in self.out.local_only:
            print(f"  {YELLOW}⚠ local-only failure{RESET} {f}")
        for f in self.out.advisory:
            print(f"  {YELLOW}⚠ {f}{RESET}")
        for s in self.out.skipped:
            print(f"  {YELLOW}· skipped{RESET} {s}")
        # Which secrets were real and which were blanked (#708) — the run's
        # honesty about where its values came from. Names only, never values.
        if SECRETS_REAL:
            print(f"  {GREEN}✓{RESET} secrets resolved for real: "
                  f"{', '.join(SECRETS_REAL)}")
        if SECRETS_BLANKED:
            print(f"  {YELLOW}·{RESET} secrets blanked (no local value): "
                  f"{', '.join(SECRETS_BLANKED)}")


def mask_secrets(text):
    """Replace supplied secret values with *** (any text, any line count).

    Shared by the streamed step output (stream_command) and the
    --verbose/--plan command echo (run_step): both print a step's text with
    ${{ secrets.* }} already substituted, so both must mask (dart_curl#76
    review) — the body echo bypassed the masking before this helper.
    """
    for v in LOCAL_SECRETS.values():
        if v and v in text:
            text = text.replace(v, "***")
    return text


def stream_command(cmd, cwd, env, cap=400_000):
    """Run a step, echo its output live, and return (exit code, captured tail).

    Supplied secret values are replaced with *** on every echoed and captured
    line, as GitHub masks them in a run log (#708 review) — a step that prints
    its env, or a tool that logs its credential, writes no token here.
    """
    buf, total = [], 0
    proc = subprocess.Popen(cmd, cwd=str(cwd), env=env, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, text=True, bufsize=1)
    try:
        for line in proc.stdout:
            line = mask_secrets(line)
            sys.stdout.write(line)
            if total < cap:
                buf.append(line)
                total += len(line)
    finally:
        if proc.stdout:
            proc.stdout.close()
        proc.wait()
    return proc.returncode, "".join(buf)


def ci_absent_prefixes():
    """Paths that exist here but not in CI's checkout: gitignored and untracked.

    Regenerated-everywhere directories (`build/`, `.dart_tool/`, `node_modules/`)
    are excluded: a failure naming one of those is a real failure, not local junk.
    """
    out = []
    for extra in (["--others", "--ignored", "--exclude-standard"],
                  ["--others", "--exclude-standard"]):
        text = run_git("ls-files", *extra, "--directory")
        for line in text.split("\n"):
            line = line.strip()
            if line and not _ci_absent_noise(line):
                out.append(line.rstrip("/") + "/")
    return sorted(set(out))


def _ci_absent_noise(path):
    base = path.rstrip("/").split("/")[-1]
    if base in ("build", ".dart_tool", "node_modules", "__pycache__", ".DS_Store",
                ".packages", ".git"):
        return True
    if path.startswith((".DS_Store", ".env", ".packages", ".flutter-plugins")):
        return True
    return path.endswith((".db", ".db-shm", ".db-wal", ".pyc"))


PATH_RE = re.compile(
    r"(?:^|[\s\"'(=:])([\w./@+-]+\.(?:dart|ts|tsx|js|jsx|mjs|cjs|py|rs|go|swift|kt|kts|"
    r"java|rb|php|cs|cc|cpp|cxx|h|hpp|sh|json|ya?ml|md|lock|toml))(?::\d+)?(?::\d+)?")

# Lines that announce a failure. Only these (and the few lines right after them,
# where e.g. cargo puts its ` --> path`) are asked "which file is this about?" —
# listing every path in the output would count harmless lint infos in tracked
# files and mask a genuine local-only failure.
FAIL_HINT = re.compile(r"(^|\s)(error|Error|ERROR|FAILED|FAIL|failed)\b|:\s*error\b")


def failure_paths(output):
    lines = (output or "").split("\n")
    paths, i = [], 0
    while i < len(lines):
        if FAIL_HINT.search(lines[i]):
            window, j = [lines[i]], i + 1
            # Only a genuine continuation (cargo's ` --> src/main.rs:3:5`) belongs
            # to this failure; the next diagnostic usually starts right after it.
            while j < len(lines) and j <= i + 6 and lines[j].strip():
                if FAIL_HINT.search(lines[j]):
                    break
                if "-->" in lines[j] or re.match(r"^\s*(note|help|expected|found)\s*:",
                                                 lines[j]):
                    window.append(lines[j])
                    j += 1
                    continue
                break
            for line in window:
                # The FIRST path on a diagnostic line is the file being diagnosed;
                # later ones are just mentioned in the message (e.g. a bad import
                # target), so they must not decide the verdict.
                m = PATH_RE.search(line)
                if m:
                    paths.append(m.group(1))
            i = j
        else:
            i += 1
    return paths


def ci_absent_hits(output, prefixes):
    """The CI-absent prefix covering every path the FAILURE output names, if any.

    Returns None when the failure names nothing, or names any path that CI's
    checkout would have — either way it is not explainable as local-only.
    """
    if not prefixes:
        return None
    found = failure_paths(output)
    if not found:
        return None
    matched = set()
    for raw in found:
        p = raw.lstrip("./")
        for pre in prefixes:
            base = pre.rstrip("/")
            if p == base or p.startswith(base + "/"):
                matched.add(base + "/")
                break
        else:
            return None  # a path CI does have: this is a real failure
    return ", ".join(sorted(matched))


def step_label(step):
    if step.get("name"):
        return str(step["name"])
    if step.get("uses"):
        return str(step["uses"])
    first = (step.get("run") or "").strip().split("\n")[0]
    return (first[:70] if first else "(unnamed step)")


def tool_version(exe, args=("--version",)):
    if not exe:
        return ""
    try:
        out = subprocess.run([exe, *args], capture_output=True, text=True, timeout=60)
        text = (out.stdout or "") + (out.stderr or "")
        return text.strip().split("\n")[0].strip()
    except Exception:
        return "present"


VERSION_RE = re.compile(r"\d+\.\d+(?:\.\d+)*")


# ------------------------------------------------ tree protection (#34, #38)
# A step can mutate the checkout it is running in: `dart pub get` / `flutter
# pub downgrade` rewrite the (here committed) pubspec.lock, and `dart analyze`
# / `flutter analyze` rewrites an analysis_options.yaml that lacks the
# build/platform excludes — it prints "Upgrading analysis_options.yaml to
# exclude build and platform directories." CI runs every step in a throwaway
# checkout, so the mutation dies with the job. This gate runs in the
# operator's working tree, so without protection the mutation SURVIVES the
# run and poisons it: a rewritten lockfile failed 23 test files on
# arrrrny/zuraffa_ui#34, and the analyze upgrade lands as a dirty
# analysis_options.yaml that the next `git add -A` ships (#38).
#
# THIS SCRIPT IS THE FLEET'S CANONICAL COPY: rollout-local-ci.sh `cp`s it over
# every fleet repo's scripts/local_ci.sh (see its `install_one`), so the
# protection has to live HERE or a rollout silently re-drops it in every repo —
# which is exactly what happened twice: the AGENTS.md standardization rollouts
# fd9fa10 (dropped #34) and f387f5b (dropped #38 again) each replaced the
# script wholesale, and zuraffa_ui had to restore the block by hand both times
# (25b375e, then ec472cf for arrrrny/zuraffa_ui#60). The wiring is pinned by
# test/unit/test_local_ci_script_test.dart ("tree protection ... on the
# canonical copy") so a future rewrite fails THERE, at the cause.
#
# The contract: every pubspec.lock and analysis_options.yaml under the repo
# root is snapshotted before the first step and restored when the run ends —
# byte-identical for files that existed, removed for files a step created,
# recreated for files a step deleted. Mid-run, later steps still see the
# mutated files, exactly as in CI. A protected file the snapshot could not
# READ is neither rewritten nor removed: its pre-run content is unknown, so
# the restore leaves it alone and counts it failed (review of #983) — the
# alternative reads "no snapshot entry" as "a step created this" and unlinks
# a file the run never touched.
#
# The guarantee is "on exit or TERM": the restore rides atexit, and the
# SIGTERM/SIGINT handler registered in main() raises SystemExit on the way
# out, so a gate `bounded-command.sh --timeout` TERMs still restores. A gate
# KILLed after the grace window restores nothing — atexit never runs for a
# SIGKILL, and unlike the per-run temp tree (#941 has a cache-sweep arm),
# the protected files have no sweep backstop. Recover by hand there:
# `git status --porcelain` names them, `git checkout -- pubspec.lock
# analysis_options.yaml` puts them back.
PROTECTED_NAMES = ("pubspec.lock", "analysis_options.yaml")
PROTECTED_PRUNE = {".git", ".dart_tool", "build", "node_modules", "Pods"}


def _walk_protected(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames
                       if d not in PROTECTED_PRUNE and not d.startswith(".")]
        for name in PROTECTED_NAMES:
            if name in filenames:
                yield Path(dirpath) / name


def snapshot_protected_files(root):
    """Every protected file under root -> its bytes, before any step runs.

    Returns (found, unreadable). A file whose bytes could not be read comes
    back in `unreadable`, never as a plain miss: the restore cannot tell a
    snapshot miss from "this file did not exist before the run", and it reads
    the latter as "a step created it" and unlinks it. So a mode-0000 file, a
    broken symlink, an ACL denial or a mount hiccup would have been DELETED by
    the restore while the summary reported it as a removal under the verdict
    "a step's mutation never survives this run" (review of #983). Unknown is
    not absent — those paths are skipped at restore time and warned about
    here, so the operator learns that one file went unprotected.
    """
    found, unreadable = {}, set()
    for path in _walk_protected(root):
        try:
            found[path] = path.read_bytes()
        except OSError:
            unreadable.add(path)
            print(f"local_ci: WARNING could not read {path} while "
                  "snapshotting — it was NOT snapshotted and will be left "
                  "untouched when this run ends", file=sys.stderr)
    return found, unreadable


def restore_protected_files(snapshot, root, unreadable=()):
    """Put every protected file back exactly as snapshotted.

    Returns (rewritten, removed, recreated, failed): files a step mutated or
    deleted are rewritten from the snapshot, files a step created are removed.
    A path that was unreadable at snapshot time is SKIPPED and counted in
    `failed`, because its pre-run content is unknown and `unlink` would
    delete a file the run never touched. A restore that could not be applied
    (permissions, file lock, disk full) is counted in `failed` and warned
    about — a silent restore is no restore.
    """
    rewritten = removed = recreated = failed = 0
    seen = set()
    unreadable = set(unreadable)
    for path in _walk_protected(root):
        seen.add(path)
        if path in unreadable:
            failed += 1
            print(f"local_ci: WARNING could not restore {path} "
                  "(unreadable before the run — left untouched)",
                  file=sys.stderr)
            continue
        try:
            if path in snapshot:
                if path.read_bytes() != snapshot[path]:
                    path.write_bytes(snapshot[path])
                    rewritten += 1
            else:
                path.unlink()
                removed += 1
        except OSError:
            failed += 1
            print(f"local_ci: WARNING could not restore {path}",
                  file=sys.stderr)
    for path, data in snapshot.items():
        if path not in seen:
            try:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
                recreated += 1
            except OSError:
                failed += 1
                print(f"local_ci: WARNING could not restore {path}",
                      file=sys.stderr)
    return rewritten, removed, recreated, failed


def version_of(text):
    """The version number inside a tool's `--version` banner."""
    m = VERSION_RE.search(text or "")
    if m:
        return m.group(0)
    m = re.search(r"\b\d+\b", text or "")
    return m.group(0) if m else ""


def version_matches(want, have):
    """True/False/None. A short pin like `22` matches any `22.x.y`."""
    if not want or not have:
        return None
    w, h = want.strip().lstrip("v"), have.strip().lstrip("v")
    if w == h:
        return True
    if re.match(r"^\d+(\.\d+)?$", w):
        return h == w or h.startswith(w + ".")
    return False


def clone_targets(body, base):
    """`git clone <url> <dst>` destinations, resolved, for the outside-repo guard."""
    out = []
    for m in re.finditer(r"git\s+clone\b([^\n;&|]*)", body):
        try:
            toks = shlex.split(m.group(1), posix=True)
        except ValueError:
            continue
        positional = [t for t in toks if not t.startswith("-")]
        if len(positional) >= 2:
            dst = Path(positional[-1])
            if not dst.is_absolute():
                dst = base / dst
            out.append(dst)
    return out


def expand_matrix(matrix, ctx):
    """Matrix combos (cross product, then include/exclude), or None if unmodelled."""
    unresolved = []
    if not matrix:
        return [None]
    if not isinstance(matrix, dict):
        return None
    if has_expr(json_dumps(matrix)):
        matrix = json_loads(expand(json_dumps(matrix), ctx, unresolved))
        if unresolved:
            return None
    axes = {k: v for k, v in matrix.items() if k not in ("include", "exclude")}
    for v in axes.values():
        if not isinstance(v, list):
            return None
    keys = list(axes)
    include = matrix.get("include") or []
    if include and not isinstance(include, list):
        return None
    if keys:
        combos = [dict(zip(keys, vals))
                  for vals in itertools.product(*(axes[k] for k in keys))]
    elif include:
        combos = []  # every combination comes from `include`
    else:
        combos = [{}]
    for entry in include:
        if not isinstance(entry, dict):
            return None
        targets = [c for c in combos
                   if all(k not in c or c[k] == v for k, v in entry.items())]
        if targets:
            for c in targets:
                c.update(entry)  # no original value is overwritten — the targets filter already saw to that
        else:
            for c in (targets or [{}]):
                merged = dict(c)
                merged.update(entry)
                combos.append(merged)
    exclude = matrix.get("exclude") or []
    if exclude:
        if not isinstance(exclude, list):
            return None
        for entry in exclude:
            if not isinstance(entry, dict):
                return None
            combos = [c for c in combos
                      if not all(k in c and c[k] == v for k, v in entry.items())]
    return combos or [None]


def json_dumps(obj):
    return json.dumps(obj)


def json_loads(text):
    try:
        return json.loads(text)
    except ValueError:
        return {}


def job_order(jobs):
    ids, done, out, remaining = list(jobs), set(), [], list(jobs)
    while remaining:
        progressed = False
        for jid in list(remaining):
            job = jobs[jid] if isinstance(jobs[jid], dict) else {}
            needs = job.get("needs") or []
            if isinstance(needs, str):
                needs = [needs]
            if all(n in done or n not in ids for n in needs):
                out.append(jid)
                done.add(jid)
                remaining.remove(jid)
                progressed = True
        if not progressed:
            out.extend(remaining)
            break
    return out


def normalize_triggers(on):
    if on is None:
        return []
    if isinstance(on, str):
        return [on]
    if isinstance(on, list):
        return [str(x) for x in on]
    if isinstance(on, dict):
        return list(on)
    return []


def workflow_files():
    wfdir = ROOT / ".github" / "workflows"
    if not wfdir.is_dir():
        return None
    return sorted(p for p in wfdir.iterdir()
                  if p.suffix in (".yml", ".yaml") and p.is_file())


# A gate is the workflow that actually checks the change. Names that say so.
PREFERRED_NAME = re.compile(
    r"\b(ci|test|tests|check|checks|build|lint|analyze|analysis|validate|validation|"
    r"quality|gate|pipeline|dart|flutter|rust|cargo|go|node|python)\b", re.I)
# Names that are automation around a PR, not a check of it. Running one of these
# locally would call a bot, publish, or relabel — never what "is CI green" means.
NON_GATE_NAME = re.compile(
    r"claude|codex|copilot|coderabbit|review|label|release|publish|deploy|stale|slash|"
    r"\bcla\b|sync|bot|autofix|comment|dependabot|docs|website|preview|docker|nix|"
    r"changelog|notification|mirror|approve", re.I)


def pick_workflow(files, event):
    """(workflow path, note) for the workflow that runs on `event`."""
    if not files:
        return None, ""
    parsed = []
    for p in files:
        try:
            triggers = normalize_triggers(parse_workflow(p).get("on"))
        except YamlError:
            continue
        parsed.append((p, triggers))
    gates = [p for p, triggers in parsed if event in triggers]
    if not gates:
        # The event is not what this repo gates on (a tag/push-only repo): take
        # the first workflow that has any trigger at all, and say so.
        for p, triggers in parsed:
            if triggers:
                return p, f"no workflow runs on {event}; using {p.name} instead"
        return files[0], f"no workflow declares triggers; using {files[0].name}"
    real = [p for p in gates if not NON_GATE_NAME.search(p.stem)]
    pool = real or gates
    note = ""
    if not real:
        note = (f"every {event} workflow looks like automation (bot/release/label), "
                f"not a gate; using {pool[0].name}")
    pref = [p for p in pool if PREFERRED_NAME.search(p.stem)]
    chosen = pref[0] if pref else pool[0]
    if not pref and not note:
        note = f"no gate-looking name among the {event} workflows; using {chosen.name}"
    if len(pool) > 1 and chosen != pool[0] and not note:
        note = f"{len(pool)} {event} workflows; using {chosen.name}"
    return chosen, note


def guess_slug():
    url = run_git("remote", "get-url", "origin")
    m = re.search(r"[:/]([^/]+/[^/]+?)(?:\.git)?$", url or "")
    return m.group(1) if m else ""


def run_git(*args):
    try:
        return subprocess.run(["git", "-C", str(ROOT), *args], capture_output=True,
                              text=True, timeout=30).stdout.strip()
    except Exception:
        return ""


def main(argv):
    args = {"workflow": None, "job": None, "event": "pull_request", "plan": False,
            "keep_going": False, "verbose": False, "allow_outside_clone": False,
            "strict": False}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("--workflow", "--job", "--event"):
            if i + 1 >= len(argv):
                return err(f"{a} needs a value")
            args[a[2:]] = argv[i + 1]
            i += 2
        elif a in ("--plan", "--dry-run"):
            args["plan"] = True
            i += 1
        elif a == "--keep-going":
            args["keep_going"] = True
            i += 1
        elif a == "--allow-outside-clone":
            args["allow_outside_clone"] = True
            i += 1
        elif a == "--strict":
            args["strict"] = True
            i += 1
        elif a in ("-v", "--verbose"):
            args["verbose"] = True
            i += 1
        elif a == "--list":
            return do_list()
        elif a in ("-h", "--help"):
            print(__doc__ or "see the header of local_ci.sh")
            return 0
        else:
            return err(f"unknown argument {a!r}")
    return run(args)


def err(msg):
    sys.stderr.write(f"local_ci.sh: {msg}\n")
    return 2


def do_list():
    files = workflow_files()
    if files is None:
        sys.stderr.write("local_ci.sh: no .github/workflows in this repo — "
                         "there is no CI gate to run locally\n")
        return 2
    if not files:
        sys.stderr.write("local_ci.sh: .github/workflows is empty\n")
        return 2
    print(f"{BRIGHT}local_ci{RESET}  repo={ROOT}")
    for p in files:
        try:
            doc = parse_workflow(p)
        except YamlError as exc:
            print(f"  {p.name:32s} {YELLOW}unreadable: {exc}{RESET}")
            continue
        triggers = ",".join(normalize_triggers(doc.get("on"))) or "?"
        jobs = doc.get("jobs") or {}
        print(f"  {p.name:32s} on={triggers:34s} "
              f"jobs={','.join(jobs) if isinstance(jobs, dict) else '?'}")
    return 0


def run(args):
    explicit = args["workflow"]
    wf_note = ""  # only the auto-pick path has a heuristic note to print
    if explicit:
        wf = Path(explicit)
        if not wf.is_absolute():
            wf = ROOT / wf
        if not wf.exists():
            return err(f"workflow not found: {wf}")
    else:
        files = workflow_files()
        if files is None:
            return err("no .github/workflows in this repo — "
                       "there is no CI gate to run locally")
        if not files:
            return err(".github/workflows is empty")
        wf, wf_note = pick_workflow(files, args["event"])
        if wf is None:
            return err(f"no workflow in .github/workflows runs on {args['event']}")

    try:
        doc = parse_workflow(wf)
    except YamlError as exc:
        return err(f"could not read {wf}: {exc}")

    print(f"{BRIGHT}local_ci{RESET}  repo={ROOT}")
    print(f"  workflow : {wf.relative_to(ROOT) if wf.is_relative_to(ROOT) else wf}"
          f"  ({doc.get('name') or 'unnamed'})")
    if wf_note:
        print(f"  {YELLOW}note     : {wf_note} (--workflow <path> picks another){RESET}")
    print(f"  event    : {args['event']} (simulated)")
    print(f"  platform : CI runs ubuntu-latest (Linux); this is {sys.platform}. "
          "Step set identical, platform not.")
    # The host preflight comes before any step (forklift#941): the TMPDIR every
    # step gets, the sqlite3 FFI remedy and the disk verdict are facts about THIS
    # machine, so they are decided here — not discovered from 96 FFI failures or
    # 42 "temporary directory" errors.
    #
    # `--plan` is a DRY RUN (forklift#941 review): it lists the steps and runs
    # nothing, so it must not mkdtemp a real per-run TMPDIR (the wrapper TERMs a
    # plan and the atexit handler never runs) and must not gain the exit-3
    # failure mode on a full disk. `create=False` measures the host without
    # creating anything, and the runner's own plan branch prints the steps.
    try:
        host = HostPreflight(create=not args["plan"])
    except ValueError as exc:
        return err(str(exc))
    for line in host.plan_lines() if args["plan"] else host.banner_lines():
        print(line)
    if host.blocked and not args["plan"]:
        # A real run cannot start on a host with no headroom; a PLAN still lists
        # the steps — a dry run's job is to say what would happen, not to fail on
        # a machine that happens to be tight right now (forklift#941 review).
        print(f"\n{RED}local_ci: HOST BLOCKED — {host.blocked}{RESET}")
        print("No step ran: this is a fact about the machine, not a verdict "
              "about the repository.")
        return 3
    if LOCAL_SECRETS:
        print(f"  secrets  : {', '.join(sorted(LOCAL_SECRETS))} supplied "
              "locally (values are not echoed)")
    if SECRETS_MISSING:
        print(f"  {YELLOW}note     : LOCAL_CI_SECRETS names "
              f"{', '.join(SECRETS_MISSING)}, but the ambient environment has "
              "no value for it — it will resolve empty"
              f"{RESET}")

    runner = Runner(wf, doc, args)
    runner.github = build_github(guess_slug(), run_git("rev-parse", "--abbrev-ref", "HEAD"),
                                 args["event"], str(doc.get("name") or ""),
                                 run_git("rev-parse", "HEAD"))
    runner.host = host
    # The runner's own temp tree lives INSIDE the run's private TMPDIR, so one
    # cleanup removes everything the run created and nothing lands in the shared
    # /tmp the gate just stopped using.
    runner.runner_temp = tempfile.mkdtemp(prefix="local_ci_", dir=host.tmpdir)

    # The gate is run under `bounded-command.sh --timeout`, which TERMs and then
    # KILLs the process group on expiry — so `atexit` alone leaks the per-run
    # TMPDIR (forklift#941 review). A signal handler reclaims it on the way out,
    # and the cache sweep carries a `local_ci_*` arm as the backstop for a kill.
    run_temp_dirs = [host.tmpdir, runner.runner_temp]

    def _reclaim_run_temp(*_a):
        for path in run_temp_dirs:
            if path:
                shutil.rmtree(path, ignore_errors=True)

    for _sig in (signal.SIGTERM, signal.SIGINT):
        try:
            signal.signal(_sig, lambda *_a: (_reclaim_run_temp(),
                                             sys.exit(128 + int(_a[0]))))
        except (ValueError, OSError):
            pass  # not the main thread (a test harness) — atexit still applies
    atexit.register(_reclaim_run_temp)
    if runner.absent_prefixes:
        print(f"  note     : this checkout has {len(runner.absent_prefixes)} "
              "gitignored/untracked path(s) that CI's clean checkout does not "
              "(list: git ls-files --others --ignored --exclude-standard --directory). "
              "Whole-tree commands (e.g. `dart analyze .`) see them; a failure confined "
              "to them is reported as local-only, not as a CI failure.")
    if run_git("status", "--porcelain"):
        print("  note     : working tree has uncommitted changes; CI runs the "
              "committed tree")
    protected_snapshot = {}
    protected_unreadable = set()
    if not args["plan"]:
        protected_snapshot, protected_unreadable = snapshot_protected_files(ROOT)
        if protected_snapshot:
            print(f"  note     : snapshotted {len(protected_snapshot)} "
                  "protected file(s) (pubspec.lock, analysis_options.yaml) — "
                  "steps that mutate them (pub get/downgrade, analyze) are "
                  "restored when this run ends (#34, #38)")

        def _restore_protected():
            rewritten, removed, recreated, failed = restore_protected_files(
                protected_snapshot, ROOT, protected_unreadable)
            if rewritten or removed or recreated or failed:
                verdict = ("a step's mutation never survives this run"
                           if not failed else
                           f"{failed} restore(s) FAILED — see the WARNING "
                           "lines above")
                print(f"\nlocal_ci: protected files vs their pre-run state "
                      f"({rewritten} rewritten, {removed} removed, "
                      f"{recreated} recreated, {failed} failed) — "
                      f"{verdict} (#34, #38)")

        atexit.register(_restore_protected)
    runner.run()
    runner.summary()
    if args["plan"]:
        print("(plan only — nothing was executed)")
    return 1 if runner.out.failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
LOCAL_CI_PY
