# Changelog

> **Versions prior to 4.0** — see the
> [upstream `twuni/docker-registry.helm` repository](https://github.com/twuni/docker-registry.helm)
> for the history of releases 1.x through 3.x.

---

## 4.0.1

Bug-fix release addressing issues still open upstream.

**Bug fixes**

- **`haSharedSecret` no longer regenerates on every render** (upstream #187). The
  value is now read back from the existing in-cluster Secret via `lookup` and
  only generated on first install, eliminating ArgoCD OutOfSync churn and the HA
  request-signing breakage caused by a rotating secret.
- **S3 with an IAM instance profile / IRSA no longer fails to template**
  (upstream #71). The S3 credential env vars and Secret keys are guarded so an
  unset `secrets.s3` falls back to the AWS credential chain instead of a nil
  pointer error.
- **`prometheusRule.enabled` without rules now applies cleanly** (upstream #150).
  An empty but valid `groups: []` is emitted instead of an empty `spec:` that
  the API rejected.
- Documented `configData` passthrough for arbitrary registry config such as
  `storage.redirect.disable` (upstream #91) and the S3 instance-profile pattern.
- Added `values.schema.json` validation and helm-docs-generated parameter docs.

**New features**

- **In-chart TLS** (upstream #112). Set `tls.crt`/`tls.key` to have the chart
  create the `kubernetes.io/tls` Secret it serves HTTPS from, instead of
  pre-creating one and pointing `tlsSecretName` at it.
- **Redis blob descriptor cache** (upstream #95). `redis.password` /
  `redis.secretRef` inject `REGISTRY_REDIS_PASSWORD` from a Secret; connection
  settings go through `configData.redis`.
- Documented token-auth/RBAC (upstream #197) and private-CA trust (upstream #64)
  patterns using `configData.auth.token` and `extraVolumes`/`extraVolumeMounts`.
- **Updated the registry image to 3.1.1** (from 3.0.0) — picks up security fixes
  for CVE-2026-35172 (3.1.0) and CVE-2026-41888 (3.1.1).

---

## 4.0.0

First release of the [`risadams`](https://github.com/risadams/docker-registry.helm)
fork. Incorporates the actionable open pull requests and issues from the upstream
`twuni` project. Selector labels are unchanged, so `helm upgrade` from upstream
3.0.0 is non-disruptive.

**Features**

- Overridable `livenessProbe` / `readinessProbe`.
- `extraContainers` (sidecars) on the Deployment and StatefulSet.
- StatefulSet deployment mode (`useStatefulSet`) with `volumeClaimTemplates`.
- Gateway API `HTTPRoute` support (`httproute.*`).
- `PodMonitor` as an additive alternative to the `ServiceMonitor`.
- `existingSecret` to reference an externally-managed Secret.
- `topologySpreadConstraints` and dual-stack `service.ipFamilies` /
  `ipFamilyPolicy`.
- `service.create` toggle and `service.name`-aware Ingress/HTTPRoute backends.
- `deployment.labels`, `enableServiceLinks`, `automountServiceAccountToken`.
- `persistence.keep`, `persistence.annotations`, `persistence.volumeName`.
- `emptydir.size` (`sizeLimit`) for the non-persistent volume.
- CronJob `restartPolicy`, `extraEnvVars`, and dedicated `affinity`.

**Fixes**

- HPA and ServiceMonitor namespaces are now set explicitly / configurable.
- Blob cache descriptor is disabled automatically when garbage collection is on.
- Adopted the Kubernetes/Helm recommended `app.kubernetes.io/*` labels.
- Corrected the documented `image.tag` (`3.0.0`) and `configPath`
  (`/etc/distribution`) defaults.
