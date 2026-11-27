#!/data/data/com.termux/files/usr/bin/bash
#
# OpenCode for Termux - uninstaller
#
#   bash uninstall.sh           # remove the launcher and binary
#   bash uninstall.sh --purge   # also remove config, auth and session data
#
set -euo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.local/share/opencode-termux}"
BIN_PATH="${OPENCODE_BIN_DIR:-$PREFIX/bin}/opencode"
PURGE=0

for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=1 ;;
    -h|--help)
      echo "Usage: bash uninstall.sh [--purge]"
      echo "  --purge  Also delete ~/.config/opencode and ~/.local/share/opencode"
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [ -f "$BIN_PATH" ] && grep -qs "opencode-termux" "$BIN_PATH"; then
  rm -f "$BIN_PATH"
  echo "Removed launcher: $BIN_PATH"
else
  echo "Skipped launcher (not managed by opencode-termux): $BIN_PATH"
fi

if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
  echo "Removed binaries: $INSTALL_DIR"
fi

if [ "$PURGE" -eq 1 ]; then
  rm -rf "$HOME/.config/opencode" "$HOME/.local/share/opencode"
  echo "Removed config and data (~/.config/opencode, ~/.local/share/opencode)"
fi

BACKUP_DIR="$(dirname "$BIN_PATH")"
HAS_BACKUP=0
for b in "$BACKUP_DIR"/opencode.bak.*; do
  [ -e "$b" ] || continue
  if [ "$HAS_BACKUP" -eq 0 ]; then
    echo
    echo "Previous opencode backups found. Restore one with:"
    HAS_BACKUP=1
  fi
  echo "  mv \"$b\" \"$BIN_PATH\""
done

echo "Uninstall complete. glibc packages were left installed (they may be used by other apps)."
