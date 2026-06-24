# 7. Stable haSharedSecret via lookup

Date: 2026-06-24

## Status

Accepted

## Context

When `secrets.haSharedSecret` was left empty, the chart generated it with
`randAlphaNum 16` on **every** render. Consequences (upstream #187):

- ArgoCD (and any drift-detecting GitOps tool) saw the Secret change on every
  sync → perpetual OutOfSync churn.
- On multi-replica HA deployments, `REGISTRY_HTTP_SECRET` must be identical
  across replicas; a rotating value breaks request signing.

## Decision

Generate `haSharedSecret` only on first install. On subsequent renders, read the
existing value back from the cluster with `lookup` and reuse it:

```yaml
{{- $existing := lookup "v1" "Secret" $namespace $secretName }}
{{- if and $existing $existing.data (index $existing.data "haSharedSecret") }}
haSharedSecret: {{ index $existing.data "haSharedSecret" | quote }}
{{- else }}
haSharedSecret: {{ randAlphaNum 16 | b64enc | quote }}
{{- end }}
```

An explicitly provided `secrets.haSharedSecret` (or an `existingSecret`) takes
precedence and bypasses generation entirely.

## Consequences

- The Secret is stable across upgrades — no ArgoCD churn, HA signing intact.
  Verified by an integration scenario that installs then upgrades twice and
  asserts the value is unchanged.
- `lookup` returns empty during `helm template` with no cluster (e.g. offline
  GitOps render), so a fresh value is generated then — same as before. For stable
  output in that mode, set `secrets.haSharedSecret` (or use `existingSecret`).
- The rendering identity needs `get` on Secrets in the release namespace
  (ArgoCD and Helm have this by default).
