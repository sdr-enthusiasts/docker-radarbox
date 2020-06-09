#!/usr/bin/env bash

# Verbosity (x)
# Exit on any error (e)
set -xe

echo "========== Install prerequisites =========="
apt-get update 
apt-get install -y --no-install-recommends \
    binutils \
    ca-certificates \
    debhelper \
    file \
    git \
    gnupg \
    netbase \
    wget \
    xz-utils

echo "========== Install s6-overlay =========="
wget -q -O - https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh

echo "========== Install mlat-client =========="
cd /src/mlat-client
apt-get install python3 -y
dpkg --install *.deb
VERSION_MLATCLIENT=$(dpkg --list | grep mlat | tr -s " " | cut -d " " -f 3)
echo "mlat-client ${VERSION_MLATCLIENT}" >> /VERSIONS

echo "========== Install rbfeeder24 =========="
apt-get install -y --no-install-recommends \
    libc6 \
    libcurl3 \
    libglib2.0-0 \
    librtlsdr0 \
    libudev1 \
    libusb-1.0-0 \
    systemd
mkdir -p /tmp/rbfeederinstall
cd /tmp/rbfeederinstall
wget http://apt.rb24.com/dists/stable/main/binary-armhf/Packages
DEBFILE=$(\
    grep -E "^\s*Filename:\s+(\w|\d|\/|\.|\-)+rbfeeder(\w|\d|\.|\-)+.deb\s*$" Packages | \
    sort | \
    tail -1 | \
    cut -d ":" -f 2 | \
    tr -d " " \
    )
wget -O rbfeeder_armhf.deb "http://apt.rb24.com/${DEBFILE}"
dpkg --install rbfeeder_armhf.deb
RBFEEDER_VERSION=$(/usr/bin/rbfeeder --version | cut -d " " -f2- | tr -d "(" | tr -d ")" | tr -s " " "_")
echo "rbfeeder $RBFEEDER_VERSION" >> /VERSIONS

###############################################################################

echo "========== Clean-up =========="
apt-get remove -y \
    binutils \
    debhelper \
    file \
    git \
    gnupg \
    wget \
    xz-utils
apt-get autoremove -y
apt-get clean -y
rm -rf /src /tmp/* /var/lib/apt/lists/*
cat /VERSIONS
