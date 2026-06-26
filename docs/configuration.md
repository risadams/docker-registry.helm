# Configuration Reference

All configurable values for the `docker-registry` chart. Values are validated
against `values.schema.json` at install time. Edit annotations in `values.yaml`
as the source of truth; this document is the grouped human-readable reference.

Pass values with `--set key=value` or a custom values file (`-f my-values.yaml`).

---

## Workload

Controls whether the registry runs as a Deployment or StatefulSet, how many
replicas it runs, and how rolling updates are applied.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `replicaCount` | int | `1` | Number of registry replicas. Ignored when `autoscaling.enabled` is true. |
| `updateStrategy` | object | `{}` | Update strategy for the Deployment or StatefulSet. Empty uses the Kubernetes default (RollingUpdate). Example: `{type: RollingUpdate, rollingUpdate: {maxSurge: 1, maxUnavailable: 0}}`. |
| `useStatefulSet` | bool | `false` | Deploy a StatefulSet with `volumeClaimTemplates` instead of a Deployment + standalone PVC. Use this when each replica needs its own PersistentVolume (e.g. multi-replica with local storage). |
| `deployment.annotations` | object | `{}` | Annotations added to the Deployment or StatefulSet object itself (not the pod). |
| `deployment.labels` | object | `{}` | Extra labels added to the Deployment or StatefulSet object. |

---

## Image

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `image.repository` | string | `"registry"` | Container image repository. Change this to use a mirrored or custom image. |
| `image.tag` | string | `"3.1.1"` | Image tag. Defaults to the Distribution v3 release tested against this chart version. |
| `image.pullPolicy` | string | `"IfNotPresent"` | Image pull policy. Use `Always` when the tag is mutable (e.g. `latest`). |
| `imagePullSecrets` | list | `[]` | Image pull secrets for private registries. Example: `[{name: my-pull-secret}]`. |

---

## Service Account

By default no ServiceAccount is created. Enable one when you need IRSA or
Workload Identity on cloud providers.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `serviceAccount.create` | bool | `false` | Create a dedicated ServiceAccount for the registry pod. |
| `serviceAccount.name` | string | `""` | Name of the ServiceAccount to use or create. When empty and `create` is true, the chart fullname is used. |
| `serviceAccount.annotations` | object | `{}` | Annotations to add to the ServiceAccount — commonly used to attach an IAM role ARN for IRSA (`eks.amazonaws.com/role-arn`). |
| `serviceAccount.automountServiceAccountToken` | bool | `false` | Mount the ServiceAccount API token into pods using this account. |

---

## Pod

Settings applied to the registry pod(s), including labels, annotations,
scheduling hints, and resource allocation.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `podAnnotations` | object | `{}` | Annotations added to the registry pod. Also applied to the garbage-collect pod unless overridden under `garbageCollect`. |
| `podLabels` | object | `{}` | Extra labels added to the registry pod. Also applied to the garbage-collect pod unless overridden under `garbageCollect`. |
| `automountServiceAccountToken` | bool | `false` | Mount the ServiceAccount token into the pod. Disabled by default — the registry does not talk to the Kubernetes API. |
| `enableServiceLinks` | bool | `true` | Inject namespace Service discovery information as environment variables. Disable to reduce env-var noise in the container. |
| `priorityClassName` | string | `""` | PriorityClass for the pod. Useful for ensuring the registry is scheduled before lower-priority workloads. |
| `podDisruptionBudget` | object | `{}` | PodDisruptionBudget spec fragment. Example: `{minAvailable: 1}` or `{maxUnavailable: 1}`. |
| `resources` | object | `{}` | CPU and memory requests/limits for the registry container. Left empty so the chart runs on small clusters; set explicitly for production. Example: `{requests: {cpu: 100m, memory: 128Mi}, limits: {cpu: 500m, memory: 512Mi}}`. |

---

## Service

The chart creates a `ClusterIP` Service by default. The Service name is also
used as the backend name for Ingress and HTTPRoute objects.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `service.create` | bool | `true` | Create the Service resource. Set to `false` when the Service is managed externally (e.g. by another chart or a mesh). |
| `service.name` | string | `"registry"` | Service name. Also used as the Ingress/HTTPRoute backend name. Empty falls back to the chart fullname. |
| `service.type` | string | `"ClusterIP"` | Service type. One of `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`. |
| `service.port` | int | `5000` | TCP port the Service exposes. Must match `configData.http.addr`. |
| `service.annotations` | object | `{}` | Annotations for the Service (e.g. cloud load-balancer hints). |
| `service.labels` | object | `{}` | Extra labels for the Service. |
| `service.clusterIP` | string | _(unset)_ | Static cluster IP. Only valid when `type` is `ClusterIP`. |
| `service.nodePort` | int | _(unset)_ | Node port. Only valid when `type` is `NodePort`. |
| `service.loadBalancerIP` | string | _(unset)_ | Load balancer IP. Only valid when `type` is `LoadBalancer`. |
| `service.loadBalancerSourceRanges` | list | _(unset)_ | Source IP ranges allowed to reach a `LoadBalancer` Service. |
| `service.sessionAffinity` | string | _(unset)_ | Session affinity (`ClientIP` or `None`). |
| `service.ipFamilyPolicy` | string | _(unset)_ | IP family policy, e.g. `PreferDualStack` or `RequireDualStack`. |
| `service.ipFamilies` | list | _(unset)_ | IP families, e.g. `[IPv4, IPv6]`. |

---

## Networking

Controls how the registry is exposed outside the cluster. The chart supports
three modes, selected by `networking.type`:

- **`gateway`** (default) — creates a Gateway API `HTTPRoute`. An HTTPRoute is
  only rendered once `httproute.parentRefs` is populated, so a default install
  is safe on clusters without Gateway API CRDs installed.
- **`ingress`** — creates a classic Kubernetes `Ingress` object.
- **`none`** — no networking object is created. Use this when you manage
  exposure externally (service mesh, LoadBalancer Service, etc.).

The legacy `httproute.enabled` and `ingress.enabled` flags are preserved for
backward compatibility and act as OR-overrides of `networking.type`.

### Selector

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `networking.type` | string | `"gateway"` | Networking mode: `"gateway"`, `"ingress"`, or `"none"`. |

### Gateway API (HTTPRoute)

Requires the [Gateway API CRDs](https://gateway-api.sigs.k8s.io/) to be
installed in the cluster (`gateway.networking.k8s.io/v1` or later).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `httproute.parentRefs` | list | `[]` | Gateways this HTTPRoute attaches to. **Populating this field triggers HTTPRoute creation** when `networking.type` is `"gateway"`. Example: `[{name: my-gateway, namespace: gateway-system, sectionName: https}]`. |
| `httproute.hostnames` | list | `[]` | Hostnames matched against the HTTP Host header. Supports Helm template expressions. |
| `httproute.matches` | list | `[{path: {type: PathPrefix, value: /}}]` | Request match conditions for the default rule. |
| `httproute.filters` | list | `[]` | Filters applied to requests on the default rule (e.g. `RequestHeaderModifier`). |
| `httproute.additionalRules` | list | `[]` | Extra HTTPRoute rules prepended before the default backend rule. Supports Helm template expressions. |
| `httproute.apiVersion` | string | `""` | Override the HTTPRoute `apiVersion`. Defaults to `gateway.networking.k8s.io/v1`. Use `gateway.networking.k8s.io/v1beta1` for older clusters. |
| `httproute.annotations` | object | `{}` | Annotations for the HTTPRoute object. |
| `httproute.labels` | object | `{}` | Extra labels for the HTTPRoute object. |
| `httproute.enabled` | bool | `false` | **Deprecated.** Use `networking.type: gateway` instead. Retained for backward compatibility. |

### Classic Ingress

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `ingress.className` | string | `""` | IngressClass name (e.g. `nginx`, `traefik`, `alb`). Required by most controllers on Kubernetes ≥ 1.18. |
| `ingress.hosts` | list | `["chart-example.local"]` | Hostnames to match. Each host gets its own rule. |
| `ingress.path` | string | `"/"` | Path prefix for all host rules. |
| `ingress.tls` | list | `nil` | TLS configuration. Each entry maps a Secret name to one or more hostnames. The Secret must exist in the same namespace. Example: `[{secretName: registry-tls, hosts: [registry.example.com]}]`. |
| `ingress.annotations` | object | `{}` | Annotations for the Ingress (e.g. `nginx.ingress.kubernetes.io/proxy-body-size: "0"` to allow large image pushes). |
| `ingress.labels` | object | `{}` | Extra labels for the Ingress object. |
| `ingress.enabled` | bool | `false` | **Deprecated.** Use `networking.type: ingress` instead. Retained for backward compatibility. |

---

## Storage

The registry supports four storage backends. The backend is selected with the
`storage` value; backend-specific options go either in `configData` (non-secret)
or in the relevant `secrets.*` block (credentials).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `storage` | string | `"filesystem"` | Storage backend. One of: `filesystem`, `s3`, `azure`, `swift`. |
| `configPath` | string | `"/etc/distribution"` | Mount path for the registry config inside the container. Use `/etc/docker/registry` for Distribution v2 images. |
| `configData` | object | _(see values.yaml)_ | Registry configuration rendered verbatim into `config.yml`. Any [Distribution config key](https://distribution.github.io/distribution/about/configuration/) can be set here. See the `configData` section below for the default structure. |
| `emptydir.size` | string | `"0"` | `sizeLimit` for the emptyDir volume used when `persistence.enabled` is false. `"0"` means no limit. |

### Persistence (filesystem backend)

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `persistence.enabled` | bool | `false` | Use a PersistentVolumeClaim for registry storage. When false, an emptyDir is used (data is lost on pod restart). |
| `persistence.size` | string | `"10Gi"` | PVC capacity request. |
| `persistence.accessMode` | string | `"ReadWriteOnce"` | PVC access mode. Use `ReadWriteMany` for multi-replica deployments on a shared filesystem. |
| `persistence.storageClass` | string | _(cluster default)_ | StorageClass for the PVC. Set to `-` to disable dynamic provisioning. |
| `persistence.volumeName` | string | _(unset)_ | Bind the PVC to a specific PersistentVolume by name. |
| `persistence.existingClaim` | string | _(unset)_ | Use an existing PVC instead of creating one. Supports Helm template expressions. |
| `persistence.keep` | bool | `true` | Retain the PVC on `helm uninstall` (adds `helm.sh/resource-policy: keep`). Set to `false` to delete data on uninstall. |
| `persistence.annotations` | object | `{}` | Annotations for the PVC. |

### S3 backend (non-secret options)

Set `storage: s3` and configure under `s3:`:

```yaml
storage: s3
s3:
  region: us-east-1
  bucket: my-registry-bucket
  regionEndpoint: ""       # custom endpoint (MinIO, Ceph, etc.)
  rootdirectory: ""        # optional key prefix
  encrypt: false
  secure: true
  forcepathstyle: false
  skipverify: false
```

For credentials see [Secrets — S3](#secrets--authentication).

### Azure backend (non-secret options)

Set `storage: azure`. Credentials go in `secrets.azure`.

### Swift backend (non-secret options)

Set `storage: swift` and configure under `swift:`:

```yaml
swift:
  authurl: http://swift.example.com/
  container: my-container
```

Credentials go in `secrets.swift`.

### `configData` default structure

```yaml
configData:
  version: 0.1
  log:
    fields:
      service: registry
  storage:
    cache:
      blobdescriptor: inmemory
  http:
    addr: :5000
    headers:
      X-Content-Type-Options: [nosniff]
    debug:
      addr: :5001
      prometheus:
        enabled: false
        path: /metrics
  health:
    storagedriver:
      enabled: true
      interval: 10s
      threshold: 3
```

Any key in this map can be overridden or extended. The entire map is merged at
install time.

---

## Secrets & Authentication

### Existing Secret

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `existingSecret` | string | `""` | Name of an existing Secret to use instead of creating one. Must contain all keys your configuration requires (see below). When set, the chart skips creating its own Secret. |

**Required keys in the existing Secret** (only those relevant to your config):

| Key | Used by |
|-----|---------|
| `haSharedSecret` | HA request signing |
| `htpasswd` | Basic auth |
| `azureAccountName`, `azureAccountKey`, `azureContainer` | Azure storage |
| `s3AccessKey`, `s3SecretKey` | S3 static credentials |
| `swiftUsername`, `swiftPassword` | Swift storage |
| `proxyUsername`, `proxyPassword` | Pull-through proxy |
| `redisPassword` | Redis cache |

### Chart-managed credentials

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `secrets.haSharedSecret` | string | `""` | Shared secret for HA request signing. Generated once on first install and read back on upgrades via `lookup` — never rotates automatically. |
| `secrets.htpasswd` | string | `""` | htpasswd file contents for basic auth. Generate with: `docker run --rm --entrypoint htpasswd httpd:2 -Bbn user pass`. Only bcrypt (`-B`) is accepted. |
| `secrets.azure.accountName` | string | `""` | Azure storage account name. |
| `secrets.azure.accountKey` | string | `""` | Azure storage account key. |
| `secrets.azure.container` | string | `""` | Azure blob container. |
| `secrets.s3.accessKey` | string | `""` | S3 access key. Omit the entire `secrets.s3` block to use an instance profile or IRSA. |
| `secrets.s3.secretKey` | string | `""` | S3 secret key. |
| `secrets.s3.secretRef` | string | `""` | Reference to an external Secret with `s3AccessKey`/`s3SecretKey` keys. |
| `secrets.swift.username` | string | `""` | Swift username. |
| `secrets.swift.password` | string | `""` | Swift password. |

### Pull-through proxy / mirror

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `proxy.enabled` | bool | `false` | Run the registry as a pull-through cache/mirror. |
| `proxy.remoteurl` | string | `"https://registry-1.docker.io"` | Upstream registry to proxy. |
| `proxy.username` | string | `""` | Upstream username. |
| `proxy.password` | string | `""` | Upstream password (stored in the chart Secret). |
| `proxy.secretRef` | string | `""` | Reference to an external Secret with `proxyUsername`/`proxyPassword` keys. |

### Redis cache credentials

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `redis.password` | string | `""` | Redis password. Injected as `REGISTRY_REDIS_PASSWORD`. Leave empty for password-less Redis. |
| `redis.secretRef` | string | `""` | Reference to an external Secret with a `redisPassword` key. |

---

## TLS

The registry can serve HTTPS directly (terminating TLS at the process). This is
separate from TLS termination at an Ingress or Gateway.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `tlsSecretName` | string | _(unset)_ | Name of an existing `kubernetes.io/tls` Secret. Takes precedence over `tls` below. Typical use: cert-manager issues the cert and you reference its Secret here. |
| `tls.crt` | string | `""` | PEM-encoded certificate. When both `tls.crt` and `tls.key` are set (and `tlsSecretName` is unset), the chart creates a Secret from this material. |
| `tls.key` | string | `""` | PEM-encoded private key. |

When either TLS option is configured:
- The cert is mounted at `/etc/ssl/docker`.
- The registry serves HTTPS.
- Liveness and readiness probes switch to the HTTPS scheme automatically.

---

## Metrics & Monitoring

The registry exposes a Prometheus-compatible metrics endpoint on the debug port.
Prometheus Operator integration is optional.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `metrics.enabled` | bool | `false` | Enable the debug/metrics port and add it to the Service. |
| `metrics.port` | int | `5001` | Debug/metrics port. Must match `configData.http.debug.addr`. |
| `metrics.serviceMonitor.enabled` | bool | `false` | Create a `ServiceMonitor` for prometheus-operator. |
| `metrics.serviceMonitor.namespace` | string | `""` | Namespace for the ServiceMonitor. Empty uses the release namespace. |
| `metrics.serviceMonitor.labels` | object | `{}` | Labels for the ServiceMonitor. Must match your Prometheus `serviceMonitorSelector` (e.g. `release: kube-prometheus-stack`). |
| `metrics.podMonitor.enabled` | bool | `false` | Create a `PodMonitor` as an alternative to the ServiceMonitor. Use when `service.create` is false. |
| `metrics.podMonitor.labels` | object | `{}` | Labels for the PodMonitor. |
| `metrics.prometheusRule.enabled` | bool | `false` | Create a `PrometheusRule` with alerting rules. |
| `metrics.prometheusRule.labels` | object | `{}` | Labels for the PrometheusRule. |
| `metrics.prometheusRule.rules` | object | `{}` | Alerting rule definitions. An empty but valid `groups: []` is emitted when this is empty. |

To enable Prometheus scraping, also set `configData.http.debug.prometheus.enabled: true`.

---

## Security

### Container security context

Applied to the registry container (and the GC container).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `containerSecurityContext.enabled` | bool | `true` | Apply the container `securityContext`. |
| `containerSecurityContext.allowPrivilegeEscalation` | bool | `false` | Disallow privilege escalation via `setuid`/`setgid`. |
| `containerSecurityContext.capabilities` | object | `{drop: [ALL]}` | Linux capabilities. The registry requires no capabilities. |
| `containerSecurityContext.privileged` | bool | `false` | Run the container as privileged. |
| `containerSecurityContext.readOnlyRootFilesystem` | bool | `true` | Mount the root filesystem read-only. |
| `containerSecurityContext.runAsUser` | int | `1000` | UID to run the container as. |
| `containerSecurityContext.runAsGroup` | int | `1000` | GID to run the container as. |
| `containerSecurityContext.runAsNonRoot` | bool | `true` | Require the container to run as a non-root user. |
| `containerSecurityContext.seccompProfile` | object | `{type: RuntimeDefault}` | Seccomp profile. |
| `containerSecurityContext.seLinuxOptions` | object | `{}` | SELinux options. |

### Pod security context

Applied to the pod as a whole (affects volume mounts and init containers).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `securityContext.enabled` | bool | `true` | Apply the pod `securityContext`. |
| `securityContext.runAsUser` | int | `1000` | UID for all containers in the pod. |
| `securityContext.fsGroup` | int | `1000` | fsGroup for mounted volumes (files created in volumes are owned by this GID). |
| `securityContext.fsGroupChangePolicy` | string | `"Always"` | When to change volume ownership: `Always` or `OnRootMismatch`. |
| `securityContext.sysctls` | list | `[]` | Kernel parameter overrides. |
| `securityContext.supplementalGroups` | list | `[]` | Additional GIDs for the pod. |
| `securityContext.seccompProfile` | object | `{type: RuntimeDefault}` | Seccomp profile for the pod. |

---

## Scheduling & Placement

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `nodeSelector` | object | `{}` | Node labels to constrain which nodes the registry pod runs on. |
| `affinity` | object | `{}` | Affinity and anti-affinity rules. For multi-replica HA, add pod anti-affinity rules here to spread replicas across nodes. |
| `tolerations` | list | `[]` | Tolerations for pod scheduling on tainted nodes. |
| `topologySpreadConstraints` | object | `{}` | Topology spread constraints for even distribution across zones/nodes. |

---

## Autoscaling

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `autoscaling.enabled` | bool | `false` | Enable a HorizontalPodAutoscaler (`autoscaling/v2`, falls back to `v1`). When enabled, `replicaCount` is ignored. |
| `autoscaling.minReplicas` | int | `1` | Minimum replica count. |
| `autoscaling.maxReplicas` | int | `2` | Maximum replica count. |
| `autoscaling.targetCPUUtilizationPercentage` | int | `60` | Target average CPU utilization across all replicas (%). |
| `autoscaling.targetMemoryUtilizationPercentage` | int | `60` | Target average memory utilization (%). Requires `autoscaling/v2` (Kubernetes ≥ 1.23). |
| `autoscaling.behavior` | object | `{}` | Scale-up/scale-down behavior config. Requires `autoscaling/v2`. |

---

## Extensibility

These values let you inject arbitrary Kubernetes resources and configuration
without forking the chart.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `extraVolumes` | list | `[]` | Additional volumes added to the pod spec. |
| `extraVolumeMounts` | list | `[]` | Additional volume mounts added to the registry container. |
| `extraEnvVars` | list | `[]` | Additional environment variables for the registry container. |
| `initContainers` | list | `[]` | Init containers added to the pod before the registry starts. |
| `extraContainers` | list | `[]` | Sidecar containers added to the Deployment/StatefulSet pod. |
| `livenessProbe` | object | _(unset)_ | Override the default liveness probe entirely. Example: `{tcpSocket: {port: 5000}}`. |
| `readinessProbe` | object | _(unset)_ | Override the default readiness probe entirely. |

---

## Garbage Collection

The chart can deploy a CronJob that runs `registry garbage-collect` on a
schedule to reclaim storage from deleted layers. **Note:** the GC job
automatically disables the in-memory blob descriptor cache to prevent cache
corruption (a cache + GC combination corrupts the layer store).

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `garbageCollect.enabled` | bool | `false` | Deploy the garbage-collection CronJob. |
| `garbageCollect.schedule` | string | `"0 1 * * *"` | CronJob schedule in standard cron format. Default: 01:00 UTC daily. |
| `garbageCollect.deleteUntagged` | bool | `true` | Pass `--delete-untagged` to the garbage collector to also remove untagged manifests. |
| `garbageCollect.restartPolicy` | string | `"OnFailure"` | Restart policy for the GC pod (`OnFailure` or `Never`). |
| `garbageCollect.podAnnotations` | object | `{}` | Annotations for the GC pod. |
| `garbageCollect.podLabels` | object | `{}` | Labels for the GC pod. |
| `garbageCollect.resources` | object | `{}` | Resource requests/limits for the GC container. |
| `garbageCollect.affinity` | object | `{}` | Affinity rules for the GC pod. Falls back to the top-level `affinity` when unset. |
| `garbageCollect.extraEnvVars` | list | `[]` | Additional environment variables for the GC container. |
