ARG BUILD_FROM=ntop/ntopng:latest
FROM $BUILD_FROM


ARG BUILD_ARCH=amd64

RUN set -eux; \
    echo "BUILD_ARCH=${BUILD_ARCH}"; \
    if [ "${BUILD_ARCH}" = "amd64" ]; then \
        echo "Running amd64 branch"; \
        apt-get update && \
        apt-get install -y software-properties-common wget && \
        add-apt-repository universe && \
        wget -O apt-ntop.deb https://packages.ntop.org/apt/24.04/all/apt-ntop.deb && \
        apt-get install -y ./apt-ntop.deb && \
        apt-get update && \
        apt-get install -y pfring-dkms nprobe ntopng n2disk cento ntap; \
    elif [ "${BUILD_ARCH}" = "aarch64" ]; then \
        echo "Running aarch64 branch"; \
        apt-get update && \
        apt-get install -y lsb-release wget gnupg  libelf1 apt-transport-https ca-certificates  && \
        wget -O apt-ntop.deb https://packages.ntop.org/RaspberryPI/apt-ntop.deb && \
        apt-get install -y ./apt-ntop.deb && \
        apt-get clean all && \
        apt-get update && \
        apt-get install -y nprobe ntopng libcap2 libzstd1; \
    else \
        echo "Unknown BUILD_ARCH=${BUILD_ARCH}"; \
        exit 1; \
    fi 

COPY run.sh /
RUN chmod a+x /run.sh

COPY rootfs /
RUN chmod a+x /etc/s6-overlay/s6-rc.d/run
# CMD [ "/run.sh" ]


ENTRYPOINT ["/init"]

