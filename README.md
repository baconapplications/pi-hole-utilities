# pi-hole-utilities

I currently use pi-hole on 2 Raspberry Pis: one is a Pi 4 Model B and the other is a PI 1 Model B.  Only the Pi 4 can run docker.  To account for the inability to run docker on the second Pi, I wrote some utility scripts to copy the docker related pi-hole config to my other pi.

## archive_pi_hole_docker.sh

Useful script for anyone, allows you to back up the core directories used by the docker pi-hole install.  By default I create a root `/data` directory to install pi-hole and write temp files.  Adjust tempDir and piHoleRoot for this process if needed.

### Usage:

`./archive_pi_hole_docker.sh -b` : back up all pi-hole files (including the pihole-FTL.db directory which includes stats) using default file directories

`./archive_pi_hole_docker.s` : back up all need files to restore a copy on another instance (does not include setupVars.conf OR pihole-FTL.db, etc)

`./archive_pi_hole_docker.s -o /data/temp/mytar.tag.gz` : save output tar as mytar.tag.gz in /data/temp.

## docker_run.sh

Copy of the default docker_run.sh from https://github.com/pi-hole/docker-pi-hole/blob/master/docker_run.sh with minor tweaks to run DHCP

## install_pi_hole_native_from_docker.sh

Takes archive create from archive_pi_hole_docker.sh and copies to the correct directories.  I use this script to copy my docker config to a second Raspberry Pi to act as DNS 2.  This script assumes you have create `/data` at root.  It will create an symlink for `/etc/pihole` to data.  I do this to match my docker set up.

### Usage:

`./install_pi_hole_native_from_docker.sh -i pi-hole-docker.tar.gz` : install from  pi-hole-docker.tar.gz created by archive_pi_hole_docker.sh script

## Current Base Pi Set Up

* Create latest SSD using Raspberry Pi Lite (No Desktop)
* Drop empty `ssh` file on SSD /boot partition (eg `touch ssh`)
* Start PI headless and use router to find IP of new PI
* ssh to PI (use default username/password)
* use `sudo raspi-config` to adjust hostname and change default password - see https://www.raspberrypi.org/documentation/computers/configuration.html for more info
* sudo reboot
* sudo nano /boot/config.txt and disable wi-fi and bluetooth via adding
    ```
    dtoverlay=pi3-disable-wifi 
    dtoverlay=pi3-disable-bt
    ```
* sudo reboot
* add static network via https://www.raspberrypi.org/documentation/computers/configuration.html#static-ip-addresses - edit `/etc/dhcpcd.conf`
* sudo reboot
* ssh to new IP
* sudo apt-get update
* sudo apt-get upgrade
* set up SSH keys for SSH on host
    ```
    ssh-keygen
    ssh-copy-id username@remote_host
    ```
* install git via `sudo apt install git`

## General Pi Hole Set Up Docker

* download docker install script via `curl -fsSL https://get.docker.com -o get-docker.sh`
* sh get-docker.sh
* add `pi` user to docker group
* sudo reboot
* confirm `pi` user can run docker hello world
* create root /data directory
    ```
    sudo mkdir /data
    sudo chown :pi /data
    sudo chmod 775 /data
    mkdir -p /data/pi-hole
    ```
* create SSH github.com key (https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
* clone git this repo and copy to `/data/pi-hole`
* adjust docker_run.sh
* ./docker_run.sh
* change default pi-hole admin password via:
    ```
    docker exec -it 1d8 /bin/bash
    sudo pihole -a -p [new password here]
    ```
* log into pi-hole web admin
* go to admin/groups-adlists.php -> group management -> adlists
* https://raw.githubusercontent.com/chadmayfield/my-pihole-blocklists/master/lists/pi_blocklist_porn_all.list
* add white list via https://github.com/anudeepND/whitelist.git.  My directory structure final command was:
    ```
    sudo python3 ./scripts/whitelist.py --dir /data/pi-hole/etc-pihole/ --docker
    ```
* add DNS Records via via admin-> Local DNS -> DNS Records
    ```
    forcesafesearch.google.com  216.239.38.120
    pi-hole.local   YOUR IP HERE
    pi-hole-2.local YOUR OTHER IP HERE
    safe.duckduckgo.com 52.250.41.2
    safesearch.pixabay.com 104.18.20.183
    strict.bing.com 204.79.197.220
    ```
* add CNAMES via admin-> Local DNS -> CNAME Records
    ```
    www.google.com,forcesafesearch.google.com
    bing.com,strict.bing.com
    www.bing.com,strict.bing.com
    www.duckduckgo.com,safe.duckduckgo.com
    duckduckgo.com,safe.duckduckgo.com
    duck.com,safe.duckduckgo.com
    www.duck.com,safe.duckduckgo.com
    pixabay.com,safesearch.pixabay.com
    ```

## General Pi Hole Set Up - Manual

* install pi-hole via `curl -sSL https://install.pi-hole.net | bash` see https://docs.pi-hole.net/main/basic-install/ for more info
* create root /data directory
    ```
    sudo mkdir /data
    sudo chown :pi /data
    sudo chmod 775 /data
    mkdir -p /data/pi-hole
    sudo chown :pihole /data/pi-hole
    sudo chmod 775 /data/pi-hole
    ```
* create SSH github.com key (https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account)
* check out this repo
* sftp tar file from `archive_pi_hole_docker.sh` script
* run `install_pi_hole_native_from_docker.sh -i [tar from previous script]`
* FIRST time run `cp /etc/pihole-orig/setupVars.conf` to `/etc/pi-hole`
* FIRST time run set web admin password via `sudo pihole -a -p`
* bask in glory? pi hole should be running as a copy from your docker instance
