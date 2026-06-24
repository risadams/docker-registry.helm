# Docker Registry Helm Chart

This directory contains a Kubernetes chart to deploy a private Docker Registry.

> **Fork notice.** This is [`risadams/docker-registry.helm`](https://github.com/risadams/docker-registry.helm),
> a maintained fork of the now-unmaintained [`twuni/docker-registry.helm`](https://github.com/twuni/docker-registry.helm).
> It incorporates the actionable community pull requests and fixes that were left
> open upstream. See the [Changelog](#changelog) for what changed.

![Version: 4.0.1](https://img.shields.io/badge/Version-4.0.1-informational?style=flat-square) ![AppVersion: 3.0.0](https://img.shields.io/badge/AppVersion-3.0.0-informational?style=flat-square)

## Prerequisites Details

* PV support on underlying infrastructure (if persistence is required)

## Chart Details

This chart will do the following:

* Implement a Docker registry deployment

## Installing the Chart

This fork publishes the chart two ways.

### Via the Helm repository (GitHub Pages)

```console
helm repo add docker-registry https://risadams.github.io/docker-registry.helm
helm repo update
helm install my-registry docker-registry/docker-registry
```

### Via the OCI registry (GHCR)

```console
helm install my-registry oci://ghcr.io/risadams/docker-registry --version 4.0.1
```

> The upstream `twuni` repositories (`https://helm.twun.io`, since migrated to
> `https://twuni.github.io/docker-registry.helm`) are no longer actively
> maintained. Point new installs at this fork instead.

## Configuration

The following tables list the configurable parameters of the chart and their
default values. Values are validated against `values.schema.json` at install
time. This section is generated from `values.yaml` by
[helm-docs](https://github.com/norwoodj/helm-docs) — edit the annotations there,
not this table.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| replicaCount | int | `1` | Number of registry replicas to run. Ignored when `autoscaling.enabled` is true. |
| updateStrategy | object | `{}` | Update strategy for the Deployment (or StatefulSet). Empty uses the Kubernetes default. Example: `{type: RollingUpdate, rollingUpdate: {maxSurge: 1, maxUnavailable: 0}}`. |
| podAnnotations | object | `{}` | Annotations added to the registry pod (and the garbage-collect pod unless overridden under `garbageCollect`). |
| podLabels | object | `{}` | Labels added to the registry pod (and the garbage-collect pod unless overridden under `garbageCollect`). |
| automountServiceAccountToken | bool | `false` | Mount the ServiceAccount API token into the pod. Disabled by default for least-privilege; the registry does not talk to the Kubernetes API. |
| serviceAccount.create | bool | `false` | Create a ServiceAccount for the registry. |
| serviceAccount.name | string | `""` | Name of the ServiceAccount to use. When empty and `create` is true, the fullname is used. |
| serviceAccount.annotations | object | `{}` | Annotations to add to the ServiceAccount (e.g. an IRSA role ARN). |
| serviceAccount.automountServiceAccountToken | bool | `false` | Mount the API token into the ServiceAccount. |
| image.repository | string | `"registry"` | Container image repository. |
| image.tag | string | `"3.0.0"` | Container image tag. |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy. |
| deployment.annotations | object | `{}` | Annotations to add to the Deployment/StatefulSet object. |
| deployment.labels | object | `{}` | Labels to add to the Deployment/StatefulSet object. |
| service.create | bool | `true` | Whether to create the Service resource. Set to false when the Service is managed externally (e.g. by another chart or an Ingress controller). |
| service.name | string | `"registry"` | Service name. Also used as the Ingress/HTTPRoute backend name. Empty falls back to the fullname. |
| service.type | string | `"ClusterIP"` | Service type. One of ClusterIP, NodePort, LoadBalancer, ExternalName. |
| service.port | int | `5000` | TCP port the Service exposes. |
| service.annotations | object | `{}` | Additional annotations for the Service. |
| service.labels | object | `{}` | Additional labels for the Service. |
| ingress.enabled | bool | `false` | Create an Ingress for the registry. |
| ingress.className | string | `"nginx"` | IngressClass name. |
| ingress.path | string | `"/"` | Ingress path. |
| ingress.hosts | list | `["chart-example.local"]` | Ingress hostnames. |
| ingress.annotations | object | `{}` | Ingress annotations. |
| ingress.labels | object | `{}` | Additional Ingress labels. |
| ingress.tls | list | `nil` | Ingress TLS configuration. Secrets must be created in the namespace. |
| httproute.enabled | bool | `false` | Create a Gateway API HTTPRoute as an alternative to Ingress. Requires the [Gateway API CRDs](https://gateway-api.sigs.k8s.io/) in the cluster. |
| httproute.apiVersion | string | `""` | HTTPRoute apiVersion. Empty defaults to `gateway.networking.k8s.io/v1`. |
| httproute.annotations | object | `{}` | HTTPRoute annotations. |
| httproute.labels | object | `{}` | HTTPRoute labels. |
| httproute.parentRefs | list | `[]` | Gateway(s) this HTTPRoute attaches to (`parentRefs`). |
| httproute.hostnames | list | `[]` | Hostnames matched against the HTTP Host header (templated). |
| httproute.matches | list | `[{"path":{"type":"PathPrefix","value":"/"}}]` | Request match conditions. Defaults to a PathPrefix `/` match. |
| httproute.filters | list | `[]` | Filters applied to requests matching the rule. |
| httproute.additionalRules | list | `[]` | Additional templated HTTPRoute rules prepended to the default rule. |
| resources | object | `{}` | Resource requests/limits for the registry container. Left empty by default so the chart runs on small clusters; set explicitly for production. |
| persistence.accessMode | string | `"ReadWriteOnce"` | Access mode for the PVC. |
| persistence.enabled | bool | `false` | Use a PersistentVolumeClaim for registry storage (filesystem backend). |
| persistence.size | string | `"10Gi"` | Size of the PVC. |
| persistence.keep | bool | `true` | Keep the PVC on `helm uninstall` (adds the `helm.sh/resource-policy: keep` annotation). |
| persistence.annotations | object | `{}` | Annotations to add to the PVC. |
| useStatefulSet | bool | `false` | Deploy a StatefulSet (with `volumeClaimTemplates`) instead of a Deployment. Useful when each replica needs its own PersistentVolume. |
| storage | string | `"filesystem"` | Storage backend. One of: filesystem, s3, azure, swift. |
| emptydir.size | string | `"0"` | `sizeLimit` for the emptyDir used when persistence is disabled. `"0"` means no limit. |
| existingSecret | string | `""` | Use an existing Secret instead of creating one. The Secret must contain the keys required by your auth/storage/proxy configuration (haSharedSecret, htpasswd, azure*/s3*/swift* keys, proxyUsername/proxyPassword). |
| secrets.haSharedSecret | string | `""` | Shared secret for registry request signing (HA). Generated and kept stable across upgrades when left empty (read back from the existing Secret). |
| secrets.htpasswd | string | `""` | htpasswd contents to enable basic auth. Generate with `docker run --rm --entrypoint htpasswd httpd:2 -Bbn user pass`. |
| proxy | object | `{"enabled":false,"password":"","remoteurl":"https://registry-1.docker.io","secretRef":"","username":""}` | Swift backend options (non-secret). Keys: authurl, container. swift:   authurl: http://swift.example.com/   container: my-container Configure the registry as a pull-through cache. See https://docs.docker.com/registry/recipes/mirror/ |
| proxy.enabled | bool | `false` | Run the registry as a proxy/mirror. |
| proxy.remoteurl | string | `"https://registry-1.docker.io"` | Upstream registry URL to proxy. |
| proxy.username | string | `""` | Upstream username. |
| proxy.password | string | `""` | Upstream password. |
| proxy.secretRef | string | `""` | Reference to an external Secret holding proxyUsername/proxyPassword. |
| metrics.enabled | bool | `false` | Expose the debug/metrics endpoint and add the metrics port to the Service. |
| metrics.port | int | `5001` | Metrics (debug) port. |
| metrics.serviceMonitor.enabled | bool | `false` | Create a prometheus-operator ServiceMonitor. |
| metrics.serviceMonitor.namespace | string | `""` | Namespace to install the ServiceMonitor in. Empty uses the release namespace. |
| metrics.serviceMonitor.labels | object | `{}` | Labels for the ServiceMonitor (e.g. `release: kube-prometheus-stack` for discovery). |
| metrics.podMonitor.enabled | bool | `false` | Create a prometheus-operator PodMonitor as an alternative to the ServiceMonitor. |
| metrics.podMonitor.labels | object | `{}` | Labels for the PodMonitor. |
| metrics.prometheusRule.enabled | bool | `false` | Create a prometheus-operator PrometheusRule. |
| metrics.prometheusRule.labels | object | `{}` | Labels for the PrometheusRule. |
| metrics.prometheusRule.rules | object | `{}` | Alerting rules. Renders an empty rule group when omitted. |
| configPath | string | `"/etc/distribution"` | Mount path for the registry config inside the container (`/etc/distribution` for registry v3, `/etc/docker/registry` for v2). |
| configData | object | `{"health":{"storagedriver":{"enabled":true,"interval":"10s","threshold":3}},"http":{"addr":":5000","debug":{"addr":":5001","prometheus":{"enabled":false,"path":"/metrics"}},"headers":{"X-Content-Type-Options":["nosniff"]}},"log":{"fields":{"service":"registry"}},"storage":{"cache":{"blobdescriptor":"inmemory"}},"version":0.1}` | Registry configuration rendered verbatim into `config.yml`. Any [Distribution config](https://distribution.github.io/distribution/about/configuration/) key can be set here (e.g. `storage.redirect.disable`, `storage.delete.enabled`). |
| containerSecurityContext.enabled | bool | `true` | Apply the container securityContext. |
| containerSecurityContext.seLinuxOptions | object | `{}` | SELinux options. |
| containerSecurityContext.allowPrivilegeEscalation | bool | `false` | Disallow privilege escalation. |
| containerSecurityContext.capabilities | object | `{"drop":["ALL"]}` | Linux capabilities. |
| containerSecurityContext.privileged | bool | `false` | Run the container privileged. |
| containerSecurityContext.readOnlyRootFilesystem | bool | `true` | Mount the root filesystem read-only. |
| containerSecurityContext.runAsUser | int | `1000` | Run as this UID. |
| containerSecurityContext.runAsGroup | int | `1000` | Run as this GID. |
| containerSecurityContext.runAsNonRoot | bool | `true` | Require running as a non-root user. |
| containerSecurityContext.seccompProfile | object | `{"type":"RuntimeDefault"}` | Seccomp profile. |
| enableServiceLinks | bool | `true` | Enable service links (inject namespace Service info as env vars). |
| securityContext.enabled | bool | `true` | Apply the pod securityContext. |
| securityContext.fsGroupChangePolicy | string | `"Always"` | fsGroup change policy. |
| securityContext.sysctls | list | `[]` | sysctls. |
| securityContext.supplementalGroups | list | `[]` | Supplemental groups. |
| securityContext.runAsUser | int | `1000` | Run as this UID. |
| securityContext.fsGroup | int | `1000` | fsGroup applied to mounted volumes. |
| securityContext.seccompProfile | object | `{"type":"RuntimeDefault"}` | Seccomp profile. |
| priorityClassName | string | `""` | PriorityClass name for the pod. |
| podDisruptionBudget | object | `{}` | PodDisruptionBudget for the registry. Example: `{minAvailable: 1}` or `{maxUnavailable: 1}`. |
| autoscaling.enabled | bool | `false` | Enable a HorizontalPodAutoscaler (autoscaling/v2, falls back to v1). |
| autoscaling.minReplicas | int | `1` | Minimum replicas. |
| autoscaling.maxReplicas | int | `2` | Maximum replicas. |
| autoscaling.targetCPUUtilizationPercentage | int | `60` | Target average CPU utilization (%). |
| autoscaling.targetMemoryUtilizationPercentage | int | `60` | Target average memory utilization (%). Requires autoscaling/v2 (k8s >= 1.23). |
| autoscaling.behavior | object | `{}` | Scaling behavior. Requires autoscaling/v2 (k8s >= 1.23). |
| nodeSelector | object | `{}` | Node selector for pod assignment. |
| affinity | object | `{}` | Affinity rules for the pod. |
| topologySpreadConstraints | object | `{}` | Topology spread constraints for the pod. |
| tolerations | list | `[]` | Pod tolerations. |
| extraVolumeMounts | list | `[]` | Additional volumeMounts for the registry container. |
| extraVolumes | list | `[]` | Additional volumes for the pod. |
| extraEnvVars | list | `[]` | Additional environment variables for the registry container. |
| initContainers | list | `[]` | Init containers added to the pod. |
| extraContainers | list | `[]` | Extra (sidecar) containers added to the Deployment/StatefulSet. |
| garbageCollect.enabled | bool | `false` | Deploy a CronJob that runs `registry garbage-collect`. Forces the blob descriptor cache off (cache + GC corrupts the store). |
| garbageCollect.deleteUntagged | bool | `true` | Pass `--delete-untagged` to the garbage collector. |
| garbageCollect.schedule | string | `"0 1 * * *"` | CronJob schedule (standard cron format). |
| garbageCollect.restartPolicy | string | `"OnFailure"` | Restart policy for the GC pod. |
| garbageCollect.podAnnotations | object | `{}` | Annotations for the GC pod. |
| garbageCollect.podLabels | object | `{}` | Labels for the GC pod. |
| garbageCollect.resources | object | `{}` | Resource requests/limits for the GC container. |
| garbageCollect.affinity | object | `{}` | Affinity for the GC pod. Falls back to the top-level `affinity` when unset. |
| garbageCollect.extraEnvVars | list | `[]` | Additional environment variables for the GC container. |

Specify each parameter using the `--set key=value[,key=value]` argument to
`helm install`, or supply a YAML file with `-f values.yaml`.

## Design decisions

The rationale behind the chart's defaults and structure is recorded as
Architecture Decision Records under [`docs/adr/`](docs/adr/) — for example why
the chart defaults to a Deployment (StatefulSet opt-in), why `service.create`
defaults to `true`, and how `haSharedSecret` stays stable across upgrades.

## Usage

### Enabling htpasswd authentication

Generate an htpasswd entry and pass it via `secrets.htpasswd`. The `-B` flag
(bcrypt) is required — the registry rejects other hash formats:

```console
docker run --rm --entrypoint htpasswd httpd:2 -Bbn user 'password' > ./htpasswd
helm install my-registry docker-registry/docker-registry \
  --set-file secrets.htpasswd=./htpasswd
```

### Pushing and pulling images

Port-forward (or expose via Ingress/LoadBalancer) and then use the Docker CLI.
With the default `ClusterIP` service:

```console
kubectl port-forward svc/my-registry-docker-registry 5000:5000 &

# tag and push
docker tag my-image:latest localhost:5000/my-image:latest
docker push localhost:5000/my-image:latest

# pull
docker pull localhost:5000/my-image:latest

# list repositories / tags via the v2 API
curl http://localhost:5000/v2/_catalog
curl http://localhost:5000/v2/my-image/tags/list
```

If htpasswd auth is enabled, run `docker login localhost:5000` first.

### Using an existing Secret

To manage registry credentials outside the chart (e.g. with an external-secrets
operator or sealed-secrets), set `existingSecret`. The chart then skips creating
its own Secret and references yours instead. The Secret must contain the keys
required by your configuration (`haSharedSecret`, `htpasswd`, the relevant
`azure*`/`s3*`/`swift*` storage keys, and `proxyUsername`/`proxyPassword` when
proxying):

```console
helm install my-registry docker-registry/docker-registry \
  --set existingSecret=my-registry-credentials
```

### Exposing via the Gateway API

As an alternative to an Ingress, the chart can create a Gateway API `HTTPRoute`
(requires the [Gateway API CRDs](https://gateway-api.sigs.k8s.io/)):

```yaml
httproute:
  enabled: true
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
  hostnames:
    - registry.example.com
```

### StatefulSet mode

Set `useStatefulSet: true` to deploy a StatefulSet with `volumeClaimTemplates`
instead of a Deployment + standalone PVC. Useful when each replica needs its own
volume:

```console
helm install my-registry docker-registry/docker-registry \
  --set useStatefulSet=true \
  --set persistence.enabled=true \
  --set persistence.storageClass=gp2
```

### Arbitrary registry configuration via `configData`

`configData` is rendered verbatim into the registry's `config.yml`, so any
Distribution config key can be set without a dedicated value. For example, to
disable storage redirects (useful when S3 is not directly reachable by clients):

```yaml
configData:
  storage:
    redirect:
      disable: true
```

The same approach covers options like `storage.maintenance.uploadpurging`,
`storage.delete.enabled`, and custom `http.headers`.

### S3 with an IAM instance profile / IRSA

When the node or pod identity already grants S3 access, omit `secrets.s3`
entirely — the chart will not emit static-credential env vars and the registry
falls back to the AWS credential chain:

```yaml
storage: s3
s3:
  region: us-east-1
  bucket: my-registry-bucket
# no secrets.s3 block -> uses the instance profile / IRSA role
```

## Testing

The chart ships an in-cluster smoke test:

```console
helm test my-registry
```

A full multi-layer suite (static analysis, helm-unittest, and cluster
integration) lives under [`tests/`](tests/) — see
[`tests/README.md`](tests/README.md).

## Changelog

### 4.0.1

Bug-fix release addressing issues still open upstream:

- **haSharedSecret no longer regenerates on every render** (upstream #187). The
  value is now read back from the existing in-cluster Secret via `lookup` and
  only generated on first install, eliminating ArgoCD OutOfSync churn and the HA
  request-signing breakage caused by a rotating secret.
- **S3 with an IAM instance profile / IRSA no longer fails to template**
  (upstream #71). The S3 credential env vars and Secret keys are guarded so an
  unset `secrets.s3` falls back to the AWS credential chain instead of a nil
  pointer error.
- **`prometheusRule.enabled` without rules now applies cleanly** (upstream #150).
  An empty but valid `groups: []` is emitted instead of an empty `spec:` that the
  API rejected.
- Documented `configData` passthrough for arbitrary registry config such as
  `storage.redirect.disable` (upstream #91) and the S3 instance-profile pattern.
- Added `values.schema.json` validation and helm-docs-generated parameter docs.

### 4.0.0

First release of the [`risadams`](https://github.com/risadams/docker-registry.helm)
fork. Incorporates the actionable open pull requests and issues from the
upstream `twuni` project. Selector labels are unchanged, so `helm upgrade` from
upstream 3.0.0 is non-disruptive.

**Features**

- Overridable `livenessProbe` / `readinessProbe`.
- `extraContainers` (sidecars) on the Deployment and StatefulSet.
- StatefulSet deployment mode (`useStatefulSet`) with `volumeClaimTemplates`.
- Gateway API `HTTPRoute` support (`httproute.*`).
- `PodMonitor` as an additive alternative to the `ServiceMonitor`.
- `existingSecret` to reference an externally-managed Secret.
- `topologySpreadConstraints` and dual-stack `service.ipFamilies` / `ipFamilyPolicy`.
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

----------------------------------------------
_Documentation for the configuration table above is generated from `values.yaml`._
