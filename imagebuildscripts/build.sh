#!/usr/bin/env bash

# Verbosity (x)
# Exit on any error (e)
set -xe

echo "========== Attempting build for $(uname -m) =========="

if [ "$(uname -m)" = "x86_64" ]
then
    exec \
        /src/buildscripts/build.amd64.sh

elif [ "$(uname -m)" = "armv7l" ]
then
    exec \
        /src/buildscripts/build.arm32.sh

elif [ "$(uname -m)" = "armhf" ]
then
    exec \
        /src/buildscripts/build.arm32.sh

elif [ "$(uname -m)" = "aarch64" ]
then
    exec \
        /src/buildscripts/build.arm64.sh

else
    echo ""
    echo "ERROR!"
    echo "This build is running on an unsupported architecture ($(uname -m))."
    echo "Please raise an issue on this container's GitHub reporting this."
    echo ""
    exit 1
    
fi