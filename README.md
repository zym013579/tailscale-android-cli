# Tailscale Android CLI

[![Build Android binaries](https://github.com/zym013579/tailscale-android-cli/actions/workflows/release_android.yml/badge.svg)](https://github.com/zym013579/tailscale-android-cli/actions/workflows/release_android.yml)

Android command-line builds of [Tailscale](https://github.com/tailscale/tailscale),
maintained by **zym013579**, based on anasfanani's Android port.
Current upstream stable baseline: **v1.102.4**. Development happens on **main**;
release versions are tags, not separate development branches.

## Downloads

Download from [Releases](https://github.com/zym013579/tailscale-android-cli/releases):

| CPU | Archive |
| --- | --- |
| ARMv7 | `tailscale_1.102.4_arm.tgz` |
| ARM64 | `tailscale_1.102.4_arm64.tgz` |
| x86_64 | `tailscale_1.102.4_amd64.tgz` |

Each archive includes the combined `tailscaled` executable, a `tailscale` symlink,
and LICENSE. These are Android bionic executables, not APKs or Linux/glibc builds.
Releases use Go from go.mod, NDK r27c, API 21, CGO, PIE, and 16 KiB page alignment.
Verify downloads using the release's `SHA256SUMS` file.

The companion module is [zym013579/magisk-tailscaled](https://github.com/zym013579/magisk-tailscaled).
Default state files live in `/data/adb/tailscale`. Rooted devices can use native TUN,
or explicitly select `--tun=userspace-networking --socks5-server=127.0.0.1:1099`.
SSH, DNS and routing features still require validation on the target Android device.

## GitHub Actions

- **Build and release Android binaries** builds every main push. When the latest
  pushed commit message contains `release` (case-insensitive), it also publishes
  the current version as the latest GitHub Release after all checks pass.
- **Build Android binaries** handles pull requests, manual build-only runs and the
  reusable build called by the release workflow, without duplicating main builds.
- Matching tags such as `v1.102.4-android` and manual release dispatch still work.
  Use `v1.102.4-android-pre` or the prerelease input for prereleases.
- VERSION.txt determines the release version and asset names. Update it before a
  new version is published; an existing release is not silently overwritten.
  Tags must match VERSION.txt. A failed build never publishes a release.
- Publishing uses the repository's built-in `GITHUB_TOKEN`; no personal token is needed.
- Original upstream workflows are retained in `.github/upstream-workflows/` as
  reference, since they target unrelated platforms or Tailscale infrastructure.

## Local builds

Install the Go version required by go.mod and Android NDK r27c:

```sh
export ANDROID_NDK_HOME=/path/to/android-ndk-r27c
./scripts/android.sh build arm64
./scripts/android.sh build arm
./scripts/android.sh build amd64
./scripts/android.sh check arm64
```

Outputs are in `dist/`. `GO`, `DIST_DIR` and `ANDROID_API` can override defaults.
`--nocgo arm64` is for quick compile checks only; use the NDK for release builds.

## Upstream updates

On a clean main branch, run `./scripts/android.sh update vX.Y.Z` with an upstream
stable tag. Resolve conflicts, review Android compatibility and any newly added
upstream workflows, then build and test before pushing and releasing. This command
merges into main and does not create version branches.

See [maintenance notes](docs/android-maintenance.md) for branch consolidation details.

## Credits and license

- [Tailscale Inc. and contributors](https://github.com/tailscale/tailscale)
- [anasfanani's Android port](https://github.com/anasfanani/tailscale-android-cli)
- [Original upstream README](README.upstream.md)

[BSD 3-Clause License](LICENSE). Original copyright and contribution history are retained.
