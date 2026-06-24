<!-- Thanks for contributing! Please fill out the sections below. -->

## Summary

<!-- What does this PR change and why? Link any related issue, e.g. "Fixes #123". -->

## Type of change

- [ ] Bug fix
- [ ] New feature / option
- [ ] Documentation
- [ ] CI / tooling
- [ ] Other:

## Checklist

- [ ] `values.yaml` annotated with `# --` doc comments for any new/changed option
- [ ] `values.schema.json` updated for new/changed options
- [ ] `README.md` regenerated (`make docs`) and committed — not hand-edited
- [ ] Tests added/updated (`bash tests/test.sh offline` passes)
- [ ] An ADR added under `docs/adr/` for any non-trivial design decision
- [ ] Backward compatible (immutable selector labels unchanged; defaults don't
      break existing installs) — or the breaking change is called out below
- [ ] Chart `version` in `Chart.yaml` **not** bumped (releases are cut separately)

## Breaking changes / upgrade notes

<!-- Describe anything users must do when upgrading, or "None". -->
