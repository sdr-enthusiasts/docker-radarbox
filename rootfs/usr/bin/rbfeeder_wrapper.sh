#!/usr/bin/env bash
# shellcheck shell=bash disable=SC1091

# This wrapper file will determine how to run rbfeeder, either natively or via qemu-arm-static.
# All command line arguments passed to this script will be passed directly to rbfeeder_armhf.

source /scripts/common
s6wrap=(s6wrap --quiet --timestamps --prepend="$(basename "$0")" --args)

# attempt to run natively
if /usr/bin/rbfeeder_arm --no-start --version >/dev/null 2>&1; then
    /usr/bin/rbfeeder_arm "$@"

elif qemu-arm-static /usr/bin/rbfeeder_arm --no-start --version >/dev/null 2>&1; then
    qemu-arm-static /usr/bin/rbfeeder_arm "$@"

else
    "${s6wrap[@]}" echo "[ERROR] Could not run rbfeeder natively or via qemu"
    sleep infinity & wait $!
fi
