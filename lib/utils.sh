#!/usr/bin/env bash
# utils.sh — Logging, dependency checks, and general helpers

readonly LW_VERSION="1.0.0"

# ── Logging ──────────────────────────────────────────────────────────────────

_lw_log()  { echo -e "${1}[lazy-weather] ${2}${C_RESET:-}" >&2; }
lw_info()  { _lw_log "${C_CYAN:-}"    "INFO  $*"; }
lw_warn()  { _lw_log "${C_YELLOW:-}"  "WARN  $*"; }
lw_error() { _lw_log "${C_RED:-}"     "ERROR $*"; }
lw_debug() { [[ "${LW_DEBUG:-0}" == "1" ]] && _lw_log "${C_DIM:-}" "DEBUG $*" || true; }

# ── Colors ────────────────────────────────────────────────────────────────────

setup_colors() {
    if [[ -t 1 ]] && command -v tput &>/dev/null && tput colors &>/dev/null; then
        C_RESET='\033[0m'
        C_BOLD='\033[1m'
        C_DIM='\033[2m'
        C_RED='\033[0;31m'
        C_YELLOW='\033[0;33m'
        C_CYAN='\033[0;36m'
    else
        C_RESET='' C_BOLD='' C_DIM='' C_RED=''
        C_YELLOW='' C_CYAN=''
    fi
}

# ── Dependency checks ─────────────────────────────────────────────────────────

check_dependencies() {
    local missing=()
    for cmd in curl fzf; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        lw_error "Missing required dependencies: ${missing[*]}"
        lw_error "Install them and try again."
        return 1
    fi
    if ! command -v jq &>/dev/null; then
        lw_debug "jq not found — not required."
    fi
}

# ── String helpers ────────────────────────────────────────────────────────────

# Slugify a city name for use in filenames: "New York" -> "new_york"
slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '_' | sed 's/_$//'
}

# Trim leading/trailing whitespace
trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    echo "$s"
}

# Return epoch seconds (portable)
now_epoch() {
    date +%s
}

# Human-readable elapsed time
elapsed_human() {
    local secs=$(( $(now_epoch) - ${1:-0} ))
    if   (( secs < 60  )); then echo "${secs}s ago"
    elif (( secs < 3600 )); then echo "$(( secs/60 ))m ago"
    else                        echo "$(( secs/3600 ))h ago"
    fi
}

# Print help and exit
show_help() {
    cat <<EOF
${C_BOLD}lazy-weather${C_RESET} v${LW_VERSION} — A fast, cached CLI weather tool

${C_BOLD}USAGE${C_RESET}
  lazy-weather [OPTIONS]

${C_BOLD}OPTIONS${C_RESET}
  -c, --city CITY       Show weather for CITY (skips fzf picker)
  -m, --mini            One-line output for status bars (polybar/i3blocks)
  -r, --refresh         Force refresh (ignore cache)
  -t, --ttl SECONDS     Override cache TTL for this run
  -d, --debug           Enable debug output
      --clear-cache     Remove all cached data
  -v, --version         Print version and exit
  -h, --help            Show this help

${C_BOLD}EXAMPLES${C_RESET}
  lazy-weather                    # interactive fzf city picker
  lazy-weather -c "London"        # direct city lookup
  lazy-weather -m                 # mini mode — uses top city in config
  lazy-weather -c "Tokyo" -m      # mini mode for a specific city
  lazy-weather -c "Paris" -r      # force refresh

${C_BOLD}CONFIG${C_RESET}
  ~/.config/lazy-weather/config
EOF
}
