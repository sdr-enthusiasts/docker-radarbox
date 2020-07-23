#!/usr/bin/env bash

set -e

EXITCODE=0

TIMESTAMP_NOW=$(date +%s.%N)
LASTLOG_PACKETS_SENT=$(cat $RBFEEDER_LOG_FILE | grep "Packets sent in the last 30 seconds" | tail -1 | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")
LASTLOG_TIMESTAMP=$(date --date="$(echo $LASTLOG_PACKETS_SENT | cut -d '[' -f 1)" +%s.%N)
LASTLOG_NUM_PACKETS_SENT=$(echo $LASTLOG_PACKETS_SENT | cut -d ']' -f 2 | cut -d ':' -f 2 | cut -d ',' -f 1 | tr -d ' ')

# check to make sure we've sent packets in the past 60 seconds
if [ $(echo "($TIMESTAMP_NOW - $LASTLOG_TIMESTAMP) < 60" | bc) -ne 1 ]; then
    echo "No packets sent in past 60 seconds. UNHEALTHY"
    EXITCODE=1
else
    if [ $LASTLOG_NUM_PACKETS_SENT -lt 1 ]; then
        echo "No packets sent in past 60 seconds. UNHEALTHY"
        EXITCODE=1
    else
        echo "At least $LASTLOG_NUM_PACKETS_SENT packets sent in past 60 seconds. HEALTHY"
    fi
fi

# truncate the log file
truncate --size=0 /var/log/rbfeeder.log

exit $EXITCODE

# TODO:
# Entries in /var/log/rbfeeder/current to search for
# "Can't connect to external source" <-- mark as unhealthy
#
# Check death counts for services <-- probably can't do this due to https://github.com/mikenye/docker-radarbox/issues/9

