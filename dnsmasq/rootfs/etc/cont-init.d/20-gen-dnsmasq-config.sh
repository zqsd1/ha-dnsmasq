#!/command/with-contenv bashio
# shellcheck shell=bash

#TODO send extra data for /24 to 255.255.255.0

tempio \
  -conf /data/options.json \
  -template /usr/share/tempio/dnsmasq.conf \
  -out /dnsmasq.conf

cat /dnsmasq.conf
