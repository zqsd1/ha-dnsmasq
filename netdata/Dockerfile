ARG BUILD_FROM=ghcr.io/hassio-addons/base/amd64:20.0.2
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apk add --no-cache \
        curl \
        jq \
        bash \
        netdata \
    && mkdir -p /usr/share/netdata \
    && ln -sfn /usr/share/webapps/netdata /usr/share/netdata/web \
    && if [ -x /command/with-contenv ] && [ ! -e /usr/bin/with-contenv ]; then \
        ln -sf /command/with-contenv /usr/bin/with-contenv; \
    fi

COPY rootfs/ /

RUN find /etc/cont-init.d /etc/services.d -type f -exec sed -i 's/\r$//' {} + 2>/dev/null || true \
    && find /etc/cont-init.d -type f -name '*.sh' -exec chmod a+x {} + \
    && find /etc/services.d -type f \( -name run -o -name finish \) -exec chmod a+x {} + \
    && mkdir -p /data/netdata /data/netdata/cache /data/netdata/lib