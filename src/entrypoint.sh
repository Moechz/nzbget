#!/bin/sh
# ===========================================================================
# NZBGet entrypoint wrapper for the TerraMaster TOS 7 package.
#
# The upstream image boots with the s6-overlay v3 init, whose service manager
# runs as root; with user "1000:1000" nothing starts and port 6789 stays
# closed. TOS forbids root containers, so this wrapper performs the same
# first-run setup as the image's init script and runs the same command the s6
# service runs, directly as the unprivileged container user.
#
# It also removes the credentials the upstream image ships in its default
# configuration: the well-known control password and the dummy news-server
# account of the template. On first start, and once when upgrading from a
# package that still used the shipped default, a random web login is generated,
# written to nzbget.conf (mode 0600) and printed once in the container log. The
# dummy server is deactivated so a fresh install never tries to reach the
# placeholder hostname. The values are read from the image's own template, so
# this package itself contains no credential.
# ===========================================================================
set -u

CONFIG_DIR=/config
DOWNLOAD_DIR=/downloads
CONF="$CONFIG_DIR/nzbget.conf"
TEMPLATE=/app/nzbget/share/nzbget/nzbget.conf

mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR"

conf_get() {
  # first value of a top-level key, empty when the key is absent
  sed -n "s/^$1=//p" "$CONF" 2>/dev/null | head -n 1
}

template_get() {
  # same, read from the upstream template that ships inside the image
  sed -n "s/^$1=//p" "$TEMPLATE" 2>/dev/null | head -n 1
}

conf_set() {
  # replace the first occurrence of key=..., append the key when it is absent
  key=$1
  value=$2
  if grep -q "^${key}=" "$CONF" 2>/dev/null; then
    awk -v k="$key" -v v="$value" '
      index($0, k "=") == 1 { if (!done) { print k "=" v; done = 1 } ; next }
      { print }
    ' "$CONF" > "$CONF.new" && mv "$CONF.new" "$CONF"
  else
    printf '%s=%s\n' "$key" "$value" >> "$CONF"
  fi
}

generate_password() {
  # 32 hex characters from the kernel CSPRNG, no config file needed
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 16
  else
    od -An -N16 -tx1 /dev/urandom | tr -d ' \n'
  fi
}

first_run=no
if [ ! -f "$CONF" ]; then
  if ! cp "$TEMPLATE" "$CONF"; then
    echo "FATAL: cannot seed $CONF from $TEMPLATE"
    exit 1
  fi
  first_run=yes
fi

# --- drop the dummy news server shipped in the template --------------------
# The value is read from the image's own template, so no placeholder host or
# dummy account name is hard-coded in this package.
template_host=$(template_get Server1.Host)
if [ -n "$template_host" ] && [ "$(conf_get Server1.Host)" = "$template_host" ]; then
  conf_set Server1.Active no
  conf_set Server1.Host ""
  conf_set Server1.Username ""
  conf_set Server1.Password ""
fi

# --- never keep the control password the image ships -----------------------
# The well-known default is compared against the image's template instead of
# being written down here, so the package itself carries no credential.
template_password=$(template_get ControlPassword)
password=$(conf_get ControlPassword)
if [ "$first_run" = yes ] || [ -z "$password" ] \
   || { [ -n "$template_password" ] && [ "$password" = "$template_password" ]; }; then
  password=$(generate_password)
  conf_set ControlPassword "$password"
  [ -n "$(conf_get ControlUsername)" ] || conf_set ControlUsername nzbget
  echo "--------------------------------------------------------------"
  echo " NZBGet web login generated for this installation"
  echo "   user      $(conf_get ControlUsername)"
  echo "   password  $password"
  echo " Stored in /config/nzbget.conf (ControlPassword, mode 0600)."
  echo " Change it in Settings -> Security. Show it again with:"
  echo "   docker logs nzbgetdocker | grep -A3 'web login generated'"
  echo "--------------------------------------------------------------"
fi

# The configuration file holds the news-server and control credentials: keep
# it private to uid 1000 and make the directory non-traversable for other
# container users, so a rewritten config cannot leak to a second application.
chmod 600 "$CONF" 2>/dev/null || true
chmod 700 "$CONFIG_DIR" 2>/dev/null || true

# A stale lock from a killed container would make NZBGet refuse to start.
rm -f "$CONFIG_DIR/nzbget.lock"

export HOME=$CONFIG_DIR
export TZ="${TZ:-Asia/Shanghai}"

exec /app/nzbget/nzbget -s -c "$CONF" -o OutputMode=log
