# 3. Merge user labels with chart labels via a helper

Date: 2026-06-24

## Status

Accepted

## Context

Several objects combine the chart's labels with user-supplied labels
(`service.labels`, `ingress.labels`, `metrics.serviceMonitor.labels`, etc.).
The original approach emitted the chart labels and then appended the user map:

```yaml
labels:
  {{- include "docker-registry.labels" . | nindent 4 }}
{{ toYaml .Values.service.labels | indent 4 }}
```

When a user set a key the chart also sets — most commonly `release`, the
kube-prometheus-stack discovery label on a ServiceMonitor — this produced a
**duplicate YAML map key**, which is invalid and was rejected by kubeconform and
the API. This blocked the standard Prometheus-operator setup.

## Decision

Add `docker-registry.labels.merged`, which deep-merges a caller-supplied label
map over the chart labels (user value wins) and emits a single map:

```yaml
labels:
  {{- include "docker-registry.labels.merged" (dict "ctx" . "extra" .Values.service.labels) | nindent 4 }}
```

Used by Service, Ingress, HTTPRoute, ServiceMonitor, PodMonitor, PrometheusRule,
Deployment, and StatefulSet.

## Consequences

- Overriding a chart-set label collapses to one entry instead of producing
  invalid YAML.
- The kube-prometheus-stack `release` discovery pattern works.
- A unit test asserts the merged `release` label renders exactly once. The bug
  was originally caught by the static (kubeconform) test layer.
