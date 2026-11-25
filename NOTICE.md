# Notices and attributions — NZBGet for TerraMaster TOS 7

**Package:** `nzbgetdocker` 26.3-7
**Upstream project:** NZBGet — <https://github.com/nzbgetcom/nzbget>
**Container image:** `linuxserver/nzbget:26.3.20261120` (Docker Hub, used unmodified)

## 1. Upstream licence (verified)

NZBGet is distributed under the **GNU General Public License, version 2**
(GPL-2.0). The upstream repository's `COPYING` file at the packaged version
(26.3) is the GPL-2.0 text, and the GitHub licence metadata for
`nzbgetcom/nzbget` reports `GPL-2.0`:

- <https://github.com/nzbgetcom/nzbget/blob/v26.3/COPYING>
- Copyright (C) 2005-2026 the NZBGet authors.

The package does not redistribute NZBGet source code or binaries. It pulls the
official LinuxServer.io image from Docker Hub at install time, so the GPL
obligations for the program itself are met by the image publisher; this
repository only contains packaging files (compose file, metadata, language
file, icon, build scripts) under the MIT licence described in section 6.

> **Recorded discrepancy:** the LinuxServer image label
> `org.opencontainers.image.licenses` says `GPL-3.0-only`. The upstream project,
> its `COPYING` file and its GitHub metadata are GPL-2.0, which is the
> authoritative statement for NZBGet itself. The label is reproduced here so
> the difference is not mistaken for a packaging error.

## 2. Container image and immutable digest

The tag was resolved on 2026-11-25 from Docker Hub. It is a multi-architecture
**OCI image index**, so the same tag installs `linux/amd64` on x86_64 NAS models
and `linux/arm64` on aarch64 models:

| Item | Digest |
|---|---|
| `linuxserver/nzbget:26.3.20261120` (OCI image index) | `sha256:217c7028b9d671b34bfb60adcd09f3d6d24761226ec7025b3438eaa55fc0728e` |
| `linux/amd64` manifest | `sha256:fdb0c03ae3349d3ffa6754f50436800d02485e1f9bf22c43c5d5c487d1a9a81b` |
| `linux/arm64` manifest | `sha256:afeced76e2f9d761934cb64cc0c24d72d8a2dd39c95921aa7f6db7b82e8f6ff5` |

The index also carries **in-toto/SLSA provenance attestations** for both
platforms (the `unknown/unknown` entries of the index). Image labels record
`v26.3-ls273`, build date `2026-11-20T22:20:28Z`.

Why the compose file uses the tag and not a single digest: a per-architecture
digest (`...@sha256:fdb0c03a...`) would make the aarch64 package pull an amd64
manifest and fail with `exec format error`. This package ships **one archive per
architecture**, both pointing at the same multi-arch tag, so the tag (a dated,
immutable LinuxServer build) is the correct immutable reference. Maintainers can
re-verify the resolution with:

```bash
docker pull linuxserver/nzbget:26.3.20261120
docker image inspect linuxserver/nzbget:26.3.20261120 --format '{{json .RepoDigests}}'
```

The previous package used `26.3.20261106` (index
`sha256:6f86d5cb17fa12c214e0c699addde8ee5b9622fbafd2f4dc2eb8f89e7251dc49`,
LinuxServer `v26.3-ls271`); see `CHANGELOG.md` for why it was replaced.

## 3. Components bundled inside the upstream image

The image is based on **Alpine Linux 3.24.4** and contains, among others, the
following components. They are included by the upstream image, not added by
this package, and each remains under its own licence and copyright.

| Component | Version in this image | Licence |
|---|---|---|
| NZBGet | 26.3 | GPL-2.0 |
| Alpine Linux base | 3.24.4 | various (Alpine packages) |
| 7-Zip (`/app/nzbget/7za`) | 26.01 | LGPL-2.1-or-later, with the unRAR restriction |
| UnRAR (`/app/nzbget/unrar`) | 7.30 beta 2 | UnRAR freeware licence (free to use, redistribution allowed, no reimplementation of the RAR compressor) |
| OpenSSL | 3.5.9 | Apache-2.0 |
| curl | 8.23.0 | curl licence (MIT-like) |
| libxml2 | 2.13.9 | MIT |
| libxslt | 1.1.43 | MIT |
| Python | 3.14.10 | PSF-2.0 |
| ca-certificates | 20261020 | MPL-2.0 |
| Apprise | 2.3.0 | BSD-2-Clause |
| requests | 2.34.2 | Apache-2.0 |
| s6-overlay (init) | v3 | ISC |

`7za` and `unrar` are used to unpack downloads; `apprise`, `requests` and the
Python runtime are installed by the LinuxServer image for its own tooling. This
package adds no binary of its own: the only code it contributes is
`src/entrypoint.sh`, embedded as the container command.

## 4. Trademarks and affiliation

- **NZBGet** and the NZBGet logo are trademarks of the NZBGet project/authors.
- **LinuxServer.io** and the LinuxServer.io logo are trademarks of LinuxServer.io.
- **TerraMaster** and **TOS** are trademarks of TerraMaster.
- **Docker** and **Docker Hub** are trademarks of Docker, Inc.

This is an independent community package by **Moechz**. It is not affiliated
with, endorsed by or sponsored by the NZBGet authors, LinuxServer.io or
TerraMaster. All trademarks belong to their respective owners and are used only
to describe what the package installs.

## 5. TerraMaster tooling

`TOSAppSelfTestingTool` is an official TerraMaster utility, redistributed here
unmodified for local package validation. It is not part of the application and
is not installed on the NAS; it is used by the build script and by the reviewer.

## 6. Licence of this packaging

The packaging files in this repository (compose file, `config.ini`, language
file, SVG icon, build and verification scripts, documentation) are released
under the **MIT License** — see `LICENSE`. That licence does not cover NZBGet or
the container image, which keep their own licences described above.

## 7. Third-party endpoints

The application's outbound connections (Usenet provider, RSS feeds, extension
catalogue on GitHub, SMTP, user-installed scripts, Docker Hub) are listed with
the data sent and the destination in `PRIVACY.md` §3.
