#!/usr/bin/env bash
# docs.sh - Layer 0: documentation & schema validation (cluster-free).
#   1. README drift: regenerate with helm-docs and fail if it differs from the
#      committed README.md (keeps docs in sync with values.yaml).
#   2. values.schema.json: helm lint (schema-validates defaults), the schema
#      accepts every tests/scenarios/*.yaml, and rejects known-bad input.
#
# Exit non-zero on any failure. No cluster required.
set -uo pipefail
. "$(dirname "$0")/lib/common.sh"

SCENARIO_DIR="$CHART_DIR/tests/scenarios"

# ---------------------------------------------------------------------------
section "1. README is in sync with values.yaml (helm-docs)"
if ! command -v helm-docs >/dev/null 2>&1; then
  warn "helm-docs not installed; skipping drift check (run tests/bootstrap.sh)"
else
  # Regenerate into a temp copy and diff, so we never mutate the working tree.
  tmp="$(mktemp -d)"
  cp "$CHART_DIR/README.md" "$tmp/README.committed.md"
  ( cd "$CHART_DIR" && helm-docs --sort-values-order=file >/dev/null 2>&1 )
  if diff -u "$tmp/README.committed.md" "$CHART_DIR/README.md" >"$tmp/readme.diff" 2>&1; then
    ok "README.md matches helm-docs output"
  else
    ko "README.md is stale — run 'helm-docs' (or 'make docs') and commit"
    sed -n '1,40p' "$tmp/readme.diff"
    # restore the committed version so a failed check doesn't leave a dirty tree
    cp "$tmp/README.committed.md" "$CHART_DIR/README.md"
  fi
  rm -rf "$tmp"
fi

# ---------------------------------------------------------------------------
section "2. values.schema.json validation"
if [ ! -f "$CHART_DIR/values.schema.json" ]; then
  ko "values.schema.json missing"
else
  # valid JSON (cd into the chart dir so the path works on Windows Python too)
  if command -v python >/dev/null 2>&1; then
    if ( cd "$CHART_DIR" && python -c "import json; json.load(open('values.schema.json'))" ) 2>/dev/null; then
      ok "values.schema.json is valid JSON"
    else
      ko "values.schema.json is not valid JSON"
    fi
  fi

  # lint validates the default values against the schema
  if helm lint "$CHART_DIR" >/tmp/docs_lint.out 2>&1; then
    ok "helm lint (schema-validates defaults)"
  else
    ko "helm lint failed"; cat /tmp/docs_lint.out
  fi

  # schema must ACCEPT every scenario
  for f in "$SCENARIO_DIR"/*.yaml; do
    [ -e "$f" ] || continue
    name="$(basename "$f")"
    if helm template t "$CHART_DIR" -f "$f" >/dev/null 2>"/tmp/docs_acc.err"; then
      ok "schema accepts scenario: $name"
    else
      ko "schema rejects valid scenario: $name"; sed -n '1,8p' /tmp/docs_acc.err
    fi
  done

  # schema must REJECT known-bad input
  reject() {  # reject <description> <helm --set args...>
    local desc="$1"; shift
    if helm template t "$CHART_DIR" "$@" >/dev/null 2>&1; then
      ko "schema accepted invalid input ($desc)"
    else
      ok "schema rejects invalid input: $desc"
    fi
  }
  reject "storage enum"            --set storage=bogus
  reject "service.type enum"       --set service.type=BadType
  reject "replicaCount type"       --set replicaCount=notanint
  reject "restartPolicy enum"      --set garbageCollect.restartPolicy=Sometimes
  reject "image.pullPolicy enum"   --set image.pullPolicy=Maybe
  reject "unknown top-level key"   --set typoKeyDoesNotExist=value
fi

# ---------------------------------------------------------------------------
summary
