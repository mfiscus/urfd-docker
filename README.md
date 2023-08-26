# URFd Docker Image

This Ubuntu Linux based Docker image allows you to run [N7TAE's](https://github.com/n7tae) [URFd](https://github.com/n7tae/urfd) and [tcd](https://github.com/n7tae/tcd) without having to configure any files or compile any code.

This is a currently a single-arch image and will only run on amd64 devices.

| Image Tag             | Architectures           | Base Image         | 
| :-------------------- | :-----------------------| :----------------- | 
| latest, ubuntu        | amd64                   | Ubuntu 22.04       | 

## Compatibility

urfd-docker requires certain variables be defined in your docker run command or docker-compose.yml (recommended) so it can automate the configuration upon bootup.

#### Required

```bash
# Define your FCC callsign
CALLSIGN="your_callsign"

# Define your email address which will appear on dashboard
EMAIL="your@email.com"

# Define your fully-qualified domain name
URL="your_domain.com"

# Where ? is A-Z or 0-9. NO EXCEPTIONS!
URFNUM="URF???"
```

#### Optional

```bash
# DO NOT enable the "calling home" feature unless you are sure
# that you will not be infringing on an existing XLX or XRF
# reflector with the same callsign suffix. If you don't understand
# what this means, don't set CALLHOME: 'true'
CALLHOME=false

# Setting this to true will ensure 'https' is used in URL
SSL=true

# Port that dashboard runs on. If SSL is enabled, then this is used for the backend proxy service
PORT="80"

# Get an ID here -> https://register.ysfreflector.de
YSFID="12345"

# Add your ID to the file here -> https://github.com/g4klx/NXDNClients/blob/master/NXDNGateway/NXDNHosts.txt
NXDNID="12345"

# Add your ID to the file here -> https://github.com/g4klx/P25Clients/blob/master/P25Gateway/P25Hosts.txt
P25ID="12345"

# Set to 'true' if you intend to interlink with Brandmeister (TGIF is better)
BRANDMEISTER=false

# Set to 'true' if you want to enable Allstar node
ALLSTAR=false

# Change to your country
COUNTRY="United States"

# Decribe your reflector. used in various places on dashboard *and* YSF registry
DESCRIPTION="My urfd-docker reflector"

# MODULES: ABCDEFGHIJKLMNOPQRSTUVWXYZ
MODULES="ABCD"

# Name your modules however you like (container only supports naming first 4)
MODULEA="Main"
MODULEB="D-Star"
MODULEC="DMR"
MODULED="YSF"

# Set your timezone here if you want dashboard times to apear in local time
TZ="UTC"
```

## Usage

#### Command Line:

```bash
docker \
  run \
    --detach \
    --name urfd \
    --hostname urfd_container \
    --restart unless-stopped \
    --volume /opt/urfd:/config \
    --env CALLSIGN=your_callsign \
    --env EMAIL=your@email.com \
    --env URL=your_domain.com \
    --env URFNUM=URF??? \
  mfiscus/urfd:latest
```

## Parameters

The parameters are split into two halves, separated by a colon, the left hand side representing the host and the right the container side.

* `--detach` - runs container in background *(required)*
* `--env` - set environment variables in the container *(minimum required: CALLSIGN, EMAIL, URL, URFNUM )*
* `--hostname` - assigns a container host name *(optional)*
* `--name` - assigns a name to the container *(optional)*
* `--restart` - set restart policy to apply when a container exits *(optional)*
* `--volume` - maps a local directory used for backing up state and configuration files including callinghome.php and urfd.ini *(required)*

## Docker Compose Examples
#### Using [Docker Compose](https://docs.docker.com/compose/) (recommended):

```yml
version: '3.8'

services:
  urfd:
    image: mfiscus/urfd:latest
    container_name: urfd
    hostname: urfd_container
    environment:
      # DO NOT enable the "calling home" feature unless you are sure
      # that you will not be infringing on an existing XLX or XRF
      # reflector with the same callsign suffix. If you don't understand
      # what this means, don't set CALLHOME: 'true'
      CALLHOME: 'false'
      # Define your FCC callsign
      CALLSIGN: 'your_callsign'
      # Define your email address which will appear on dashboard
      EMAIL: 'your@email.com'
      # Define your fully-qualified domain name
      URL: 'your_domain.com'
      # Setting this to true will ensure 'https' is used in URL
      SSL: 'true'
      # Port that dashboard runs on. If SSL is enabled, then this is used for the backend proxy service
      PORT: '80'
      # Where ? is A-Z or 0-9. NO EXCEPTIONS!
      URFNUM: 'URF???'
      # Get an ID here -> https://register.ysfreflector.de
      YSFID: '12345'
      # Add your ID to the file here -> https://github.com/g4klx/NXDNClients/blob/master/NXDNGateway/NXDNHosts.txt
      NXDNID: '12345'
      # Add your ID to the file here -> https://github.com/g4klx/P25Clients/blob/master/P25Gateway/P25Hosts.txt
      P25ID: '12345'
      # Set to 'true' if you intend to interlink with Brandmeister (TGIF is better)
      BRANDMEISTER: 'false'
      # Set to 'true' if you want to enable Allstar node
      ALLSTAR: 'false'
      # Change to your country
      COUNTRY: 'United States'
      # Decribe your reflector. used in various place on dashboard and YSF registry
      DESCRIPTION: 'My urfd-docker reflector'
      # MODULES: ABCDEFGHIJKLMNOPQRSTUVWXYZ
      MODULES: 'ABCD'
      # Name your modules however you like (container only supports naming first 4)
      MODULEA: 'Main'
      MODULEB: 'D-Star'
      MODULEC: 'DMR'
      MODULED: 'YSF'
      # Set your timezone here if you want dashboard times to apear in local time
      TZ: 'UTC'
    # Privilged MUST be enabled if you are using AMBE transcoding usb hardware 
    privileged: true
    volumes:
      # Local directory where state and config files (including callinghome.php and urfd.ini)
      # will be saved. Change /opt/urfd to any location you prefer on your host machine
      - /opt/urfd:/config
    restart: unless-stopped
```

#### Using [Docker Compose](https://docs.docker.com/compose/) (recommended) and [traefik](https://github.com/traefik/traefik) (reverse proxy w/ssl):  

```yml
version: '3.8'

networks:
  proxy:
    driver: bridge
    driver_opts:
      com.docker.network.bridge.name: br-proxy
    ipam:
      driver: default
      config:
        - subnet: "10.0.0.0/24"
          gateway: "10.0.0.1"
          ip_range: "10.0.0.0/30"

services:
  traefik:
    image: traefik:latest
    container_name: "traefik"
    domainname: your_domain.com
    hostname: traefik_container
    command:
      # Enable dashboard
      - --api.dashboard=true
      # Enable docker backend with default settings
      - --providers.docker=true
      # Do not expose containers by default
      - --providers.docker.exposedbydefault=false
      # Default docker network used
      - --providers.docker.network=proxy
      # logging
      - --accesslog=true
      - --accesslog.filepath=/var/log/traefik.log
      - --accesslog.bufferingsize=100
      # create entrypoints
      - --entrypoints.webinsecure.address=:80/tcp
      - --entrypoints.websecure.address=:443/tcp
      # your_domain.com tls
      # Comment the following line to use production resolver
      # (don't do this until you're sure everyting is configured properly)
      - --certificatesresolvers.your_domain.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory
      # Be certain to add your email address here and change 'your_domain' to something meaninful
      - --certificatesresolvers.your_domain.acme.email=your@email.com
      - --certificatesresolvers.your_domain.acme.storage=/letsencrypt/your_domain.com.json
      - --certificatesresolvers.your_domain.acme.certificatesDuration=2160
      - --certificatesresolvers.your_domain.acme.keytype=RSA4096
      - --certificatesresolvers.your_domain.acme.tlschallenge=true
      # urfd
      - --entrypoints.urfd-m17.address=:17000/udp
      - --entrypoints.urfd-m17.udp.timeout=86400s
      - --entrypoints.urfd-dht.address=:17171/udp
      - --entrypoints.urfd-dht.udp.timeout=86400s
      - --entrypoints.urfd-http.address=:8470/tcp
      - --entrypoints.urfd-repnet.address=:8080/udp
      - --entrypoints.urfd-repnet.udp.timeout=86400s
      - --entrypoints.urfd-bm.address=:10002/udp
      - --entrypoints.urfd-bm.udp.timeout=86400s
      - --entrypoints.urfd-interlink.address=:10017/udp
      - --entrypoints.urfd-interlink.udp.timeout=86400s
      - --entrypoints.urfd-usrp.address=:32000/udp
      - --entrypoints.urfd-usrp.udp.timeout=86400s
      - --entrypoints.urfd-p25.address=:41000/udp
      - --entrypoints.urfd-p25.udp.timeout=86400s
      - --entrypoints.urfd-nxdn.address=:41400/udp
      - --entrypoints.urfd-nxdn.udp.timeout=86400s
      - --entrypoints.urfd-ysf.address=:42000/udp
      - --entrypoints.urfd-ysf.udp.timeout=1296000s
      - --entrypoints.urfd-dextra.address=:30001/udp
      - --entrypoints.urfd-dextra.udp.timeout=1296000s
      - --entrypoints.urfd-dplus.address=:20001/udp
      - --entrypoints.urfd-dplus.udp.timeout=1296000s
      - --entrypoints.urfd-dcs.address=:30051/udp
      - --entrypoints.urfd-dcs.udp.timeout=1296000s
      - --entrypoints.urfd-dmr.address=:8880/udp
      - --entrypoints.urfd-dmr.udp.timeout=1296000s
      - --entrypoints.urfd-mmdvm.address=:62030/udp
      - --entrypoints.urfd-mmdvm.udp.timeout=1296000s
      - --entrypoints.urfd-icom-terminal-1.address=:12345/udp
      - --entrypoints.urfd-icom-terminal-1.udp.timeout=1296000s
      - --entrypoints.urfd-icom-terminal-2.address=:12346/udp
      - --entrypoints.urfd-icom-terminal-2.udp.timeout=1296000s
      - --entrypoints.urfd-icom-dv.address=:40000/udp
      - --entrypoints.urfd-icom-dv.udp.timeout=86400s
      - --entrypoints.urfd-yaesu-imrs.address=:21110/udp
      - --entrypoints.urfd-yaesu-imrs.udp.timeout=86400s
    labels:
      traefik.enable: true
      traefik.http.routers.traefik.rule: Host(`traefik.local`)
      traefik.http.routers.traefik.service: api@internal
      traefik.http.routers.traefik.entrypoints: webinsecure
    ports:
      # traefik ports
      - 80:80/tcp       # (HTTP webinsecure port)
      - 443:443/tcp     # (HTTPS websecure port)
      - 8880:8880/udp   # (DMR+ DMO mode)
      - 10002:10002/udp # (BM connection)
      - 10017:10017/udp # (URF interlinking)
      - 12345:12345/udp # (G3 Icom Terminal presence and request port 1)
      - 12346:12346/udp # (G3 Icom Terminal presence and request port 2)
      - 17000:17000/udp # (M17 protocol)
      - 17171:17171/udp # (OpenDHT port)
      - 20001:20001/udp # (DPlus protocol)
      - 30001:30001/udp # (DExtra protocol)
      - 30051:30051/udp # (DCS protocol)
      - 32000:32000/udp # (USRP protocol)
      - 40000:40000/udp # (G3 Icom Terminal port)
      - 41000:41000/udp # (P25 port)
      - 41400:41400/udp # (NXDN port)
      - 42000:42000/udp # (YSF protocol)
      - 62030:62030/udp # (MMDVM protocol)
    networks:
      - proxy
    volumes:
      # Let Traefik listen to the Docker events
      - /var/run/docker.sock:/var/run/docker.sock:ro
      # Volume to store letsencrypt certificates
      - /opt/traefik:/letsencrypt
    dns:
      - 1.1.1.1
    dns_search: your_domain.com
    restart: unless-stopped

  urfd:
    image: mfiscus/urfd:latest
    container_name: urfd
    domainname: your_domain.com
    hostname: urfd_container
    depends_on:
      traefik:
        condition: service_healthy
    labels:
      traefik.urfd-http.priority: 1
      traefik.docker.network: docker_proxy
      # Explicitly tell Traefik to expose this container
      traefik.enable: true
      # The domain the service will respond to
      traefik.http.routers.urfd-http.rule: Host(`your_domain.com`)
      # enable tls
      traefik.http.routers.urfd-http.tls: true
      traefik.http.routers.urfd-http.tls.certresolver: your_domain
      # Allow request only from the predefined entry point named urfd-http
      traefik.http.routers.urfd-http.entrypoints: websecure
      # Specify proxy service port
      traefik.http.services.urfd-http.loadbalancer.server.port: 80
      # (DMR+ DMO mode)
      traefik.udp.routers.urfd-dmr.entrypoints: urfd-dmr
      traefik.udp.routers.urfd-dmr.service: urfd-dmr
      traefik.udp.services.urfd-dmr.loadbalancer.server.port: 8880
      # (BM connection)
      traefik.udp.routers.urfd-bm.entrypoints: urfd-bm
      traefik.udp.routers.urfd-bm.service: urfd-bm
      traefik.udp.services.urfd-bm.loadbalancer.server.port: 10002
      # (URF interlinking)
      traefik.udp.routers.urfd-interlink.entrypoints: urfd-interlink
      traefik.udp.routers.urfd-interlink.service: urfd-interlink
      traefik.udp.services.urfd-interlink.loadbalancer.server.port: 10017
      # (G3 Icom Terminal presence and request port 1)
      traefik.udp.routers.urfd-icom-terminal-1.entrypoints: urfd-icom-terminal-1
      traefik.udp.routers.urfd-icom-terminal-1.service: urfd-icom-terminal-1
      traefik.udp.services.urfd-icom-terminal-1.loadbalancer.server.port: 12345
      # (G3 Icom Terminal presence and request port 2)
      traefik.udp.routers.urfd-icom-terminal-2.entrypoints: urfd-icom-terminal-2
      traefik.udp.routers.urfd-icom-terminal-2.service: urfd-icom-terminal-2
      traefik.udp.services.urfd-icom-terminal-2.loadbalancer.server.port: 12346
      # (M17 protocol)
      traefik.udp.routers.urfd-m17.entrypoints: urfd-m17
      traefik.udp.routers.urfd-m17.service: urfd-m17
      traefik.udp.services.urfd-m17.loadbalancer.server.port: 17000
      # (OpenDHT port)
      traefik.udp.routers.urfd-dht.entrypoints: urfd-dht
      traefik.udp.routers.urfd-dht.service: urfd-dht
      traefik.udp.services.urfd-dht.loadbalancer.server.port: 17171
      # (DPlus protocol)
      traefik.udp.routers.urfd-dplus.entrypoints: urfd-dplus
      traefik.udp.routers.urfd-dplus.service: urfd-dplus
      traefik.udp.services.urfd-dplus.loadbalancer.server.port: 20001
      # (DExtra protocol)
      traefik.udp.routers.urfd-dextra.entrypoints: urfd-dextra
      traefik.udp.routers.urfd-dextra.service: urfd-dextra
      traefik.udp.services.urfd-dextra.loadbalancer.server.port: 30001
      # (DCS protocol)
      traefik.udp.routers.urfd-dcs.entrypoints: urfd-dcs
      traefik.udp.routers.urfd-dcs.service: urfd-dcs
      traefik.udp.services.urfd-dcs.loadbalancer.server.port: 30051
      # (USRP protocol)
      traefik.udp.routers.urfd-usrp.entrypoints: urfd-usrp
      traefik.udp.routers.urfd-usrp.service: urfd-usrp
      traefik.udp.services.urfd-usrp.loadbalancer.server.port: 32000
      # (G3 Icom Terminal port)
      traefik.udp.routers.urfd-icom-dv.entrypoints: urfd-icom-dv
      traefik.udp.routers.urfd-icom-dv.service: urfd-icom-dv
      traefik.udp.services.urfd-icom-dv.loadbalancer.server.port: 40000
      # (P25 port)
      traefik.udp.routers.urfd-p25.entrypoints: urfd-p25
      traefik.udp.routers.urfd-p25.service: urfd-p25
      traefik.udp.services.urfd-p25.loadbalancer.server.port: 41000
      # (NXDN port)
      traefik.udp.routers.urfd-nxdn.entrypoints: urfd-nxdn
      traefik.udp.routers.urfd-nxdn.service: urfd-nxdn
      traefik.udp.services.urfd-nxdn.loadbalancer.server.port: 41400
      # (YSF protocol)
      traefik.udp.routers.urfd-ysf.entrypoints: urfd-ysf
      traefik.udp.routers.urfd-ysf.service: urfd-ysf
      traefik.udp.services.urfd-ysf.loadbalancer.server.port: 42000
      # (MMDVM protocol)
      traefik.udp.routers.urfd-mmdvm.entrypoints: urfd-mmdvm
      traefik.udp.routers.urfd-mmdvm.service: urfd-mmdvm
      traefik.udp.services.urfd-mmdvm.loadbalancer.server.port: 62030
    environment:
      # DO NOT enable the "calling home" feature unless you are sure
      # that you will not be infringing on an existing XLX or XRF
      # reflector with the same callsign suffix. If you don't understand
      # what this means, don't set CALLHOME: 'true'
      CALLHOME: 'false'
      # Define your FCC callsign
      CALLSIGN: 'your_callsign'
      # Define your email address which will appear on dashboard
      EMAIL: 'your@email.com'
      # Define your fully-qualified domain name
      URL: 'your_domain.com'
      # Setting this to true will ensure 'https' is used in URL
      SSL: 'true'
      # Port that dashboard runs on. If SSL is enabled, then this is used for the backend proxy service
      PORT: '80'
      # Where ? is A-Z or 0-9. NO EXCEPTIONS!
      URFNUM: 'URF???'
      # Get an ID here -> https://register.ysfreflector.de
      YSFID: '12345'
      # Add your ID to the file here -> https://github.com/g4klx/NXDNClients/blob/master/NXDNGateway/NXDNHosts.txt
      NXDNID: '12345'
      # Add your ID to the file here -> https://github.com/g4klx/P25Clients/blob/master/P25Gateway/P25Hosts.txt
      P25ID: '12345'
      # Set to 'true' if you intend to interlink with Brandmeister (TGIF is better)
      BRANDMEISTER: 'false'
      # Set to 'true' if you want to enable Allstar node
      ALLSTAR: 'false'
      # Change to your country
      COUNTRY: 'United States'
      # Decribe your reflector. used in various place on dashboard and YSF registry
      DESCRIPTION: 'My urfd-docker reflector'
      # MODULES: ABCDEFGHIJKLMNOPQRSTUVWXYZ
      MODULES: 'ABCD'
      # Name your modules however you like (container only supports naming first 4)
      MODULEA: 'Main'
      MODULEB: 'D-Star'
      MODULEC: 'DMR'
      MODULED: 'YSF'
      # Set your timezone here if you want dashboard times to apear in local time
      TZ: 'UTC'  
    networks:
      - proxy
    # Privilged MUST be enabled if you are using AMBE transcoding usb hardware 
    privileged: true
    volumes:
      # Local directory where state and config files (including callinghome.php and urfd.ini)
      # will be saved. Change /opt/urfd to any location you prefer on your host machine
      - /opt/urfd:/config
    dns:
      - 1.1.1.1
    dns_search: your_domain.com
    restart: unless-stopped
```

## License

Copyright (C) 2016 Jean-Luc Deltombe LX3JL and Luc Engelmann LX1IQ  
Copyright (C) 2023 Matt Fiscus

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.
