#!/usr/bin/env bash
# uninstall.sh — Remove lazy-weather
set -euo pipefail

INSTALL_DIR="${HOME}/.local/bin"
LIB_DIR="${HOME}/.local/lib/lazy-weather"
CONFIG_DIR="${HOME}/.config/lazy-weather"

C_RED='\033[0;31m'; C_CYAN='\033[0;36m'; C_RESET='\033[0m'
info() { echo -e "${C_CYAN}[uninstall]${C_RESET} $*"; }

removed=0

if [[ -f "${INSTALL_DIR}/lazy-weather" ]]; then
    rm -f "${INSTALL_DIR}/lazy-weather"
    info "Removed ${INSTALL_DIR}/lazy-weather"
    removed=1
fi

if [[ -d "$LIB_DIR" ]]; then
    rm -rf "$LIB_DIR"
    info "Removed ${LIB_DIR}"
    removed=1
fi

# Remove cache files
rm -f /tmp/lazy-weather-*.cache /tmp/lazy-weather-*.meta 2>/dev/null && \
    info "Removed cache files from /tmp"

echo ""
if [[ "$removed" -eq 1 ]]; then
    echo -e "${C_CYAN}lazy-weather uninstalled.${C_RESET}"
else
    echo "lazy-weather does not appear to be installed."
fi

echo ""
echo "Your config at ${CONFIG_DIR} was NOT removed."
echo "To remove it: rm -rf ${CONFIG_DIR}"
