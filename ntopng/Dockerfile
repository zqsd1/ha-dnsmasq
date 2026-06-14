ARG BUILD_FROM=ntop/ntopng:latest
FROM $BUILD_FROM
ARG BUILD_ARCH=amd64

RUN ARCH="${BUILD_ARCH}" \
    && if [ "${BUILD_ARCH}" = "amd64" ]; then \
    apt-get install software-properties-common wget && \
    add-apt-repository universe  && \
    wget https://packages.ntop.org/apt/26.04/all/apt-ntop.deb && \
    apt install ./apt-ntop.deb && \
    apt-get clean all && \
    apt-get update && \
    apt-get install pfring-dkms nprobe ntopng n2disk cento ntap \
    \
    && if [ "${BUILD_ARCH}" = "aarch64" ]; then ARCH="arm64"; fi \
    wget https://packages.ntop.org/RaspberryPI/apt-ntop.deb \
    dpkg -i apt-ntop.deb \
    apt-get clean all \
    apt-get update \
    apt-get install nprobe ntopng
    
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

