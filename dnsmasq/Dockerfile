ARG BUILD_FROM
FROM $BUILD_FROM

LABEL \
    org.opencontainers.image.title="ha dnsmasq by zqsd" \
    org.opencontainers.image.description="dnsmasq to fit my need" \
    org.opencontainers.image.source="https://github.com/zqsd/ha-dnsmasq" 

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG=C.UTF-8

RUN apk update && \
    apk add --no-cache \
        networkmanager \
        networkmanager-cli \
        dnsmasq  &&\
    rm -rf /var/cache/apk/*

COPY dnsmasq.conf /

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]


