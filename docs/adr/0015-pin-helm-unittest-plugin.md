# 15. Pin the helm-unittest plugin version in CI

Date: 2026-06-29

## Status

Accepted

## Context

The `unit` CI job installed the test plugin with no version:

```yaml
run: helm plugin install https://github.com/helm-unittest/helm-unittest
```

`helm plugin install` with no `--version` checks out the default branch HEAD at run
time. Every CI run therefore pulled whatever was latest on `main` and executed it —
the plugin is not a passive dependency, it runs Go code against the chart during the
build. That is unpinned (the test tool can change without any commit here),
non-reproducible (two runs of the same SHA can use different plugin code), and an
unvetted supply-chain path. Same class as ADR-0013 (actions) and ADR-0014 (CI
binaries): the thing CI executes must be pinned.

## Decision

Pin the plugin version in the workflow `env` and pass it to `--version`:

```yaml
HELM_UNITTEST_VERSION: v1.1.1
```

```yaml
run: helm plugin install https://github.com/helm-unittest/helm-unittest --version "${HELM_UNITTEST_VERSION}"
```

The version lives next to the other pinned tool versions (`HELM_VERSION`,
`KUBECONFORM_VERSION`) so all CI tooling is upgraded deliberately in one place.

`helm plugin install --version` resolves a git **tag**, not a commit SHA — helm does
not support SHA-pinning a plugin source, so a release tag is the finest pin
available. helm-unittest's release tags are stable (published releases, not moving
branches), so this is an acceptable residual compared with the previous "HEAD of
main" behaviour.

## Consequences

- CI uses a known, fixed plugin build; runs are reproducible and a surprise upstream
  change can no longer alter test behaviour mid-stream.
- Upgrading is an explicit one-line bump of `HELM_UNITTEST_VERSION`. Dependabot does
  not track helm plugins, so this env var is the single manual touch-point.
- The pin is a tag, not a SHA (helm limitation). Release tags moving is the residual
  trust; it is far smaller than trusting branch HEAD.
- `tests/bootstrap.sh` also installs the plugin unpinned, but it is a best-effort
  *local* developer installer, not a gating path — left as a noted follow-up, the
  same boundary drawn in ADR-0014.
- Verified locally: `--version v1.1.1` installs plugin 1.1.1, and the full suite
  (17 suites / 141 tests) passes against it.
