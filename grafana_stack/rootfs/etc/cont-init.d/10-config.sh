#!/command/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Render Prometheus / Blackbox / Grafana configs into /data
# ==============================================================================
set -euo pipefail

PROM_DIR="/data/prometheus"
GRAFANA_DIR="/data/grafana"
BLACKBOX_DIR="/data/blackbox"
PROM_PORT="$(bashio::config prometheus_port)"
BLACKBOX_PORT="$(bashio::config blackbox_port)"
GRAFANA_PORT="$(bashio::config grafana_port)"
SCRAPE_INTERVAL="$(bashio::config scrape_interval)"
RETENTION="$(bashio::config prometheus_retention_time)"
AP_URL="$(bashio::config ap_traffic_monitor_url)"

mkdir -p "${PROM_DIR}/data" "${GRAFANA_DIR}/data" "${GRAFANA_DIR}/provisioning/datasources" "${BLACKBOX_DIR}"

cat >"${BLACKBOX_DIR}/blackbox.yml" <<'EOF'
modules:
  http_2xx:
    prober: http
    timeout: 10s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
      follow_redirects: true
      preferred_ip_protocol: ip4
  icmp:
    prober: icmp
    timeout: 5s
    icmp:
      preferred_ip_protocol: ip4
EOF

HTTP_TARGETS=()
if bashio::config.has_value "blackbox_http_targets"; then
  readarray -t HTTP_TARGETS < <(jq -r '.blackbox_http_targets[]? // empty' /data/options.json)
fi

if bashio::config.true "scrape_ap_traffic"; then
  HTTP_TARGETS+=("${AP_URL}")
fi

ICMP_TARGETS=()
if bashio::config.has_value "blackbox_icmp_targets"; then
  readarray -t ICMP_TARGETS < <(jq -r '.blackbox_icmp_targets[]? // empty' /data/options.json)
fi

{
  echo "global:"
  echo "  scrape_interval: ${SCRAPE_INTERVAL}"
  echo "  evaluation_interval: ${SCRAPE_INTERVAL}"
  echo ""
  echo "scrape_configs:"
  echo "  - job_name: prometheus"
  echo "    static_configs:"
  echo "      - targets: ['127.0.0.1:${PROM_PORT}']"
  echo ""
  echo "  - job_name: blackbox_exporter"
  echo "    static_configs:"
  echo "      - targets: ['127.0.0.1:${BLACKBOX_PORT}']"
  echo ""

  if bashio::config.true "scrape_telegraf"; then
    TG_PORT="$(bashio::config telegraf_prometheus_port)"
    echo "  - job_name: telegraf"
    echo "    static_configs:"
    echo "      - targets: ['127.0.0.1:${TG_PORT}']"
    echo ""
  fi

  if bashio::config.true "scrape_conntrack"; then
    CT_PORT="$(bashio::config conntrack_port)"
    echo "  - job_name: conntrack"
    echo "    static_configs:"
    echo "      - targets: ['127.0.0.1:${CT_PORT}']"
    echo ""
  fi

  if [ "${#HTTP_TARGETS[@]}" -gt 0 ]; then
    echo "  - job_name: blackbox_http"
    echo "    metrics_path: /probe"
    echo "    params:"
    echo "      module: [http_2xx]"
    echo "    static_configs:"
    echo "      - targets:"
    for t in "${HTTP_TARGETS[@]}"; do
      echo "          - '${t}'"
    done
    echo "    relabel_configs:"
    echo "      - source_labels: [__address__]"
    echo "        target_label: __param_target"
    echo "      - source_labels: [__param_target]"
    echo "        target_label: instance"
    echo "      - target_label: __address__"
    echo "        replacement: 127.0.0.1:${BLACKBOX_PORT}"
    echo ""
  fi

  if [ "${#ICMP_TARGETS[@]}" -gt 0 ]; then
    echo "  - job_name: blackbox_icmp"
    echo "    metrics_path: /probe"
    echo "    params:"
    echo "      module: [icmp]"
    echo "    static_configs:"
    echo "      - targets:"
    for t in "${ICMP_TARGETS[@]}"; do
      echo "          - '${t}'"
    done
    echo "    relabel_configs:"
    echo "      - source_labels: [__address__]"
    echo "        target_label: __param_target"
    echo "      - source_labels: [__param_target]"
    echo "        target_label: instance"
    echo "      - target_label: __address__"
    echo "        replacement: 127.0.0.1:${BLACKBOX_PORT}"
    echo ""
  fi

  CUSTOM="$(bashio::config custom_prometheus_jobs)"
  if [ -n "${CUSTOM}" ]; then
    echo "${CUSTOM}"
  fi
} >"${PROM_DIR}/prometheus.yml"

GF_USER="$(bashio::config grafana_admin_user)"
GF_PASS="$(bashio::config grafana_admin_password)"

cat >"${GRAFANA_DIR}/grafana.ini" <<EOF
[server]
protocol = http
http_port = ${GRAFANA_PORT}
domain = localhost
enforce_domain = false
root_url = %(protocol)s://%(domain)s:%(http_port)s%%ingress_entry%%

[security]
admin_user = ${GF_USER}
admin_password = ${GF_PASS}
allow_embedding = true


[users]
allow_sign_up = false
EOF

cat >"${GRAFANA_DIR}/provisioning/datasources/prometheus.yaml" <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://127.0.0.1:${PROM_PORT}
    isDefault: true
    editable: true
EOF

CT_INFO=""
if bashio::config.true "scrape_conntrack"; then
  CT_INFO=", Conntrack :$(bashio::config conntrack_port)"
fi
bashio::log.info "Monitoring configs ready (Grafana :${GRAFANA_PORT}, Prometheus :${PROM_PORT}, Blackbox :${BLACKBOX_PORT}${CT_INFO})"


chmod -R 755 /data/prometheus
chmod -R 755 /data/grafana