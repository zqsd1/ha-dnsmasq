#!/bin/sh

echo "# HELP host_upload_bytes_total Host upload bytes"
echo "# TYPE host_upload_bytes_total counter"

iptables -L TRAFFIC_MONITOR -v -n -x | awk '
/RETURN/ {
    bytes=$2
    ip=$8
    printf "host_upload_bytes_total{ip=\"%s\"} %s\n", ip, bytes
}'