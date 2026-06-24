#!/usr/bin/env python
"""Structural invariant checks over rendered Helm manifests.

Validates properties that kubeconform's schema pass cannot express, e.g.:
  - every namespaced object has metadata.name
  - workloads carry the Kubernetes recommended labels
  - a workload's selector.matchLabels is a subset of its pod template labels
    (a mismatch silently breaks rollouts and is immutable post-install)

Usage: invariants.py <rendered.yaml> [<rendered.yaml> ...]
Exits non-zero if any invariant is violated.
"""
import io
import sys
import yaml

RECOMMENDED = {"app.kubernetes.io/name", "app.kubernetes.io/instance"}
WORKLOADS = {"Deployment", "StatefulSet"}

errors = []


def check_doc(doc, src):
    if not isinstance(doc, dict) or "kind" not in doc:
        return
    kind = doc.get("kind")
    md = doc.get("metadata", {}) or {}
    name = md.get("name")
    if not name:
        errors.append(f"{src}: {kind} missing metadata.name")
        return
    ref = f"{src}: {kind}/{name}"

    labels = md.get("labels", {}) or {}
    if kind in WORKLOADS | {"Service"}:
        missing = RECOMMENDED - set(labels)
        if missing:
            errors.append(f"{ref}: missing recommended labels {sorted(missing)}")

    if kind in WORKLOADS:
        spec = doc.get("spec", {}) or {}
        sel = (spec.get("selector", {}) or {}).get("matchLabels", {}) or {}
        pod_labels = (
            ((spec.get("template", {}) or {}).get("metadata", {}) or {}).get("labels", {})
            or {}
        )
        if not sel:
            errors.append(f"{ref}: empty selector.matchLabels")
        for k, v in sel.items():
            if pod_labels.get(k) != v:
                errors.append(
                    f"{ref}: selector {k}={v!r} not matched in pod template labels"
                )


def main(paths):
    doc_count = 0
    for p in paths:
        with io.open(p, encoding="utf-8") as fh:
            for doc in yaml.safe_load_all(fh):
                if doc:
                    doc_count += 1
                    check_doc(doc, p.replace("\\", "/").split("/")[-1])
    if errors:
        print(f"invariant violations ({len(errors)}):")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"invariants OK across {doc_count} manifests in {len(paths)} renders")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
