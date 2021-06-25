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
    dirmngr \
    file \
    git \
    gnupg \
    lsb-release \
    netbase \
    wget \
    xz-utils

# Get debian release name (for apt repos)
VERS=$(lsb_release -c | awk -F ':' '{print $2}' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

echo "========== Install s6-overlay =========="
wget -q -O - https://raw.githubusercontent.com/mikenye/deploy-s6-overlay/master/deploy-s6-overlay.sh | sh

echo "========== Import apt keys =========="
# AirNavSystems (for rbfeeder)
apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 1D043681

echo "========== Add apt repos =========="
echo "deb https://apt.rb24.com/ $VERS main" > /etc/apt/sources.list.d/rb24.list
apt-get update

echo "========== Install rbfeeder24 =========="
apt-get install --no-install-recommends -y rbfeeder
rbfeeder --version >> /VERSIONS
apt-cache show rbfeeder | grep Version | cut -d: -f2 | tr -d " " > /CONTAINER_VERSION

echo "========== Install mlat-client =========="
apt-get install -y --no-install-recommends \
    build-essential \
    debhelper \
    python3 \
    python3-dev
git clone https://github.com/mutability/mlat-client.git /src/mlat-client
pushd /src/mlat-client
BRANCH_MLAT_CLIENT=$(git tag --sort="-creatordate" | head -1)
git checkout "$BRANCH_MLAT_CLIENT"
./setup.py install
popd
echo "mlat-client ${BRANCH_MLAT_CLIENT}" >> /VERSIONS

echo "========== Clean-up =========="
apt-get remove -y \
    binutils \
    build-essential \
    debhelper \
    file \
    git \
    gnupg \
    python3-dev \
    wget \
    xz-utils
apt-get autoremove -y
apt-get clean -y
rm -rf /src /tmp/* /var/lib/apt/lists/*
cat /VERSIONS
