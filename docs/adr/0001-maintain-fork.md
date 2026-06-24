# 1. Maintain a fork of twuni/docker-registry.helm

Date: 2026-06-24

## Status

Accepted

## Context

The widely-used [`twuni/docker-registry.helm`](https://github.com/twuni/docker-registry.helm)
chart is effectively unmaintained: dozens of useful pull requests and bug reports
sit open with no releases. Our organization depends on the chart and needs those
fixes plus a reliable release channel.

## Decision

Maintain [`risadams/docker-registry.helm`](https://github.com/risadams/docker-registry.helm)
as a fork. Incorporate the actionable upstream PRs/issues, add automated tests and
documentation, and publish releases ourselves from two channels:

- a Helm repository on GitHub Pages (`https://risadams.github.io/docker-registry.helm`,
  served from the `gh-pages` branch by `chart-releaser`), and
- an OCI artifact at `oci://ghcr.io/risadams/docker-registry`.

Releases are cut manually via the `Release Charts` workflow, which uses the
built-in `GITHUB_TOKEN` (no PAT) for same-repo publishing.

## Consequences

- We own maintenance, testing, and release cadence.
- Selector labels and defaults are kept backward compatible so existing upstream
  installs can `helm upgrade` onto this fork without disruption.
- Divergence from upstream grows over time; each incorporated change is recorded
  in the changelog and, where it reflects a design choice, in these ADRs.
