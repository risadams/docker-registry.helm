# 9. Four-layer test strategy with an in-chart helm test hook

Date: 2026-06-24

## Status

Accepted

## Context

The fork added many configurable options and several bug fixes. Without tests,
regressions are easy and "does it still install?" is unanswerable in CI. A
template-only approach can't catch runtime issues (e.g. the `lookup`-based
`haSharedSecret` stability, ADR 7), and a cluster-only approach is slow and flaky
for per-option coverage.

## Decision

Layer the tests by cost and fidelity (see `tests/README.md`):

1. **Static** (`tests/static.sh`) — `helm lint --strict`, render every scenario,
   validate with kubeconform (k8s schema), and run structural invariants. No
   cluster.
2. **Unit** (`tests/unit/*_test.yaml`, helm-unittest) — assert template output per
   option; ~100% of top-level values keys referenced. No cluster.
3. **Integration** (`tests/integration.sh`) — install each scenario on a real
   cluster, run `helm test`, probe functionality (incl. real docker push/pull
   through htpasswd), then tear down. Cluster required.
4. **In-chart `helm test` hook** (`templates/tests/test-connection.yaml`) — ships
   with the chart so end users can `helm test <release>`.

CI runs layers 1–2 as required gates and layer 3 on a kind cluster as
non-gating (`continue-on-error`) to avoid blocking merges on cluster flakiness.

## Consequences

- Fast, deterministic feedback on every PR; full functional coverage available
  on demand and in CI.
- The `helm test` hook is shipped in the package (only the repo-root `tests/`
  dir is excluded via `.helmignore`).
- New options are expected to come with unit coverage; the coverage report flags
  untested top-level keys.
