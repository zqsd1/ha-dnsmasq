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



bashio::log.info "Starting addon"
# Setup signal handlers
trap 'term_handler' SIGTERM
trap 'term_handler' EXIT

if bashio::config.true 'dry_run';then
    dry_run
fi

bashio::log.info "## Starting dnsmasq daemon"

if [[ "${LOG_LVL}" == "debug" ]];then
dnsmasq --no-daemon --log-queries -C /dnsmasq.conf
else
dnsmasq -C /dnsmasq.conf
fi
bashio::log.info "setup finished, sleep till the end of the world ....."
sleep infinity &
wait $!
