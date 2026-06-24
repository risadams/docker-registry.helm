# 2. Recommended labels via a shared helper; immutable selector labels

Date: 2026-06-24

## Status

Accepted

## Context

The original templates repeated four ad-hoc labels (`app`, `chart`, `release`,
`heritage`) inline on every object, and used `app` + `release` as the
Deployment/StatefulSet `selector.matchLabels`. Two problems:

1. The chart did not carry the Kubernetes-recommended `app.kubernetes.io/*`
   labels that tooling (dashboards, kubectl, operators) expects.
2. A workload's `selector.matchLabels` is **immutable** after creation. Changing
   it on an existing release fails the upgrade.

## Decision

Centralize labels in two helpers in `_helpers.tpl`:

- `docker-registry.match-labels` — only `app` + `release`. Used for all
  `selector.matchLabels` and Service/Monitor selectors. **Never changed**, so
  upgrades from upstream remain valid.
- `docker-registry.labels` — the match-labels plus chart metadata and the
  recommended set (`app.kubernetes.io/name`, `/instance`, `/managed-by`,
  `/version`, `helm.sh/chart`). Used for `metadata.labels`.

## Consequences

- Objects gain the recommended labels without changing the immutable selectors,
  so `helm upgrade` from upstream 3.0.0 is non-disruptive.
- Label content is defined once; templates call the helper.
- The selector deliberately excludes `app.kubernetes.io/*` to preserve
  immutability — see the note in `_helpers.tpl`. Tests assert the selector stays
  `app` + `release` only.
