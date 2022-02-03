#!/usr/bin/env bash

set -e

EXITCODE=0

CHECK_PERIOD_SECONDS=300

TIMESTAMP_NOW=$(date +%s.%N)
LASTLOG_PACKETS_SENT=$(grep "Packets sent in the last 30 seconds" "$RBFEEDER_LOG_FILE" | tail -1 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")
LASTLOG_TIMESTAMP=$(date --date="$(echo "$LASTLOG_PACKETS_SENT" | cut -d '[' -f 2 | cut -d ']' -f 1)" +%s.%N)
LASTLOG_NUM_PACKETS_SENT=$(echo "$LASTLOG_PACKETS_SENT" | cut -d ']' -f 2 | cut -d ':' -f 2 | cut -d ',' -f 1 | tr -d ' ')

# check to make sure we've sent packets recently
if [ "$(echo "($TIMESTAMP_NOW - $LASTLOG_TIMESTAMP) < $CHECK_PERIOD_SECONDS" | bc)" -ne 1 ]; then
    echo "No packets sent in past $CHECK_PERIOD_SECONDS seconds. UNHEALTHY"
    EXITCODE=1
else
    if [ "$LASTLOG_NUM_PACKETS_SENT" -lt 1 ]; then
        echo "No packets sent in past $CHECK_PERIOD_SECONDS seconds. UNHEALTHY"
        EXITCODE=1
    else
        echo "$LASTLOG_NUM_PACKETS_SENT packets sent in past 30 seconds. HEALTHY"
    fi
fi

exit $EXITCODE

# TODO:
# Entries in /var/log/rbfeeder/current to search for
# "Can't connect to external source" <-- mark as unhealthy
#
# Check death counts for services <-- probably can't do this due to https://github.com/mikenye/docker-radarbox/issues/9
