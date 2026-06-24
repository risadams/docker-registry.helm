# 6. existingSecret over per-provider key overrides

Date: 2026-06-24

## Status

Accepted

## Context

Two competing upstream PRs addressed "use an externally-managed Secret":

- **#185** — a single `existingSecret` name; the chart references it instead of
  creating its own Secret.
- **#186** — per-provider key-name overrides (`secrets.azure.accountNameKey`,
  `secrets.swift.usernameKey`, etc.) plus per-provider existing-secret refs.

#186 is far more surface area and shipped with real defects (whitespace-chomping
`key: {{- ... }}` that broke Azure rendering; references to an undefined
`secrets.azure.existingSecret`).

## Decision

Adopt the **#185 approach**: a single top-level `existingSecret`. When set, the
chart skips creating its Secret and all `secretKeyRef`s resolve to the named
Secret via the `docker-registry.secretName` helper. The user is responsible for
populating the expected keys (`haSharedSecret`, `htpasswd`, the storage keys,
`proxyUsername`/`proxyPassword`).

## Consequences

- Simple, correct, and works with external-secrets / sealed-secrets operators.
- The pod's `checksum/secret` annotation is omitted when `existingSecret` is set
  (the chart no longer owns that Secret's contents).
- Per-key remapping (#186) is not supported; users align their Secret to the
  expected key names. Covered by the `existing-secret` scenario and unit tests.
