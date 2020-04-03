#!/usr/bin/env bash

# Verbosity (x)
# Exit on any error (e)
set -xe

echo "========== Install prerequisites =========="
apt-get update
apt-get install -y --no-install-recommends \
    ca-certificates \
    binutils \
    debhelper \
    git \
    gnupg \
    netbase \
    qemu-user \
    qemu-user-static \
    binfmt-support \
    wget \
    xz-utils

echo "========== Install s6-overlay =========="
wget -q -O - https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh

###############################################################################
# RadarBox don't provide binaries for any linux platform other than armhf (RPi)
# Accordingly, we run their feeder using qemu-arm
###############################################################################

echo "========== Set up armhf repos =========="
cp /etc/apt/sources.list /etc/apt/sources.list.orig
sed -i 's/\<deb\>/& [arch=amd64]/' /etc/apt/sources.list
sed -i 's/\<deb\>/& [arch=armhf]/' /tmp/sources.list.arm32v7
cat /tmp/sources.list.arm32v7 >> /etc/apt/sources.list
dpkg --add-architecture armhf
apt-get update

echo "========== Install armhf mlat-client =========="
cd /src/mlat-client
apt-get install python3:armhf -y
dpkg --install *.deb
VERSION_MLATCLIENT=$(dpkg --list | grep mlat | tr -s " " | cut -d " " -f 3)
echo "mlat-client ${VERSION_MLATCLIENT}" >> /VERSIONS

echo "========== Install armhf rbfeeder24 =========="
apt-get install -y --no-install-recommends \
    libc6:armhf \
    libcurl3:armhf \
    libglib2.0-0:armhf \
    librtlsdr0:armhf \
    libudev1:armhf \
    libusb-1.0-0:armhf
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
ar xv rbfeeder_armhf.deb
xz -dv data.tar.xz
tar xvf data.tar -C /
RBFEEDER_VERSION=$(/usr/bin/rbfeeder --version | cut -d " " -f2- | tr -d "(" | tr -d ")" | tr -s " " "_")
echo "rbfeeder $RBFEEDER_VERSION" >> /VERSIONS

###############################################################################

echo "========== Clean-up =========="
apt-get remove -y \
    binutils \
    debhelper \
    git \
    gnupg \
    wget \
    xz-utils
apt-get autoremove -y
apt-get clean -y
rm -rf /src /tmp/* /var/lib/apt/lists/*
cat /VERSIONS
