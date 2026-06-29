# 14. Checksum-verify third-party binaries downloaded in CI

Date: 2026-06-29

## Status

Accepted

## Context

The `static` CI job fetches the `kubeconform` release tarball with `curl` and
extracts it straight into `/usr/local/bin`:

```yaml
curl -fsSL -o /tmp/kc.tgz ".../kubeconform-linux-amd64.tar.gz"
tar -C /usr/local/bin -xzf /tmp/kc.tgz kubeconform
```

The version was pinned (`KUBECONFORM_VERSION`), but the *content* was not verified.
A pinned tag still trusts whatever bytes the release URL serves: a hijacked release,
a replaced asset, or a compromised upstream account would put an attacker-controlled
binary on `PATH` and run it in CI. This is the same supply-chain class as ADR-0013
(actions pinned to SHAs) — pinning the reference is not enough if the fetched
artifact itself can change underneath the pin.

## Decision

Pin the **content hash** alongside the version and verify it before use. The
expected SHA256 (from the release `CHECKSUMS` file) lives next to the version in the
workflow `env`, with a comment requiring the two to move together:

```yaml
KUBECONFORM_VERSION: v0.8.0
KUBECONFORM_SHA256: "9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883"
```

```yaml
curl -fsSL -o /tmp/kc.tgz ".../kubeconform-linux-amd64.tar.gz"
echo "${KUBECONFORM_SHA256}  /tmp/kc.tgz" | sha256sum -c -
tar -C /usr/local/bin -xzf /tmp/kc.tgz kubeconform
```

`sha256sum -c` exits non-zero on mismatch, failing the job before the binary is
extracted or run. The check executes on every CI run, so it is self-testing — no
separate guard is needed; a tampered or wrong-version download simply breaks the
build.

The principle generalises: **any third-party binary fetched during a gating CI run
is verified against a pinned checksum before it is executed.**

## Consequences

- A tampered or substituted `kubeconform` download fails CI instead of running.
- Upgrading `kubeconform` now requires updating `KUBECONFORM_SHA256` as well as
  `KUBECONFORM_VERSION`; the env comment makes that explicit. This is deliberate
  friction — the cost of an upgrade is one checksum lookup.
- `tests/bootstrap.sh` also downloads `kubeconform` (and `helm`) without
  verification, but it is a best-effort, multi-platform *local* developer installer,
  not a gating path. Hardening it would need a per-OS/arch checksum map and is left
  as a separate follow-up rather than folded into this CI-scoped change.
- `helm` itself is installed in CI via the SHA-pinned `azure/setup-helm` action
  (ADR-0013), which verifies its own download, so it is already covered.
