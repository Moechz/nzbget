# nzbget-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [NZBGet](https://github.com/nzbgetcom/nzbget) 26.3.

## What this is

A four-file TOS Docker application archive (`nzbgetdocker.tar.gz`) that installs
NZBGet on TOS 7 through the App Center:

- `config.ini` — TOS application metadata (`application_type: docker`, id `nzbgetdocker`)
- `nzbgetdocker.lang` — 23-language superset (TOS requires 14)
- `nzbgetdocker.svg` — application icon
- `docker-compose.yml` — one service, image `linuxserver/nzbget:26.3.20261120`

NZBGet is a lightweight Usenet downloader written in C++: it fetches NZBs from
the news server you configure, verifies and repairs them with PAR2, unpacks the
result with 7-Zip/UnRAR and keeps a queue you manage from a web UI. This package
runs the official LinuxServer.io image unmodified, as a non-root container, with
all persistent data below the application data folder.

## Repository layout

```
.
├── src/                     files that go into the package
│   ├── config.ini           TOS App Center metadata (help -> PRIVACY.md)
│   ├── nzbgetdocker.lang    23-language descriptions (max 512 chars each)
│   ├── nzbgetdocker.svg     icon
│   ├── docker-compose.yml   service definition (image, port, volumes, hardening)
│   └── entrypoint.sh        wrapper: first-run setup + credential handling
├── specs/nzbget.yaml        source spec (tosdocker format, regenerates the project)
├── scripts/build.sh         package one architecture: stage -> verify -> tar.gz
├── scripts/build-dual.sh    build x86_64 + aarch64 and run the official check
├── tools/verify.py          review-standards self-check (hard gate for the build)
├── test/install-and-verify.sh  on-device end-to-end check (needs root; not run here)
├── PRIVACY.md               privacy policy (linked from the app's help field)
├── NOTICE.md                licences, image digests, trademarks
├── CHANGELOG.md             one entry per packaged version
├── LICENSE                  MIT for the packaging + third-party notices
└── TOSAppSelfTestingTool    official TerraMaster checker (used by the build)
```

## How it works

| | |
|---|---|
| Container image | `linuxserver/nzbget:26.3.20261120` (Docker Hub, used unmodified, multi-arch) |
| Open | `http://<NAS-IP>:8017/` (container port 6789) |
| Runs as | non-root, `user: "1000:1000"`, `cap_drop: [ALL]`, `no-new-privileges` |
| Persistent data | `/config` → `/Volume1/DockerAppData/nzbgetdocker/config`, `/downloads` → `/Volume1/DockerAppData/nzbgetdocker/downloads` |
| Logs | `docker logs nzbgetdocker` plus `config/nzbget-YYYY-MM-DD.log` (3-day rotation) |
| Web login | user `nzbget`, **random password generated on first start** |
| Network | one published port, no `network_mode: host`, no Docker socket |

The upstream image starts its own s6-overlay v3 supervisor as root; that cannot
run inside a non-root container, so `src/entrypoint.sh` performs the same
first-run setup (seed `nzbget.conf`, drop a stale lock) and starts
`/app/nzbget/nzbget` directly as uid 1000. It also removes the credentials the
image ships in its template — `ControlPassword=tegbzn6789` and the dummy news
server `user`/`pass` on `my.newsserver.com` — and generates a random control
password instead.

## First start and the web login

On the first start the wrapper generates a 32-hex-character control password,
writes it to `config/nzbget.conf` (mode 0600, directory 0700) and prints it once:

```bash
docker logs nzbgetdocker | grep -A3 'web login generated'
```

Sign in with user `nzbget` and that password, then change it under
**Settings → Security**. The password survives restarts and updates; it is
generated only when the file has no password or still contains the upstream
default. Because NZBGet answers unauthenticated requests from `127.0.0.1` by
default (`AuthorizedIP=127.0.0.1`, used by the health check), only remote
clients are asked to log in.

## Adding your Usenet provider

A fresh install has **no active news server** (the placeholder is removed on
purpose, so nothing is contacted before you configure it). NZBGet therefore logs
`At least one server must be active` at start-up until you add one — that is
expected and harmless. Open the web UI → **Settings → News Servers**, fill in
host, port, user name and password, keep TLS on for port 563, then **Save &
reload**. Optional: RSS feeds under **Settings → RSS Feeds**, notifications under
**Settings → E-Mail**, extensions under **Settings → Extensions** (fetches its
catalogue from GitHub, see `PRIVACY.md`).

## Runtime files

Everything the application writes lives inside its own data directory; the
container-internal `/tmp` is discarded with the container.

| Path | Purpose | Created when | Growth bound | Lifecycle |
|---|---|---|---|---|
| `config/nzbget.conf` | all settings — news servers, control login, feeds, notifications, paths | first start | static, rewritten on every settings change | never overwritten after the first run; it is the whole configuration |
| `config/nzbget-YYYY-MM-DD.log` | rotating server log | first start | 3 daily files (`RotateLog=3`) | older files deleted automatically |
| `config/queue/` | download queue and history database | first start | grows with the queue and history | managed by NZBGet; history records age out after 30 days (`KeepHistory=30`) |
| `config/nzb/` | NZB files you added | when you add an NZB | one file per NZB | deleted after processing (`NzbDirArchiveAction=delete`) |
| `config/tmp/` | temporary data while downloading and unpacking | first start | bounded by the active downloads | safe to delete when NZBGet is stopped |
| `config/scripts/` | extensions and post-processing scripts you install | when you install one | one directory per script | remove through the UI or delete the directory |
| `downloads/completed/` | finished downloads (`DestDir`) | first start (empty) | grows with every download | managed by NZBGet and by you |
| `downloads/intermediate/` | files being unpacked/verified (`InterDir`) | first start (empty) | bounded by active downloads | empty when the queue is idle |

## Data & uninstall

Docker applications have **no uninstall hook**: uninstalling in the App Center
removes the container but keeps the data folder, and the data must be deleted
explicitly.

1. App Center → NZBGet → **Uninstall** (container removed, data kept).
2. Delete `/Volume1/DockerAppData/nzbgetdocker/` — configuration with the
   news-server and SMTP passwords, queue/history, logs and downloads.
3. Optionally delete `/Volume1/@apps/DockerEngine/application/nzbgetdocker/`
   (generated compose file only).
4. Delete any backup of the folder; clear the saved web login in your browser.

Back up by copying the whole `/Volume1/DockerAppData/nzbgetdocker/` folder while
the app is stopped — that copy contains credentials, so store it accordingly.
Downloads stay below `DockerAppData` because TOS Docker applications cannot mount
shared folders; move finished files out with File Manager or a scheduled job.

## Privacy

The application stores its configuration, queue/history, logs and downloads only
on your NAS. It contains no telemetry, analytics, advertising or crash
reporting, and it does not contact the packager. Outbound connections happen
only to endpoints **you** configure — your Usenet provider (NNTP/NNTPS with
credentials), RSS feeds/indexers, your SMTP server, scripts you install — plus
the NZBGet extension catalogue on GitHub (only when you open the Extensions
page) and the Docker Hub image pull at install/update. Nothing is preconfigured
and no update check is performed.

The full disclosure — what is stored where, every endpoint with the data sent
and the destination/region, retention, user rights, security measures and the
deletion channel — is in **[PRIVACY.md](PRIVACY.md)**, which is also the target
of the app's `help` field (`config.ini`).

## Notices

NZBGet is **GPL-2.0** (verified against the upstream `COPYING` file; the
LinuxServer image label records GPL-3.0-only, see `NOTICE.md` §1). The container
image is the official multi-arch image from Docker Hub, used unmodified and not
redistributed here. Alpine Linux 3.24.4, 7-Zip 26.01, UnRAR 7.30 beta 2,
OpenSSL 3.5.9, Python 3.14.10, Apprise 2.3.0 and the s6-overlay init keep their
own licences. NZBGet, LinuxServer.io, TerraMaster and Docker are trademarks of
their owners; this is an independent community package, not affiliated with any
of them. The packaging itself is MIT. Details, image digests and the full
component list: **[NOTICE.md](NOTICE.md)**.

## Build

```bash
scripts/build.sh                     # current version from tosapp.json, x86_64
scripts/build.sh 26.3-6 aarch64      # one architecture, explicit version
scripts/build-dual.sh 26.3-6         # both architectures + official check
```

`build.sh` stages the four files, substitutes `@@VERSION@@`/`@@PLATFORM@@`,
embeds `src/entrypoint.sh` into the compose block scalar (escaping every `$` as
`$$`), removes CRLF/BOM/AppleDouble files, writes a deterministic tar.gz
(uid/gid 0, zeroed mtimes, gzip without timestamp) and runs `tools/verify.py`,
the review-standards self-check: archive layout, JSON validity, required fields,
14+ language coverage, version consistency, Docker-Hub-only images, fixed tag,
reserved/recommended host ports, non-root user, per-service
healthcheck/TZ/restart, data paths below the application data root, no
`/Volume*` wildcard, comment-free sequence blocks, `x-app-meta` position, no
literal secrets, the embedded entrypoint matching `src/entrypoint.sh`, and the
SVG size/element limits.

## Local verification

```bash
./TOSAppSelfTestingTool -c out/nzbgetdocker.tar.gz   # official spec check
python3 ../stage.py . --timeout 300                  # isolated runtime check
```

`stage.py` (in the parent workspace) extracts the package, rewrites the compose
file to a free loopback port and a staging data directory, brings it up, waits
for the health check, asserts the HTTP answer and the non-root user, then tears
everything down. It never touches production data or the production port.

> Docker applications cannot be side-loaded through the App Center's manual
> install page (it accepts `.deb` only); the official self-testing tool's `-i`
> mode or `docker compose` are the only ways to install one for testing.

## Store submission

1. Public GitHub repo (packaging code + docs).
2. Release tag `v26.3-6` with assets `nzbgetdocker_x86_64.tar.gz` +
   `.sha256` and `nzbgetdocker_aarch64.tar.gz` + `.sha256`.
3. Developer platform: app id `nzbgetdocker`, package type Docker, repository
   URL, one App record per architecture.
4. Version `26.3-6` for `x86_64` and for `aarch64`, then review.

## Limitations

- A fresh install has no news server; NZBGet logs `At least one server must be
  active` until you add one under Settings → News Servers.
- The web UI is served over plain HTTP on the LAN. Put a TLS reverse proxy in
  front before exposing the published port to the internet.
- TOS Docker applications cannot mount shared folders: downloads stay in
  `/Volume1/DockerAppData/nzbgetdocker/downloads/`. Move them out with File
  Manager or edit the generated compose file after installation.
- The web login is generated per install and printed in the container log; if
  you lose it, read `config/nzbget.conf` (`ControlPassword`) or reset it there.

---

Packaged for TOS 7 by Moechz. Upstream image used unmodified from Docker Hub.
