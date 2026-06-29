---
title: Introduction
sidebar_position: 1
slug: /intro
---

# Docker Registry Helm Chart

A Helm chart for deploying a private [Docker Registry](https://distribution.github.io/distribution/)
(Distribution) on Kubernetes.

> **Fork notice.** This is [`risadams/docker-registry.helm`](https://github.com/risadams/docker-registry.helm),
> a maintained fork of the now-unmaintained [`twuni/docker-registry.helm`](https://github.com/twuni/docker-registry.helm).
> It incorporates the actionable community pull requests and issues left open upstream.
> For versions prior to 4.0 see the [upstream repository](https://github.com/twuni/docker-registry.helm).

## Installing

### Via the Helm repository

```bash
helm repo add docker-registry https://risadams.github.io/docker-registry.helm
helm repo update
helm install my-registry docker-registry/docker-registry
```

### Via the OCI registry (GHCR)

```bash
helm install my-registry oci://ghcr.io/risadams/docker-registry --version 4.0.1
```

## Quick start

With the default `ClusterIP` service, port-forward and push:

```bash
kubectl port-forward svc/my-registry-docker-registry 5000:5000 &
docker tag my-image:latest localhost:5000/my-image:latest
docker push localhost:5000/my-image:latest
docker pull localhost:5000/my-image:latest
```

To expose the registry outside the cluster, configure `httproute.parentRefs` to
attach to your Gateway — Gateway API is the default networking mode:

```yaml
httproute:
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
      sectionName: https
  hostnames:
    - registry.example.com
```

## Prerequisites

| Requirement | Version |
|-------------|---------|
| Kubernetes  | ≥ 1.19  |
| Helm        | ≥ 3.2 — both 3.x and 4.x supported |
| PersistentVolume support | Required if `persistence.enabled` is true |
| Gateway API CRDs | Required if `networking.type: gateway` |

## What's next?

- [Configuration reference](configuration) — every value, grouped by concern
- [Usage examples](usage) — auth, TLS, storage backends, HA, and more
- [Testing](testing) — running the four-layer test suite locally and in CI
- [Design decisions](adr/README) — Architecture Decision Records
- [Changelog](https://github.com/risadams/docker-registry.helm/blob/main/CHANGELOG.md)
