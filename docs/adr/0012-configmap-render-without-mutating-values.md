# 12. Render the ConfigMap without mutating .Values

Date: 2026-06-29

## Status

Accepted

## Context

The registry's blob descriptor cache and the garbage-collection CronJob cannot
run against the same store: `registry garbage-collect` walks the filesystem while
the running registry assumes its in-memory (or Redis) blob descriptor cache is
authoritative, and the two views diverge — GC can delete blobs the cache still
believes are present, corrupting the registry. To prevent operators from
configuring a combination that silently corrupts data, the chart forces the cache
off whenever `garbageCollect.enabled` is true, regardless of what
`configData.storage.cache.blobdescriptor` is set to.

`templates/configmap.yaml` implemented that override by mutating the shared values
tree at render time:

```yaml
{{- if .Values.garbageCollect.enabled -}}
{{- $_ := set .Values.configData.storage.cache "blobdescriptor" "disabled" -}}
{{- end -}}
...
  config.yml: |-
{{ toYaml .Values.configData | indent 4 }}
```

`set` mutates the map **in place**. In Helm, `.Values` is a single tree shared by
every template in the release — it is not re-derived per file. So this line does
not just change what the ConfigMap renders; it permanently rewrites
`.Values.configData.storage.cache.blobdescriptor` to `disabled` for the remainder
of the render. Every template processed *after* `configmap.yaml` sees the mutated
value.

This is a leaky seam, and it is dangerous for three reasons:

1. **Render-order dependence.** Helm renders templates in a deterministic but
   incidental order (lexical by path). The correctness of any other template that
   reads `configData.storage.cache` would silently depend on whether it happens to
   sort before or after `configmap.yaml`. Today no other template reads that
   subtree (`deployment.yaml`, `statefulset.yaml`, and `service.yaml` only read the
   unrelated `configData.http.debug.addr`), so the bug is latent — but it arms a
   trap for the next person who adds such a read.
2. **Non-locality.** A reader of, say, `deployment.yaml` has no way to know that
   `configData` may have already been rewritten by an unrelated file. Behaviour is
   no longer explained by the code in front of you; understanding requires holding
   the whole render order in your head.
3. **Idempotency by luck.** The `checksum/config` pod annotation re-includes the
   ConfigMap template (`include (print $.Template.BasePath "/configmap.yaml")`),
   so the mutation runs more than once per render. It happens to be idempotent
   (setting `disabled` twice is harmless), but the pattern does not guarantee that
   for future edits.

The override behaviour itself is correct and is covered by tests
(`tests/unit/configmap_test.yaml` asserts `inmemory` when GC is off and `disabled`
when GC is on, and the `garbage-collect` scenario depends on it). The problem is
purely *how* the override is applied, not *what* it produces.

## Decision

Compute the effective config on a local deep copy and render that, leaving
`.Values` untouched:

```yaml
{{- $configData := deepCopy .Values.configData -}}
{{- if .Values.garbageCollect.enabled -}}
{{- $_ := set $configData.storage.cache "blobdescriptor" "disabled" -}}
{{- end -}}
...
  config.yml: |-
{{ toYaml $configData | indent 4 }}
```

`deepCopy` (sprig) produces a fully independent tree, including nested maps, so the
`set` on `$configData.storage.cache` cannot leak back into the shared `.Values`.
The rendered output is byte-for-byte identical to before for both the GC-on and
GC-off paths; only the side effect on shared state is removed.

The `set`/`deepCopy` mechanism is kept (rather than, say, building the disabled
config with `dict`/`merge`) because it is the smallest change that preserves the
exact existing output, and because the GC-on path is a single, well-understood
override of one leaf key.

## Consequences

- The ConfigMap is now a pure function of its inputs: it reads `.Values` and never
  writes to it. Render order no longer affects any other template, and the latent
  trap for future readers of `configData.storage.cache` is removed.
- Behaviour is unchanged and the existing unit assertions and `garbage-collect`
  scenario continue to pass; the change needed no test edits.
- The decision assumes `configData.storage.cache` exists, the same assumption the
  original code made (the default `values.yaml` always provides it). A fully
  custom `configData` that drops `storage.cache` would error on the `set` — if
  that ever becomes a real use case, guard the `set` with a `dig` lookup. It was
  left out here to keep the fix behaviour-identical.
- This establishes a chart-wide rule worth following in future templates: **treat
  `.Values` as read-only; derive a local copy when a template needs a modified
  view.** In-place `set`/`unset` on `.Values` should be avoided.
