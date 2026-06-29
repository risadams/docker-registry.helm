# 17. Share the pod template between Deployment and StatefulSet

Date: 2026-06-29

## Status

Accepted

## Context

`deployment.yaml` and `statefulset.yaml` each carried the full pod template
(`spec.template`) — pod labels and checksum annotations, the serviceAccount and
security context, the container with its probes, env, resources and volume mounts,
and all the scheduling fields — duplicated verbatim, ~72 lines apiece. The two
templates differed only in:

- `kind` (Deployment vs StatefulSet),
- `strategy` vs `serviceName` + `updateStrategy`,
- the StatefulSet's `volumeClaimTemplates`.

The pod template was byte-for-byte identical. Duplication of this size has no
locality: a change to the security context, an env var, or a probe had to be made
in both files, and any miss produced a Deployment and a StatefulSet that quietly
diverged. This was item 8 of the maintainability review; the CronJob carrying yet
another copy of much of this (item 9) is the same root cause.

## Decision

Extract the pod template into a single `docker-registry.podTemplate` helper in
`_helpers.tpl`, consumed by both workloads. `deployment.yaml` and
`statefulset.yaml` keep only their kind-specific scaffolding (metadata, selector,
replicas, the strategy/serviceName fields, and — for the StatefulSet —
`volumeClaimTemplates`) and call:

```yaml
  template:
  {{- include "docker-registry.podTemplate" . }}
```

The helper body is the pod template **verbatim**, at the same indentation it had
inline (including the two column-0 `{{ include ... | indent 10 }}` probe lines). It
is defined with a leading newline (`{{- define "…" }}`, no trailing dash) so the
caller can inline it after `template:` with no extra indentation and no `nindent`
re-calculation. This is deliberate: re-indenting the block via `nindent` would have
shifted the column-0 probe lines and changed the output. Authoring it verbatim keeps
the render identical and the diff reviewable.

Correctness was verified by rendering **every** scenario (defaults plus all
`tests/scenarios/*.yaml`) as both a Deployment and a StatefulSet — 28 renders — and
diffing against the pre-refactor output with `haSharedSecret` pinned to remove the
random-generation noise. All 28 were byte-identical.

## Consequences

- The pod spec has one home. A change is made once and both workloads get it; they
  can no longer drift. `deployment.yaml` (96 → 24 lines) and `statefulset.yaml`
  (126 → 54 lines) become thin, readable kind-specific wrappers.
- Output is unchanged; the existing `deployment`, `statefulset`, and `pod-spec` unit
  suites pass without modification.
- This does **not** reopen ADR-0004 (Deployment by default, StatefulSet opt-in),
  which governs *which* workload is rendered, not how the pod spec is authored.
- The garbage-collect CronJob still has its own pod spec (with known drift — item 9).
  It is the next candidate for sharing fragments of this helper; that is left to a
  separate change because a Job's pod spec legitimately omits some fields.
- Maintainers editing the helper must preserve its verbatim indentation (including
  the column-0 probe lines); "tidying" it with `nindent` would change the rendered
  output. The render-diff method above is how to confirm a future edit is safe.
