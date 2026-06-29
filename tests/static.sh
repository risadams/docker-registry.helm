#!/usr/bin/env bash
# static.sh - Layer 1: cluster-free static validation.
#   1. helm lint --strict
#   2. helm template across a matrix of scenario values
#   3. kubeconform schema validation of every render (k8s 1.34.1)
#   4. python YAML-parse + invariant checks (labels, selectors, names)
#
# Exit non-zero on any failure. No cluster required.
set -uo pipefail
. "$(dirname "$0")/lib/common.sh"

K8S_VERSION="${K8S_VERSION:-1.34.1}"
SCENARIO_DIR="$CHART_DIR/tests/scenarios"
RENDER_DIR="$(mktemp -d)"
trap 'rm -rf "$RENDER_DIR"' EXIT

# CRDs that kubeconform has no built-in schema for; validated structurally by us,
# skipped by kubeconform's strict schema check (logged, not silent).
CRD_SKIP_KINDS="ServiceMonitor,PodMonitor,PrometheusRule,HTTPRoute"

# ---------------------------------------------------------------------------
section "1. helm lint --strict"
if helm lint --strict "$CHART_DIR" >/tmp/lint.out 2>&1; then
  ok "helm lint --strict"
else
  ko "helm lint --strict"; cat /tmp/lint.out
fi

# ---------------------------------------------------------------------------
section "1b. template source hygiene (no in-place .Values mutation)"
# ADR-0012: templates must treat .Values as read-only. An in-place `set`/`unset`
# on .Values mutates the tree shared by the whole render, so any template
# processed afterwards sees the change and output becomes render-order dependent.
# Derive a local `deepCopy` instead. This guard is the regression test for that
# rule: the bug it prevents is invisible in rendered output until some later
# template happens to read the mutated key, so it cannot be caught by an
# output assertion.
if grep -rnE '\b(set|unset)[[:space:]]+\.Values\b' "$CHART_DIR/templates"; then
  ko "template mutates .Values in place (use deepCopy; see docs/adr/0012)"
else
  ok "no in-place .Values mutation in templates"
fi

# ---------------------------------------------------------------------------
section "2-3. render + kubeconform each scenario (k8s $K8S_VERSION)"

have_kubeconform=1
command -v kubeconform >/dev/null 2>&1 || { have_kubeconform=0; warn "kubeconform not found; schema checks skipped (run tests/bootstrap.sh)"; }

# Build the scenario list: every scenario values file, plus an implicit "base"
# (chart defaults). Scenario files may be absent on first run; default always runs.
scenarios=( "default:" )
if [ -d "$SCENARIO_DIR" ]; then
  for f in "$SCENARIO_DIR"/*.yaml; do
    [ -e "$f" ] || continue
    name="$(basename "$f" .yaml)"
    scenarios+=( "${name}:${f}" )
  done
fi

render() {  # render <name> <valuesfile-or-empty>
  local name="$1" vf="$2"
  local out="$RENDER_DIR/${name}.yaml"
  if [ -n "$vf" ]; then
    helm template rel "$CHART_DIR" -f "$vf" --namespace testns > "$out" 2>"$RENDER_DIR/${name}.err"
  else
    helm template rel "$CHART_DIR" --namespace testns > "$out" 2>"$RENDER_DIR/${name}.err"
  fi
}

for entry in "${scenarios[@]}"; do
  name="${entry%%:*}"; vf="${entry#*:}"
  if render "$name" "$vf"; then
    ok "render: $name"
  else
    ko "render: $name"; cat "$RENDER_DIR/${name}.err"; continue
  fi

  if [ "$have_kubeconform" -eq 1 ]; then
    # First pass: strict, skipping CRD kinds with no upstream schema.
    if kubeconform -strict -summary \
         -kubernetes-version "$K8S_VERSION" \
         -skip "$CRD_SKIP_KINDS" \
         "$RENDER_DIR/${name}.yaml" >"$RENDER_DIR/${name}.kc" 2>&1; then
      ok "kubeconform: $name ($(grep -o 'Valid: [0-9]*' "$RENDER_DIR/${name}.kc" | head -1))"
    else
      ko "kubeconform: $name"; cat "$RENDER_DIR/${name}.kc"
    fi
  fi
done

# ---------------------------------------------------------------------------
section "4. structural invariants (python)"
if command -v python >/dev/null 2>&1 && python -c "import yaml" >/dev/null 2>&1; then
  PYTHONIOENCODING=utf-8 python "$CHART_DIR/tests/lib/invariants.py" "$RENDER_DIR"/*.yaml
  if [ $? -eq 0 ]; then ok "invariants"; else ko "invariants"; fi
else
  warn "python+pyyaml unavailable; invariant checks skipped"
fi

# ---------------------------------------------------------------------------
summary
