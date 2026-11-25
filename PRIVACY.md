# Privacy Policy — NZBGet for TerraMaster TOS 7

**Package:** `nzbgetdocker` · **Version:** 26.3-7 · **Effective:** 2026-11-25
**Upstream software:** NZBGet 26.3 (<https://github.com/nzbgetcom/nzbget>, GPL-2.0)
**Container image:** `linuxserver/nzbget:26.3.20261120` (Docker Hub, used unmodified)

This policy describes what this application package stores, where it is stored,
what leaves the NAS, and how you can access, correct or delete it. It covers the
container image above and the TOS packaging around it. NZBGet is a self-hosted
Usenet downloader: the NAS owner is the operator and decides which servers,
feeds, scripts and notifications are configured.

## 1. Who is responsible

The package is published by **Moechz**, an independent community packager, not
by TerraMaster and not by the NZBGet authors. Privacy questions and data
requests: open an issue at <https://github.com/Moechz/nzbget/issues>. There is
no separate analytics or advertising controller, because the package contains
neither.

## 2. What is stored, and where

Everything the application writes lives below the application data directory:

```
/Volume1/DockerAppData/nzbgetdocker/          (host)
├── config/                                    -> /config      (inside the container)
│   ├── nzbget.conf          all settings, plain text, mode 0600 (directory 0700)
│   ├── nzbget-YYYY-MM-DD.log rotating log, RotateLog=3 keeps three days
│   ├── queue/               download queue and history database
│   ├── nzb/                 NZB files you added, until processed or deleted
│   ├── tmp/                 temporary data while downloading/unpacking
│   └── scripts/             extensions and post-processing scripts you install
└── downloads/                                 -> /downloads
    ├── completed/           finished downloads (DestDir)
    └── intermediate/        files being unpacked/verified (InterDir)
```

`nzbget.conf` is the whole configuration and contains, in **plain text**:

| Data | Why it is there |
|---|---|
| Usenet news-server host, port, user name and **password**, TLS/cipher settings | authenticate against the provider you configure |
| Control user name and **control password** (randomly generated on first start) | web UI / API login |
| RSS feed and indexer URLs, and their user names/passwords if you set them | fetch NZBs from feeds |
| E-mail notification server, port, sender, recipient and **SMTP password** (only if you enable notifications) | send notification e-mails |
| News-server level, retention, connection count, categories, paths, script order | the downloader's own settings |

The queue and history database store NZB names, file names, sizes, states and
timestamps of your downloads; NZB contents can include indexer URLs and release
names. Downloaded files live under `downloads/` and are ordinary user files.

Logs (`config/nzbget-YYYY-MM-DD.log` and `docker logs nzbgetdocker`) may contain
news-server host names, download names, paths, IP addresses of clients using the
web UI, and error text. They are ordinary server logs; they are kept as
described in section 6.

## 3. What leaves the NAS (third-party disclosures)

The package contains **no telemetry, analytics, advertising, crash reporting or
account system**, and it does not contact the packager. NZBGet starts with no
active news server: the placeholder server of the upstream template is removed
on first start, so a fresh install makes no download-related request at all. The table lists every
outbound path; only row 6 happens without you configuring something.

| # | Endpoint / service | What is sent | Destination / region | When / default |
|---|---|---|---|---|
| 1 | Your **Usenet provider** over NNTP/NNTPS, e.g. `news.example.com:563` | NNTP `AUTHINFO` user name and password, `GROUP`/`ARTICLE`/`BODY` requests for the message IDs of the NZB, client and TLS handshake data | The provider you configure (region chosen by you) | Only after you add a news server under Settings → News Servers. **None preconfigured.** TLS is on by default (`Server1.Encryption=yes`, certificate verification strict). |
| 2 | **RSS feeds / indexers** you add (any HTTP(S) URL) | HTTP(S) GET of the feed URL, and feed credentials if the URL or options carry them | The host of the URL you entered | Only for feeds you add. **None preconfigured.** |
| 3 | **NZBGet extension catalogue**: `https://raw.githubusercontent.com/nzbgetcom/nzbget-extensions/main/extensions.json`; extension files are then downloaded from the URLs listed there (usually `github.com` / `raw.githubusercontent.com`) | HTTP GET; no account data, only the request itself (your public IP and a standard user agent) | GitHub, Inc. (United States, global CDN) | Only when you open Settings → Extensions and refresh the list, or install an extension. **Nothing is fetched at start-up.** |
| 4 | **E-mail notifications** via your own SMTP server (Settings → E-Mail) | sender and recipient addresses, subject, message body, SMTP user name and password | The SMTP host you configure | Only if you enable e-mail notifications. **Disabled by default.** |
| 5 | **Post-processing / notification scripts** you install under `config/scripts` | Whatever that script sends (for example Sonarr/Radarr API calls, Apprise, Telegram, Pushover, a webhook); the package ships no script | The endpoint the script names | Only for scripts you install. **None installed by default.** |
| 6 | **Docker Hub and its CDN** (`registry-1.docker.io`, `auth.docker.io`, `production.cloudflare.docker.com`) | image name and tag, Docker client version, your public IP, TLS handshake | Docker, Inc. / Cloudflare (United States and edge locations worldwide) | When the image is pulled, i.e. at install and when you update the package. **Unavoidable** for a Docker application; no user or download data is sent. |
| 7 | **Update check** | **None.** NZBGet 26.3 has no version/update service and the package adds none; the search for new package versions is done by the TOS App Center. | — | Never |
| 8 | **Inbound only:** Sonarr, Radarr, nzb360, LunaSea or a browser connect **to** `http://<NAS-IP>:8017/` | your control credentials (HTTP Basic), API calls, NZB uploads | Your LAN, or wherever you connect from | Whenever you or an *arr application uses the API. This is inbound traffic; NZBGet does not call those applications. |
| 9 | **DNS resolver of the NAS** | host names of the endpoints above | Your configured DNS server | Whenever one of the endpoints above is used |

No other host is contacted. If you put the app behind a reverse proxy or a
tunnel, that component's own privacy policy applies to the traffic reaching it.

## 4. What is deliberately not collected

No account, e-mail address or phone number is required. The package has no
analytics SDK, no advertising identifier, no crash reporter, no remote logging,
no "phone home" heartbeat and no usage statistics. It does not read files
outside its two volumes (`/config`, `/downloads`) and has no access to the
Docker socket or to host paths other than those two directories.

## 5. Cookies, sessions and authentication

The web UI authenticates with **HTTP Basic** authentication. It does not set
advertising or cross-site tracking cookies; the browser may cache the
credentials you type, and clearing them is a browser setting. Requests from
`127.0.0.1` (the container's own health check) are allowed without a password by
NZBGet's `AuthorizedIP` default; all other clients must authenticate.

The control password is **generated randomly on first start** and written to
`nzbget.conf`; the well-known default of the upstream image can no longer be
used (the wrapper compares the stored value with the value in the image's own
template and replaces it; the string is not repeated in this package). The generated password is printed once in the container log
(`docker logs nzbgetdocker`) so that you can retrieve it, and you can change it
under Settings → Security.

## 6. Retention

| Data | Retention |
|---|---|
| `nzbget.conf` (servers, credentials, settings) | until you change it or delete the data folder |
| queue and history | kept until you delete the entries in the UI or delete the data folder; the default `KeepHistory=30` drops history records after 30 days |
| NZB files in `config/nzb/` | until NZBGet has processed them (the default archive action is `delete`), or until you delete them |
| rotating log `config/nzbget-YYYY-MM-DD.log` | **3 days** (`RotateLog=3`, the upstream default); older files are deleted automatically |
| `docker logs nzbgetdocker` | until the container is recreated or your Docker log rotation removes them |
| `downloads/completed/`, `downloads/intermediate/` | until you delete them in the UI, in File Manager, or by deleting the data folder |
| installed scripts/extensions in `config/scripts/` | until you uninstall them or delete the data folder |

There is no server-side copy: nothing is uploaded to the packager, so nothing
can be retained by the packager.

## 7. Your rights

You can exercise all of the following directly on the NAS, without asking the
packager:

- **Access** — read `config/nzbget.conf`, the logs and the queue/history in the
  web UI, or open the data folder over SSH/File Manager.
- **Correction** — change any setting in the web UI (Settings), or edit the
  files while the container is stopped.
- **Deletion** — delete individual downloads/history entries in the UI, or
  remove the whole data folder as described in section 9.
- **Portability** — copy `/Volume1/DockerAppData/nzbgetdocker/` to another
  location; it is a complete copy of the application's data (including
  credentials, so treat the copy as a secret).
- **Restriction / objection** — stop the container in the App Center; it then
  processes nothing until you start it again. Removing a news server or a feed
  in the UI immediately stops the corresponding outbound traffic.

Because the operator and the data subject are the same person (the NAS owner),
no separate data-export request procedure is needed. If you believe the package
still handles data incorrectly, use the contact in section 11.

## 8. Security measures

- The container runs as **uid/gid 1000**, never as root; all Linux capabilities
  are dropped (`cap_drop: [ALL]`) and `no-new-privileges` is set.
- No `privileged`, no `network_mode: host`, no Docker socket, no added
  capabilities, no host path besides the two volumes.
- `nzbget.conf` is mode **0600** and its directory mode **0700**, so the
  news-server and SMTP credentials are not readable by other containers or
  users on the NAS.
- The web login is a **per-install random 32-hex-character password**; the
  upstream image's well-known default is removed on first start and rejected by
  the running instance (verified: HTTP 401).
- TLS to the Usenet provider is enabled by default with strict certificate
  verification; turning it off is a deliberate user choice.
- Downloads and configuration never leave the NAS unless you configure a
  server, feed, notification or script that does so.

Residual risks you should know about: the web UI is served over plain HTTP on
the LAN (put a TLS reverse proxy in front before exposing it to the internet),
and the News-Server/SMTP passwords are stored in plain text in `nzbget.conf`
because NZBGet itself reads them from there — protect the data folder and any
backup of it.

## 9. How to delete your data

1. In the TOS App Center, uninstall **NZBGet**. This stops and removes the
   container but **keeps** the data folder (Docker applications have no
   uninstall hook).
2. Delete `/Volume1/DockerAppData/nzbgetdocker/` (File Manager or SSH). This
   removes the configuration with all credentials, the queue/history, the logs
   and every downloaded file.
3. Optionally delete the generated compose directory
   `/Volume1/@apps/DockerEngine/application/nzbgetdocker/` (it contains only the
   compose file, no user data).
4. Delete any backup copies you made of that folder, and clear the saved web
   login in your browser if you asked it to remember the password.

Deleting the container alone does **not** delete anything: the data survives
until step 2. There is no copy on the packager's side to delete.

## 10. Scope

This policy covers the package and the upstream image only. Usenet providers,
indexers, notification services and *arr applications have their own privacy
policies; configure only services you trust.

## 11. Contact and changes

Questions, access/correction/deletion requests and security reports:
<https://github.com/Moechz/nzbget/issues> (public issue tracker).

This policy is versioned with the package. Material changes are described in
`CHANGELOG.md` and in the store release note of the version that introduces
them. The current text always lives at
<https://github.com/Moechz/nzbget/blob/main/PRIVACY.md>.
