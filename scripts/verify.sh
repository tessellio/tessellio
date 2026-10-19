#!/usr/bin/env bash
# Runs every check the codec's repositories have.
#
# The codec has no continuous integration: its checks are local, and this
# script is how they are run together. It is what a contributor runs before
# opening a proposal, and what a release is cut from.
#
# Usage:
#   scripts/verify.sh                # check what is present
#   scripts/verify.sh --all          # require every repository
#
# The repositories are expected next to this one as `../tessellio-core`,
# `../tessellio-ts`, `../tessellio-proto` and
# `../tessellio-conformance`. A repository that is absent is reported and
# skipped, unless `--all` was given.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKSPACE="$(cd "$REPO_ROOT/.." && pwd)"

CORE_DIR="${TESSELLIO_CORE_DIR:-$WORKSPACE/tessellio-core}"
TS_DIR="${TESSELLIO_TS_DIR:-$WORKSPACE/tessellio-ts}"
PROTO_DIR="${TESSELLIO_PROTO_DIR:-$WORKSPACE/tessellio-proto}"
CONFORMANCE_DIR="${TESSELLIO_CONFORMANCE_DIR:-$WORKSPACE/tessellio-conformance}"

REQUIRE_ALL=0
for argument in "$@"; do
    case "$argument" in
        --all) REQUIRE_ALL=1 ;;
        *) printf 'verify: unknown argument %s\n' "$argument" >&2; exit 2 ;;
    esac
done

PASSES=0
FAILURES=0
SKIPPED=0

ok() {
    PASSES=$((PASSES + 1))
    printf '  ok    %s\n' "$1"
}

fail() {
    FAILURES=$((FAILURES + 1))
    printf '  FAIL  %s\n' "$1" >&2
    if [ $# -gt 1 ]; then
        printf '        %s\n' "$2" >&2
    fi
}

skip() {
    SKIPPED=$((SKIPPED + 1))
    printf '  skip  %s\n' "$1"
}

# Run a step, and report it by name.
step() { # name, directory, command...
    local name="$1" directory="$2"
    shift 2
    if [ ! -d "$directory" ]; then
        if [ "$REQUIRE_ALL" = "1" ]; then
            fail "$name" "the repository is missing at $directory"
        else
            skip "$name (no repository at $directory)"
        fi
        return 0
    fi
    if ( cd "$directory" && "$@" ) >/tmp/tessellio-verify-step.log 2>&1; then
        ok "$name"
    else
        fail "$name" "see the output below"
        tail -20 /tmp/tessellio-verify-step.log >&2
    fi
}

echo "verify: the codec's repositories"

step "specification: cross-references resolve" "$REPO_ROOT" \
    node scripts/check-references.mjs

step "specification: cross-references resolve in the implementations" "$REPO_ROOT" \
    node scripts/check-references.mjs \
        --impl "$CORE_DIR" --impl "$TS_DIR" --impl "$CONFORMANCE_DIR"

step "tessellio-core: builds" "$CORE_DIR" cargo build
step "tessellio-core: tests" "$CORE_DIR" cargo test
step "tessellio-core: lints clean" "$CORE_DIR" cargo clippy --all-targets -- -D warnings
step "tessellio-core: formatted" "$CORE_DIR" cargo fmt --check

step "tessellio-ts: typechecks" "$TS_DIR" npm run typecheck
step "tessellio-ts: tests" "$TS_DIR" npm test

step "tessellio-proto: generated bindings are current" "$PROTO_DIR" npm run generate:check

step "tessellio-conformance: the corpus is reproducible" "$CONFORMANCE_DIR" \
    scripts/conformance-gate.sh

step "tessellio-conformance: the gate checks its own teeth" "$CONFORMANCE_DIR" \
    scripts/conformance-gate.sh --self-test

if [ "$FAILURES" -eq 0 ]; then
    echo "verify: all checks passed ($PASSES passed, $SKIPPED skipped)"
    exit 0
fi
echo "verify: $FAILURES check(s) failed" >&2
exit 1
