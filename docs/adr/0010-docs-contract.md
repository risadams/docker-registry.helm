# 10. values.yaml as the documentation source; helm-docs + values.schema.json

Date: 2026-06-24

## Status

Accepted

## Context

The README parameter table was hand-maintained and had drifted badly from
`values.yaml` — whole option groups were undocumented while stale rows lingered.
There was also no machine validation of user input, so typos and wrong types
failed late with cryptic template errors.

## Decision

Make `values.yaml` the single source of truth for option documentation and add
machine validation:

- Annotate every value with helm-docs `# --` comments. The README parameters
  table is **generated** by [helm-docs](https://github.com/norwoodj/helm-docs)
  from `values.yaml` + `README.md.gotmpl`; the curated prose lives in the
  template. `README.md` is not edited by hand.
- Ship a `values.schema.json` (JSON Schema). Helm validates values against it on
  lint/template/install — enforcing types, enums (`storage`, `service.type`,
  `image.pullPolicy`, `garbageCollect.restartPolicy`), and rejecting unknown
  top-level keys via `additionalProperties: false`. Freeform passthrough maps
  (`configData`, `*.labels`, `*.annotations`, `resources`, security contexts)
  stay open.
- A docs test layer (`tests/docs.sh`) regenerates the README and fails CI if it
  differs from the committed copy (drift guard), and checks the schema accepts
  the scenarios and rejects bad input.

## Consequences

- Docs cannot silently drift from values; CI enforces it.
- Bad input fails fast with a clear schema error at install time.
- Adding an option means annotating it in `values.yaml` and (if typed/enumerated)
  updating the schema; the README regenerates. Contributors run `make docs`.
