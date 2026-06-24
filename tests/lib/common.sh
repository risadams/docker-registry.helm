#!/usr/bin/env bash
# common.sh - shared helpers for the docker-registry.helm test scripts.
# Source this from test scripts: . "$(dirname "$0")/lib/common.sh"

# Resolve chart root (parent of the tests/ directory this lib lives in).
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="$(cd "$COMMON_DIR/../.." && pwd)"
export CHART_DIR

# ----- logging ---------------------------------------------------------------
_c_red=$'\033[0;31m'; _c_grn=$'\033[0;32m'; _c_ylw=$'\033[0;33m'
_c_cyn=$'\033[0;36m'; _c_rst=$'\033[0m'
log()   { printf '%s[test]%s %s\n' "$_c_cyn" "$_c_rst" "$*"; }
pass()  { printf '%s[ PASS ]%s %s\n' "$_c_grn" "$_c_rst" "$*"; }
fail()  { printf '%s[ FAIL ]%s %s\n' "$_c_red" "$_c_rst" "$*" >&2; }
warn()  { printf '%s[ WARN ]%s %s\n' "$_c_ylw" "$_c_rst" "$*"; }
section(){ printf '\n%s==== %s ====%s\n' "$_c_cyn" "$*" "$_c_rst"; }

# ----- pass/fail accounting --------------------------------------------------
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_NAMES=()
ok()    { TESTS_PASSED=$((TESTS_PASSED+1)); pass "$*"; }
ko()    { TESTS_FAILED=$((TESTS_FAILED+1)); FAILED_NAMES+=("$*"); fail "$*"; }

# assert_contains <description> <haystack> <needle>
assert_contains() {
  local desc="$1" hay="$2" needle="$3"
  if printf '%s' "$hay" | grep -qF -- "$needle"; then ok "$desc"; else
    ko "$desc (expected to contain: $needle)"; fi
}
# assert_not_contains <description> <haystack> <needle>
assert_not_contains() {
  local desc="$1" hay="$2" needle="$3"
  if printf '%s' "$hay" | grep -qF -- "$needle"; then
    ko "$desc (expected NOT to contain: $needle)"; else ok "$desc"; fi
}
# assert_eq <description> <expected> <actual>
assert_eq() {
  local desc="$1" exp="$2" act="$3"
  if [ "$exp" = "$act" ]; then ok "$desc"; else
    ko "$desc (expected='$exp' actual='$act')"; fi
}

summary() {
  printf '\n%s==== summary ====%s\n' "$_c_cyn" "$_c_rst"
  printf 'passed: %s%d%s  failed: %s%d%s\n' \
    "$_c_grn" "$TESTS_PASSED" "$_c_rst" \
    "$( [ "$TESTS_FAILED" -gt 0 ] && echo "$_c_red" || echo "$_c_grn")" \
    "$TESTS_FAILED" "$_c_rst"
  if [ "$TESTS_FAILED" -gt 0 ]; then
    printf 'failures:\n'; printf '  - %s\n' "${FAILED_NAMES[@]}"
    return 1
  fi
  return 0
}

# ----- generic retry ---------------------------------------------------------
# retry <attempts> <sleep_seconds> <cmd...>
retry() {
  local attempts="$1" delay="$2"; shift 2
  local i=1
  until "$@"; do
    if [ "$i" -ge "$attempts" ]; then return 1; fi
    sleep "$delay"; i=$((i+1))
  done
  return 0
}

# ----- kubernetes helpers ----------------------------------------------------
# svc_name <release> <namespace> -> the Service name actually created (or empty)
svc_name() {
  kubectl get svc -n "$2" \
    -l "app.kubernetes.io/instance=$1" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null
}

# wait_rollout <kind/name> <namespace> <timeout>
wait_rollout() {
  kubectl rollout status "$1" -n "$2" --timeout="${3:-120s}"
}

# port_forward <svc/name> <local:remote> <namespace> -> sets PF_PID, waits ready
PF_PID=""
port_forward() {
  local target="$1" ports="$2" ns="$3"
  kubectl port-forward "$target" "$ports" -n "$ns" >/dev/null 2>&1 &
  PF_PID=$!
  local lport="${ports%%:*}"
  # wait until the local port answers (max ~20s)
  retry 20 1 bash -c "exec 3<>/dev/tcp/127.0.0.1/${lport}" 2>/dev/null
}
stop_port_forward() {
  [ -n "$PF_PID" ] && kill "$PF_PID" >/dev/null 2>&1 || true
  PF_PID=""
}

# ----- namespace lifecycle with cleanup trap ---------------------------------
# Tracks namespaces created during a run so a trap can always tear them down.
CREATED_NAMESPACES=()
new_namespace() {
  local ns="$1"
  kubectl get ns "$ns" >/dev/null 2>&1 || kubectl create namespace "$ns" >/dev/null
  CREATED_NAMESPACES+=("$ns")
}
cleanup_namespaces() {
  stop_port_forward
  for ns in "${CREATED_NAMESPACES[@]:-}"; do
    [ -n "$ns" ] || continue
    # best-effort uninstall of any releases, then delete ns
    for rel in $(helm ls -n "$ns" -q 2>/dev/null); do
      helm uninstall "$rel" -n "$ns" >/dev/null 2>&1 || true
    done
    kubectl delete ns "$ns" --wait=false >/dev/null 2>&1 || true
  done
}
