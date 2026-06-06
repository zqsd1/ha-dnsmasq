ARG BUILD_FROM=ghcr.io/hassio-addons/base:20.1.1
# hadolint ignore=DL3006
FROM ${BUILD_FROM}


SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG BUILD_ARCH=amd64

RUN \
    ARCH="${BUILD_ARCH}" \
    && case "${BUILD_ARCH}" in \
        amd64) BB_ARCH="amd64"; CT_ARCH="amd64" ;; \
        aarch64) BB_ARCH="arm64"; CT_ARCH="arm64" ;; \
        *) echo "WARNING: unsupported BUILD_ARCH ${BUILD_ARCH}, using amd64 binaries" >&2; BB_ARCH="amd64"; CT_ARCH="amd64" ;; \
    esac \
    && apk add --no-cache \
        curl \
        tar \
        jq \  
        prometheus \
        grafana \
        prometheus-blackbox-exporter
    
COPY rootfs/ /

RUN find /etc/cont-init.d /etc/services.d -type f -exec sed -i 's/\r$//' {} + 2>/dev/null || true \
    && find /etc/cont-init.d -type f -name '*.sh' -exec chmod a+x {} + \
    && find /etc/services.d -type f \( -name run -o -name finish \) -exec chmod a+x {} +
