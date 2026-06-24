#!/usr/bin/env bash
# bootstrap.sh - install / verify the tooling the test suite needs.
#
# Safe to run repeatedly. Installs (when missing):
#   - helm           >= 3.11 (helm-unittest requires it)
#   - helm-unittest  plugin
#   - kubeconform    (static manifest schema validation)
#   - kind           (optional; only used for the CI-parity integration target)
#
# Honors these env vars:
#   HELM_MIN_MINOR   minimum acceptable helm 3.x minor (default 11)
#   BIN_DIR          where to drop downloaded binaries (default: first writable
#                    of /c/bin, /usr/local/bin, $HOME/bin)
#   SKIP_KIND        set to 1 to skip the optional kind check
set -euo pipefail

HELM_MIN_MINOR="${HELM_MIN_MINOR:-11}"
HELM_FALLBACK_VERSION="${HELM_FALLBACK_VERSION:-v3.21.2}"
KUBECONFORM_VERSION="${KUBECONFORM_VERSION:-v0.8.0}"

log()  { printf '\033[0;36m[bootstrap]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[bootstrap] WARN:\033[0m %s\n' "$*"; }
err()  { printf '\033[0;31m[bootstrap] ERROR:\033[0m %s\n' "$*" >&2; }

# Detect OS/arch for binary downloads.
case "$(uname -s)" in
  Linux*)  OS=linux ;;
  Darwin*) OS=darwin ;;
  MINGW*|MSYS*|CYGWIN*) OS=windows ;;
  *) OS=linux ;;
esac
case "$(uname -m)" in
  x86_64|amd64) ARCH=amd64 ;;
  arm64|aarch64) ARCH=arm64 ;;
  *) ARCH=amd64 ;;
esac
EXE=""; [ "$OS" = windows ] && EXE=".exe"

pick_bin_dir() {
  if [ -n "${BIN_DIR:-}" ]; then echo "$BIN_DIR"; return; fi
  for d in /c/bin /usr/local/bin "$HOME/bin"; do
    if [ -d "$d" ] && [ -w "$d" ]; then echo "$d"; return; fi
  done
  mkdir -p "$HOME/bin"; echo "$HOME/bin"
}
BIN_DIR="$(pick_bin_dir)"
log "binary install dir: $BIN_DIR (OS=$OS ARCH=$ARCH)"

have() { command -v "$1" >/dev/null 2>&1; }

# --- helm --------------------------------------------------------------------
helm_minor() { helm version --short 2>/dev/null | sed -E 's/^v?3\.([0-9]+)\..*/\1/; t; s/.*/0/'; }

install_helm() {
  log "installing helm $HELM_FALLBACK_VERSION -> $BIN_DIR"
  local tmp; tmp="$(mktemp -d)"
  local url="https://get.helm.sh/helm-${HELM_FALLBACK_VERSION}-${OS}-${ARCH}.zip"
  curl -fsSL -m 180 -o "$tmp/helm.zip" "$url"
  ( cd "$tmp" && unzip -oq helm.zip )
  cp "$tmp/${OS}-${ARCH}/helm${EXE}" "$BIN_DIR/helm${EXE}"
  rm -rf "$tmp"; hash -r 2>/dev/null || true
}

if ! have helm; then
  install_helm
elif [ "$(helm_minor)" -lt "$HELM_MIN_MINOR" ] 2>/dev/null; then
  warn "helm $(helm version --short) is older than 3.${HELM_MIN_MINOR}; upgrading"
  install_helm
fi
log "helm: $(helm version --short)"

# --- helm-unittest plugin ----------------------------------------------------
if helm plugin list 2>/dev/null | grep -q '^unittest'; then
  log "helm-unittest: $(helm plugin list | awk '/^unittest/{print $2}')"
else
  log "installing helm-unittest plugin"
  helm plugin install https://github.com/helm-unittest/helm-unittest >/dev/null 2>&1 \
    || helm plugin install https://github.com/helm-unittest/helm-unittest
  log "helm-unittest installed"
fi

# --- kubeconform -------------------------------------------------------------
if have kubeconform; then
  log "kubeconform: $(kubeconform -v)"
else
  log "installing kubeconform $KUBECONFORM_VERSION -> $BIN_DIR"
  tmp="$(mktemp -d)"
  if [ "$OS" = windows ]; then
    curl -fsSL -m 120 -o "$tmp/kc.zip" \
      "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-${OS}-${ARCH}.zip"
    ( cd "$tmp" && unzip -oq kc.zip )
  else
    curl -fsSL -m 120 -o "$tmp/kc.tgz" \
      "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-${OS}-${ARCH}.tar.gz"
    ( cd "$tmp" && tar xzf kc.tgz )
  fi
  cp "$tmp/kubeconform${EXE}" "$BIN_DIR/kubeconform${EXE}"
  rm -rf "$tmp"; hash -r 2>/dev/null || true
  log "kubeconform: $(kubeconform -v)"
fi

# --- kind (optional) ---------------------------------------------------------
if [ "${SKIP_KIND:-0}" != "1" ]; then
  if have kind; then
    log "kind: $(kind version 2>&1 | head -1)"
  else
    warn "kind not installed (optional). Local integration uses your current"
    warn "kube context (e.g. docker-desktop). Install kind only for CI parity:"
    warn "  https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
  fi
fi

# --- python + pyyaml (for static invariant checks) ---------------------------
if have python && python -c "import yaml" >/dev/null 2>&1; then
  log "python+pyyaml: OK"
else
  warn "python with pyyaml not found; static invariant checks will be skipped."
  warn "  pip install pyyaml"
fi

log "bootstrap complete."
