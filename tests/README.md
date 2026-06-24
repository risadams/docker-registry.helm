# Test suite

Automated tests for the `docker-registry` Helm chart. Four layers, runnable
locally and in CI.

| Layer | Script | Needs a cluster? | What it proves |
|-------|--------|:----------------:|----------------|
| 0. Docs       | `tests/docs.sh`        | No  | README is in sync with `values.yaml` (regenerates via **helm-docs** and fails on drift), and `values.schema.json` is valid, accepts every scenario, and rejects known-bad input. |
| 1. Static     | `tests/static.sh`      | No  | `helm lint --strict`, renders every scenario, validates each against the Kubernetes 1.34.1 JSON schemas with **kubeconform**, and runs structural invariants (selector ⊆ pod labels, recommended labels, names present). |
| 2. Unit       | `tests/unit.sh`        | No  | **helm-unittest** template assertions — 123 tests across 16 suites, covering 100% of top-level `values.yaml` keys. Prints a coverage report. |
| 3. Integration| `tests/integration.sh` | Yes | Installs the chart on the active kube context, runs `helm test`, performs scenario-specific functional probes (incl. real `docker push`/`pull` through htpasswd auth), then tears everything down. |
| 4. `helm test`| `templates/tests/test-connection.yaml` | Yes | Ships **inside the chart**. `helm test <release>` probes the `/v2/` API using the registry image. Available to end users, not just this suite. |

> Docs are generated, not hand-written: `values.yaml` is the source of truth for
> the parameters table (helm-docs renders it into `README.md` via
> `README.md.gotmpl`). Run `make docs` (or `helm-docs`) after changing values, and
> commit the regenerated `README.md`. `tests/docs.sh` fails CI if you forget.

## Quick start

```bash
# 1. one-time: install helm (>=3.11), helm-unittest, kubeconform
bash tests/bootstrap.sh

# 2. fast, no cluster
bash tests/test.sh offline        # = docs + static + unit

# 3. full, requires a working kube context (docker-desktop, kind, ...)
bash tests/test.sh all            # = static + unit + integration
```

With `make` (Linux/macOS/CI):

```bash
make bootstrap
make test-offline
make test-all
make test-integration ARGS="default htpasswd"   # subset
```

On Windows use Git Bash and the `tests/test.sh` entrypoint (no `make` needed).

## Layer detail

### Static (`tests/static.sh`)
Renders chart defaults plus every file in `tests/scenarios/` and pipes each
render through kubeconform. CRD kinds with no upstream schema
(`ServiceMonitor`, `PodMonitor`, `PrometheusRule`, `HTTPRoute`) are skipped by
the schema pass (logged, not silent) and instead covered structurally by
`tests/lib/invariants.py` and by the unit layer.

Tunables: `K8S_VERSION` (default `1.34.1`).

### Unit (`tests/unit.sh`)
Runs `helm unittest` over `tests/unit/*_test.yaml`. Each suite scopes its
assertions to one template but loads the templates it references (e.g. the
`checksum/*` annotations pull in `configmap.yaml` / `secret.yaml`).
`tests/lib/coverage.py` reports which top-level `values.yaml` keys are exercised.

### Integration (`tests/integration.sh`)
For each scenario: fresh namespace → `helm install -f scenarios/<x>.yaml --wait`
→ `helm test` → functional probes → uninstall + namespace delete. A cleanup
trap removes namespaces even on failure/Ctrl-C.

Scenarios: `default`, `service-create-false`, `persistence`, `statefulset`,
`garbage-collect`, `metrics`, `ingress`, `existing-secret`, `autoscaling`,
`sidecars`, `htpasswd`.

Run a subset and tune behaviour:

```bash
tests/integration.sh default htpasswd     # only these two
SKIP_DOCKER=1 tests/integration.sh        # skip docker push/pull depth
INSTALL_CRDS=0 tests/integration.sh metrics  # don't install prom-operator CRDs
NS_PREFIX=drtest TIMEOUT=240s tests/integration.sh
```

Clean up leftovers from an interrupted run: `make clean` (or
`kubectl delete ns -l ... ` / delete `drtest-*` namespaces).

## What CI can and cannot cover

CI runs in `.github/workflows/ci.yaml` as a hybrid:

- **`helm-lint`, `static`, `unit` jobs** — fast, deterministic, **required**.
  These need no cluster and reliably gate every PR.
- **`integration` job** — spins up a [kind](https://kind.sigs.k8s.io/) cluster
  and runs `tests/integration.sh`. It is marked **`continue-on-error: true`** so
  a flaky ephemeral cluster never blocks a merge; its result is still visible on
  the PR. To make it gating, remove that line (see the workflow comment).

Known coverage limits in CI (documented so green ≠ false confidence):

- **Prometheus-operator CRDs** (`ServiceMonitor`/`PodMonitor`/`PrometheusRule`)
  and **Gateway API CRDs** (`HTTPRoute`) are not present on a vanilla cluster.
  The integration job installs the prometheus-operator CRDs best-effort; where a
  CRD is absent the object is validated at render time (static + unit) and the
  live apply is skipped with a logged note.
- **HPA live scaling** needs metrics-server. The suite asserts the HPA object is
  created and targets the right workload, not that it actually scales.
- **`docker push`/`pull` depth** needs a docker daemon. Locally that's
  docker-desktop; in kind the in-cluster path differs, so the htpasswd and
  garbage-collect deep probes auto-skip when no usable daemon/NodePath is found
  (`SKIP_DOCKER=1` forces this). The object-level assertions still run.
- **Ingress / HTTPRoute traffic** is not driven end-to-end (no controller/gateway
  installed); the suite asserts the objects are created and well-formed.

## Files

```
tests/
  bootstrap.sh            install/verify tooling
  test.sh                 portable entrypoint (used by the Makefile)
  static.sh               Layer 1
  unit.sh                 Layer 2
  integration.sh          Layer 3
  lib/
    common.sh             shared bash helpers (logging, retry, ns cleanup trap)
    invariants.py         structural manifest checks
    coverage.py           values-key coverage report
  scenarios/*.yaml        values files shared by static + integration
  unit/*_test.yaml        helm-unittest suites
templates/tests/
  test-connection.yaml    Layer 4: in-chart `helm test` hook
```
