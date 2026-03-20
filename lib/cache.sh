#!/usr/bin/env bash
# cache.sh — Per-city cache with TTL validation and stale fallback

# Return the cache file path for a given city
cache_path() {
    local city="$1"
    local slug
    slug="$(slugify "$city")"
    echo "${LW_CACHE_DIR}/lazy-weather-${slug}.cache"
}

# Return the metadata file path (stores timestamp + city name)
cache_meta_path() {
    local city="$1"
    local slug
    slug="$(slugify "$city")"
    echo "${LW_CACHE_DIR}/lazy-weather-${slug}.meta"
}

# Write data to cache
cache_write() {
    local city="$1"
    local data="$2"
    local path meta_path ts

    path="$(cache_path "$city")"
    meta_path="$(cache_meta_path "$city")"
    ts="$(now_epoch)"

    echo "$data" > "$path"
    echo "timestamp=${ts}" > "$meta_path"
    echo "city=${city}" >> "$meta_path"
    lw_debug "Cache written for '${city}' at ${path} (ts=${ts})"
}

# Read cache data; returns 0 and prints data if valid, 1 if missing/expired
cache_read() {
    local city="$1"
    local ttl="${2:-${LW_CACHE_TTL}}"
    local path meta_path ts age

    path="$(cache_path "$city")"
    meta_path="$(cache_meta_path "$city")"

    [[ -f "$path" && -f "$meta_path" ]] || { lw_debug "Cache miss for '${city}'"; return 1; }

    ts="$(grep '^timestamp=' "$meta_path" | cut -d= -f2)"
    age=$(( $(now_epoch) - ts ))

    lw_debug "Cache age for '${city}': ${age}s (ttl=${ttl}s)"

    if (( age <= ttl )); then
        cat "$path"
        return 0
    fi

    lw_debug "Cache expired for '${city}'"
    return 1
}

# Read stale cache regardless of TTL (fallback on network failure)
cache_read_stale() {
    local city="$1"
    local path
    path="$(cache_path "$city")"
    if [[ -f "$path" ]]; then
        lw_warn "Using stale cache for '${city}'"
        cat "$path"
        return 0
    fi
    return 1
}

# Return cache age in seconds, or -1 if no cache
cache_age() {
    local city="$1"
    local meta_path ts
    meta_path="$(cache_meta_path "$city")"
    [[ -f "$meta_path" ]] || { echo -1; return; }
    ts="$(grep '^timestamp=' "$meta_path" | cut -d= -f2)"
    echo $(( $(now_epoch) - ts ))
}

# Delete cache for a city
cache_clear() {
    local city="$1"
    rm -f "$(cache_path "$city")" "$(cache_meta_path "$city")"
    lw_debug "Cache cleared for '${city}'"
}

# Delete all lazy-weather cache files
cache_clear_all() {
    rm -f "${LW_CACHE_DIR}"/lazy-weather-*.cache \
          "${LW_CACHE_DIR}"/lazy-weather-*.meta
    lw_info "All caches cleared."
}
