#!/usr/bin/env bats
# test_utils.bats — Utility function tests

setup() {
    export LW_DEBUG=0
    LIB_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../lib" && pwd)"
    source "${LIB_DIR}/utils.sh"
    setup_colors
}

# ── slugify ───────────────────────────────────────────────────────────────────

@test "slugify: single word lowercased" {
    [ "$(slugify "London")" = "london" ]
}

@test "slugify: spaces become underscores" {
    [ "$(slugify "New York")" = "new_york" ]
}

@test "slugify: multiple spaces" {
    [ "$(slugify "Los  Angeles")" = "los_angeles" ]
}

@test "slugify: already lowercase unchanged" {
    [ "$(slugify "paris")" = "paris" ]
}

@test "slugify: special chars stripped" {
    result="$(slugify "São Paulo")"
    [[ "$result" =~ ^[a-z0-9_]+$ ]]
}

# ── trim ──────────────────────────────────────────────────────────────────────

@test "trim: removes leading spaces" {
    [ "$(trim "  hello")" = "hello" ]
}

@test "trim: removes trailing spaces" {
    [ "$(trim "hello  ")" = "hello" ]
}

@test "trim: removes both sides" {
    [ "$(trim "  hello world  ")" = "hello world" ]
}

@test "trim: no-op on clean string" {
    [ "$(trim "clean")" = "clean" ]
}

@test "trim: empty string stays empty" {
    [ "$(trim "")" = "" ]
}

# ── now_epoch ─────────────────────────────────────────────────────────────────

@test "now_epoch returns a positive integer" {
    ts="$(now_epoch)"
    [[ "$ts" =~ ^[0-9]+$ ]]
    [ "$ts" -gt 0 ]
}

@test "now_epoch is close to system date +%s" {
    ts="$(now_epoch)"
    sys="$(date +%s)"
    diff=$(( sys - ts ))
    [ "${diff#-}" -le 2 ]
}

# ── elapsed_human ─────────────────────────────────────────────────────────────

@test "elapsed_human: seconds ago" {
    ts=$(( $(now_epoch) - 30 ))
    result="$(elapsed_human "$ts")"
    [ "$result" = "30s ago" ]
}

@test "elapsed_human: minutes ago" {
    ts=$(( $(now_epoch) - 120 ))
    result="$(elapsed_human "$ts")"
    [ "$result" = "2m ago" ]
}

@test "elapsed_human: hours ago" {
    ts=$(( $(now_epoch) - 7200 ))
    result="$(elapsed_human "$ts")"
    [ "$result" = "2h ago" ]
}

# ── setup_colors ──────────────────────────────────────────────────────────────

@test "setup_colors: C_RESET is defined" {
    [ -n "${C_RESET+x}" ]
}

@test "setup_colors: C_RED is defined" {
    [ -n "${C_RED+x}" ]
}
