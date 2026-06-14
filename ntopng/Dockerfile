ARG BUILD_FROM=ntop/ntopng:latest
FROM $BUILD_FROM


ARG BUILD_ARCH=amd64

RUN set -eux; \
    if [ "${BUILD_ARCH}" = "amd64" ]; then \
        apt-get update && \
        apt-get install -y software-properties-common wget && \
        add-apt-repository universe && \
        wget -O apt-ntop.deb https://packages.ntop.org/apt/26.04/all/apt-ntop.deb && \
        apt-get install -y ./apt-ntop.deb && \
        apt-get update && \
        apt-get install -y pfring-dkms nprobe ntopng n2disk cento ntap; \
    elif [ "${BUILD_ARCH}" = "aarch64" ]; then \
        wget -O apt-ntop.deb https://packages.ntop.org/RaspberryPI/apt-ntop.deb && \
        dpkg -i apt-ntop.deb && \
        apt-get update && \
        apt-get install -y nprobe ntopng; \
    fi 

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

