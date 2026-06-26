---
title: Testing
sidebar_position: 4
---

# Testing

The chart ships a four-layer automated test suite, runnable locally and in CI.
No cluster is required for the first three layers.

| Layer | Script | Needs cluster? | What it proves |
|-------|--------|:--------------:|----------------|
| 0. Docs | `tests/docs.sh` | No | README is in sync with `values.yaml` (regenerated via **helm-docs**); `values.schema.json` is valid, accepts every scenario, and rejects known-bad input. |
| 1. Static | `tests/static.sh` | No | `helm lint --strict`, renders every scenario, validates each against Kubernetes 1.34.1 JSON schemas with **kubeconform**, and runs structural invariants. |
| 2. Unit | `tests/unit.sh` | No | **helm-unittest** template assertions — 137 tests across 17 suites, covering 100 % of top-level `values.yaml` keys. Prints a coverage report. |
| 3. Integration | `tests/integration.sh` | Yes | Installs the chart on the active kube context, runs `helm test`, performs scenario-specific functional probes (including real `docker push`/`pull` through htpasswd auth), then tears everything down. |
| 4. `helm test` | `templates/tests/test-connection.yaml` | Yes | Ships **inside the chart**. `helm test <release>` probes the `/v2/` API. Available to end users, not just this suite. |

> **Docs are generated, not hand-written.** `values.yaml` is the source of truth for
> the parameters table. Run `make docs` (or `helm-docs`) after changing values and
> commit the regenerated `README.md`. Layer 0 (`tests/docs.sh`) fails CI if you forget.

---

## Prerequisites

### Helm test tooling

The bootstrap script installs and verifies all CLI tools needed by the suite.
Run it once before anything else:

```bash
bash tests/bootstrap.sh
```

It will check for (and where possible install) `helm` ≥ 3.11,
the `helm-unittest` plugin, `kubeconform`, `helm-docs`, and Python 3.

### Docker Desktop (integration tests only)

Layers 0–2 need only a shell. Layer 3 (integration) requires both a Docker
daemon and a Kubernetes cluster. The simplest way to get both on a local
machine is [Docker Desktop](https://www.docker.com/products/docker-desktop/).

1. Download and install Docker Desktop for your platform.
2. Open **Settings → Kubernetes** and check **Enable Kubernetes**.
3. Click **Apply & Restart** and wait for the green Kubernetes status indicator
   in the bottom-left corner of the Docker Desktop window.

Docker Desktop creates a `docker-desktop` kube context and sets it as the
active context automatically. Verify with:

```bash
kubectl config current-context   # should print "docker-desktop"
kubectl get nodes                # should show one Ready node
```

The Docker daemon is also available to the test suite at this point, which
enables the `docker push`/`pull` depth probes in the `htpasswd` and
`garbage-collect` scenarios.

### Using kind instead of Docker Desktop

[kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) is a lightweight
alternative that runs a cluster inside Docker containers. Install it with:

```bash
# macOS / Linux
brew install kind

# Windows (Git Bash / Scoop)
scoop install kind
```

Then create a cluster:

```bash
kind create cluster
kubectl config use-context kind-kind
```

See [Kind cluster setup for NodePort tests](#kind-cluster-setup-for-nodeport-tests)
below if you plan to run the `htpasswd` or `garbage-collect` scenarios — those
require extra port mappings that must be configured at cluster creation time.

---

## Quick start

```bash
# 1. One-time: install helm (>=3.11), helm-unittest, kubeconform
bash tests/bootstrap.sh

# 2. Fast — no cluster required
bash tests/test.sh offline        # docs + static + unit

# 3. Full — requires a working kube context (docker-desktop, kind, …)
bash tests/test.sh all            # static + unit + integration
```

With `make` (Linux / macOS / CI):

```bash
make bootstrap
make test-offline
make test-all
make test-integration ARGS="default htpasswd"   # subset of scenarios
```

On Windows, use Git Bash and the `tests/test.sh` entrypoint directly — no `make` needed.

---

## Layer detail

### Layer 0 — Docs

Regenerates `README.md` via `helm-docs` and diffs the result against the
committed file. Also validates `values.schema.json`: verifies it parses as JSON
Schema, runs every `tests/scenarios/*.yaml` file through it (each must pass),
and runs a small set of known-bad inputs (each must be rejected). Fails fast and
loudly on any drift or schema error.

### Layer 1 — Static

Renders chart defaults plus every file in `tests/scenarios/` and pipes each
render through kubeconform against the Kubernetes 1.34.1 JSON schemas.

CRD kinds with no upstream schema (`ServiceMonitor`, `PodMonitor`,
`PrometheusRule`, `HTTPRoute`) are skipped by the schema pass (logged, not
silent) and instead covered structurally by `tests/lib/invariants.py` and by
the unit layer.

Tunables: set `K8S_VERSION` to target a different Kubernetes version (default `1.34.1`).

### Layer 2 — Unit

Runs `helm unittest` over `tests/unit/*_test.yaml`. Each suite scopes its
assertions to one template but loads the templates it references (e.g. the
`checksum/*` annotations pull in `configmap.yaml` / `secret.yaml`).
`tests/lib/coverage.py` reports which top-level `values.yaml` keys are exercised.

### Layer 3 — Integration

For each scenario: fresh namespace → `helm install -f scenarios/<x>.yaml --wait`
→ `helm test` → functional probes → uninstall and namespace delete. A cleanup
trap removes namespaces even on failure or Ctrl-C.

**Scenarios:** `default`, `service-create-false`, `persistence`, `statefulset`,
`garbage-collect`, `metrics`, `ingress`, `existing-secret`, `autoscaling`,
`sidecars`, `htpasswd`.

Run a subset and tune behaviour:

```bash
tests/integration.sh default htpasswd       # only these two scenarios
SKIP_DOCKER=1 tests/integration.sh          # skip docker push/pull probes
INSTALL_CRDS=0 tests/integration.sh metrics # don't install prom-operator CRDs
NS_PREFIX=drtest TIMEOUT=240s tests/integration.sh
```

Clean up leftovers from an interrupted run: `make clean` (or delete the
`drtest-*` namespaces with `kubectl delete ns`).

---

## Kind cluster setup for NodePort tests

The `htpasswd` and `garbage-collect` scenarios use NodePort services (30577 and
30578) to let the Docker daemon push/pull images into the running registry. Kind
does **not** expose NodePorts to `localhost` by default — they require
`extraPortMappings` in the cluster config.

Save the following as `kind-config.yaml` and recreate your cluster before
running `make test-all`:

```yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30577
    hostPort: 30577
    protocol: TCP
  - containerPort: 30578
    hostPort: 30578
    protocol: TCP
```

```bash
kind delete cluster
kind create cluster --config kind-config.yaml
```

Without this, the NodePort probes auto-skip with a `[ WARN ]` message. Set
`SKIP_DOCKER=1` to silence the warnings and skip those probes intentionally.
The object-level assertions still run either way.

---

## What CI covers (and what it doesn't)

CI runs in `.github/workflows/ci.yaml` as a hybrid pipeline:

- **`helm-lint`, `static`, `unit` jobs** — fast, deterministic, **required**.
  These need no cluster and gate every PR.
- **`integration` job** — spins up a [kind](https://kind.sigs.k8s.io/) cluster.
  Marked `continue-on-error: true` so a flaky ephemeral cluster never blocks a
  merge; its result is still visible on the PR. Remove that flag to make it gating.

**Known coverage limits** (so a green CI doesn't imply false confidence):

- **Prometheus-operator CRDs** (`ServiceMonitor`/`PodMonitor`/`PrometheusRule`)
  and **Gateway API CRDs** (`HTTPRoute`) are not present on a vanilla cluster.
  The integration job installs the prometheus-operator CRDs best-effort; where a
  CRD is absent the object is validated at render time (static + unit) and the
  live apply is skipped with a logged note.
- **HPA live scaling** needs metrics-server. The suite asserts the HPA object is
  created and targets the right workload, not that it actually scales.
- **`docker push`/`pull` depth** needs a Docker daemon. In kind the in-cluster
  path differs, so the htpasswd and garbage-collect deep probes auto-skip when no
  usable daemon is found (`SKIP_DOCKER=1` forces this).
- **Ingress / HTTPRoute traffic** is not driven end-to-end (no controller
  installed); the suite asserts the objects are created and well-formed.

---

## Files

```
tests/
  bootstrap.sh            install/verify tooling
  test.sh                 portable entrypoint (used by the Makefile)
  static.sh               Layer 1
  unit.sh                 Layer 2
  integration.sh          Layer 3
  lib/
    common.sh             shared bash helpers (logging, retry, namespace cleanup trap)
    invariants.py         structural manifest checks
    coverage.py           values-key coverage report
  scenarios/*.yaml        values files shared by static + integration
  unit/*_test.yaml        helm-unittest suites
templates/tests/
  test-connection.yaml    Layer 4: in-chart helm test hook
```
