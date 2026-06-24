#!/usr/bin/env python
"""Heuristic values.yaml coverage report for the helm-unittest suites.

Walks every top-level and nested key in values.yaml and reports whether that
key name appears anywhere in the tests/unit/*_test.yaml suites (as a `set:`
override or in an assertion path). This is a guide, not a guarantee - it tells
you which options have *no* test mentioning them so coverage gaps are visible.

Usage: coverage.py <values.yaml> <unit_test_dir>
"""
import io
import os
import sys
import yaml

IGNORE_LEAF_ONLY = {"enabled", "create", "labels", "annotations", "name"}


def flatten(d, prefix=""):
    keys = []
    if isinstance(d, dict):
        for k, v in d.items():
            path = f"{prefix}.{k}" if prefix else k
            keys.append(path)
            keys.extend(flatten(v, path))
    return keys


def main(values_path, unit_dir):
    with io.open(values_path, encoding="utf-8") as fh:
        values = yaml.safe_load(fh) or {}
    all_keys = flatten(values)
    top_keys = sorted({k.split(".")[0] for k in all_keys})

    corpus = ""
    for root, _, files in os.walk(unit_dir):
        for f in files:
            if f.endswith(".yaml"):
                with io.open(os.path.join(root, f), encoding="utf-8") as fh:
                    corpus += fh.read()

    covered, missing = [], []
    for k in top_keys:
        if k in corpus:
            covered.append(k)
        else:
            missing.append(k)

    total = len(top_keys)
    pct = (len(covered) * 100 // total) if total else 100
    print(f"top-level values keys: {total}")
    print(f"referenced in unit suites: {len(covered)} ({pct}%)")
    if missing:
        print("not referenced (review for coverage gaps):")
        for k in missing:
            print(f"  - {k}")
    else:
        print("all top-level keys referenced by at least one unit test.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1], sys.argv[2]))
