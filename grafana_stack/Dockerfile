ARG BUILD_FROM
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
    bash \
    curl \
    tar \
    jq \
    prometheus \
    grafana \
    prometheus-blackbox-exporter

RUN mkdir -p \
    /data/prometheus \
    /data/grafana

COPY rootfs/ /

RUN find /etc/cont-init.d /etc/services.d -type f \
      -exec sed -i 's/\r$//' {} + 2>/dev/null || true \
 && find /etc/cont-init.d -type f -exec chmod a+x {} + \
 && find /etc/services.d -type f \( -name run -o -name finish \) \
      -exec chmod a+x {} +

RUN which prometheus || true
RUN which grafana-server || true
RUN which blackbox_exporter || true