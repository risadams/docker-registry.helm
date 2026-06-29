---
title: Architecture Decision Records
sidebar_position: 1
slug: /adr/README
---

# Architecture Decision Records

These ADRs capture the significant design decisions behind this chart — the
*why* behind defaults and structure, so future changes are made with full
context. Format: [Michael Nygard's ADR](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

| # | Decision |
|---|----------|
| [0001](0001-maintain-fork.md) | Maintain a fork of twuni/docker-registry.helm |
| [0002](0002-recommended-labels-immutable-selectors.md) | Recommended labels via a shared helper; immutable selector labels |
| [0003](0003-labels-merged-helper.md) | Merge user labels with chart labels via a helper |
| [0004](0004-deployment-default-statefulset-optin.md) | Deployment by default, StatefulSet opt-in |
| [0005](0005-service-create-defaults-true.md) | service.create defaults to true |
| [0006](0006-existing-secret-approach.md) | existingSecret over per-provider key overrides |
| [0007](0007-stable-hasharedsecret-lookup.md) | Stable haSharedSecret via lookup |
| [0008](0008-additive-podmonitor.md) | PodMonitor is additive, not a replacement |
| [0009](0009-test-strategy.md) | Four-layer test strategy with an in-chart helm test hook |
| [0010](0010-docs-contract.md) | values.yaml as docs source; helm-docs + values.schema.json |
| [0011](0011-tls-and-redis-cache.md) | In-chart TLS material and Redis cache credentials |
| [0012](0012-configmap-render-without-mutating-values.md) | Render the ConfigMap without mutating .Values |

## Adding an ADR

Copy the format of an existing record, use the next number, and link it in the
table above. Keep them short: Status, Context, Decision, Consequences.
