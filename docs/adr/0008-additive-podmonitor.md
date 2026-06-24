# 8. PodMonitor is additive, not a replacement for ServiceMonitor

Date: 2026-06-24

## Status

Accepted

## Context

Upstream PR #108 switched metrics scraping from a ServiceMonitor to a PodMonitor —
but did so destructively: it deleted `servicemonitor.yaml` and removed the metrics
port from the Service. That breaks anyone relying on the ServiceMonitor and
conflicts with the ServiceMonitor namespace fix (#149).

## Decision

Make the PodMonitor **additive**. Keep the ServiceMonitor (default path) and add
`metrics.podMonitor.enabled` as an independent alternative for setups that prefer
scraping pods directly. The Service keeps its metrics port.

## Consequences

- No breakage for existing ServiceMonitor users.
- Users on either model are supported; both can even be enabled.
- Both objects require the prometheus-operator CRDs; the integration test installs
  them best-effort and asserts both render, and the static layer validates them.
