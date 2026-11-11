# Changelog

All notable user-visible changes to the NZBGet TOS application package.

## 26.3-2 — 2026-11-12

### Changed
- Icon: replaced the letter monogram with a functional vector mark that describes what the app does (the upstream project does not publish a compliant SVG).

## 26.3-1 — 2026-11-09

### Added
- First release. NZBGet (`linuxserver/nzbget:26.3.20261106`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8017 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/nzbgetdocker/`.
