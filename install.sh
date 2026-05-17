#!/bin/bash
# claude-sandbox installer
#
# Creates ./claude-sandbox/ in the current directory (script + profiles live
# inside), then symlinks the script into ~/.local/bin so it's on PATH.
#
# Re-run any time to upgrade in place; existing profiles are kept.
set -e

REPO_RAW="${CLAUDE_SANDBOX_INSTALL_URL:-https://raw.githubusercontent.com/wjsoj/claude-sandboxed/main/claude-sandbox}"
INSTALL_PARENT="${1:-$PWD}"
INSTALL_DIR="$INSTALL_PARENT/claude-sandbox"
BIN_DIR="${CLAUDE_SANDBOX_BIN_DIR:-$HOME/.local/bin}"
LINK="$BIN_DIR/claude-sandbox"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET=; C_DIM=; C_BOLD=; C_GREEN=; C_YELLOW=; C_RED=
fi
die()  { echo "${C_RED}error:${C_RESET} $*" >&2; exit 1; }
info() { echo "${C_DIM}·${C_RESET} $*"; }
ok()   { echo "${C_GREEN}✓${C_RESET} $*"; }

command -v curl >/dev/null 2>&1 || die "curl is required"

mkdir -p "$INSTALL_DIR" "$INSTALL_DIR/profiles" "$BIN_DIR"

info "downloading $REPO_RAW"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
curl -fsSL --connect-timeout 10 "$REPO_RAW" -o "$tmp" || die "download failed"
[[ -s "$tmp" ]] || die "downloaded file is empty"
head -1 "$tmp" | grep -q '^#!.*sh' || die "downloaded file is not a shell script"
bash -n "$tmp" || die "downloaded script failed syntax check"

install -m 755 "$tmp" "$INSTALL_DIR/claude-sandbox"
ok "installed script  → $INSTALL_DIR/claude-sandbox"

if [[ -L "$LINK" || -e "$LINK" ]]; then
  current="$(readlink -f "$LINK" 2>/dev/null || true)"
  target="$(readlink -f "$INSTALL_DIR/claude-sandbox")"
  if [[ "$current" != "$target" ]]; then
    echo "${C_YELLOW}!${C_RESET} $LINK already exists and points elsewhere ($current)"
    read -r -p "  overwrite? [y/N] " ans
    [[ "$ans" =~ ^[Yy]$ ]] || die "aborted"
  fi
fi
ln -sfn "$INSTALL_DIR/claude-sandbox" "$LINK"
ok "symlinked         → $LINK"
ok "profiles dir      → $INSTALL_DIR/profiles"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *)
    echo
    echo "${C_YELLOW}!${C_RESET} $BIN_DIR is not on PATH. Add this to your shell rc:"
    echo "    ${C_BOLD}export PATH=\"$BIN_DIR:\$PATH\"${C_RESET}"
    ;;
esac

echo
echo "${C_BOLD}Done.${C_RESET} Try: ${C_GREEN}claude-sandbox${C_RESET}"
echo "${C_DIM}Upgrade later with: claude-sandbox update${C_RESET}"
