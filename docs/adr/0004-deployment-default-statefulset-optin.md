# 4. Deployment by default, StatefulSet opt-in

Date: 2026-06-24

## Status

Accepted

## Context

Upstream PR #89 proposed StatefulSet support. A registry backed by per-replica
PersistentVolumes (via `volumeClaimTemplates`) is useful, but most installs use a
single replica or shared object storage (S3/Azure/Swift) and a Deployment is the
simpler, expected default. The PR as written also had defects (`strategy` instead
of `updateStrategy`, a `serviceName` referencing `service.name`).

## Decision

Keep the **Deployment** as the default workload. Add `useStatefulSet: false` as
an opt-in that swaps to a StatefulSet with `volumeClaimTemplates`. `deployment.yaml`
renders only when `useStatefulSet` is false; `statefulset.yaml` only when true.
The standalone PVC (`pvc.yaml`) is skipped in StatefulSet mode since the template
provisions storage.

Fixes applied versus the upstream PR: use `updateStrategy` (valid for both
kinds) and set `serviceName` to the chart fullname.

## Consequences

- Existing installs are unaffected (default unchanged).
- StatefulSet users get stable per-replica volumes.
- Both paths share the same pod spec, probes, security context, and label
  helpers, so they stay in sync. Unit and integration tests cover both modes.
