# 18. Align the garbage-collect CronJob pod spec with the workload

Date: 2026-06-29

## Status

Accepted

## Context

The garbage-collect CronJob (`cronjob.yaml`) carries its own pod spec. It overlapped
heavily with the Deployment/StatefulSet pod template but **silently dropped** several
fields the workload sets: `automountServiceAccountToken`, `enableServiceLinks`,
`initContainers`, and `topologySpreadConstraints`. This was item 9 of the review, and
the downstream of item 8 (ADR-0017) — the same duplication-causes-drift problem.

After ADR-0017 the workload pod spec is single-sourced in
`docker-registry.podTemplate`. The CronJob, however, **cannot** include that helper
wholesale: a batch Job's pod spec is legitimately different. It runs the
`garbage-collect` command (not `serve`), exposes no ports and has no probes, uses
`garbageCollect.resources` / `extraEnvVars` / `affinity` overrides, merges
`garbageCollect.podLabels`/`podAnnotations`, and sets a `restartPolicy`. So the drift
is a mix of *genuine omissions* (fields that should match the workload) and
*intentional differences* (fields a Job must not share).

## Decision

Close the genuine drift by adding the missing identity/scheduling fields to the
CronJob pod spec, reading the **same values** the workload reads, so they stay in
lockstep:

- `automountServiceAccountToken: {{ .Values.automountServiceAccountToken }}`
- `enableServiceLinks: {{ .Values.enableServiceLinks }}`
- `initContainers` (`{{- with .Values.initContainers }}`)
- `topologySpreadConstraints` (`{{- if .Values.topologySpreadConstraints }}`)

Keep the CronJob pod spec as its own template (not a shared `include` of
`podTemplate`) and document inline the fields a Job must **not** carry:

- **`extraContainers` (sidecars)** — a sidecar that never exits keeps the Job pod
  `Running` and prevents the Job from ever completing.
- **`ports` / `livenessProbe` / `readinessProbe`** — `registry garbage-collect` is a
  one-shot batch command, not an HTTP server.

A parameterised shared include was considered and rejected: the overlap is partial and
the differences are load-bearing, so a shared template would need enough conditionals
to be less readable than the explicit, commented CronJob spec. The security-relevant
blocks that *do* remain duplicated (pod and container `securityContext`, `volumes`,
`env`, `volumeMounts`) already read from the same values / shared helpers
(`docker-registry.volumes`, `.volumeMounts`, `.envs`), so they are consistent by
construction rather than by copy.

## Consequences

- **Behaviour change.** The GC pod now emits `automountServiceAccountToken` (default
  `false`, so the ServiceAccount token is no longer auto-mounted — a least-privilege
  improvement, and the GC command does not call the Kubernetes API) and an explicit
  `enableServiceLinks`. It also honours `initContainers` and
  `topologySpreadConstraints` when set. Default GC renders gain the two explicit lines;
  runtime behaviour is unchanged except the token is no longer mounted.
- The GC pod and the workload pods can no longer silently diverge on these
  identity/scheduling fields.
- The intentional omissions are documented in `cronjob.yaml`, so a future reader does
  not "fix" the Job by adding ports, probes, or blocking sidecars to it.
- New unit tests assert the added fields and the intentional omissions
  (`tests/unit/cronjob_test.yaml`).
