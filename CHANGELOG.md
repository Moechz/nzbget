# Changelog

All notable user-visible changes to the NZBGet TOS application package.

## 26.3-6 — 2026-11-25

Remediation of the App Center listing review of 26.3-5 (x86_64). One version
covers both architectures; port 8017 is unchanged.

### Security / CVE (T1)
- Image upgraded `linuxserver/nzbget:26.3.20261106` (LinuxServer `v26.3-ls271`,
  Alpine 3.24.3) → `linuxserver/nzbget:26.3.20261120` (LinuxServer `v26.3-ls273`,
  Alpine 3.24.4), which carries the updated base-system packages for the CVE
  scan report. NZBGet itself is 26.3, the current upstream stable release; the
  multi-arch index digest is recorded in `NOTICE.md`.

### Credentials (T2)
- The image's default configuration ships `ControlPassword=tegbzn6789` and a
  dummy news server (`my.newsserver.com`, user `user`, password `pass`). The
  wrapper now removes both: the dummy server is deactivated and cleared, and a
  random 32-hex-character control password is generated on first start (or once
  on upgrade from a build that still used the shipped default) and printed in
  the container log. `tegbzn6789` is rejected by the running instance.
- `nzbget.conf` is forced to mode 0600 inside a 0700 data directory (it holds
  the news-server and SMTP passwords).

### Privacy and compliance (C3, C4, C5, C6, C8)
- Added `PRIVACY.md`: what is stored and where, every outbound endpoint with the
  data sent and the destination/region (Usenet provider over NNTP, RSS feeds,
  the GitHub extension catalogue, SMTP notifications, user-installed scripts,
  Docker Hub, DNS), retention (including the 3-day rotating log), user rights,
  security measures and the deletion channel.
- Added `NOTICE.md`: verified upstream licence, multi-arch image digests,
  bundled components and licences, trademark and non-affiliation statement.
- `help` in `config.ini`/`tosapp.json` now opens
  `https://github.com/Moechz/nzbget/blob/main/PRIVACY.md`, a public page.
- Documentation corrected to what the container actually writes (config, queue,
  `nzb/`, `tmp/`, `scripts/`, dated log files, `downloads/completed`,
  `downloads/intermediate`) — the previous text claimed logs went to stdout only.
- Declared and documented that a fresh install contacts nothing: the template's
  placeholder news server is removed instead of being left active.

### Description (C9)
- `descript`, `important` and `release_note` rewritten to the delivered
  functionality, and the ASCII semicolons that the store parser treats as an INI
  comment (truncating the description) removed. `zh-cn` and `zh-hk` rewritten
  from scratch instead of the reused copy.

### Runtime hardening (F11, S11)
- `cap_drop: [ALL]` and `no-new-privileges:true` added; non-root `1000:1000`
  unchanged. The entrypoint exports the generated login; the data directory and
  its files are documented for a complete uninstall (Docker packages have no
  uninstall hook).

### Notes
- 26.3-3/4/5 were re-submission builds of the same four files; this entry
  supersedes them.
- Upgrading keeps `/Volume1/DockerAppData/nzbgetdocker/` (settings, queue,
  downloads). The first start after the upgrade generates the new control
  password if the old build's `tegbzn6789` default is still in place; read it
  with `docker logs nzbgetdocker | grep -A3 'web login generated'`.

## 26.3-2 — 2026-11-12

### Changed
- Icon: replaced the letter monogram with a functional vector mark that describes what the app does (the upstream project does not publish a compliant SVG).

## 26.3-1 — 2026-11-09

### Added
- First release. NZBGet (`linuxserver/nzbget:26.3.20261106`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8017 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/nzbgetdocker/`.
