#!/usr/bin/env bash
# run-tests.sh — Install bats-core if needed and run all test suites
set -euo pipefail

BATS_DIR="/tmp/bats-core"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Install bats-core if not available ────────────────────────────────────────
if ! command -v bats &>/dev/null; then
    echo "bats not found — installing bats-core..."
    rm -rf "$BATS_DIR"
    git clone --depth=1 https://github.com/bats-core/bats-core.git "$BATS_DIR"
    "$BATS_DIR/install.sh" "${HOME}/.local"
    export PATH="${HOME}/.local/bin:${PATH}"
fi

# ── Run tests ─────────────────────────────────────────────────────────────────
echo "Running lazy-weather test suites..."
bats --tap "${REPO_ROOT}/src/tests/"
