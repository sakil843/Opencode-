#!/data/data/com.termux/files/usr/bin/bash
#
# OpenCode for Termux - updater
# Reinstalls the latest version using install.sh.
#
set -euo pipefail

REPO_SLUG="${OPENCODE_TERMUX_REPO:-sakil843/Opencode-}"
BRANCH="${OPENCODE_TERMUX_BRANCH:-main}"
SELF_DIR=""

if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [ -n "$SELF_DIR" ] && [ -f "$SELF_DIR/install.sh" ]; then
  exec bash "$SELF_DIR/install.sh" "$@"
fi

TMP_FILE="${TMPDIR:-/tmp}/opencode-install-$$.sh"
trap 'rm -f "$TMP_FILE"' EXIT

echo "Downloading installer from https://raw.githubusercontent.com/${REPO_SLUG}/${BRANCH}/install.sh"
curl -fsSL "https://raw.githubusercontent.com/${REPO_SLUG}/${BRANCH}/install.sh" -o "$TMP_FILE"
bash "$TMP_FILE" "$@"
