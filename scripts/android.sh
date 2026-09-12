#!/usr/bin/env bash
# Build the combined tailscaled/tailscale executable for rooted Android.
set -euo pipefail
cd "$(dirname "$0")/.."

GO="${GO:-go}"
DIST_DIR="${DIST_DIR:-$PWD/dist}"
ANDROID_API="${ANDROID_API:-21}"

usage() {
    echo "Usage: $0 build [--pre] [--nocgo] <arm|arm64|amd64>"
    echo "       $0 check [arm64]"
    echo "       $0 update <upstream-stable-tag>"
}

build_tags() {
    local remove="aws,bird,tap,kube,completion,completion_scripts,wakeonlan,capture,systray,syspolicy,appconnectors,identityfederation,usermetrics,logtail,netlog,linuxdnsfight,tpm"
    CGO_ENABLED=0 GOOS= GOARCH= "$GO" run ./cmd/featuretags --remove "$remove" --add cli
}

set_arch() {
    export GOOS=android GOARCH="$1"
    case "$GOARCH" in
        arm) export GOARM=7; triple=armv7a-linux-androideabi ;;
        arm64) triple=aarch64-linux-android ;;
        amd64) triple=x86_64-linux-android ;;
        *) echo "Unsupported architecture: $GOARCH" >&2; exit 1 ;;
    esac
}

setup_ndk() {
    local ndk="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}" host
    case "$(uname -s)" in
        Linux) host=linux-x86_64 ;;
        Darwin) host=darwin-x86_64 ;;
        *) echo "Use Linux or macOS with the Android NDK." >&2; exit 1 ;;
    esac
    local bin="${ANDROID_NDK_PATH:-${ndk:+$ndk/toolchains/llvm/prebuilt/$host/bin}}"
    if [[ -z "$bin" || ! -x "$bin/${triple}${ANDROID_API}-clang" ]]; then
        echo "Set ANDROID_NDK_HOME to an installed NDK (CI uses r27c)." >&2
        echo "Alternatively set ANDROID_NDK_PATH to its LLVM bin directory." >&2
        exit 1
    fi
    export CC="$bin/${triple}${ANDROID_API}-clang"
    export CXX="$bin/${triple}${ANDROID_API}-clang++"
    export CGO_ENABLED=1
    # Support Android devices using either 4 KiB or 16 KiB pages.
    export CGO_LDFLAGS="${CGO_LDFLAGS:-} -Wl,-z,max-page-size=16384"
}

build() {
    local pre="" nocgo="" tags version hash stage
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pre) pre=-pre; shift ;;
            --nocgo) nocgo=1; shift ;;
            *) break ;;
        esac
    done
    [[ $# -eq 1 ]] || { usage; exit 1; }
    tags=$(build_tags)
    set_arch "$1"
    if [[ -n "$nocgo" ]]; then
        [[ "$GOARCH" == arm64 ]] || { echo "--nocgo is supported only for arm64; releases use the NDK." >&2; exit 1; }
        export CGO_ENABLED=0
    else
        setup_ndk
    fi
    version=$(tr -d '\r\n' < VERSION.txt)
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "Invalid VERSION.txt" >&2; exit 1; }
    hash=$(git rev-parse HEAD)
    mkdir -p "$DIST_DIR"
    "$GO" build -trimpath -buildvcs=false -tags="$tags" \
        -ldflags="-s -w -X tailscale.com/version.shortStamp=${version}${pre} -X tailscale.com/version.longStamp=${version}-android${pre}-${hash:0:12} -X tailscale.com/version.gitCommitStamp=$hash" \
        -o "$DIST_DIR/tailscaled.$GOARCH" ./cmd/tailscaled
    stage=$(mktemp -d)
    cp "$DIST_DIR/tailscaled.$GOARCH" "$stage/tailscaled"
    chmod 755 "$stage/tailscaled"
    ln -s tailscaled "$stage/tailscale"
    cp LICENSE "$stage/LICENSE"
    tar -czf "$DIST_DIR/tailscale_${version}_${GOARCH}.tgz" -C "$stage" tailscaled tailscale LICENSE
    rm -rf "$stage"
    echo "Built $DIST_DIR/tailscale_${version}_${GOARCH}.tgz"
}

check() {
    local tags
    tags=$(build_tags)
    set_arch "${1:-arm64}"
    CGO_ENABLED=0 "$GO" vet -tags="$tags" ./cmd/tailscaled ./cmd/tailscale
}

update() {
    [[ $# -eq 1 && "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || { usage; exit 1; }
    [[ "$(git branch --show-current)" == main ]] || { echo "Run updates on main." >&2; exit 1; }
    [[ -z "$(git status --porcelain)" ]] || { echo "Commit or stash your changes first." >&2; exit 1; }
    # Fetch only the selected upstream tag. Keep a single development branch.
    git fetch --no-tags https://github.com/tailscale/tailscale.git "refs/tags/$1:refs/tags/$1"
    git merge --no-ff "$1" -m "Merge Tailscale $1 into Android main"
    echo "Run the Android build and tests before pushing main."
}

case "${1:-}" in
    build) shift; build "$@" ;;
    check) shift; check "$@" ;;
    update) shift; update "$@" ;;
    *) usage; exit 1 ;;
esac
