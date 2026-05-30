#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

LOG_LVL="$(bashio::config 'log_level')"
bashio::log.level "${LOG_LVL}
"

clean_nftables(){
    nft delete table ip haap_zqsd 2>/dev/null || true
    nft delete table inet filter_haap_zqsd 2>/dev/null || true
    # if  is_masquerading_enabled; then
    #     iptables-nft -t nat -D POSTROUTING -o "$WANFACE" -j MASQUERADE -m comment --comment "ap-addon-inet"
    # fi
    # if is_forwarding_enabled; then
    #     iptables-nft -D FORWARD -i "$IFACE" -o "$WANFACE" -j ACCEPT -m comment --comment "ap-addon-inet"
    #     iptables-nft -D FORWARD -i "$WANFACE" -o "$IFACE" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "ap-addon-inet"
    # fi
    unset_iptables
}
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

    clean_nftables
   
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
WANFACE=end0
if bashio::config.true 'hidden'; then
    HIDDEN=yes
else
    HIDDEN=no
fi
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
        ipv4.never-default yes \
        ipv4.addresses "$IP_CIDR" \
        ipv6.method manual \
        ipv6.never-default yes \
        ipv6.addresses fd44:44::1/64 
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

is_masquerading_enabled() {
    iptables-nft -t nat -C POSTROUTING -o "$WANFACE" -j MASQUERADE -m comment --comment "ap-addon-inet" 2>/dev/null
}

is_forwarding_enabled() {
    iptables-nft -C FORWARD -i "$IFACE" -o "$WANFACE" -j ACCEPT -m comment --comment "ap-addon-inet" 2>/dev/null
}

set_iptables(){
    # Allow AP clients to reach the host itself
    # iptables -I DOCKER-USER 1 -s 192.168.99.0/24 -d 192.168.1.1 -j ACCEPT

    # Block access to the rest of the LAN
    iptables -I DOCKER-USER 2 -s 192.168.99.0/24 -d 192.168.1.0/24 -j DROP

    # Allow AP -> Internet forwarding
    iptables -I DOCKER-USER 3 -i "$IFACE" -o "$WANFACE" -j ACCEPT

    # Allow return traffic from Internet
    iptables -I DOCKER-USER 4 -i "$WANFACE" -o "$IFACE" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

    # NAT AP clients to the Internet
    iptables -t nat -A POSTROUTING -s 192.168.99.0/24 -o "$WANFACE" -j MASQUERADE
}
unset_iptables(){
    # iptables -D DOCKER-USER -s 192.168.99.0/24 -d 192.168.1.1 -j ACCEPT

    iptables -D DOCKER-USER -s 192.168.99.0/24 -d 192.168.1.0/24 -j DROP

    iptables -D DOCKER-USER -i "$IFACE "-o "$WANFACE" -j ACCEPT

    iptables -D DOCKER-USER -i "$WANFACE" -o "$IFACE" -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

    iptables -t nat -D POSTROUTING -s 192.168.99.0/24 -o "$WANFACE" -j MASQUERADE
}

if bashio::config.true 'enable_nftables';then
    bashio::log.info "## Starting nftables"
    # clean_nftables
    sed -i \
		-e "s/wlan0/$IFACE/g" \
        -e "s/end0/$WANFACE/g" \
        /nftables.conf
    # nft -f /nftables.conf
    # nft list ruleset
    # if ! is_masquerading_enabled; then
    #     iptables-nft -t nat -A POSTROUTING -o "$WANFACE" -j MASQUERADE -m comment --comment "ap-addon-inet"
    # fi
    # if ! is_forwarding_enabled; then
    #     iptables-nft -A FORWARD -i "$IFACE" -o "$WANFACE" -j ACCEPT -m comment --comment "ap-addon-inet"
    #     iptables-nft -A FORWARD -i "$WANFACE" -o "$IFACE" -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "ap-addon-inet"
    # fi
    set_iptables
fi

if bashio::config.true 'enable_dns';then
    bashio::log.info "## Starting dnsmasq daemon"

    if [[ $IFACE != "wlan0" ]];then
        bashio::log.info "## rename interface "
        sed -i \
            -e "s/wlan0/$IFACE/g" /dnsmasq.conf
    fi
    sleep 5
    if bashio::debug ;then
        dnsmasq --no-daemon --log-queries -C /dnsmasq.conf
    else
        dnsmasq -C /dnsmasq.conf
    fi
fi
bashio::log.info "setup finished, sleep till the end of the world ....."
# tcpdump -i "$IFACE"
sleep infinity &
wait $!
