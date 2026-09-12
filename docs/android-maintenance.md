# Android fork maintenance

## 2026-09-12 migration

Upstream stable release: v1.102.4, released 2026-09-10.
Source: https://github.com/tailscale/tailscale/releases/tag/v1.102.4

The former default branch, 1.98.8-android-dev (d6a741131), contains the cumulative
Android patch on top of v1.98.8. That commit explicitly squashes the 1.98.5 Android
series. Earlier branches include repeated rebases/squashes of the same port.

| Former branch | Tip | Disposition |
| --- | --- | --- |
| 1.64.0-android | b22d8df9c | Ancestor of the 1.82.5 development history |
| 1.76.6-android | 8a4bd556d | Ancestor of the 1.82.5 development history |
| 1.82.5-android | 8bc9dc2aa | Ancestor of 1.82.5-dev |
| 1.82.5-dev | e56e5b394 | SSH, user lookup, paths and logs carried forward |
| 1.90.4-android-dev | 52a315171 | DNS, routes, certificates and updater carried forward |
| 1.90.6-android-dev | c2d89f9dc | Connectivity and PeerAPI fixes carried forward |
| 1.98.5-android-dev | f9ab4ef74 | Cumulative port squashed into d6a741131 |
| 1.98.8-android-dev | d6a741131 | Integration starting point |
| main | e0677ccc7 | Already an ancestor of v1.102.4 |

The integration merge uses the v1.102.4 tree plus the cumulative v1.98.8 Android
delta. This avoids reintroducing older release-branch backports whose commit IDs
differ from upstream main. Four patch conflicts were resolved in daemon flags,
SSH incubation, firewall marks and router imports. Historical squashed branches
are joined with history-only merges after their changes are accounted for; all
original tips remain reachable from main. Full Git bundles and the original
uncommitted Magisk settings patch were saved outside both repositories first.

Compatibility decisions:

- Preserve v1.102.4 SSH client-environment isolation and inherited-file forwarding.
  Do not copy the daemon's full environment into the privileged SSH child.
  Provide a specific Android executable search path instead.
- Scope Android firewall marks to Android. Keep upstream native-endian encoding
  and the original constants on other operating systems.
- Keep DNS, routing, SSH, Taildrop, certificates, Android user lookup, default
  state paths, and combined CLI support from the cumulative port.
- Migrate binary updates to zym013579/tailscale-android-cli.
- Use standard Go and NDK r27c. Remove automatic UPX packing and machine-wide
  tool installation from the build script.
- Keep main as the only development branch and use tags for releases.

Build checks do not substitute for installation and network validation on a
physical rooted Android device.
