# nzbget-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [NZBGet](https://github.com/nzbgetcom/nzbget).

## What this is

A four-file TOS Docker application archive (`nzbgetdocker.tar.gz`) that installs
NZBGet on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `nzbgetdocker`)
- `nzbgetdocker.lang` — 23-language superset (TOS requires 14)
- `nzbgetdocker.svg` — application icon (326 bytes, 2 SVG elements)
- `docker-compose.yml` — one service, image `linuxserver/nzbget:26.3.20261106`

## How it works

| | |
|---|---|
| Container image | `linuxserver/nzbget:26.3.20261106` (Docker Hub, used unmodified) |
| Open | `http://<NAS-IP>:8017/` (container port 6789) |
| Runs as | non-root, `user: "1000:1000"` |
| Persistent data | `/config` → `/Volume1/DockerAppData/nzbgetdocker/config`, `/downloads` → `/Volume1/DockerAppData/nzbgetdocker/downloads` |
| Logs | `docker logs nzbgetdocker` (stdout/stderr) |

`config/` holds `nzbget.conf` (servers, paths, categories, control login), the queue database, `queue/`, `tmp/` and the logs; `downloads/` receives the finished files. Copying the `nzbgetdocker` folder is a complete backup.

## Design highlights

- **Non-root.** `user: "1000:1000"`; verified on real hardware (the container reports uid 1000).
- **Entrypoint wrapper** (not a privilege shim): the s6 service manager of the image needs root, so `src/entrypoint.sh` seeds the default `nzbget.conf` and starts NZBGet directly as the unprivileged container user.
- **Fixed image tag, never `:latest`**, Docker Hub only, no `privileged`, no `network_mode: host`, and no Docker socket, no `cap_add`.
- **Health check** probing the service on container port 6789.
- **Deterministic build**: GNU tar with uid/gid 0 and zeroed timestamps, gzip without a timestamp, plus the review-standards self-check above.
- **Non-root by construction.** The s6 service manager of the image needs root, so the wrapper seeds the default config and starts the NZBGet binary directly as `1000:1000`; verified on real hardware.
- **Fixed image tag `26.3.20261106`** (NZBGet publishes dated builds), Docker Hub only, no `privileged`, no `network_mode: host`, no `cap_add`, no Docker socket.
- **Health check** on the UI (`GET /` on port 6789) with a 60 s start period.

## Runtime file manifest

Everything the application writes on the NAS lives inside its own data
directory; the container-internal `/tmp` is discarded with the container. The
table lists what is created and how it behaves. Nothing else is written.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `config/nzbget.conf` | all settings - Usenet servers, folders, categories, control login | first start | static, rewritten on every settings change | never overwritten after the first run; it is the whole configuration |
| `config/queue` | download queue and history database | first start | grows with the queue and history | managed by NZBGet; safe to prune from the UI |
| `config/tmp` | temporary files while downloading and unpacking | first start | bounded by the active downloads | safe to delete when NZBGet is stopped |
| `downloads` | finished downloads | first start (empty) | grows with every download | managed by NZBGet and by you |

## Build

```bash
scripts/build.sh                  # -> out/nzbgetdocker.tar.gz + .sha256
scripts/build.sh 26.3-2   # packaging iteration bump
scripts/build.sh 26.3-1 aarch64
```

The build stages the four files, substitutes the version/platform placeholders,
embeds `src/entrypoint.sh` into the compose file (escaping every `$` as `$$`), removes CRLF/BOM/AppleDouble, then runs
`tools/verify.py`, a review-standards self-check (archive layout, JSON validity,
required fields, 14+ language coverage, version consistency, Docker-Hub-only
images, fixed tag, reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data path below the application data root, never the
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets and the SVG size/element limits).

## Local verification

```bash
./TOSAppSelfTestingTool -c out/nzbgetdocker.tar.gz   # official spec check
bash test/install-and-verify.sh                  # on-device E2E (needs root)
```

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission checklist

1. Public GitHub repo (code + README only).
2. Release **tag `v26.3-1`**, assets `nzbgetdocker.tar.gz` +
   `nzbgetdocker.tar.gz.sha256` (Docker asset naming: `<app_id>.tar.gz`, **no
   platform suffix**).
3. Developer platform → Add Application: ID `nzbgetdocker`, package type Docker,
   repository URL, architecture `x86_64`.
4. Version Management → Add Version `26.3-1` → automated validation → review.

## License / branding

NZBGet is distributed by its upstream authors under **GPL-2.0**. The container image is the official image from Docker Hub (`linuxserver/nzbget:26.3.20261106`) and is used unmodified; no upstream source code is redistributed here. This packaging is an independent community submission by Moechz and is not affiliated with the upstream project or TerraMaster.

## Limitations

NZBGet has no default web login: anyone on your LAN can open it. Set ControlUsername and ControlPassword in `nzbget.conf` (or Settings → Security) before exposing the port.
TOS Docker applications cannot mount shared folders: downloads stay in `/Volume1/DockerAppData/nzbgetdocker/downloads/`. Move them out with File Manager, or edit `/Volume1/@apps/DockerEngine/application/nzbgetdocker/docker-compose.yml` after installation.
The UI is served over plain HTTP on the LAN. Do not expose the published port to the internet without a TLS reverse proxy.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
