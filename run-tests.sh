#!/usr/bin/env bash
# run-tests.sh — Install bats-core if needed and run all test suites
set -euo pipefail

BATS_DIR="/tmp/bats-core"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Locate or install bats ────────────────────────────────────────────────────

if command -v bats &>/dev/null; then
    BATS_BIN="$(command -v bats)"
else
    if [[ ! -x "${BATS_DIR}/bin/bats" ]]; then
        echo "bats not found — cloning bats-core to /tmp..."
        rm -rf "$BATS_DIR"
        git clone --depth=1 https://github.com/bats-core/bats-core.git "$BATS_DIR"
    fi
    BATS_BIN="${BATS_DIR}/bin/bats"
fi

# ── Run tests ─────────────────────────────────────────────────────────────────

echo "Running lazy-weather test suites..."
"$BATS_BIN" --tap "${REPO_ROOT}/src/tests/"
