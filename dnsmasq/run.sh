#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

LOG_LVL="$(bashio::config 'log_level')"
bashio::log.level "${LOG_LVL}
"
CLEANED_UP=false
# SIGTERM-handler this funciton will be executed when the container receives the SIGTERM signal (when stopping)
term_handler(){
    if $CLEANED_UP; then
        return
    fi
    CLEANED_UP=true
	bashio::log.warning "Stopping addon"
    bashio::log.warning "cleanup"
    killall dnsmasq 2>/dev/null || true

    	nmcli connection delete $CONN_NAME 2>/dev/null || true

	exit 0
}

debug_file() {
    local file="$1"

    if [ ! -f "$file" ]; then
        bashio::log.error "File not found: $file"
        return
    fi

    bashio::log.info "===== $file ====="

    while IFS= read -r line; do
        bashio::log.info "$line"
    done < "$file"
}

dry_run(){
    bashio::log.info  "start dry run, make sure to enable debug logs"
    config_dnsmasq
    debug_file /dnsmasq.conf
    exit 0

}

# cidr2mask(){
#     local prefix=$1
#     local shift=$(( 32 - prefix ))
#     local bits
#     # start with 32 bits to 1, shift left to match the /24 , trim extra bits with mask so it stay 32bits
#     bits=$(( 0xffffffff << shift & 0xffffffff ))

#     printf "%d.%d.%d.%d\n" \
#         $(( (bits >> 24) & 0xff )) \
#         $(( (bits >> 16) & 0xff )) \
#         $(( (bits >> 8)  & 0xff )) \
#         $(( bits & 0xff ))
# }

IP_CIDR="$(bashio::config 'ip_cidr')"
CHANNEL=6
CONN_NAME=MatterAP-addon
SSID="$(bashio::config 'ssid')"
PASS="$(bashio::config 'password')"
IFACE="$(bashio::config 'interface')"
HIDDEN="$(bashio::config 'hidden' false)"
DRY_RUN="$(bashio::config 'dry_run' false)"

nmcli_setup(){
        nmcli connection delete $CONN_NAME 2>/dev/null || true
    	nmcli connection add type wifi ifname "$IFACE" con-name "$CONN_NAME" autoconnect yes ssid "$SSID" \
		802-11-wireless.mode ap \
		802-11-wireless.band bg \
		802-11-wireless.channel "$CHANNEL" \
		802-11-wireless.hidden "$HIDDEN" \
        802-11-wireless.powersave 2 \
		wifi-sec.key-mgmt wpa-psk \
		wifi-sec.psk "$PASS" \
		wifi-sec.proto rsn \
		wifi-sec.pairwise ccmp \
		wifi-sec.group ccmp \
        ipv4.method manual \
        ipv4.addresses "$IP_CIDR" \
        ipv4.never-default yes \
        ipv6.method manual \
        ipv6.addresses fd44:44::1/64 \
        ipv6.never-default yes 
}


bashio::log.info "Starting addon"
# Setup signal handlers
trap 'term_handler' SIGTERM
trap 'term_handler' EXIT

if bashio::config.true 'dry_run';then
    dry_run
fi

bashio::log.info "## setup nmcli"
nmcli_setup

bashio::log.info "## Starting dnsmasq daemon"
sleep 5
if bashio::debug ;then
dnsmasq --no-daemon --log-queries -C /dnsmasq.conf
else
dnsmasq -C /dnsmasq.conf
fi
bashio::log.info "setup finished, sleep till the end of the world ....."
sleep infinity &
wait $!
