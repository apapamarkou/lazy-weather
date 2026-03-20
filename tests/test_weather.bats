#!/usr/bin/env bats
# test_weather.bats — Weather fetching tests with mocked curl (no network)

setup() {
    export LW_CACHE_DIR="$(mktemp -d)"
    export LW_CACHE_TTL=60
    export LW_MINI_FORMAT="%t %C"
    export LW_FORECAST_DAYS=3
    export LW_WTTR_VERSION="narrow"
    export LW_UNITS="m"
    export LW_DEBUG=0

    LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"
    source "${LIB_DIR}/utils.sh"
    source "${LIB_DIR}/cache.sh"
    source "${LIB_DIR}/weather.sh"

    export PATH="${LW_CACHE_DIR}/bin:${PATH}"
    mkdir -p "${LW_CACHE_DIR}/bin"
    cat > "${LW_CACHE_DIR}/bin/curl" <<'MOCK'
#!/usr/bin/env bash
echo "Weather: Sunny 22°C"
exit 0
MOCK
    chmod +x "${LW_CACHE_DIR}/bin/curl"
}

teardown() {
    rm -rf "$LW_CACHE_DIR"
}

# ── get_weather ───────────────────────────────────────────────────────────────

@test "get_weather fetches and caches data" {
    result="$(get_weather "London" 1)"
    [ "$result" = "Weather: Sunny 22°C" ]
    cached="$(cache_read "London" 60)"
    [ "$cached" = "Weather: Sunny 22°C" ]
}

@test "get_weather returns cached data on second call" {
    get_weather "London" 1 >/dev/null
    echo '#!/usr/bin/env bash; exit 1' > "${LW_CACHE_DIR}/bin/curl"
    chmod +x "${LW_CACHE_DIR}/bin/curl"
    result="$(get_weather "London" 0)"
    [ "$result" = "Weather: Sunny 22°C" ]
}

@test "get_weather falls back to stale cache on network failure" {
    cache_write "Paris" "Stale: Cloudy 10°C"
    meta="$(cache_meta_path "Paris")"
    echo "timestamp=$(( $(date +%s) - 9999 ))" > "$meta"
    echo "city=Paris" >> "$meta"
    echo '#!/usr/bin/env bash; exit 1' > "${LW_CACHE_DIR}/bin/curl"
    chmod +x "${LW_CACHE_DIR}/bin/curl"
    result="$(get_weather "Paris" 0)"
    [ "$result" = "Stale: Cloudy 10°C" ]
}

@test "get_weather with force_refresh bypasses cache" {
    cache_write "Tokyo" "Cached: Old data"
    result="$(get_weather "Tokyo" 1)"
    [ "$result" = "Weather: Sunny 22°C" ]
}

# ── get_weather_mini ──────────────────────────────────────────────────────────

@test "get_weather_mini returns non-empty output" {
    result="$(get_weather_mini "Berlin" 1)"
    [ -n "$result" ]
}

@test "get_weather_mini caches result" {
    get_weather_mini "Rome" 1 >/dev/null
    cached="$(cache_read "Rome_mini" 60)"
    [ -n "$cached" ]
}

@test "get_weather_mini returns cached data on second call" {
    get_weather_mini "Madrid" 1 >/dev/null
    echo '#!/usr/bin/env bash; exit 1' > "${LW_CACHE_DIR}/bin/curl"
    chmod +x "${LW_CACHE_DIR}/bin/curl"
    result="$(get_weather_mini "Madrid" 0)"
    [ -n "$result" ]
}

@test "get_weather_mini returns N/A on network failure with no cache" {
    echo '#!/usr/bin/env bash; exit 1' > "${LW_CACHE_DIR}/bin/curl"
    chmod +x "${LW_CACHE_DIR}/bin/curl"
    run get_weather_mini "NoCity" 1
    [ "$output" = "N/A" ]
}

# ── URL flag construction ─────────────────────────────────────────────────────

_url_mock() {
    cat > "${LW_CACHE_DIR}/bin/curl" <<'MOCK'
#!/usr/bin/env bash
echo "$@"
MOCK
    chmod +x "${LW_CACHE_DIR}/bin/curl"
}

@test "LW_FORECAST_DAYS is passed as leading flag in URL" {
    _url_mock
    LW_FORECAST_DAYS=1
    result="$(_fetch_wttr "London")"
    [[ "$result" == *"?1F"* ]]
}

@test "LW_WTTR_VERSION=narrow adds n flag to URL" {
    _url_mock
    LW_WTTR_VERSION="narrow"
    result="$(_fetch_wttr "London")"
    [[ "$result" == *"mn"* ]]
}

@test "LW_WTTR_VERSION=wide omits n flag from URL" {
    _url_mock
    LW_WTTR_VERSION="wide"
    result="$(_fetch_wttr "London")"
    [[ "$result" != *"mn"* ]]
}

@test "LW_UNITS=m adds m flag to URL" {
    _url_mock
    LW_UNITS="m"
    result="$(_fetch_wttr "London")"
    [[ "$result" == *"FqQm"* ]]
}

@test "LW_UNITS=u adds u flag to URL" {
    _url_mock
    LW_UNITS="u"
    result="$(_fetch_wttr "London")"
    [[ "$result" == *"FqQu"* ]]
}

@test "city name is URL-encoded in request" {
    _url_mock
    result="$(_fetch_wttr "New York")"
    [[ "$result" == *"New%20York"* ]]
}
