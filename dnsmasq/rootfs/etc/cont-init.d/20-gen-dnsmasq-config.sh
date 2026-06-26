#!/command/with-contenv bashio
# shellcheck shell=bash

#TODO send extra data for /24 to 255.255.255.0
DHCP_RANGE_MASK=cidr2mask "$(bashio::config 'ip_cidr')"

# jq --arg mask "$DHCP_RANGE_MASK" \
#   '.netmask = $mask' \
#   /data/options.json > /tmp/options.json

tempio \
  -conf /data/options.json \
  -template /usr/share/tempio/dnsmasq.conf \
  -out /dnsmasq.conf

cat /dnsmasq.conf
