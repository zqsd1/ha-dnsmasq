#!/command/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Netdata paths and config under /data (persistent)
# ==============================================================================
set -euo pipefail

ND_PORT="$(bashio::config netdata_port)"
ND_ALLOW="$(bashio::config allow_from)"
ND_MODE="$(bashio::config memory_mode)"
ND_RETENTION="$(bashio::config retention_mb)"
ND_EVERY="$(bashio::config update_every)"
ND_HOME="/data/netdata"
ND_ETC="${ND_HOME}/etc"
ND_CACHE="${ND_HOME}/cache"
ND_LIB="${ND_HOME}/lib"

# Alpine packages install the dashboard under webapps, not /usr/share/netdata/web
if [ -d /usr/share/webapps/netdata ]; then
  ND_WEB="/usr/share/webapps/netdata"
elif [ -d /usr/share/netdata/web ]; then
  ND_WEB="/usr/share/netdata/web"
else
  bashio::log.warning "Netdata web UI directory not found; defaulting to Alpine path"
  ND_WEB="/usr/share/webapps/netdata"
fi

mkdir -p "${ND_ETC}" "${ND_CACHE}" "${ND_LIB}" "${ND_ETC}/go.d" "${ND_ETC}/python.d"

# Seed defaults from package if present
if [ -d /etc/netdata ] && [ ! -f "${ND_ETC}/netdata.conf" ]; then
  cp -a /etc/netdata/. "${ND_ETC}/" 2>/dev/null || true
fi

cat >"${ND_ETC}/netdata.conf" <<EOF
[global]
    run as user = root
    web files owner = root
    web files group = root
    memory mode = ${ND_MODE}
    page cache size = ${ND_RETENTION}
    dbengine disk space MB = ${ND_RETENTION}
    update every = ${ND_EVERY}
    bind to = 0.0.0.0

[web]
    bind to = 0.0.0.0:${ND_PORT}
    allow connections from = ${ND_ALLOW}
    enable gzip compression = yes

[directories]
    config = ${ND_ETC}
    stock config = /usr/lib/netdata/conf.d
    log = ${ND_LIB}
    plugins = /usr/libexec/netdata/plugins.d
    web = ${ND_WEB}
    cache = ${ND_CACHE}
    lib = ${ND_LIB}

[plugins]
    cgroup = no
    tc = no
    idlejitter = yes
    enable running new plugins = yes
    check for new plugins every = 60

[plugin:proc]
    proc path = /proc
    sys path = /sys
    disks path = /proc/diskstats
EOF

# Optional Netdata Cloud claim (one-time)
CLAIM_FILE="${ND_LIB}/.claim_done"
if bashio::config.true "enable_cloud_claim" && [ ! -f "${CLAIM_FILE}" ]; then
  TOKEN="$(bashio::config claim_token)"
  ROOMS="$(bashio::config claim_rooms)"
  URL="$(bashio::config claim_url)"
  if [ -n "${TOKEN}" ] && [ -n "${ROOMS}" ]; then
    bashio::log.info "Claiming node to Netdata Cloud..."
    if netdata-claim.sh -token="${TOKEN}" -rooms="${ROOMS}" -url="${URL}" -id="$(hostname)" 2>/dev/null; then
      touch "${CLAIM_FILE}"
      bashio::log.info "Netdata Cloud claim succeeded"
    else
      bashio::log.warning "Netdata Cloud claim failed (check token/rooms)"
    fi
  fi
fi

bashio::log.info "Netdata ready on port ${ND_PORT} (web ${ND_WEB})"