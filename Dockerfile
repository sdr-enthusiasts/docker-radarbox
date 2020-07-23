FROM ubuntu:bionic

COPY --from=arm32v7/ubuntu:bionic /etc/apt/sources.list /tmp/sources.list.arm32v7
COPY /mlat-builder/output/*.deb /src/mlat-client/

COPY imagebuildscripts/ /src/buildscripts/

ENV BEASTPORT=30005 \
    MLAT_INPUT_TYPE="dump1090" \
    MLAT_SERVER=mlat1.rb24.com:40900 \
    RBFEEDER_LOG_FILE="/var/log/rbfeeder.log" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    VERBOSE_LOGGING=false

RUN set -x && \
    /src/buildscripts/build.sh && \
    # Make sure we have an init
    test -f /init

COPY rootfs/ /

# Set s6 init as entrypoint
ENTRYPOINT [ "/init" ]

# Expose ports
EXPOSE 32088/tcp 30105/tcp

# Add healthcheck
HEALTHCHECK --start-period=300s CMD /healthcheck.sh
