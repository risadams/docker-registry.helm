# 16. Remove the PR-diff smoketest workflow

Date: 2026-06-29

## Status

Accepted

## Context

`pr_diff.yaml` ran a `helm template` of the base branch and the PR branch across a
fixed option matrix, diffed the two renders, and posted the result as a sticky
pull-request comment. It was a reviewer convenience: see the rendered manifest impact
of a change inline on the PR.

Two problems made it not worth keeping:

- **It rendered Secret manifests into a public PR comment.** The option matrix set
  `secrets.*`, so the diff included the chart's `Secret` objects with their
  base64-encoded `data:`. The values were placeholders, but the workflow normalised
  publishing rendered Secrets, and it ran with `pull-requests: write` — a
  write-scoped, comment-posting workflow whose only job was to surface output that
  the static layer already validates. This was item 5 of the maintainability/security
  review.
- **It duplicated coverage that already gates.** The `static` job in `ci.yaml`
  renders the chart across the full scenario matrix and runs kubeconform plus the
  structural invariants. The PR-diff comment added no validation — only a
  human-readable diff — at the cost of a write-permissioned workflow and an external
  comment-posting action.

## Decision

Delete `pr_diff.yaml` entirely rather than hardening it (e.g. filtering `Secret`
kinds out of the diff). The reviewer-convenience value did not justify a
write-scoped workflow that publishes rendered manifests, given the static layer
already covers correctness. This also removes the chart's only use of the
`marocchino/sticky-pull-request-comment` action and the only workflow holding
`pull-requests: write`.

## Consequences

- No more rendered-Secret exposure in PR comments; the repository no longer has a
  workflow with `pull-requests: write`.
- Reviewers lose the inline rendered-diff convenience. The `static` job still proves
  every scenario renders and validates; a reviewer wanting a local diff can run
  `helm template` on the two refs by hand.
- If a PR-diff capability is ever wanted again, it must be reintroduced **without**
  rendering Secrets into any externally-posted output — this ADR records why the
  previous one was removed so the same risk is not re-added.
- If the `PR Diff for Helm chart` check was configured as a required status check in
  branch protection, it must be removed there too, or PRs will block on a check that
  no longer runs.
