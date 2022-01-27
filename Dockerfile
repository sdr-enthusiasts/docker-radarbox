FROM debian:buster-20220125-slim

ENV BEASTPORT=30005 \
    MLAT_SERVER=mlat1.rb24.com:40900 \
    RBFEEDER_LOG_FILE="/var/log/rbfeeder.log" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    STATS_INTERVAL_MINUTES=5 \
    VERBOSE_LOGGING=false \
    ENABLE_MLAT=true

COPY rootfs/ /

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    /buildscripts/build.sh && \
    ldconfig && \
    # Make sure we have an init
    test -f /init && \
    # Make sure rbfeeder binary works
    rbfeeder --no-start && \
    cat /CONTAINER_VERSION

# Set s6 init as entrypoint
ENTRYPOINT [ "/init" ]

# Expose ports
EXPOSE 32088/tcp 30105/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s  CMD /healthcheck.sh
