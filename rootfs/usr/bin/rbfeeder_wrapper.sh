#!/usr/bin/env bash

# This wrapper file will determine how to run rbfeeder, either natively or via qemu-arm-static.
# All command line arguments passed to this script will be passed directly to rbfeeder_armhf.

# attempt to run natively
if /usr/bin/rbfeeder_armhf --no-start --version > /dev/null 2>&1; then
    /usr/bin/rbfeeder_armhf "$@"

elif qemu-arm-static /usr/bin/rbfeeder_armhf --no-start --version > /dev/null 2>&1; then
    qemu-arm-static /usr/bin/rbfeeder_armhf "$@"

else
    >&2 echo "ERROR: Could not run rbfeeder natively or via qemu"
    sleep 3600

fi

