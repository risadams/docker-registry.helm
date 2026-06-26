#!/usr/bin/env bash
# integration.sh - Layer 3: real-cluster install + functional verification.
#
# For each scenario: create a fresh namespace, helm install with the scenario's
# values, wait for healthy rollout, run `helm test`, run scenario-specific
# functional probes, then uninstall and delete the namespace. A cleanup trap
# guarantees namespaces are removed even on failure.
#
# Requires a working kube context (docker-desktop locally, or kind in CI) and,
# for the htpasswd push/pull scenario, a docker daemon.
#
# Usage:
#   tests/integration.sh                 # run all scenarios
#   tests/integration.sh default htpasswd  # run a subset
#   SKIP_DOCKER=1 tests/integration.sh   # skip scenarios needing a docker daemon
#   NS_PREFIX=drtest TIMEOUT=180s        # tunables via env
set -uo pipefail
. "$(dirname "$0")/lib/common.sh"

NS_PREFIX="${NS_PREFIX:-drtest}"
TIMEOUT="${TIMEOUT:-180s}"
RELEASE="reg"
SCEN_DIR="$CHART_DIR/tests/scenarios"

trap cleanup_namespaces EXIT

# Resolve the cluster's default StorageClass once (used for sanity logging).
default_sc="$(kubectl get sc -o jsonpath='{range .items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")]}{.metadata.name}{end}' 2>/dev/null)"
log "kube context: $(kubectl config current-context 2>/dev/null) | default StorageClass: ${default_sc:-<none>}"

docker_ok=1
if [ "${SKIP_DOCKER:-0}" = "1" ] || ! docker version >/dev/null 2>&1; then
  docker_ok=0
  warn "docker daemon unavailable or skipped: push/pull depth will be skipped"
fi

# _nodeport_live <port> -> 0 if localhost:<port> answers with an HTTP 200 or 401,
# else 1.  Used to detect whether a NodePort is routable before attempting docker
# operations.  Docker Desktop (built-in k8s) maps NodePorts to localhost
# automatically; Kind requires extraPortMappings in the cluster config.
_nodeport_live() {
  local port="$1" code
  code="$(curl -so /dev/null -w '%{http_code}' --max-time 3 \
    "http://localhost:${port}/v2/" 2>/dev/null)"
  [ "$code" = "401" ] || [ "$code" = "200" ]
}

# install_release <namespace> <values-file-or-empty> [extra helm args...]
install_release() {
  local ns="$1" vf="$2"; shift 2
  local args=( install "$RELEASE" "$CHART_DIR" -n "$ns" --wait --timeout "$TIMEOUT" )
  [ -n "$vf" ] && args+=( -f "$vf" )
  args+=( "$@" )
  helm "${args[@]}"
}

# http_code <url> -> prints the HTTP status code for a single GET (empty on failure)
http_code() { curl -s -o /dev/null -w '%{http_code}' "$1" 2>/dev/null; }

# wait_http <url> <expected-regex> -> retry until the code matches (or timeout)
wait_http() {
  local url="$1" want="$2" i
  for i in $(seq 1 15); do
    [[ "$(http_code "$url")" =~ $want ]] && return 0
    sleep 1
  done
  return 1
}

# probe_v2 <namespace> -> curls /v2/ via port-forward, expects 200 or 401
probe_v2() {
  local ns="$1" sname lport=5599
  sname="$(svc_name "$RELEASE" "$ns")"
  [ -n "$sname" ] || { warn "no service in $ns to probe"; return 1; }
  port_forward "svc/$sname" "${lport}:5000" "$ns" || { warn "port-forward failed"; return 1; }
  local rc=1
  wait_http "http://localhost:${lport}/v2/" '^(200|401)$' && rc=0
  stop_port_forward
  return $rc
}

# ===========================================================================
# Scenarios. Each is a function scenario_<name>.
# ===========================================================================

scenario_default() {
  local ns="$1"
  install_release "$ns" "$SCEN_DIR/default.yaml" >/dev/null
  assert_eq "default: 1 pod ready" "true" "$(pod_ready "$RELEASE" "$ns")"
  if helm test "$RELEASE" -n "$ns" >/dev/null 2>&1; then ok "default: helm test"; else ko "default: helm test"; fi
  if probe_v2 "$ns"; then ok "default: /v2/ API reachable"; else ko "default: /v2/ API reachable"; fi
}

scenario_service_create_false() {
  local ns="$1"
  install_release "$ns" "$SCEN_DIR/service-create-false.yaml" >/dev/null
  local svc; svc="$(kubectl get svc -n "$ns" -l app.kubernetes.io/instance=$RELEASE -o name 2>/dev/null)"
  assert_eq "service-create-false: no Service created" "" "$svc"
}

scenario_persistence() {
  local ns="$1"
  install_release "$ns" "$SCEN_DIR/persistence.yaml" >/dev/null
  local phase; phase="$(kubectl get pvc -n "$ns" -o jsonpath='{.items[0].status.phase}' 2>/dev/null)"
  assert_eq "persistence: PVC bound" "Bound" "$phase"
  if probe_v2 "$ns"; then ok "persistence: /v2/ reachable"; else ko "persistence: /v2/ reachable"; fi
}

scenario_statefulset() {
  local ns="$1"
  install_release "$ns" "$SCEN_DIR/statefulset.yaml" >/dev/null
  local kind; kind="$(kubectl get statefulset -n "$ns" -o name 2>/dev/null)"
  assert_contains "statefulset: StatefulSet created" "$kind" "statefulset"
  # volumeClaimTemplate PVC is named data-<sts>-0
  local pvc; pvc="$(kubectl get pvc -n "$ns" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)"
  assert_contains "statefulset: volumeClaimTemplate PVC present" "$pvc" "data-"
  if probe_v2 "$ns"; then ok "statefulset: /v2/ reachable"; else ko "statefulset: /v2/ reachable"; fi
}

scenario_garbage_collect() {
  local ns="$1"
  install_release "$ns" "$SCEN_DIR/garbage-collect.yaml" \
    --set service.type=NodePort --set service.nodePort=30578 >/dev/null
  local cj; cj="$(kubectl get cronjob -n "$ns" -o name 2>/dev/null)"
  assert_contains "garbage-collect: CronJob created" "$cj" "cronjob"
  # blob cache must be disabled in the rendered ConfigMap (cache + GC corrupts data)
  local cfg; cfg="$(kubectl get cm -n "$ns" -l app.kubernetes.io/instance=$RELEASE -o jsonpath='{.items[0].data.config\.yml}' 2>/dev/null)"
  assert_contains "garbage-collect: blobdescriptor disabled" "$cfg" "blobdescriptor: disabled"

  # The registry's garbage-collect command errors on a completely empty store
  # ("repositories path not found"), so push one image first when docker is
  # available. Without docker we can only assert the CronJob object exists.
  if [ "$docker_ok" -ne 1 ]; then
    warn "garbage-collect: docker unavailable; manual GC run skipped (CronJob object verified)"
    return 0
  fi
  local reg="localhost:30578"
  if ! _nodeport_live 30578; then
    warn "garbage-collect: NodePort ${reg} not reachable — seed push skipped (CronJob object verified)"
    warn "garbage-collect: For Kind: recreate cluster with extraPortMappings for port 30578 (see tests/README.md)"
    return 0
  fi
  docker pull registry:3.1.1 >/dev/null 2>&1 || true
  docker tag registry:3.1.1 "$reg/gctest:ci" >/dev/null 2>&1
  if ! docker push "$reg/gctest:ci" >/dev/null 2>&1; then
    warn "garbage-collect: seed push failed; skipping manual GC run"
    docker rmi "$reg/gctest:ci" >/dev/null 2>&1 || true
    return 0
  fi
  docker rmi "$reg/gctest:ci" >/dev/null 2>&1 || true
  # trigger a one-off job from the cronjob and wait for completion
  local cjname; cjname="$(kubectl get cronjob -n "$ns" -o jsonpath='{.items[0].metadata.name}')"
  kubectl create job -n "$ns" gc-manual --from="cronjob/$cjname" >/dev/null 2>&1
  if kubectl wait -n "$ns" --for=condition=complete job/gc-manual --timeout=120s >/dev/null 2>&1; then
    ok "garbage-collect: manual GC job completed"
  else
    ko "garbage-collect: manual GC job completed"
    kubectl logs -n "$ns" -l job-name=gc-manual --tail=15 2>/dev/null | sed 's/^/    gc> /'
  fi
}

# Best-effort install of the prometheus-operator CRDs the chart can emit, so the
# ServiceMonitor/PodMonitor objects can actually be applied. Controlled by
# INSTALL_CRDS (default 1). Safe to call repeatedly.
PROM_OPERATOR_VERSION="${PROM_OPERATOR_VERSION:-v0.76.0}"
ensure_monitoring_crds() {
  [ "${INSTALL_CRDS:-1}" = "1" ] || return 1
  kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1 && return 0
  local base="https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/${PROM_OPERATOR_VERSION}/example/prometheus-operator-crd"
  kubectl apply --server-side \
    -f "${base}/monitoring.coreos.com_servicemonitors.yaml" \
    -f "${base}/monitoring.coreos.com_podmonitors.yaml" \
    -f "${base}/monitoring.coreos.com_prometheusrules.yaml" >/dev/null 2>&1 || return 1
  kubectl wait --for=condition=established --timeout=60s \
    crd/servicemonitors.monitoring.coreos.com \
    crd/podmonitors.monitoring.coreos.com >/dev/null 2>&1 || return 1
  return 0
}

scenario_metrics() {
  local ns="$1"
  local crds_ok=0
  if ensure_monitoring_crds; then crds_ok=1; else
    warn "metrics: prometheus-operator CRDs unavailable; installing without ServiceMonitor/PodMonitor"
  fi
  if [ "$crds_ok" -eq 1 ]; then
    install_release "$ns" "$SCEN_DIR/metrics.yaml" >/dev/null
  else
    # CRDs absent (e.g. offline): install metrics but disable the operator objects
    install_release "$ns" "$SCEN_DIR/metrics.yaml" \
      --set metrics.serviceMonitor.enabled=false \
      --set metrics.podMonitor.enabled=false >/dev/null
  fi
  # metrics endpoint on the debug port (does not require CRDs)
  local sname; sname="$(svc_name "$RELEASE" "$ns")"
  port_forward "svc/$sname" "5601:5001" "$ns" || true
  local body=""
  for i in $(seq 1 12); do
    body="$(curl -s "http://localhost:5601/metrics" 2>/dev/null)"
    printf '%s' "$body" | grep -q '# HELP' && break
    sleep 1
  done
  stop_port_forward
  assert_contains "metrics: /metrics serves prometheus output" "$body" "# HELP"
  if [ "$crds_ok" -eq 1 ]; then
    local sm; sm="$(kubectl get servicemonitor -n "$ns" -o name 2>/dev/null)"
    assert_contains "metrics: ServiceMonitor created" "$sm" "servicemonitor"
    local pm; pm="$(kubectl get podmonitor -n "$ns" -o name 2>/dev/null)"
    assert_contains "metrics: PodMonitor created" "$pm" "podmonitor"
  else
    warn "metrics: ServiceMonitor/PodMonitor live-apply skipped (CRDs absent; rendered+validated in static layer)"
  fi
}

scenario_ingress() {
  local ns="$1"
  install_release "$ns" "$SCEN_DIR/ingress.yaml" >/dev/null
  local host; host="$(kubectl get ingress -n "$ns" -o jsonpath='{.items[0].spec.rules[0].host}' 2>/dev/null)"
  assert_eq "ingress: host set" "registry.test.local" "$host"
  local backend; backend="$(kubectl get ingress -n "$ns" -o jsonpath='{.items[0].spec.rules[0].http.paths[0].backend.service.name}' 2>/dev/null)"
  assert_eq "ingress: backend points at service" "registry" "$backend"
}

scenario_existing_secret() {
  local ns="$1"
  # pre-create the external secret the scenario references
  kubectl create secret generic drtest-existing-secret -n "$ns" \
    --from-literal=haSharedSecret=externalsharedsecret >/dev/null 2>&1
  install_release "$ns" "$SCEN_DIR/existing-secret.yaml" >/dev/null
  # chart must NOT create its own -secret
  local own; own="$(kubectl get secret -n "$ns" "${RELEASE}-docker-registry-secret" -o name 2>/dev/null || true)"
  assert_eq "existing-secret: chart Secret not created" "" "$own"
  assert_eq "existing-secret: pod ready" "true" "$(pod_ready "$RELEASE" "$ns")"
}

scenario_autoscaling() {
  local ns="$1"
  install_release "$ns" "$SCEN_DIR/autoscaling.yaml" >/dev/null
  local tgt; tgt="$(kubectl get hpa -n "$ns" -o jsonpath='{.items[0].spec.scaleTargetRef.name}' 2>/dev/null)"
  assert_eq "autoscaling: HPA targets the registry" "${RELEASE}-docker-registry" "$tgt"
}

scenario_sidecars() {
  local ns="$1"
  install_release "$ns" "$SCEN_DIR/sidecars.yaml" >/dev/null
  local n; n="$(kubectl get pods -n "$ns" -l "$(pod_selector "$RELEASE")" -o jsonpath='{.items[0].spec.containers[*].name}' 2>/dev/null | wc -w | tr -d ' ')"
  assert_eq "sidecars: pod has 2 containers" "2" "$n"
}

scenario_htpasswd() {
  local ns="$1"
  if [ "$docker_ok" -ne 1 ]; then
    warn "htpasswd: skipped (no docker daemon)"
    return 0
  fi
  # generate a real htpasswd (bcrypt) for testuser/testpass
  local hp; hp="$(docker run --rm --entrypoint htpasswd httpd:2 -Bbn testuser testpass 2>/dev/null)"
  install_release "$ns" "" \
    --set "secrets.haSharedSecret=ciSharedSecret" \
    --set-string "secrets.htpasswd=$hp" \
    --set "service.type=NodePort" \
    --set "service.nodePort=30577" >/dev/null
  # anonymous pull must be rejected (401)
  local sname; sname="$(svc_name "$RELEASE" "$ns")"
  port_forward "svc/$sname" "5602:5000" "$ns" || true
  wait_http "http://localhost:5602/v2/" '^401$' >/dev/null
  local anon; anon="$(http_code "http://localhost:5602/v2/")"
  assert_eq "htpasswd: anonymous access rejected" "401" "$anon"
  # Authenticated push/pull via the NodePort.  Docker Desktop (built-in k8s) maps
  # NodePorts to localhost automatically; Kind needs extraPortMappings (see
  # tests/README.md).  Skip gracefully when the port is not reachable so that a
  # missing extraPortMappings doesn't surface as a hard chart failure.
  local reg="localhost:30577"
  if ! _nodeport_live 30577; then
    warn "htpasswd: NodePort ${reg} not reachable — docker login/push/pull skipped"
    warn "htpasswd: For Kind: recreate cluster with extraPortMappings for port 30577 (see tests/README.md)"
    stop_port_forward
    return 0
  fi
  if echo "testpass" | docker login "$reg" -u testuser --password-stdin >/dev/null 2>&1; then
    ok "htpasswd: docker login"
    docker pull registry:3.1.1 >/dev/null 2>&1 || true
    docker tag registry:3.1.1 "$reg/probe:ci" >/dev/null 2>&1
    if docker push "$reg/probe:ci" >/dev/null 2>&1; then ok "htpasswd: docker push"; else ko "htpasswd: docker push"; fi
    docker rmi "$reg/probe:ci" >/dev/null 2>&1 || true
    if docker pull "$reg/probe:ci" >/dev/null 2>&1; then ok "htpasswd: docker pull"; else ko "htpasswd: docker pull"; fi
    docker logout "$reg" >/dev/null 2>&1 || true
  else
    ko "htpasswd: docker login"
  fi
  stop_port_forward
}

# upstream #187: haSharedSecret must stay stable across helm upgrades (a
# regenerating value causes ArgoCD OutOfSync churn and breaks HA request signing).
# This needs a live cluster because the fix relies on `lookup` reading the
# existing Secret, which is empty during `helm template`.
scenario_secret_stable() {
  local ns="$1"
  install_release "$ns" "$SCEN_DIR/default.yaml" >/dev/null
  local s1; s1="$(kubectl get secret -n "$ns" "${RELEASE}-docker-registry-secret" -o jsonpath='{.data.haSharedSecret}' 2>/dev/null)"
  assert_contains "secret-stable: haSharedSecret generated on install" "$s1" "="
  helm upgrade "$RELEASE" "$CHART_DIR" -n "$ns" -f "$SCEN_DIR/default.yaml" \
    --set podAnnotations.bump=1 --wait --timeout "$TIMEOUT" >/dev/null 2>&1
  local s2; s2="$(kubectl get secret -n "$ns" "${RELEASE}-docker-registry-secret" -o jsonpath='{.data.haSharedSecret}' 2>/dev/null)"
  assert_eq "secret-stable: haSharedSecret unchanged after upgrade" "$s1" "$s2"
}

# ===========================================================================
# Runner
# ===========================================================================
ALL_SCENARIOS=(default service_create_false persistence statefulset \
  garbage_collect metrics ingress existing_secret autoscaling sidecars \
  secret_stable htpasswd)

run_scenario() {
  local name="$1"
  local ns="${NS_PREFIX}-$(echo "$name" | tr '_' '-')"
  section "scenario: $name (ns: $ns)"
  new_namespace "$ns"
  if "scenario_${name}" "$ns"; then :; fi
  # tear down this release/ns promptly to free the cluster
  helm uninstall "$RELEASE" -n "$ns" >/dev/null 2>&1 || true
  kubectl delete ns "$ns" --wait=false >/dev/null 2>&1 || true
}

main() {
  local targets=()
  if [ "$#" -gt 0 ]; then targets=( "$@" ); else targets=( "${ALL_SCENARIOS[@]}" ); fi
  for s in "${targets[@]}"; do
    # normalize dashes to underscores for function names
    run_scenario "$(echo "$s" | tr '-' '_')"
  done
  summary
}

main "$@"
