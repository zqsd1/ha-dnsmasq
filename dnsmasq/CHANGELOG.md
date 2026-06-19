# Changelog

## [0.1.16] 2026-06-19
healcheck and persistance test

## [0.1.15] 2026-05-29
allow to send directly to dns server

## [0.1.14] 2026-05-29
allow change of dns server
use default for ra advertising timings

## [0.1.13] 2026-05-29
try deny access to other lan

## [0.1.12] 2026-05-29
nftables doesnt works,going back to iptables script
add switch to turn off dnsmasq so i can use external adguard

## [0.1.11] 2026-05-29
try new nftables setup

## [0.1.9] 2026-05-29
added table ip beacause masquerade not enough
dns server=1.1.1.1 only allow resolve not accesswebsite
try remove home.arpa by just home

## [0.1.8] 2026-05-29
start implement nftables so i can set wan access

## [0.1.7] 2026-05-23
correctly hide ssid ?

## [0.1.7] 2026-05-23
rename interface in dnsmasq if iface not wlan0

## [0.1.6] 2026-05-23
added option to hide ssid

## [0.1.5] 2026-05-23
and going back again with nmcli because nmcli fail on reboot on the host
it rebuild the connection created with client mode and change its name

## [0.1.4] 2026-05-23
activate logs for dnsmasq in debug

## [0.1.3] 2026-05-23
readed config parameter for log and dry run

## [0.1.2] 2026-05-23
fix dockerfile add command

## [0.1.1] 2026-05-23
try to make the addon appear by removing empty variable setting
