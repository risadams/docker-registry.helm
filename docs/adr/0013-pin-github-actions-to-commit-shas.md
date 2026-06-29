# 13. Pin GitHub Actions to commit SHAs

Date: 2026-06-29

## Status

Accepted

## Context

The workflows referenced third-party actions by mutable tags —
`actions/checkout@v7`, `azure/setup-helm@v5`, `actions/setup-python@v6`,
`actions/setup-node@v6`, `helm/kind-action@v1`,
`helm/chart-releaser-action@v1.7.0`, and
`JamesIves/github-pages-deploy-action@v4`. A git tag is not immutable: the action
owner (or anyone who compromises their account) can move `v7` to a new commit, and
every consumer silently runs the new code on its next workflow run.

That is a real supply-chain exposure for this repository, not a theoretical one.
The release workflow runs with `contents: write` and `packages: write` and handles
`GITHUB_TOKEN`; the docs workflow has `contents: write` and pushes `gh-pages`. A
repointed tag in any of those jobs runs attacker-controlled code with those
permissions.

The policy was already applied inconsistently: `pr_diff.yaml` pinned
`marocchino/sticky-pull-request-comment` to a full commit SHA while every other
action floated on a tag.

## Decision

Pin every third-party action to a full 40-character commit SHA, with a trailing
`# vX.Y.Z` comment recording the human-readable version:

```yaml
- uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7
```

The SHA is what GitHub actually resolves and run; the comment is what Dependabot
reads and rewrites when it proposes an update. Dependabot is already configured for
the `github-actions` ecosystem (`.github/dependabot.yaml`, daily), so pinned SHAs
still receive update PRs — the version bump just becomes an explicit, reviewable
change instead of a silent one.

A required CI job (`actions-pinned` in `ci.yaml`) enforces the rule: it fails if any
`uses:` reference is not pinned to a 40-char commit SHA. This is the regression
guard — without it, a future edit or a careless Dependabot config change could
reintroduce floating tags unnoticed.

## Consequences

- CI cannot be silently altered by a moved upstream tag; what ran yesterday runs
  today unless a SHA change lands through review.
- Action versions are visible (the `# vX.Y.Z` comment) and upgraded deliberately
  via Dependabot PRs rather than implicitly.
- The SHA strings are opaque; the version comment is mandatory so reviewers can see
  what version a pin corresponds to. The `actions-pinned` job keeps the policy from
  eroding over time.
- Pinning to a major-tag SHA (e.g. the commit `v7` currently points to) freezes the
  exact tested commit; Dependabot advances it. Precise patch tags in comments are
  preferred where known (e.g. `# v1.7.0`, `# v3.0.4`).
