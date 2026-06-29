#!/usr/bin/env bash
# bootstrap.sh - install / verify the tooling the test suite needs.
#
# Safe to run repeatedly. Installs (when missing):
#   - helm           latest 3.x (>= 3.17) or any 4.x (helm-unittest's platformHooks
#                    field needs helm >= 3.17)
#   - helm-unittest  plugin
#   - kubeconform    (static manifest schema validation)
#   - kind           (optional; only used for the CI-parity integration target)
#
# Honors these env vars:
#   HELM_MIN_MINOR   minimum acceptable helm 3.x minor (default 17). helm 4.x+ is
#                    always accepted regardless of this value.
#   BIN_DIR          where to drop downloaded binaries (default: first writable
#                    of /c/bin, /usr/local/bin, $HOME/bin)
#   SKIP_KIND        set to 1 to skip the optional kind check
set -euo pipefail

HELM_MIN_MINOR="${HELM_MIN_MINOR:-17}"
HELM_FALLBACK_VERSION="${HELM_FALLBACK_VERSION:-v3.21.2}"
KUBECONFORM_VERSION="${KUBECONFORM_VERSION:-v0.8.0}"
# helm-unittest plugin version, pinned to match CI (ci.yaml HELM_UNITTEST_VERSION).
HELM_UNITTEST_VERSION="${HELM_UNITTEST_VERSION:-v1.1.1}"
# kubeconform release these checksums correspond to. Verification is skipped (with a
# warning) when KUBECONFORM_VERSION is overridden to anything else. Update both.
KUBECONFORM_PINNED_VERSION="v0.8.0"

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

# verify_sha256 <file> <expected_hex>: hard-fail on mismatch or missing tooling.
verify_sha256() {
  local file="$1" expected="$2" actual=""
  if have sha256sum; then
    actual="$(sha256sum "$file" | awk '{print $1}')"
  elif have shasum; then
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  else
    err "no sha256sum/shasum available to verify $file"; exit 1
  fi
  if [ "$actual" != "$expected" ]; then
    err "checksum mismatch for $file"
    err "  expected: $expected"
    err "  actual:   $actual"
    exit 1
  fi
}

# SHA256 of the kubeconform-${OS}-${ARCH} asset for KUBECONFORM_PINNED_VERSION,
# from the release CHECKSUMS file. Update together with KUBECONFORM_PINNED_VERSION.
kubeconform_sha256() {
  case "${OS}-${ARCH}" in
    linux-amd64)   echo 9bc2bffbf71f261128533edaf912153948b7ff238f9a531ae6d34466ec287883 ;;
    linux-arm64)   echo 1f53fc8e81258197a35e8603054162a5af1de8c5af13746c71ab680d9534ed87 ;;
    darwin-amd64)  echo 71dbc87ac9f24099a62b93570e65aa06312ba6ac8aea63b7f86e9d999edf5a92 ;;
    darwin-arm64)  echo f84f4dfbebf4a6b0b230385fa065a39ea35e02608c2b50d025dcf64775a69d67 ;;
    windows-amd64) echo e3f56102bcf4f50b034a567e2482a1c5330799983ddd655952310211aef73d93 ;;
    windows-arm64) echo 4f3c9889f5f3a1e4aba84f9212f599ad3164d1fb32175fba3a53b505b0fffd0f ;;
    *)             echo "" ;;
  esac
}

# --- helm --------------------------------------------------------------------
# Accept the latest helm 3.x (minor >= HELM_MIN_MINOR) or any helm 4.x+.
# `helm version --short` prints e.g. "v3.21.2+g..." or "v4.2.2+g...".
helm_supported() {
  local v maj min
  v="$(helm version --short 2>/dev/null | sed -E 's/^[^0-9]*([0-9]+)\.([0-9]+).*/\1 \2/')"
  maj="${v%% *}"; min="${v##* }"
  case "$maj" in ''|*[!0-9]*) return 1 ;; esac
  case "$min" in ''|*[!0-9]*) return 1 ;; esac
  if [ "$maj" -ge 4 ]; then return 0; fi
  [ "$maj" -eq 3 ] && [ "$min" -ge "$HELM_MIN_MINOR" ]
}

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
elif ! helm_supported; then
  warn "helm $(helm version --short) is unsupported (need helm >= 3.${HELM_MIN_MINOR} or >= 4.x); installing $HELM_FALLBACK_VERSION"
  install_helm
fi
log "helm: $(helm version --short)"

# --- helm-unittest plugin ----------------------------------------------------
if helm plugin list 2>/dev/null | grep -q '^unittest'; then
  log "helm-unittest: $(helm plugin list | awk '/^unittest/{print $2}')"
else
  log "installing helm-unittest plugin $HELM_UNITTEST_VERSION"
  # Pin the version for reproducibility. helm 4 requires plugin provenance
  # verification or an explicit opt-out, and the plugin's git source has none, so
  # fall back to --verify=false (an unknown flag on helm 3, where the first attempt
  # already succeeds). The last attempt drops the redirect so errors are visible.
  uurl="https://github.com/helm-unittest/helm-unittest"
  helm plugin install "$uurl" --version "$HELM_UNITTEST_VERSION" >/dev/null 2>&1 \
    || helm plugin install "$uurl" --version "$HELM_UNITTEST_VERSION" --verify=false >/dev/null 2>&1 \
    || helm plugin install "$uurl" --version "$HELM_UNITTEST_VERSION"
  log "helm-unittest installed"
fi

# --- kubeconform -------------------------------------------------------------
if have kubeconform; then
  log "kubeconform: $(kubeconform -v)"
else
  log "installing kubeconform $KUBECONFORM_VERSION -> $BIN_DIR"
  tmp="$(mktemp -d)"
  if [ "$OS" = windows ]; then
    asset="kubeconform-${OS}-${ARCH}.zip"; out="$tmp/kc.zip"
  else
    asset="kubeconform-${OS}-${ARCH}.tar.gz"; out="$tmp/kc.tgz"
  fi
  curl -fsSL -m 120 -o "$out" \
    "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/${asset}"
  # Verify the download against the pinned checksum before extracting/running it.
  expected="$(kubeconform_sha256)"
  if [ "$KUBECONFORM_VERSION" = "$KUBECONFORM_PINNED_VERSION" ] && [ -n "$expected" ]; then
    verify_sha256 "$out" "$expected"
    log "kubeconform checksum verified"
  else
    warn "no pinned checksum for kubeconform $KUBECONFORM_VERSION ($OS-$ARCH); skipping verification"
  fi
  if [ "$OS" = windows ]; then ( cd "$tmp" && unzip -oq kc.zip ); else ( cd "$tmp" && tar xzf kc.tgz ); fi
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
