#!/usr/bin/env bats
# test_cache.bats — Cache hit/miss/expiry tests (no network required)

setup() {
    export LW_CACHE_DIR="$(mktemp -d)"
    export LW_CACHE_TTL=60
    export LW_DEBUG=0

    LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"
    source "${LIB_DIR}/utils.sh"
    source "${LIB_DIR}/cache.sh"
}

teardown() {
    rm -rf "$LW_CACHE_DIR"
}

@test "slugify converts spaces to underscores" {
    result="$(slugify "New York")"
    [ "$result" = "new_york" ]
}

@test "slugify lowercases input" {
    result="$(slugify "LONDON")"
    [ "$result" = "london" ]
}

@test "cache_path returns expected path" {
    result="$(cache_path "London")"
    [ "$result" = "${LW_CACHE_DIR}/lazy-weather-london.cache" ]
}

@test "cache miss when no file exists" {
    run cache_read "London" 60
    [ "$status" -eq 1 ]
}

@test "cache write then read returns data" {
    cache_write "London" "sunny 20C"
    result="$(cache_read "London" 60)"
    [ "$result" = "sunny 20C" ]
}

@test "cache read returns 0 on hit" {
    cache_write "Tokyo" "cloudy 15C"
    run cache_read "Tokyo" 60
    [ "$status" -eq 0 ]
}

@test "cache expires after TTL" {
    cache_write "Paris" "rainy 10C"
    # Manually backdate the timestamp
    meta="$(cache_meta_path "Paris")"
    old_ts=$(( $(date +%s) - 120 ))
    echo "timestamp=${old_ts}" > "$meta"
    echo "city=Paris" >> "$meta"

    run cache_read "Paris" 60
    [ "$status" -eq 1 ]
}

@test "cache_read_stale returns data even when expired" {
    cache_write "Berlin" "snow -5C"
    meta="$(cache_meta_path "Berlin")"
    old_ts=$(( $(date +%s) - 9999 ))
    echo "timestamp=${old_ts}" > "$meta"
    echo "city=Berlin" >> "$meta"

    result="$(cache_read_stale "Berlin")"
    [ "$result" = "snow -5C" ]
}

@test "cache_age returns positive integer after write" {
    cache_write "Sydney" "clear 25C"
    age="$(cache_age "Sydney")"
    [ "$age" -ge 0 ]
}

@test "cache_age returns -1 when no cache" {
    age="$(cache_age "NoSuchCity")"
    [ "$age" -eq -1 ]
}

@test "cache_clear removes cache files" {
    cache_write "Rome" "sunny 28C"
    cache_clear "Rome"
    run cache_read "Rome" 60
    [ "$status" -eq 1 ]
}

@test "cache_clear_all removes all cache files" {
    cache_write "Madrid" "hot 35C"
    cache_write "Oslo" "cold 2C"
    cache_clear_all
    [ -z "$(ls "${LW_CACHE_DIR}"/lazy-weather-*.cache 2>/dev/null)" ]
}

@test "cache write overwrites previous data" {
    cache_write "Vienna" "old data"
    cache_write "Vienna" "new data"
    result="$(cache_read "Vienna" 60)"
    [ "$result" = "new data" ]
}
