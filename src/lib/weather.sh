#!/usr/bin/env bash
# weather.sh — wttr.in weather provider

# ── Public entry points ───────────────────────────────────────────────────────

get_weather() {
    local city="$1"
    local force_refresh="${2:-0}"
    local data

    if [[ "$force_refresh" != "1" ]]; then
        if data="$(cache_read "$city" "$LW_CACHE_TTL")"; then
            lw_debug "Serving '${city}' from cache"
            echo "$data"
            return 0
        fi
    fi

    lw_debug "Fetching '${city}' from wttr.in"
    if data="$(_fetch_wttr "$city")"; then
        cache_write "$city" "$data"
        echo "$data"
    else
        lw_warn "Network fetch failed for '${city}', trying stale cache..."
        if ! cache_read_stale "$city"; then
            lw_error "No data available for '${city}'"
            return 1
        fi
    fi
}

get_weather_mini() {
    local city="$1"
    local force_refresh="${2:-0}"
    _fetch_wttr_mini "$city" "$force_refresh"
}

# ── wttr.in ───────────────────────────────────────────────────────────────────

_wttr_encode() {
    python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))' "$1" 2>/dev/null \
        || echo "${1// /+}"
}

_fetch_wttr() {
    local city="$1"
    local encoded_city narrow_flag
    encoded_city="$(_wttr_encode "$city")"
    [[ "$LW_WTTR_VERSION" == "narrow" ]] && narrow_flag="n" || narrow_flag=""

    curl -fsSL --max-time 10 \
        "https://wttr.in/${encoded_city}?${LW_FORECAST_DAYS}FqQ${LW_UNITS}${narrow_flag}" 2>/dev/null
}

_fetch_wttr_mini() {
    local city="$1"
    local force_refresh="${2:-0}"
    local cached

    if [[ "$force_refresh" != "1" ]]; then
        cached="$(cache_read "${city}_mini" "$LW_CACHE_TTL")" && { echo "$cached"; return 0; }
    fi

    local encoded_city encoded_format result
    encoded_city="$(_wttr_encode "$city")"
    encoded_format="$(_wttr_encode "$LW_MINI_FORMAT")"
    encoded_format="${encoded_format//+/%20}"

    result="$(curl -fsSL --max-time 10 \
        "https://wttr.in/${encoded_city}?FqQ${LW_UNITS}&format=${encoded_format}" 2>/dev/null || true)"
    if [[ -z "$result" ]]; then
        cache_read_stale "${city}_mini" && return 0
        echo "N/A"
        return 1
    fi
    cache_write "${city}_mini" "$result"
    echo "$result"
}
