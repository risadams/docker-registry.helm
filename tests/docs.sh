#!/usr/bin/env bash
# docs.sh - Layer 0: schema validation (cluster-free).
#   1. values.schema.json: helm lint (schema-validates defaults), the schema
#      accepts every tests/scenarios/*.yaml, and rejects known-bad input.
#
# Exit non-zero on any failure. No cluster required.
set -uo pipefail
. "$(dirname "$0")/lib/common.sh"

SCENARIO_DIR="$CHART_DIR/tests/scenarios"

# ---------------------------------------------------------------------------
section "1. values.schema.json validation"
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
