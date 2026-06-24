#!/usr/bin/env bash
# unit.sh - Layer 2: helm-unittest template assertions (cluster-free).
# Runs every tests/unit/*_test.yaml and prints a values-key coverage summary.
set -uo pipefail
. "$(dirname "$0")/lib/common.sh"

section "helm-unittest"
if ! helm plugin list 2>/dev/null | grep -q '^unittest'; then
  fail "helm-unittest plugin not installed. Run: bash tests/bootstrap.sh"
  exit 1
fi

# -t to fail on missing snapshots etc.; glob all suites.
if helm unittest "$CHART_DIR" -f 'tests/unit/*_test.yaml'; then
  ok "helm-unittest suites"
  rc=0
else
  ko "helm-unittest suites"
  rc=1
fi

# ----- values-key coverage report -------------------------------------------
section "values.yaml key coverage (heuristic)"
if command -v python >/dev/null 2>&1; then
  PYTHONIOENCODING=utf-8 python "$CHART_DIR/tests/lib/coverage.py" \
    "$CHART_DIR/values.yaml" "$CHART_DIR/tests/unit" || true
else
  warn "python unavailable; skipping coverage report"
fi

exit "$rc"
