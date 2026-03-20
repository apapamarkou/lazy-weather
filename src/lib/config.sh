#!/usr/bin/env bash
# config.sh — Load and expose configuration

readonly LW_CONFIG_DIR="${HOME}/.config/lazy-weather"
readonly LW_CONFIG_FILE="${LW_CONFIG_DIR}/config"
LW_DEFAULT_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../config" && pwd)"
readonly LW_DEFAULT_CONFIG_DIR

# Defaults (overridden by config file, then CLI flags)
LW_CITIES=()
LW_DEFAULT_CITY=""
LW_CACHE_TTL=1800        # 30 minutes
LW_CACHE_DIR="/tmp"
LW_MINI_FORMAT="%t %C"   # temperature + condition
LW_FORECAST_DAYS=3       # 0=current only, 1-3 days
LW_WTTR_VERSION="narrow" # narrow | wide
LW_UNITS="m"             # m=metric | u=USCS

load_config() {
    # Load bundled defaults first
    local default_conf="${LW_DEFAULT_CONFIG_DIR}/default.conf"
    [[ -f "$default_conf" ]] && _source_conf "$default_conf"

    # Override with user config
    [[ -f "$LW_CONFIG_FILE" ]] && _source_conf "$LW_CONFIG_FILE"

    # Apply WTTR_VERSION: wide removes the 'd' (narrow glyph) flag
    lw_debug "Config loaded: ttl=${LW_CACHE_TTL} days=${LW_FORECAST_DAYS} version=${LW_WTTR_VERSION} units=${LW_UNITS}"
}

_source_conf() {
    local file="$1"
    # Only allow safe key=value lines; skip comments and blanks
    while IFS='=' read -r key value; do
        key="$(trim "$key")"
        value="$(trim "$value")"
        [[ -z "$key" || "$key" == \#* ]] && continue
        case "$key" in
            CITIES)
                IFS=',' read -ra LW_CITIES <<< "$value"
                export LW_CITIES
                ;;
            DEFAULT_CITY)    export LW_DEFAULT_CITY="$value" ;;
            CACHE_TTL)       export LW_CACHE_TTL="$value" ;;
            CACHE_DIR)       export LW_CACHE_DIR="$value" ;;
            MINI_FORMAT)     export LW_MINI_FORMAT="$value" ;;
            FORECAST_DAYS)   export LW_FORECAST_DAYS="$value" ;;
            WTTR_VERSION)    export LW_WTTR_VERSION="$value" ;;
            UNITS)           export LW_UNITS="$value" ;;
        esac
    done < "$file"
}

init_config_dir() {
    if [[ ! -d "$LW_CONFIG_DIR" ]]; then
        mkdir -p "$LW_CONFIG_DIR"
        lw_info "Created config directory: ${LW_CONFIG_DIR}"
    fi
    if [[ ! -f "$LW_CONFIG_FILE" ]]; then
        cp "${LW_DEFAULT_CONFIG_DIR}/default.conf" "$LW_CONFIG_FILE" 2>/dev/null || true
        lw_info "Created default config: ${LW_CONFIG_FILE}"
    fi
}

# Write or update a single key=value in the user config file
save_config_value() {
    local key="$1" value="$2"
    init_config_dir
    if grep -q "^${key}=" "$LW_CONFIG_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$LW_CONFIG_FILE"
    else
        echo "${key}=${value}" >> "$LW_CONFIG_FILE"
    fi
}
