<p align="center">
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44" width="72" height="72" fill="none">
    <polygon points="24,7 35,13.5 35,28.5 24,35 13,28.5 13,13.5" fill="#1a5b6e" opacity=".55"/>
    <polygon points="22,5 33,11.5 33,26.5 22,33 11,26.5 11,11.5" fill="#CB0162"/>
    <text x="22" y="23.5" text-anchor="middle" font-family="JetBrains Mono,monospace" font-size="10" font-weight="600" fill="#faf6ef" letter-spacing="-0.5">DR</text>
  </svg>
</p>

# Docker Registry Helm Chart

A Helm chart for deploying a private [Docker Registry](https://distribution.github.io/distribution/)
(Distribution) on Kubernetes.

> **Fork notice.** This is [`risadams/docker-registry.helm`](https://github.com/risadams/docker-registry.helm),
> a maintained fork of the now-unmaintained [`twuni/docker-registry.helm`](https://github.com/twuni/docker-registry.helm).
> It incorporates the actionable community pull requests and issues that were
> left open upstream. For versions prior to 4.0, see the
> [upstream repository](https://github.com/twuni/docker-registry.helm).

[![Docs site](https://img.shields.io/badge/docs-risadams.github.io%2Fdocker--registry.helm-CB0162?style=flat-square)](https://risadams.github.io/docker-registry.helm/)
![Version: 4.0.1](https://img.shields.io/badge/Version-4.0.1-informational?style=flat-square)
![AppVersion: 3.1.1](https://img.shields.io/badge/AppVersion-3.1.1-informational?style=flat-square)

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2+ — both Helm 3.x and 4.x are supported (CI tests the latest of each)
- PersistentVolume support (if persistence is required)

## Installing

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

## Quick start

With the default `ClusterIP` service, port-forward and push:

```console
kubectl port-forward svc/my-registry-docker-registry 5000:5000 &
docker tag my-image:latest localhost:5000/my-image:latest
docker push localhost:5000/my-image:latest
docker pull localhost:5000/my-image:latest
```

To expose the registry outside the cluster, set `httproute.parentRefs` to
attach it to your Gateway (Gateway API is the default networking mode):

```yaml
httproute:
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
```

## Documentation

Full documentation is available at **https://risadams.github.io/docker-registry.helm/**

| Topic | |
|-------|-|
| [Configuration reference](docs/configuration.md) | All values, grouped by concern, with detailed descriptions |
| [Usage examples](docs/usage.md) | Auth, TLS, storage backends, networking, HA, and more |
| [Design decisions](docs/adr/) | Architecture Decision Records explaining the chart's defaults |
| [Changelog](CHANGELOG.md) | Release history (4.x+) |

## Testing

```console
helm test my-registry
```

The full multi-layer test suite (static analysis, helm-unittest, cluster
integration) lives under [`tests/`](tests/) — see
[`tests/README.md`](tests/README.md).
