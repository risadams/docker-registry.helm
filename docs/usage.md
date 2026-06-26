---
title: Usage Guide
sidebar_position: 3
---

# Usage Guide

Practical examples for common deployment scenarios. For the full list of
configuration values, see [configuration.md](configuration.md).

## Pushing and pulling images

Port-forward (or expose via networking — see below) and use the Docker CLI.
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

---

## Enabling htpasswd authentication

Generate an htpasswd entry and pass it via `secrets.htpasswd`. The `-B` flag
(bcrypt) is required — the registry rejects other hash formats:

```console
docker run --rm --entrypoint htpasswd httpd:2 -Bbn user 'password' > ./htpasswd
helm install my-registry docker-registry/docker-registry \
  --set-file secrets.htpasswd=./htpasswd
```

---

## Exposing via the Gateway API (recommended)

The chart defaults to `networking.type: gateway`. Set `httproute.parentRefs` to
point at your Gateway and the HTTPRoute is created automatically. Requires the
[Gateway API CRDs](https://gateway-api.sigs.k8s.io/) in the cluster.

```yaml
# values.yaml
networking:
  type: gateway       # already the default — explicit here for clarity
httproute:
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
      sectionName: https
  hostnames:
    - registry.example.com
```

No HTTPRoute is created until `parentRefs` is populated, so a plain
`helm install` is safe on clusters without Gateway API CRDs.

---

## Exposing via a classic Ingress

If your cluster does not have Gateway API CRDs, use `networking.type: ingress`:

```yaml
networking:
  type: ingress
ingress:
  className: nginx
  hosts:
    - registry.example.com
  tls:
    - secretName: registry-tls
      hosts:
        - registry.example.com
```

---

## Using an existing Secret

To manage registry credentials outside the chart (e.g. with external-secrets or
sealed-secrets), set `existingSecret`. The chart skips creating its own Secret
and references yours instead. The Secret must contain the keys required by your
configuration (`haSharedSecret`, `htpasswd`, the relevant `azure*`/`s3*`/
`swift*` storage keys, and `proxyUsername`/`proxyPassword` when proxying):

```console
helm install my-registry docker-registry/docker-registry \
  --set existingSecret=my-registry-credentials
```

---

## StatefulSet mode

Set `useStatefulSet: true` to deploy a StatefulSet with `volumeClaimTemplates`
instead of a Deployment + standalone PVC. Useful when each replica needs its own
volume:

```console
helm install my-registry docker-registry/docker-registry \
  --set useStatefulSet=true \
  --set persistence.enabled=true \
  --set persistence.storageClass=gp2
```

---

## Arbitrary registry configuration via `configData`

`configData` is rendered verbatim into the registry's `config.yml`, so any
[Distribution config](https://distribution.github.io/distribution/about/configuration/)
key can be set without a dedicated value. For example, to disable storage
redirects (useful when S3 is not directly reachable by clients):

```yaml
configData:
  storage:
    redirect:
      disable: true
```

The same approach covers options like `storage.maintenance.uploadpurging`,
`storage.delete.enabled`, and custom `http.headers`.

---

## S3 with an IAM instance profile / IRSA

When the node or pod identity already grants S3 access, omit `secrets.s3`
entirely — the chart emits no static-credential env vars and the registry falls
back to the AWS credential chain:

```yaml
storage: s3
s3:
  region: us-east-1
  bucket: my-registry-bucket
# no secrets.s3 block -> uses the instance profile / IRSA role
```

---

## Serving HTTPS (TLS)

Two ways to terminate TLS at the registry:

**Existing Secret** — reference a `kubernetes.io/tls` Secret you manage
(cert-manager, etc.):

```yaml
tlsSecretName: registry-tls
```

**Inline cert/key** — let the chart create the Secret from PEM material
(`tlsSecretName` takes precedence if both are set):

```yaml
tls:
  crt: |
    -----BEGIN CERTIFICATE-----
    ...
  key: |
    -----BEGIN PRIVATE KEY-----
    ...
```

Either way the registry mounts the cert at `/etc/ssl/docker`, serves HTTPS, and
the probes switch to the HTTPS scheme.

---

## Redis blob descriptor cache

For multi-replica HA, back the blob descriptor cache with Redis. Put the
connection settings in `configData` (rendered into `config.yml`) and the
password under `redis` so it stays out of the ConfigMap (injected as
`REGISTRY_REDIS_PASSWORD`):

```yaml
configData:
  storage:
    cache:
      blobdescriptor: redis
  redis:
    addr: redis-master:6379
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
redis:
  password: my-redis-password
  # or reference an external Secret with a redisPassword key:
  # secretRef: my-redis-secret
```

---

## Token authentication / RBAC

Delegate authorization to an external token server by passing the registry's
[`auth.token`](https://distribution.github.io/distribution/about/configuration/#token)
config through `configData`, and mount the issuer's root cert bundle with
`extraVolumes`/`extraVolumeMounts`:

```yaml
configData:
  auth:
    token:
      realm: "https://auth.example.com/token"
      service: "container_registry"
      issuer: "auth-server"
      rootcertbundle: "/etc/docker/registry/auth.crt"
extraVolumes:
  - name: auth-cert
    secret:
      secretName: registry-auth-cert
extraVolumeMounts:
  - name: auth-cert
    mountPath: /etc/docker/registry/auth.crt
    subPath: auth.crt
    readOnly: true
```

---

## Trusting a private CA

To make the registry (e.g. as a proxy/mirror) trust an upstream served by a
private CA, mount the CA bundle into the system trust store via `extraVolumes`/
`extraVolumeMounts`:

```yaml
extraVolumes:
  - name: private-ca
    configMap:
      name: my-private-ca   # contains ca.crt
extraVolumeMounts:
  - name: private-ca
    mountPath: /etc/ssl/certs/my-private-ca.crt
    subPath: ca.crt
    readOnly: true
```

---

## Running as a pull-through cache / mirror

Configure the registry to proxy and cache another registry (e.g. Docker Hub):

```yaml
proxy:
  enabled: true
  remoteurl: https://registry-1.docker.io
  username: my-dockerhub-user
  password: my-dockerhub-token
```

See the [Distribution mirror documentation](https://docs.docker.com/registry/recipes/mirror/)
for client-side configuration.
