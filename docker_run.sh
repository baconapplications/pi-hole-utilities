#!/bin/bash

# https://github.com/pi-hole/docker-pi-hole/blob/master/README.md
# orig source is from https://github.com/pi-hole/docker-pi-hole/blob/master/docker_run.sh

# This version is tweaked to add my DNS primary server, DHCP in the container and my time zone
# To run DHCP in docker remove -p 53:53/tcp -p 53:53/udp \ and -p 80:80 \ and ADD --net=host and add --cap-add=NET_ADMIN \

PIHOLE_BASE="${PIHOLE_BASE:-$(pwd)}"
[[ -d "$PIHOLE_BASE" ]] || mkdir -p "$PIHOLE_BASE" || { echo "Couldn't create storage directory: $PIHOLE_BASE"; exit 1; }

# *** Note: ServerIP should be replaced with your external ip.
docker run -d \
    --platform linux/arm/v7 \
    --name pihole \
    --net=host \
    --cap-add=NET_ADMIN \
    -e TZ="America/Los_Angeles" \
    -v "${PIHOLE_BASE}/etc-pihole/:/etc/pihole/" \
    -v "${PIHOLE_BASE}/etc-dnsmasq.d/:/etc/dnsmasq.d/" \
    --dns=127.0.0.1 --dns=185.228.168.10 \
    --restart=unless-stopped \
    --hostname pi.hole \
    -e VIRTUAL_HOST="pi.hole" \
    -e PROXY_LOCATION="pi.hole" \
    -e ServerIP="127.0.0.1" \
    pihole/pihole:latest

printf 'Starting up pihole container '
for i in $(seq 1 20); do
    if [ "$(docker inspect -f "{{.State.Health.Status}}" pihole)" == "healthy" ] ; then
        printf ' OK'
        echo -e "\n$(docker logs pihole 2> /dev/null | grep 'password:') for your pi-hole: https://${IP}/admin/"
        exit 0
    else
        sleep 3
        printf '.'
    fi

    if [ $i -eq 20 ] ; then
        echo -e "\nTimed out waiting for Pi-hole start, consult your container logs for more info (\`docker logs pihole\`)"
        exit 1
    fi
done;