# Changelog

> **Versions prior to 4.0** were released as [`twuni/docker-registry.helm`](https://github.com/twuni/docker-registry.helm).
> Abbreviated entries for notable upstream releases are included below, with attribution to the
> community contributors whose pull requests were accepted.

---

## 4.0.1

Bug-fix release addressing issues still open upstream.

**Bug fixes**

- **`haSharedSecret` no longer regenerates on every render**
  ([twuni#187](https://github.com/twuni/docker-registry.helm/pull/187)).
  The value is now read back from the existing in-cluster Secret via `lookup` and
  only generated on first install, eliminating ArgoCD OutOfSync churn and the HA
  request-signing breakage caused by a rotating secret.
- **S3 with an IAM instance profile / IRSA no longer fails to template**
  ([twuni#71](https://github.com/twuni/docker-registry.helm/pull/71)).
  The S3 credential env vars and Secret keys are guarded so an unset `secrets.s3`
  falls back to the AWS credential chain instead of a nil pointer error.
- **`prometheusRule.enabled` without rules now applies cleanly**
  ([twuni#150](https://github.com/twuni/docker-registry.helm/pull/150)).
  An empty but valid `groups: []` is emitted instead of an empty `spec:` that the
  API rejected.
- Documented `configData` passthrough for arbitrary registry config such as
  `storage.redirect.disable` ([twuni#91](https://github.com/twuni/docker-registry.helm/pull/91))
  and the S3 instance-profile pattern.
- Added `values.schema.json` validation and helm-docs-generated parameter docs.

**New features**

- **In-chart TLS**
  ([twuni#112](https://github.com/twuni/docker-registry.helm/pull/112)).
  Set `tls.crt`/`tls.key` to have the chart create the `kubernetes.io/tls` Secret
  it serves HTTPS from, instead of pre-creating one and pointing `tlsSecretName` at it.
- **Redis blob descriptor cache**
  ([twuni#95](https://github.com/twuni/docker-registry.helm/pull/95)).
  `redis.password` / `redis.secretRef` inject `REGISTRY_REDIS_PASSWORD` from a Secret;
  connection settings go through `configData.redis`.
- Documented token-auth/RBAC ([twuni#197](https://github.com/twuni/docker-registry.helm/pull/197))
  and private-CA trust ([twuni#64](https://github.com/twuni/docker-registry.helm/pull/64))
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

- Overridable `livenessProbe` / `readinessProbe`
  ([twuni#57](https://github.com/twuni/docker-registry.helm/pull/57),
  [issue #54](https://github.com/twuni/docker-registry.helm/issues/54)).
- `extraContainers` (sidecars) on the Deployment and StatefulSet
  ([twuni#140](https://github.com/twuni/docker-registry.helm/pull/140)).
- StatefulSet deployment mode (`useStatefulSet`) with `volumeClaimTemplates`
  ([twuni#89](https://github.com/twuni/docker-registry.helm/pull/89)).
- Gateway API `HTTPRoute` support (`httproute.*`)
  ([twuni#199](https://github.com/twuni/docker-registry.helm/pull/199),
  [issue #137](https://github.com/twuni/docker-registry.helm/issues/137)).
- `PodMonitor` as an additive alternative to the `ServiceMonitor`
  ([twuni#108](https://github.com/twuni/docker-registry.helm/pull/108)).
- `existingSecret` to reference an externally-managed Secret
  ([twuni#185](https://github.com/twuni/docker-registry.helm/pull/185),
  [issue #58](https://github.com/twuni/docker-registry.helm/issues/58)).
- `topologySpreadConstraints` and dual-stack `service.ipFamilies` /
  `ipFamilyPolicy`
  ([twuni#198](https://github.com/twuni/docker-registry.helm/pull/198)).
- `service.create` toggle and `service.name`-aware Ingress/HTTPRoute backends
  ([twuni#159](https://github.com/twuni/docker-registry.helm/pull/159),
  [twuni#116](https://github.com/twuni/docker-registry.helm/pull/116)).
- `deployment.labels`
  ([twuni#195](https://github.com/twuni/docker-registry.helm/pull/195)),
  `enableServiceLinks`
  ([twuni#181](https://github.com/twuni/docker-registry.helm/pull/181)).
- `automountServiceAccountToken` on pod and ServiceAccount
  ([twuni#151](https://github.com/twuni/docker-registry.helm/pull/151)).
- `persistence.keep`, `persistence.annotations`, `persistence.volumeName`
  ([twuni#81](https://github.com/twuni/docker-registry.helm/pull/81),
  [twuni#138](https://github.com/twuni/docker-registry.helm/pull/138),
  [twuni#145](https://github.com/twuni/docker-registry.helm/pull/145)).
- `emptydir.size` (`sizeLimit`) for the non-persistent volume
  ([twuni#93](https://github.com/twuni/docker-registry.helm/pull/93)).
- CronJob `restartPolicy`, `extraEnvVars`, and dedicated `affinity`
  ([twuni#154](https://github.com/twuni/docker-registry.helm/pull/154),
  [twuni#188](https://github.com/twuni/docker-registry.helm/pull/188),
  [twuni#191](https://github.com/twuni/docker-registry.helm/pull/191)).

**Fixes**

- HPA and ServiceMonitor namespaces are now set explicitly / configurable
  ([twuni#152](https://github.com/twuni/docker-registry.helm/pull/152),
  [issue #111](https://github.com/twuni/docker-registry.helm/issues/111);
  [twuni#149](https://github.com/twuni/docker-registry.helm/pull/149),
  [issue #148](https://github.com/twuni/docker-registry.helm/issues/148)).
- Blob cache descriptor is disabled automatically when garbage collection is on
  ([twuni#105](https://github.com/twuni/docker-registry.helm/pull/105),
  [issues #103](https://github.com/twuni/docker-registry.helm/issues/103)/[#104](https://github.com/twuni/docker-registry.helm/issues/104)).
- Adopted the Kubernetes/Helm recommended `app.kubernetes.io/*` labels via shared
  helpers
  ([twuni#173](https://github.com/twuni/docker-registry.helm/pull/173),
  [issue #69](https://github.com/twuni/docker-registry.helm/issues/69)).
- Corrected the documented `image.tag` (`3.0.0`) and `configPath`
  (`/etc/distribution`) defaults.

---

## 3.0.0

Included in the 4.0.0 fork base.*

**Changes**

- **`configPath` now configurable** — updated the chart to accept `configPath`
  to fix distribution's 3.0.0 breaking change (`/etc/docker/registry` →
  `/etc/distribution`).
  By [@Clovel](https://github.com/Clovel)
  ([twuni#168](https://github.com/twuni/docker-registry.helm/pull/168),
  fixes [#135](https://github.com/twuni/docker-registry.helm/issues/135)).
- **S3 force-path-style** — added `s3.forcepathstyle` to the S3 storage
  backend configuration.
  By [@TheAceMan](https://github.com/TheAceMan)
  ([twuni#169](https://github.com/twuni/docker-registry.helm/pull/169)).
- **S3 TLS verification skip** — added `s3.skipverify` to disable certificate
  verification for private S3-compatible endpoints.
  By [@TheAceMan](https://github.com/TheAceMan)
  ([twuni#171](https://github.com/twuni/docker-registry.helm/pull/171)).

---

## 2.3.0

*Released upstream by [twuni/docker-registry.helm](https://github.com/twuni/docker-registry.helm).
Included in the 4.0.0 fork base.*

**Changes**

- **Garbage-collect CronJob improvements** — added `restartPolicy`,
  `extraEnvVars`, and a dedicated `affinity` field to the GC CronJob.
  By [@Mercbot7](https://github.com/Mercbot7)
  ([twuni#164](https://github.com/twuni/docker-registry.helm/pull/164)).
- Documentation updates for the garbage-collect CronJob values.
  By [@Mercbot7](https://github.com/Mercbot7)
  ([twuni#166](https://github.com/twuni/docker-registry.helm/pull/166)).

---

## 2.2.3

*Released upstream by [twuni/docker-registry.helm](https://github.com/twuni/docker-registry.helm).
Included in the 4.0.0 fork base.*

**Changes**

- **Service labels** — updated README to document and correct the default
  image version reference.
  By [@laverya](https://github.com/laverya)
  ([twuni#117](https://github.com/twuni/docker-registry.helm/pull/117)).
- **Deployment annotations** — added support for `deployment.annotations`
  to annotate the Deployment resource.
  By [@ChevronTango](https://github.com/ChevronTango)
  ([twuni#106](https://github.com/twuni/docker-registry.helm/pull/106)).
