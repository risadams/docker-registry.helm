# 5. service.create defaults to true

Date: 2026-06-24

## Status

Accepted

## Context

Upstream PR #159 added a `service.create` toggle so the Service can be managed
externally — but defaulted it to `false`, which is a breaking change: existing
installs would lose their Service on upgrade.

## Decision

Adopt the `service.create` toggle but default it to **`true`**. The Service is
created unless explicitly disabled.

## Consequences

- Backward compatible — upgrades keep their Service.
- Users who manage the Service elsewhere set `service.create: false`.
- The in-chart `helm test` hook and templates that reference the Service
  (Ingress, HTTPRoute backends) account for the Service possibly being absent;
  the test hook skips itself when `service.create` is false. Covered by the
  `service-create-false` scenario and unit tests.
