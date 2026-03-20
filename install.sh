#!/usr/bin/env bash
# install.sh — Install lazy-weather to ~/.local/bin
set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/<user>/lazy-weather/main"
INSTALL_DIR="${HOME}/.local/bin"
CONFIG_DIR="${HOME}/.config/lazy-weather"
TMP_DIR="$(mktemp -d)"

C_GREEN='\033[0;32m'; C_CYAN='\033[0;36m'
C_YELLOW='\033[0;33m'; C_RED='\033[0;31m'; C_RESET='\033[0m'

info()  { echo -e "${C_CYAN}[install]${C_RESET} $*"; }
ok()    { echo -e "${C_GREEN}[install]${C_RESET} $*"; }
warn()  { echo -e "${C_YELLOW}[install]${C_RESET} $*"; }
die()   { echo -e "${C_RED}[install] ERROR:${C_RESET} $*" >&2; exit 1; }

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# ── Dependency check ──────────────────────────────────────────────────────────

for cmd in curl bash; do
    command -v "$cmd" &>/dev/null || die "Required: ${cmd}"
done
command -v fzf &>/dev/null || warn "fzf not found — install it for interactive mode"
command -v jq  &>/dev/null || warn "jq not found  — Open-Meteo provider will be unavailable"

# ── Detect install source ─────────────────────────────────────────────────────

# If running from a cloned repo, install from local files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/bin/lazy-weather" ]]; then
    info "Installing from local source: ${SCRIPT_DIR}"
    SRC_DIR="$SCRIPT_DIR"
    USE_LOCAL=1
else
    info "Downloading from GitHub..."
    USE_LOCAL=0
fi

# ── Create directories ────────────────────────────────────────────────────────

mkdir -p "$INSTALL_DIR" "${INSTALL_DIR}/../lib/lazy-weather" "$CONFIG_DIR"

LIB_INSTALL_DIR="${HOME}/.local/lib/lazy-weather"
mkdir -p "$LIB_INSTALL_DIR"

# ── Install files ─────────────────────────────────────────────────────────────

install_file() {
    local src="$1" dst="$2"
    if [[ "$USE_LOCAL" -eq 1 ]]; then
        cp "$src" "$dst"
    else
        curl -fsSL "${REPO_URL}/${src}" -o "$dst"
    fi
}

info "Installing lib files..."
for lib in utils.sh config.sh cache.sh weather.sh ui.sh; do
    if [[ "$USE_LOCAL" -eq 1 ]]; then
        cp "${SRC_DIR}/lib/${lib}" "${LIB_INSTALL_DIR}/${lib}"
    else
        curl -fsSL "${REPO_URL}/lib/${lib}" -o "${LIB_INSTALL_DIR}/${lib}"
    fi
done

info "Installing main executable..."
if [[ "$USE_LOCAL" -eq 1 ]]; then
    cp "${SRC_DIR}/bin/lazy-weather" "${INSTALL_DIR}/lazy-weather"
else
    curl -fsSL "${REPO_URL}/bin/lazy-weather" -o "${INSTALL_DIR}/lazy-weather"
fi

# Patch LIB_DIR in the installed binary to point to the installed lib path
sed -i "s|LIB_DIR=.*|LIB_DIR=\"${LIB_INSTALL_DIR}\"|" "${INSTALL_DIR}/lazy-weather"

chmod +x "${INSTALL_DIR}/lazy-weather"

info "Installing default config..."
if [[ ! -f "${CONFIG_DIR}/config" ]]; then
    if [[ "$USE_LOCAL" -eq 1 ]]; then
        cp "${SRC_DIR}/config/default.conf" "${CONFIG_DIR}/config"
    else
        curl -fsSL "${REPO_URL}/config/default.conf" -o "${CONFIG_DIR}/config"
    fi
    ok "Default config written to ${CONFIG_DIR}/config"
else
    warn "Config already exists at ${CONFIG_DIR}/config — not overwritten"
fi

# Also install default.conf alongside lib so config.sh can find it
mkdir -p "${LIB_INSTALL_DIR}/../config"
if [[ "$USE_LOCAL" -eq 1 ]]; then
    cp "${SRC_DIR}/config/default.conf" "${LIB_INSTALL_DIR}/../config/default.conf"
else
    curl -fsSL "${REPO_URL}/config/default.conf" -o "${LIB_INSTALL_DIR}/../config/default.conf"
fi

# ── PATH check ────────────────────────────────────────────────────────────────

ok "Installation complete!"
echo ""
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
    warn "${INSTALL_DIR} is not in your PATH."
    echo "  Add this to your shell rc file:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
fi
echo -e "  Run: ${C_CYAN}lazy-weather --help${C_RESET}"
