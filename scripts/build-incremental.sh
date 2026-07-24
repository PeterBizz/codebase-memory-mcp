#!/usr/bin/env bash
# build-incremental.sh — Incremental production build (no clean step).
#
# Usage:
#   scripts/build-incremental.sh                              # Standard binary
#   scripts/build-incremental.sh --with-ui                    # Binary with embedded UI
#   scripts/build-incremental.sh --version v0.8.0             # With version stamp
#   scripts/build-incremental.sh --arch x86_64                # Force x86_64 build
#   scripts/build-incremental.sh CC=gcc-14 CXX=g++-14         # Override compiler
#
# Unlike scripts/build.sh, this script does NOT remove build artifacts first.
# It relies on Makefile dependency tracking and only rebuilds what changed.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Pre-parse --arch flag before sourcing env.sh
for arg in "$@"; do
    case "$arg" in
        --arch=*) export CBM_ARCH="${arg#--arch=}" ;;
    esac
done
prev_arg=""
for arg in "$@"; do
    if [[ "${prev_arg:-}" == "--arch" ]]; then
        export CBM_ARCH="$arg"
    fi
    prev_arg="$arg"
done

# shellcheck source=env.sh
source "$ROOT/scripts/env.sh"

WITH_UI=false
VERSION=""
BUILD_DIR="build/c"
EXTRA_MAKE_ARGS=()

prev_arg=""
for arg in "$@"; do
    if [[ "${prev_arg:-}" == "--arch" ]]; then
        prev_arg="$arg"
        continue
    fi
    case "$arg" in
        --with-ui)
            WITH_UI=true
            ;;
        --version)
            prev_arg="$arg"
            continue
            ;;
        --arch|--arch=*)
            ;;
        BUILD_DIR=*)
            BUILD_DIR="${arg#BUILD_DIR=}"
            EXTRA_MAKE_ARGS+=("$arg")
            ;;
        CC=*|CXX=*)
            export "${arg}"
            EXTRA_MAKE_ARGS+=("$arg")
            ;;
        *)
            if [[ "${prev_arg:-}" == "--version" ]]; then
                VERSION="$arg"
            else
                EXTRA_MAKE_ARGS+=("$arg")
            fi
            ;;
    esac
    prev_arg="$arg"
done

CFLAGS_EXTRA=""
if [[ -n "$VERSION" ]]; then
    CLEAN_VERSION="${VERSION#v}"
    CFLAGS_EXTRA="-DCBM_VERSION=\"\\\"$CLEAN_VERSION\\\"\""
fi

print_env "build-incremental.sh"
echo "  ui=$WITH_UI version=${VERSION:-dev}"

verify_compiler "$CC"

if $WITH_UI; then
    make -j"$NPROC" -f Makefile.cbm cbm-with-ui \
        CFLAGS_EXTRA="$CFLAGS_EXTRA" "${EXTRA_MAKE_ARGS[@]+"${EXTRA_MAKE_ARGS[@]}"}"
else
    make -j"$NPROC" -f Makefile.cbm cbm \
        CFLAGS_EXTRA="$CFLAGS_EXTRA" "${EXTRA_MAKE_ARGS[@]+"${EXTRA_MAKE_ARGS[@]}"}"
fi

echo "=== Incremental build complete: ${BUILD_DIR}/codebase-memory-mcp ==="
