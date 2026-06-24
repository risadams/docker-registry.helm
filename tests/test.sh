#!/usr/bin/env bash
# test.sh - portable entrypoint for the docker-registry.helm test suite.
# Works anywhere bash is available (Git Bash on Windows, Linux, macOS) without
# requiring `make`. The Makefile delegates here.
#
# Usage:
#   tests/test.sh bootstrap      install/verify tooling
#   tests/test.sh static         Layer 1: lint + render + kubeconform + invariants
#   tests/test.sh unit           Layer 2: helm-unittest + coverage
#   tests/test.sh integration    Layer 3: cluster install + functional probes
#   tests/test.sh offline        static + unit (no cluster needed)
#   tests/test.sh all            static + unit + integration
#   tests/test.sh integration default htpasswd   run a scenario subset
set -uo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"

cmd="${1:-all}"; shift || true

case "$cmd" in
  bootstrap)    bash "$DIR/bootstrap.sh" "$@" ;;
  static)       bash "$DIR/static.sh" "$@" ;;
  unit)         bash "$DIR/unit.sh" "$@" ;;
  integration)  bash "$DIR/integration.sh" "$@" ;;
  offline)
    bash "$DIR/static.sh" && bash "$DIR/unit.sh"
    ;;
  all)
    bash "$DIR/static.sh" \
      && bash "$DIR/unit.sh" \
      && bash "$DIR/integration.sh"
    ;;
  *)
    echo "unknown command: $cmd" >&2
    echo "usage: tests/test.sh {bootstrap|static|unit|integration|offline|all} [args]" >&2
    exit 2
    ;;
esac
