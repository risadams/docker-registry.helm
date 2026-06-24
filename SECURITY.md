# Security Policy

## Scope

This policy covers the **`docker-registry` Helm chart** maintained in this
repository ([`risadams/docker-registry.helm`](https://github.com/risadams/docker-registry.helm))
— the chart templates, default values, schema, and packaging.

It does **not** cover the Docker Registry / Distribution **application** that the
chart deploys (the `registry` container image). Vulnerabilities in the registry
itself should be reported to the upstream project:

- **Application source:** [distribution/distribution](https://github.com/distribution/distribution)
- **Application security:** <https://github.com/distribution/distribution/security/policy>

If you are unsure whether an issue is in the chart or the application: if it can
only be fixed by changing a template, a default value, the schema, or how the
chart wires things together, it is a chart issue — report it here. If it
reproduces by running the `registry` image directly (regardless of this chart),
it belongs upstream.

## Supported Versions

Security fixes are provided only for the current `4.x` line of this fork. Earlier
versions were published under the original, now-unmaintained
[`twuni/docker-registry.helm`](https://github.com/twuni/docker-registry.helm)
project and are **not** maintained here.

| Chart version | Supported | Where |
|---------------|-----------|-------|
| `4.x`         | ✅ Yes     | This repository |
| `< 4.0.0`     | ❌ No      | Upstream [`twuni/docker-registry.helm`](https://github.com/twuni/docker-registry.helm) — unmaintained; please upgrade to `4.x` |

If you are running a chart version below `4.0.0`, the supported remediation is to
upgrade to the latest `4.x` release. Selector labels are unchanged from upstream
`3.0.0`, so `helm upgrade` onto this fork is non-disruptive — see the
[README](README.md#installing-the-chart).

Keeping the deployed registry image current is also part of staying secure: set
`image.tag` to a supported [`registry`](https://hub.docker.com/_/registry) release
(the chart's default `appVersion` tracks a recent stable image).

## Reporting a Vulnerability

Please **do not** open a public issue for security vulnerabilities.

Report chart vulnerabilities privately via GitHub's
[private vulnerability reporting](https://github.com/risadams/docker-registry.helm/security/advisories/new)
("Report a vulnerability" under the repository's **Security** tab). If that is
unavailable, contact the maintainer through their
[GitHub profile](https://github.com/risadams).

Please include:

- the chart version (and `appVersion` / `image.tag` in use),
- the values that trigger the issue (redact any secrets),
- the rendered manifest or behavior demonstrating the problem, and
- the impact and any suggested remediation.

### What to expect

- **Acknowledgement:** within about 5 business days.
- **Assessment:** we triage, confirm, and determine severity and affected versions.
- **Fix & disclosure:** confirmed issues are fixed in a new `4.x` release and
  disclosed via a GitHub Security Advisory, crediting the reporter unless they
  prefer to remain anonymous.

This is a community-maintained, best-effort project; there is no formal SLA, but
security reports are prioritized.
