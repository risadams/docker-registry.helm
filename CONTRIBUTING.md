# Contributing

Thanks for your interest in improving this Helm chart! This document explains how
to propose changes and what the project expects from a contribution.

## Scope

This repository maintains the **`docker-registry` Helm chart** only. Issues with
the registry **application** (the `registry` container image) belong upstream at
[distribution/distribution](https://github.com/distribution/distribution). See
[SECURITY.md](SECURITY.md) for the chart-vs-application distinction.

This is a community-maintained fork of the unmaintained
[`twuni/docker-registry.helm`](https://github.com/twuni/docker-registry.helm).
Significant design decisions are recorded as ADRs in [`docs/adr/`](docs/adr/) —
skim them before proposing structural changes.

## Ways to contribute

Code is only one way to help, and every item below moves the project forward.

### Code & docs

- **Report a bug** or **request a feature** via the
  [issue templates](https://github.com/risadams/docker-registry.helm/issues/new/choose).
- **Open a pull request** for fixes, features, docs, or tests.
- **Improve documentation** — see the docs contract below.

### No code required

- **Triage issues** — reproduce reported bugs, add missing detail, or confirm
  whether an issue still applies to the current release.
- **Answer questions** and help other users in
  [issues](https://github.com/risadams/docker-registry.helm/issues) and
  [discussions](https://github.com/risadams/docker-registry.helm/discussions).
- **Share your experience** — real-world `values.yaml` setups, upgrade notes, or
  gotchas make the docs better for everyone.
- **Review open pull requests** — a second pair of eyes on rendered output or a
  values change is always welcome.
- **Spread the word** — star the repo, write a blog post, or mention the chart
  where people are looking for a registry deployment.
- **Report a security concern** privately per [SECURITY.md](SECURITY.md).

Prefer to support the work financially? See [Support the project](#support-the-project).

## Development setup

You need a POSIX shell (Git Bash on Windows is fine), `helm` **>= 3.17**
(required by helm-unittest), `kubectl`, `docker`, and `python` with `pyyaml`. A
local Kubernetes cluster (docker-desktop or kind) is needed only for integration
tests.

Install the test/dev tooling (helm-unittest, kubeconform) with:

```bash
bash tests/bootstrap.sh
```

## Making a change

1. **Branch** off `main`.
2. **Edit templates and `values.yaml`.** `values.yaml` is the single source of
   truth for options and their documentation — annotate every value with a
   comment (see existing entries for the style).
3. **Update `values.schema.json`** if you add or change an option (type, enum,
   etc.). The schema is validated by `helm` on lint/template/install.
4. **Add tests** for the behavior you changed (see below). New options are
   expected to come with assertions.
5. **Record a decision.** For a non-trivial design choice, add an ADR under
   [`docs/adr/`](docs/adr/) following the existing format and link it in the
   index.
6. **Run the suite** and confirm CI is green before requesting review.

## Testing

The suite has four layers (full detail in [`tests/README.md`](tests/README.md)):

```bash
bash tests/test.sh offline   # docs + static + unit — no cluster, fast
bash tests/test.sh all       # + integration (needs a cluster)
make test-docs               # README drift + values.schema.json checks only
```

- **Docs** (`tests/docs.sh`) — checks the schema accepts every scenario and rejects bad input.
- **Static** (`tests/static.sh`) — `helm lint --strict`, render every scenario,
  kubeconform schema validation, structural invariants.
- **Unit** (`tests/unit/*_test.yaml`, helm-unittest) — per-template assertions;
  keep top-level values-key coverage at 100%.
- **Integration** (`tests/integration.sh`) — installs each scenario on a real
  cluster, runs `helm test`, probes functionality, tears down.

CI runs docs/lint/static/unit as required checks and the integration job on a
kind cluster (non-gating). All required checks must pass before merge.

## Pull request guidelines

- Keep PRs focused; one logical change per PR.
- Fill out the PR template checklist.
- Reference any related issue (`Fixes #123`).
- Preserve backward compatibility — selector labels are immutable and defaults
  should not break existing installs (see ADR
  [0002](docs/adr/0002-recommended-labels-immutable-selectors.md) and
  [0005](docs/adr/0005-service-create-defaults-true.md)). Call out any breaking
  change explicitly.
- Do **not** bump the chart `version` in `Chart.yaml` in feature/fix PRs unless
  asked — releases are cut separately by a maintainer.
- Ensure CI is green.

## Versioning & releases

The chart follows [SemVer](https://semver.org/). `version` is the chart version;
`appVersion` tracks the upstream `registry` image. Releases are published by a
maintainer via the **Release Charts** workflow, which pushes to the GitHub Pages
Helm repository and the GHCR OCI registry.

## Support the project

This chart is maintained on volunteer time. If it saves you or your team effort,
sponsorship helps fund ongoing maintenance, releases, and support:

- **[GitHub Sponsors](https://github.com/sponsors/risadams)** — one-time or
  recurring, any amount.

Sponsorship is entirely optional and never buys priority or influence over the
roadmap — every issue and PR is weighed on its merits. If money isn't an option,
the [no-code contributions](#no-code-required) above are just as valuable.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By
participating, you agree to uphold it.

## License

By contributing, you agree that your contributions are licensed under the
[Apache License 2.0](LICENSE).
