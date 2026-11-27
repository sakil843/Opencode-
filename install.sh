#!/data/data/com.termux/files/usr/bin/bash
#
# OpenCode for Termux - installer
# Downloads the official OpenCode Linux ARM64/x64 release and runs it
# on Termux through the glibc loader (no proot, no chroot).
#
# Author: Sakil (https://github.com/sakil843)
#
# Usage:
#   bash install.sh                 # install latest
#   bash install.sh --version 1.19.6
#   bash install.sh --no-deps       # skip package installation
#
set -euo pipefail

REPO="${OPENCODE_REPO:-anomalyco/opencode}"
FALLBACK_VERSION="1.19.6"

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.local/share/opencode-termux}"
BIN_DIR="${OPENCODE_BIN_DIR:-$PREFIX/bin}"
BIN_PATH="$BIN_DIR/opencode"
REAL_BIN="$INSTALL_DIR/opencode"

C_RESET=$'\033[0m'
C_INFO=$'\033[1;36m'
C_OK=$'\033[1;32m'
C_WARN=$'\033[1;33m'
C_ERR=$'\033[1;31m'

info() { printf '%s::%s %s\n' "$C_INFO" "$C_RESET" "$*"; }
ok()   { printf '%s✓%s %s\n' "$C_OK" "$C_RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$C_WARN" "$C_RESET" "$*"; }
err()  { printf '%s✗%s %s\n' "$C_ERR" "$C_RESET" "$*" >&2; }
die()  { err "$*"; exit 1; }

usage() {
  cat <<'EOF'
OpenCode for Termux installer

Usage: bash install.sh [options]

Options:
  -v, --version <ver>   Install a specific version (e.g. 1.19.6 or v1.19.6)
      --no-deps         Do not install missing system packages
  -h, --help            Show this help

Environment:
  OPENCODE_VERSION      Same as --version
  OPENCODE_INSTALL_DIR  Where the real binary is stored
                        (default: ~/.local/share/opencode-termux)
  OPENCODE_BIN_DIR      Where the opencode launcher is created
                        (default: $PREFIX/bin)
  OPENCODE_REPO         GitHub repo to download from
                        (default: anomalyco/opencode)
  OPENCODE_ARCHIVE      Use a local .tar.gz instead of downloading
EOF
}

VERSION="${OPENCODE_VERSION:-}"
SKIP_DEPS=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -v|--version)
      [ $# -ge 2 ] || die "--version requires a value"
      VERSION="$2"; shift 2 ;;
    --no-deps) SKIP_DEPS=1; shift ;;
    *) die "Unknown option: $1 (try --help)" ;;
esac

if [ "$BIN_PATH" = "$REAL_BIN" ]; then
  die "OPENCODE_BIN_DIR and OPENCODE_INSTALL_DIR point to the same file."
fi

done

VERSION="${VERSION#v}"

if [ ! -d /data/data/com.termux/files/usr ]; then
  die "This installer is for Termux on Android only."
fi
if [ -z "${PREFIX:-}" ] || [ ! -d "$PREFIX" ]; then
  die "PREFIX is not set. Please run this inside Termux."
fi

case "$(uname -m)" in
  aarch64|arm64)
    ASSET="opencode-linux-arm64.tar.gz"
    LOADER="$PREFIX/glibc/lib/ld-linux-aarch64.so.1"
    ;;
  x86_64|amd64)
    ASSET="opencode-linux-x64.tar.gz"
    LOADER="$PREFIX/glibc/lib/ld-linux-x86-64.so.2"
    ;;
  *)
    die "Unsupported architecture: $(uname -m). Only aarch64/arm64 and x86_64 are supported."
    ;;
esac

install_deps() {
  local need=()
  local pkg_name

  command -v curl >/dev/null 2>&1 || need+=(curl)
  command -v tar  >/dev/null 2>&1 || need+=(tar)
  command -v find >/dev/null 2>&1 || need+=(findutils)

  if ! dpkg -s glibc >/dev/null 2>&1; then
    info "Installing glibc (required to run OpenCode on Termux)..."
    if ! dpkg -s glibc-repo >/dev/null 2>&1; then
      pkg install -y glibc-repo || die "Failed to install glibc-repo"
      pkg update -y || pkg update || die "Failed to update package lists"
    fi
    pkg install -y glibc || die "Failed to install glibc"
  fi

  if [ ! -f "$PREFIX/etc/tls/cert.pem" ] && [ ! -f "$PREFIX/etc/ssl/cert.pem" ]; then
    need+=(ca-certificates)
  fi

  if [ "${#need[@]}" -gt 0 ]; then
    info "Installing missing packages: ${need[*]}"
    pkg install -y "${need[@]}" || die "Failed to install: ${need[*]}"
  fi

  for pkg_name in curl tar; do
    command -v "$pkg_name" >/dev/null 2>&1 || die "'$pkg_name' is required but was not found."
  done
}

fetch_latest_version() {
  local v=""
  v="$(curl -fsSL --connect-timeout 10 --max-time 30 \
        "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p' \
        | head -n 1)" || true
  if [ -z "$v" ]; then
    warn "Could not reach the GitHub API (rate limit or network issue)."
    warn "Falling back to v${FALLBACK_VERSION}."
    v="$FALLBACK_VERSION"
  fi
  printf '%s\n' "$v"
}

if [ "$SKIP_DEPS" -eq 0 ]; then
  install_deps
fi

command -v curl >/dev/null 2>&1 || die "'curl' is required. Install it with: pkg install curl"
command -v tar  >/dev/null 2>&1 || die "'tar' is required. Install it with: pkg install tar"

if [ ! -x "$LOADER" ]; then
  die "glibc loader not found at $LOADER
Install it with: pkg install glibc-repo && pkg update && pkg install glibc"
fi

if [ -z "$VERSION" ]; then
  info "Finding the latest OpenCode version..."
  VERSION="$(fetch_latest_version)"
fi
[ -n "$VERSION" ] || die "Could not determine the OpenCode version."

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${ASSET}"
TMP="${TMPDIR:-$PREFIX/tmp}"
mkdir -p "$TMP"
ARCHIVE_OVERRIDE="${OPENCODE_ARCHIVE:-}"
STAGE="$TMP/opencode-extract-$$"
CLEAN_ARCHIVE=0

if [ -n "$ARCHIVE_OVERRIDE" ]; then
  [ -f "$ARCHIVE_OVERRIDE" ] || die "OPENCODE_ARCHIVE not found: $ARCHIVE_OVERRIDE"
  ARCHIVE="$ARCHIVE_OVERRIDE"
  info "Using local archive: $ARCHIVE"
else
  ARCHIVE="$TMP/opencode-${VERSION}-$$.tar.gz"
  CLEAN_ARCHIVE=1
  info "Downloading OpenCode v${VERSION} (${ASSET})..."
  info "$DOWNLOAD_URL"
  if ! curl -fL --retry 3 --retry-delay 2 --connect-timeout 20 \
        -o "$ARCHIVE" "$DOWNLOAD_URL"; then
    die "Download failed. Check your connection or pin a version with --version."
  fi
  [ -s "$ARCHIVE" ] || die "Downloaded archive is empty."
fi

cleanup() {
  rm -rf "$STAGE"
  [ "$CLEAN_ARCHIVE" -eq 1 ] && rm -f "$ARCHIVE"
}
trap cleanup EXIT

info "Extracting..."
mkdir -p "$STAGE"
tar -xzf "$ARCHIVE" -C "$STAGE" || die "Failed to extract the archive."

if [ -f "$STAGE/opencode" ]; then
  BIN_SRC="$STAGE/opencode"
elif command -v find >/dev/null 2>&1; then
  BIN_SRC="$(find "$STAGE" -type f -name opencode -print -quit)"
else
  BIN_SRC="$(ls -1 "$STAGE"/opencode "$STAGE"/*/opencode 2>/dev/null | head -n 1)"
fi
[ -n "${BIN_SRC:-}" ] && [ -f "$BIN_SRC" ] \
  || die "Could not find the opencode binary inside the archive."

mkdir -p "$INSTALL_DIR" "$BIN_DIR"
rm -f "$REAL_BIN"
mv "$BIN_SRC" "$REAL_BIN"
chmod 755 "$REAL_BIN"

if [ -e "$BIN_PATH" ]; then
  if grep -qs "opencode-termux" "$BIN_PATH" 2>/dev/null; then
    rm -f "$BIN_PATH"
  else
    BACKUP="${BIN_PATH}.bak.$(date +%Y%m%d%H%M%S)"
    warn "An existing opencode was found. Backing it up to:"
    warn "  $BACKUP"
    mv "$BIN_PATH" "$BACKUP"
  fi
fi

CERT_FILE="$PREFIX/etc/tls/cert.pem"
CERT_DIR="$PREFIX/etc/tls"
if [ ! -f "$CERT_FILE" ]; then
  CERT_FILE="$PREFIX/etc/ssl/cert.pem"
  CERT_DIR="$PREFIX/etc/ssl"
fi

cat > "$BIN_PATH" <<EOF
#!${PREFIX}/bin/bash
# Managed by the opencode-termux installer. Do not edit.
unset LD_PRELOAD LD_LIBRARY_PATH
export SSL_CERT_FILE="${CERT_FILE}"
export SSL_CERT_DIR="${CERT_DIR}"
export NODE_EXTRA_CA_CERTS="\$SSL_CERT_FILE"
export GODEBUG="\${GODEBUG:-netdns=cgo}"
exec "${LOADER}" --library-path "${PREFIX}/glibc/lib" "${REAL_BIN}" "\$@"
EOF
chmod 755 "$BIN_PATH"

if [ ! -f "$CERT_FILE" ]; then
  warn "CA certificate bundle not found. TLS requests may fail."
  warn "Run: pkg install ca-certificates"
fi

info "Verifying installation..."
INSTALLED_VERSION="$("$BIN_PATH" --version 2>/dev/null | head -n 1)" || true
if [ -z "$INSTALLED_VERSION" ]; then
  die "Installation finished but 'opencode --version' failed.
Try running: pkg install glibc ca-certificates"
fi

ok "OpenCode ${INSTALLED_VERSION} installed successfully!"
printf '\n'
printf '  Run it with:  %sopencode%s\n' "$C_INFO" "$C_RESET"
printf '  Add API keys: %sopencode auth login%s\n' "$C_INFO" "$C_RESET"
printf '  Installer by: Sakil (github.com/sakil843)\n'
printf '\n'
