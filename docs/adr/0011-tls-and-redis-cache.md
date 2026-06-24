# 11. In-chart TLS material and Redis cache credentials

Date: 2026-06-24

## Status

Accepted

## Context

Two upstream requests needed first-class support without leaking secrets into the
ConfigMap or forcing users to pre-create resources:

- **#112** — serve HTTPS from a cert/key the user supplies inline, rather than
  always requiring a pre-existing `tlsSecretName` Secret.
- **#95** — back the blob descriptor cache with Redis. The connection settings
  are plain config, but the Redis password must not land in the ConfigMap.

## Decision

**TLS** — keep `tlsSecretName` (reference an existing `kubernetes.io/tls` Secret)
and add an inline `tls.crt`/`tls.key`. When both inline values are set and
`tlsSecretName` is unset, `tls-secret.yaml` creates `<fullname>-tls`. A single
resolver helper, `docker-registry.tlsSecretName`, returns the effective Secret
name (or empty) and is used at every TLS site — probes, env, volume, volumeMount,
the Service port name, and the `helm test` hook — so they cannot diverge.
Precedence is explicit: an external `tlsSecretName` always wins over inline `tls`.

**Redis** — connection settings (`addr`, `db`, timeouts, pool, tls) pass through
`configData.redis` into `config.yml`. Only the password is special-cased: a
top-level `redis.password` (or `redis.secretRef` to an external Secret) is
injected as `REGISTRY_REDIS_PASSWORD` via `secretKeyRef`, so it never appears in
the ConfigMap. Enabling the cache still requires the user to set
`configData.storage.cache.blobdescriptor: redis`.

## Consequences

- Users can serve HTTPS with zero pre-created resources, or keep managing the
  cert externally — both paths are supported and tested.
- The resolver helper means adding a future TLS site is one helper call, not six
  edits.
- Redis credentials follow the same secret-handling pattern as proxy/storage
  credentials. Connection tuning stays in the freeform `configData` passthrough
  rather than adding bespoke values for every Redis option.
- Both features are covered by unit tests (`tls_secret_test.yaml`, secret/env
  suites) and render-only scenarios; live functional coverage would require a
  real cert and a Redis deployment and is intentionally out of scope.
