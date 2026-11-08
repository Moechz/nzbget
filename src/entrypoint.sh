#!/bin/sh
# ===========================================================================
# NZBGet entrypoint wrapper for the TerraMaster TOS 7 package.
#
# The upstream image boots with the s6-overlay v3 init, whose service manager
# runs as root; with user "1000:1000" nothing starts and port 6789 stays
# closed. TOS forbids root containers, so this wrapper performs the same
# first-run setup as the image's init script and runs the same command the s6
# service runs, directly as the unprivileged container user.
# ===========================================================================
set -u

CONFIG_DIR=/config
DOWNLOAD_DIR=/downloads

mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR"

# First-run configuration, copied from the image defaults (never overwritten).
if [ ! -f "$CONFIG_DIR/nzbget.conf" ]; then
  cp /app/nzbget/share/nzbget/nzbget.conf "$CONFIG_DIR/nzbget.conf" 2>/dev/null || true
fi

# A stale lock from a killed container would make NZBGet refuse to start.
rm -f "$CONFIG_DIR/nzbget.lock"

export HOME=$CONFIG_DIR
export TZ="${TZ:-Asia/Shanghai}"

exec /app/nzbget/nzbget -s -c "$CONFIG_DIR/nzbget.conf" -o OutputMode=log
