# syntax=docker/dockerfile:1-labs
FROM amd64/ubuntu:latest AS base

ENTRYPOINT ["/init"]

ENV TERM="xterm" LANG="C.UTF-8" LC_ALL="C.UTF-8"
ENV CALLSIGN EMAIL URL URFNUM TZ="UTC"
ENV CALLHOME=false COUNTRY="United States" DESCRIPTION="XLX Reflector" PORT=80 YSFID=12345
ENV NUM_MODULES=4 MODULES=ABCD MODULEA="Main" MODULEB="TBD" MODULEC="TBD" MODULED="TBD" BRANDMEISTER="false" ALLSTAR="false"
ENV URFD_INST_DIR=/src/urfd OPENDHT_INST_DIR=/src/opendht URFD_WEB_DIR=/var/www/urfd
ENV URFD_DASH_CONFIG=/var/www/urfd/pgs/config.inc.php URFD_CONFIG_DIR=/config URFD_CONFIG_TMP_DIR=/config_tmp
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
    ${URFD_WEB_DIR}

# Fetch and extract S6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz

# Clone OpenDHT repository
ADD --keep-git-dir=true https://github.com/savoirfairelinux/opendht.git#master ${OPENDHT_INST_DIR}

# Clone urfd repository
ADD --keep-git-dir=true https://github.com/n7tae/urfd.git#main ${URFD_INST_DIR}

# Copy in source code (use local sources if repositories go down)
#COPY src/ /

# Compile and install OpenDHT
RUN cd ${OPENDHT_INST_DIR} && \
    mkdir -p build && \
    cd build && \
    cmake -DOPENDHT_PYTHON=OFF -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make && \
    make install

# Perform pre-compiliation configurations (remove references to systemctl from Makefile)
RUN sed -i "s/\(^[[:space:]]*[[:print:]]*..systemd*\)/#\1/" ${URFD_INST_DIR}/reflector/Makefile && \
    sed -i "s/\(^[[:space:]]*systemctl*\)/#\1/" ${URFD_INST_DIR}/reflector/Makefile

# Compile and install urfd
RUN cd ${URFD_INST_DIR}/reflector && \
    cp ../config/urfd.mk . && \
    make && \
    make install

# Install configuration files
RUN cp -iv ${URFD_INST_DIR}/config/* ${URFD_CONFIG_TMP_DIR}/

# Install web dashboard
RUN cp -ivR ${URFD_INST_DIR}/dashboard/* ${URFD_WEB_DIR}/ && \
    chown -R www-data:www-data ${URFD_WEB_DIR}/

# Copy in custom images and stylesheet
COPY --chown=www-data:www-data custom/up.png ${URFD_WEB_DIR}/img/up.png
COPY --chown=www-data:www-data custom/down.png ${URFD_WEB_DIR}/img/down.png
COPY --chown=www-data:www-data custom/ear.png ${URFD_WEB_DIR}/img/ear.png
COPY --chown=www-data:www-data custom/header.jpg ${URFD_WEB_DIR}/img/header.jpg
COPY --chown=www-data:www-data custom/logo.jpg ${URFD_WEB_DIR}/img/dvc.jpg
COPY --chown=www-data:www-data custom/layout.css ${URFD_WEB_DIR}/css/layout.css
COPY --chown=www-data:www-data custom/favicon.ico ${URFD_WEB_DIR}/favicon.ico

# Copy in s6 service definitions and scripts
COPY root/ /

# Cleanup
RUN apt -y purge build-essential && \
    apt -y autoremove && \
    apt -y clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    rm -rf /src

#TCP port(s) for http(s)
EXPOSE ${PORT}/tcp
#TCP port 8080 (RepNet) optional
EXPOSE 8080/tcp
#UDP port 10001 (json interface XLX Core)
EXPOSE 10001/udp
#UDP port 10002 (XLX interlink)
EXPOSE 10002/udp
#UDP port 42000 (YSF protocol)
EXPOSE 42000/udp
#UDP port 30001 (DExtra protocol)
EXPOSE 30001/udp
#UPD port 20001 (DPlus protocol)
EXPOSE 20001/udp
#UDP port 30051 (DCS protocol)
EXPOSE 30051/udp
#UDP port 8880 (DMR+ DMO mode)
EXPOSE 8880/udp
#UDP port 62030 (MMDVM protocol)
EXPOSE 62030/udp
#UDP port 12345 - 12346 (Icom Terminal presence and request port)
EXPOSE 12345-12346/udp
#UDP port 40000 (Icom Terminal dv port)
EXPOSE 40000/udp
#UDP port 21110 (Yaesu IMRS protocol)
EXPOSE 21110/udp

HEALTHCHECK --interval=5s --timeout=2s --retries=20 CMD /healthcheck.sh || exit 1