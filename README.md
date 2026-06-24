# Docker Registry Helm Chart

This directory contains a Kubernetes chart to deploy a private Docker Registry.

> **Fork notice.** This is [`risadams/docker-registry.helm`](https://github.com/risadams/docker-registry.helm),
> a maintained fork of the now-unmaintained [`twuni/docker-registry.helm`](https://github.com/twuni/docker-registry.helm).
> It incorporates the actionable community pull requests and fixes that were left
> open upstream. See the [Changelog](#changelog) for what changed.

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
helm install my-registry oci://ghcr.io/risadams/docker-registry --version 4.0.0
```

> The upstream `twuni` repositories (`https://helm.twun.io`, since migrated to
> `https://twuni.github.io/docker-registry.helm`) are no longer actively
> maintained. Point new installs at this fork instead.

## Configuration

The following table lists the configurable parameters of the docker-registry chart and
their default values.

| Parameter                   | Description                                                                                | Default         |
|:----------------------------|:-------------------------------------------------------------------------------------------|:----------------|
| `image.pullPolicy`          | Container pull policy                                                                      | `IfNotPresent`  |
| `image.repository`          | Container image to use                                                                     | `registry`      |
| `image.tag`                 | Container image tag to deploy                                                              | `3.0.0`         |
| `imagePullSecrets`          | Specify image pull secrets                                                                 | `nil` (does not add image pull secrets to deployed pods) |
| `persistence.accessMode`    | Access mode to use for PVC                                                                 | `ReadWriteOnce` |
| `persistence.enabled`       | Whether to use a PVC for the Docker storage                                                | `false`         |
| `persistence.deleteEnabled` | Enable the deletion of image blobs and manifests by digest                                 | `nil`           |
| `persistence.size`          | Amount of space to claim for PVC                                                           | `10Gi`          |
| `persistence.storageClass`  | Storage Class to use for PVC                                                               | `-`             |
| `persistence.existingClaim` | Name of an existing PVC to use for config                                                  | `nil`           |
| `persistence.keep`          | Keep the PVC on `helm uninstall` (adds `helm.sh/resource-policy: keep`)                    | `true`          |
| `persistence.volumeName`    | Bind the PVC to a specific PersistentVolume by name                                        | `nil`           |
| `persistence.annotations`   | Annotations to add to the PVC                                                              | `{}`            |
| `useStatefulSet`            | Deploy as a StatefulSet (with `volumeClaimTemplates`) instead of a Deployment             | `false`         |
| `emptydir.size`             | `sizeLimit` for the emptyDir used when persistence is disabled (`0` = unlimited)           | `"0"`           |
| `serviceAccount.create`     | Create ServiceAccount                                                                      | `false`         |
| `serviceAccount.name`       | ServiceAccount name                                                                        | `nil`           |
| `serviceAccount.annotations` | Annotations to add to the ServiceAccount                                                  | `{}`            |
| `serviceAccount.automountServiceAccountToken` | Mount the SA token into the ServiceAccount                               | `false`         |
| `automountServiceAccountToken` | Mount the ServiceAccount API token into the pod                                         | `false`         |
| `deployment.annotations`    | Annotations to add to the Deployment                                                       | `{}`            |
| `deployment.labels`         | Labels to add to the Deployment                                                            | `{}`            |
| `enableServiceLinks`        | Whether to enable service links in the pod                                                 | `true`          |
| `service.create`            | Whether to create the Service resource                                                     | `true`          |
| `service.name`              | Name of the Service (also used by Ingress/HTTPRoute backends)                              | `registry`      |
| `service.port`              | TCP port on which the service is exposed                                                   | `5000`          |
| `service.type`              | service type                                                                               | `ClusterIP`     |
| `service.clusterIP`         | if `service.type` is `ClusterIP` and this is non-empty, sets the cluster IP of the service | `nil`           |
| `service.nodePort`          | if `service.type` is `NodePort` and this is non-empty, sets the node port of the service   | `nil`           |
| `service.loadBalancerIP`     | if `service.type` is `LoadBalancer` and this is non-empty, sets the loadBalancerIP of the service | `nil`          |
| `service.loadBalancerSourceRanges`| if `service.type` is `LoadBalancer` and this is non-empty, sets the loadBalancerSourceRanges of the service | `nil`           |
| `service.sessionAffinity`       | service session affinity                                                               | `nil`           |
| `service.sessionAffinityConfig` | service session affinity config                                                        | `nil`           |
| `service.ipFamilies`        | IP families for the service (e.g. `[IPv4, IPv6]`)                                          | `[]`            |
| `service.ipFamilyPolicy`    | IP family policy for the service (e.g. `PreferDualStack`)                                  | `nil`           |
| `replicaCount`              | k8s replicas                                                                               | `1`             |
| `updateStrategy`            | update strategy for deployment                                                             | `{}`            |
| `podAnnotations`            | Annotations for deployment pod, and `garbageCollect` pod unless set explicitly there. See `garbageCollect` | `{}` |
| `podLabels`                 | Labels for deployment pod, and `garbageCollect` pod unless set explicitly there. See `garbageCollect` | `{}` |
| `podDisruptionBudget`       | Pod disruption budget                                                                      | `{}`            |
| `resources.limits.cpu`      | Container requested CPU                                                                    | `nil`           |
| `resources.limits.memory`   | Container requested memory                                                                 | `nil`           |
| `autoscaling.enabled`       | Enable autoscaling using HorizontalPodAutoscaler                                           | `false`         |
| `autoscaling.minReplicas`   | Minimal number of replicas                                                                 | `1`             |
| `autoscaling.maxReplicas`   | Maximal number of replicas                                                                 | `2`             |
| `autoscaling.targetCPUUtilizationPercentage` | Target average utilization of CPU on Pods                                 | `60`            |
| `autoscaling.targetMemoryUtilizationPercentage` | (Kubernetes ≥1.23) Target average utilization of Memory on Pods        | `60`            |
| `autoscaling.behavior`      | (Kubernetes ≥1.23) Configurable scaling behavior                                           | `{}`            |
| `priorityClassName      `   | priorityClassName                                                                          | `""`            |
| `storage`                   | Storage system to use                                                                      | `filesystem`    |
| `tlsSecretName`             | Name of secret for TLS certs                                                               | `nil`           |
| `existingSecret`            | Name of an existing Secret to use instead of creating one                                  | `""`            |
| `secrets.htpasswd`          | Htpasswd authentication                                                                    | `nil`           |
| `secrets.s3.accessKey`      | Access Key for S3 configuration                                                            | `nil`           |
| `secrets.s3.secretKey`      | Secret Key for S3 configuration                                                            | `nil`           |
| `secrets.s3.secretRef`      | The ref for an external secret containing the s3AccessKey and s3SecretKey keys                 | `""`            |
| `secrets.swift.username`    | Username for Swift configuration                                                           | `nil`           |
| `secrets.swift.password`    | Password for Swift configuration                                                           | `nil`           |
| `secrets.haSharedSecret`    | Shared secret for Registry                                                                 | `nil`           |
| `configData`                | Configuration hash for docker                                                              | `nil`           |
| `configPath` | Configuration mount point in docker, `/etc/docker/registry` for registry version 2, `/etc/distribution` for version 3 | `/etc/distribution` |
| `s3.region`                 | S3 region                                                                                  | `nil`           |
| `s3.regionEndpoint`         | S3 region endpoint                                                                         | `nil`           |
| `s3.bucket`                 | S3 bucket name                                                                             | `nil`           |
| `s3.rootdirectory`          | S3 prefix that is applied to allow you to segment data                                     | `nil`           |
| `s3.encrypt`                | Store images in encrypted format                                                           | `nil`           |
| `s3.secure`                 | Use HTTPS                                                                                  | `nil`           |
| `s3.forcepathstyle`         | Use path-style addressing, needed for some s3 compatible storage (minio)                   | `nil`           |
| `s3.skipverify`             | Allows connection to s3 storage using TLS with untrusted/self-signed certificate           | `nil`           |
| `swift.authurl`             | Swift authurl                                                                              | `nil`           |
| `swift.container`           | Swift container                                                                            | `nil`           |
| `proxy.enabled`             | If true, registry will function as a proxy/mirror                                          | `false`         |
| `proxy.remoteurl`           | Remote registry URL to proxy requests to                                                   | `https://registry-1.docker.io`            |
| `proxy.username`            | Remote registry login username                                                             | `nil`           |
| `proxy.password`            | Remote registry login password                                                             | `nil`           |
| `proxy.secretRef`           | The ref for an external secret containing the proxyUsername and proxyPassword keys         | `""`            |
| `namespace`                 | specify a namespace to install the chart to - defaults to `.Release.Namespace`             | `{{ .Release.Namespace }}` |
| `nodeSelector`              | node labels for pod assignment                                                             | `{}`            |
| `affinity`                  | affinity settings                                                                          | `{}`            |
| `topologySpreadConstraints` | topology spread constraints for the pod                                                    | `{}`            |
| `tolerations`               | pod tolerations                                                                            | `[]`            |
| `ingress.enabled`           | If true, Ingress will be created                                                           | `false`         |
| `ingress.annotations`       | Ingress annotations                                                                        | `{}`            |
| `ingress.labels`            | Ingress labels                                                                             | `{}`            |
| `ingress.path`              | Ingress service path                                                                       | `/`             |
| `ingress.hosts`             | Ingress hostnames                                                                          | `[]`            |
| `ingress.tls`               | Ingress TLS configuration (YAML)                                                           | `[]`            |
| `ingress.className`         | Ingress controller class name                                                              | `nginx`         |
| `httproute.enabled`         | If true, a Gateway API HTTPRoute will be created                                           | `false`         |
| `httproute.apiVersion`      | HTTPRoute apiVersion (defaults to `gateway.networking.k8s.io/v1` when empty)               | `""`            |
| `httproute.annotations`     | HTTPRoute annotations                                                                      | `{}`            |
| `httproute.labels`          | HTTPRoute labels                                                                           | `{}`            |
| `httproute.parentRefs`      | Gateway(s) this HTTPRoute is attached to                                                   | `[]`            |
| `httproute.hostnames`       | Hostnames matched against the HTTP Host header (templated)                                 | `[]`            |
| `httproute.matches`         | Request match conditions                                                                   | `PathPrefix /`  |
| `httproute.filters`         | Filters applied to requests matching the rule                                              | `[]`            |
| `httproute.additionalRules` | Additional templated HTTPRoute rules prepended to the default rule                         | `[]`            |
| `metrics.enabled`           | Enable metrics on Service                                                                  | `false`         |
| `metrics.port`              | TCP port on which the service metrics is exposed                                           | `5001`          |
| `metrics.serviceMonitor.annotations` | Prometheus Operator ServiceMonitor annotations                                    | `{}`            |
| `metrics.serviceMonitor.enabled` | If true, Prometheus Operator ServiceMonitor will be created                           | `false`         |
| `metrics.serviceMonitor.namespace` | Namespace to install the ServiceMonitor in (defaults to the release namespace)      | `""`            |
| `metrics.serviceMonitor.labels` | Prometheus Operator ServiceMonitor labels                                              | `{}`            |
| `metrics.podMonitor.enabled` | If true, a Prometheus Operator PodMonitor will be created (alternative to ServiceMonitor) | `false`         |
| `metrics.podMonitor.labels` | Prometheus Operator PodMonitor labels                                                      | `{}`            |
| `metrics.prometheusRule.annotations` | Prometheus Operator PrometheusRule annotations                                    | `{}`            |
| `metrics.prometheusRule.enable` | If true, Prometheus Operator prometheusRule will be created                            | `false`         |
| `metrics.prometheusRule.labels` | Prometheus Operator prometheusRule labels                                              | `{}`            |
| `metrics.prometheusRule.rules` | PrometheusRule defining alerting rules for a Prometheus instance                        | `{}`            |
| `extraVolumeMounts`         | Additional volumeMounts to the registry container                                          | `[]`            |
| `extraVolumes`              | Additional volumes to the pod                                                              | `[]`            |
| `extraEnvVars`              | Additional environment variables to the pod                                                | `[]`            |
| `livenessProbe`             | Override the default livenessProbe (whole probe spec)                                      | `nil`           |
| `readinessProbe`            | Override the default readinessProbe (whole probe spec)                                     | `nil`           |
| `initContainers`            | Init containers to be created in the pod                                                   | `[]`            |
| `extraContainers`           | Extra (sidecar) containers to add to the Deployment/StatefulSet                            | `[]`            |
| `garbageCollect.enabled`    | If true, will deploy garbage-collector cronjob                                             | `false`         |
| `garbageCollect.deleteUntagged` | If true, garbage-collector will delete manifests that are not currently referenced via tag | `true`      |
| `garbageCollect.schedule`   | CronTab schedule, please use standard crontab format                                       | `0 1 * * *`     |
| `garbageCollect.restartPolicy` | Restart policy for the garbage-collect CronJob pod                                      | `OnFailure`     |
| `garbageCollect.affinity`   | Affinity for the garbage-collect CronJob pod (falls back to top-level `affinity`)          | `{}`            |
| `garbageCollect.extraEnvVars` | Additional environment variables for the garbage-collect CronJob                         | `[]`            |
| `garbageCollect.podAnnotations` | CronJob pod Annotations. If left empty and chart `podAnnotations` are set, will use those. If both are set, these take precedence for the `garbageCollect` pods. | `{}` |
| `garbageCollect.podLabels`  | CronJob pod Annotations. If left empty and chart `podLabels` are set, will use those. If both are set, these take precedence for the `garbageCollect` pods. | `{}` |
| `garbageCollect.resources`  | garbage-collector requested resources                                                      | `{}`            |

Specify each parameter using the `--set key=value[,key=value]` argument to
`helm install`.

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

## Changelog

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
