# syntax=docker/dockerfile:1-labs
FROM amd64/ubuntu:latest AS base

ENTRYPOINT ["/init"]

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV CALLSIGN EMAIL URL SSL="false" URFNUM=URF??? TZ="UTC"
ENV CALLHOME=false COUNTRY="US" DESCRIPTION="XLX Reflector" PORT=80 YSFID=12345 NXDNID=12345 P25ID=12345
ENV MODULES=ABCD MODULEA="Main" MODULEB="TBD" MODULEC="TBD" MODULED="TBD" BRANDMEISTER="false" ALLSTAR="false"
ENV URFD_WEB_DIR=/var/www/urfd URFD_CONFIG_DIR=/config URFD_CONFIG_TMP_DIR=/config_tmp
ARG URFD_INST_DIR=/src/urfd OPENDHT_INST_DIR=/src/opendht TCD_INST_DIR=/src/tcd IMBE_INST_DIR=/src/imbe_vocoder FTDI_INST_DIR=/src/ftdi
ARG ARCH=x86_64 S6_OVERLAY_VERSION=3.1.5.0 S6_RCD_DIR=/etc/s6-overlay/s6-rc.d S6_LOGGING=1 S6_KEEP_ENV=1

# install dependencies
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt update && \
    apt upgrade -y && \
    apt install -y \
        apache2 \
        build-essential \
        cmake \
        curl \
        libapache2-mod-php \
        libasio-dev \
        libargon2-0-dev \
        libcppunit-dev \
        libfmt-dev \
        libgnutls28-dev \
        libhttp-parser-dev \
        libjsoncpp-dev \
        libmsgpack-dev \
        libcurl4-gnutls-dev \
        libncurses5-dev \
        libreadline-dev \
        libssl-dev \
        nettle-dev \
        nlohmann-json3-dev \
        php \
        php-mbstring \
        pkg-config 

# Setup directories
RUN mkdir -p \
    ${OPENDHT_INST_DIR} \
    ${URFD_CONFIG_DIR} \
    ${URFD_CONFIG_TMP_DIR} \
    ${URFD_INST_DIR} \
    ${URFD_WEB_DIR} \
    ${FTDI_INST_DIR} \
    ${IMBE_INST_DIR}

# Fetch and extract S6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz

# Clone OpenDHT repository
#ADD --keep-git-dir=true https://github.com/savoirfairelinux/opendht.git#master ${OPENDHT_INST_DIR}
#ADD --keep-git-dir=true https://github.com/savoirfairelinux/opendht.git#v2.6.0rc7 ${OPENDHT_INST_DIR}
ADD --keep-git-dir=true https://github.com/savoirfairelinux/opendht.git#v2.5.5 ${OPENDHT_INST_DIR}

# Clone imbe_vocoder repository
ADD --keep-git-dir=true https://github.com/nostar/imbe_vocoder.git#master ${IMBE_INST_DIR}

# Clone tcd repository
ADD --keep-git-dir=true https://github.com/n7tae/tcd.git#main ${TCD_INST_DIR}

# Clone urfd repository
ADD --keep-git-dir=true https://github.com/n7tae/urfd.git#main ${URFD_INST_DIR}

# Download and extract ftdi driver
ADD https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-${ARCH}-1.4.27.tgz /tmp
RUN tar -C ${FTDI_INST_DIR} -zxvf /tmp/libftd2xx-${ARCH}-*.tgz

# Copy in source code (use local sources if repositories go down)
#COPY src/ /

# Install FTDI driver
RUN cp ${FTDI_INST_DIR}/release/build/libftd2xx.* /usr/local/lib && \
    chmod 0755 /usr/local/lib/libftd2xx.so.* && \
    ln -sf /usr/local/lib/libftd2xx.so.* /usr/local/lib/libftd2xx.so

# Compile and install imbe_vocoder
RUN cd ${IMBE_INST_DIR} && \
    make && \
    make install && \
    ldconfig   

# Compile and install OpenDHT
RUN cd ${OPENDHT_INST_DIR} && \
    mkdir -p build && \
    cd build && \
    cmake -DOPENDHT_PYTHON=OFF -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make && \
    make install

# Perform pre-compiliation configurations (remove references to systemctl from Makefiles)
RUN sed -i "s/\(^[[:space:]]*[[:print:]]*..systemd*\)/#\1/" ${URFD_INST_DIR}/reflector/Makefile && \
    sed -i "s/\(^[[:space:]]*systemctl*\)/#\1/" ${URFD_INST_DIR}/reflector/Makefile && \
    sed -i "s/\(^[[:space:]]*[[:print:]]*..systemd*\)/#\1/" ${TCD_INST_DIR}/Makefile && \
    sed -i "s/\(^[[:space:]]*systemctl*\)/#\1/" ${TCD_INST_DIR}/Makefile

# Compile and install tcd
RUN cd ${TCD_INST_DIR} && \
    cp ./config/tcd.mk . && \
    make && \
    make install

# Install configuration files
RUN cp -v ${TCD_INST_DIR}/config/* ${URFD_CONFIG_TMP_DIR}/

# Compile and install urfd
RUN cd ${URFD_INST_DIR}/reflector && \
    cp ../config/urfd.mk . && \
    make && \
    make install

# Install configuration files
RUN cp -v ${URFD_INST_DIR}/config/* ${URFD_CONFIG_TMP_DIR}/

# Install web dashboard
RUN cp -vR ${URFD_INST_DIR}/dashboard/* ${URFD_WEB_DIR}/ && \
    chown -R www-data:www-data ${URFD_WEB_DIR}/

# Copy in custom images and stylesheet
COPY --chown=www-data:www-data custom/up.png ${URFD_WEB_DIR}/img/up.png
COPY --chown=www-data:www-data custom/down.png ${URFD_WEB_DIR}/img/down.png
COPY --chown=www-data:www-data custom/ear.png ${URFD_WEB_DIR}/img/ear.png
COPY --chown=www-data:www-data custom/logo.png ${URFD_WEB_DIR}/img/logo.png
COPY --chown=www-data:www-data custom/favicon.ico ${URFD_WEB_DIR}/favicon.ico

# Copy in s6 service definitions and scripts
COPY root/ /

# Cleanup
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt -y purge build-essential \
        cmake \
        pkg-config && \
    apt -y autoremove && \
    apt -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /src

#TCP port(s) for http(s)
EXPOSE ${PORT}/tcp
#UDP port 8880 (DMR+ DMO mode)
EXPOSE 8880/udp
#UDP port 10002 (BM connection)
EXPOSE 10002/udp
#UDP port 10017 (URF interlinking)
EXPOSE 10017/udp
#UDP port 12345 - 12346 (G3 Icom Terminal presence and request port)
EXPOSE 12345-12346/udp
#UDP port 17000 (M17 protocol)
EXPOSE 17000/udp
#UDP port 17171 (OpenDHT)
EXPOSE 17171/udp
#UPD port 20001 (DPlus protocol)
EXPOSE 20001/udp
#UDP port 30001 (DExtra protocol)
EXPOSE 30001/udp
#UDP port 30051 (DCS protocol)
EXPOSE 30051/udp
#UDP port 32000 (USRP protocol)
EXPOSE 32000/udp
#UDP port 40000 (G3 Icom Terminal port)
EXPOSE 40000/udp
#UDP port 41000 (P25 port)
EXPOSE 41000/udp
#UDP port 41400 (NXDN port)
EXPOSE 41400/udp
#UDP port 42000 (YSF protocol)
EXPOSE 42000/udp
#UDP port 62030 (MMDVM protocol)
EXPOSE 62030/udp

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1