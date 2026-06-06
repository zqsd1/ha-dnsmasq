#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
echo "Starting ntopng..."

INTERFACE="$(bashio::config 'interface')"
ntopng \
  -i "${INTERFACE}" \
  -w 4000