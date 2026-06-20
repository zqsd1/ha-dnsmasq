ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.23
FROM $BUILD_FROM


COPY dnsmasq.conf /
COPY nftables.conf /

COPY rootfs /
# RUN chmod a+x /etc/cont-init.d/10-test.sh

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG=C.UTF-8

RUN apk update && \
    apk add --no-cache \
    networkmanager \
    networkmanager-cli \
    dnsmasq \
    tcpdump \
    iptables \
    nftables &&\
    rm -rf /var/cache/apk/*


# COPY run.sh /
# RUN chmod a+x /run.sh

HEALTHCHECK --interval=30s --timeout=5s --retries=2 --start-period=15s  CMD healthcheck

# CMD [ "/run.sh" ]



LABEL \
    org.opencontainers.image.title="ha dnsmasq by zqsd" \
    org.opencontainers.image.description="dnsmasq to fit my need" \
    org.opencontainers.image.source="https://github.com/zqsd/ha-dnsmasq"