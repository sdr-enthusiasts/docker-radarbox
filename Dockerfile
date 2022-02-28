FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

ENV BEASTHOST=readsb \
    BEASTPORT=30005 \
    UAT_RECEIVER_PORT=30979 \
    MLAT_SERVER=mlat1.rb24.com:40900 \
    RBFEEDER_LOG_FILE="/var/log/rbfeeder.log" \
    S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    STATS_INTERVAL_MINUTES=5 \
    VERBOSE_LOGGING=false \
    ENABLE_MLAT=true

COPY rootfs/ /

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    # define required packages
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # required for adding rb24 repo
    TEMP_PACKAGES+=(gnupg) && \
    # mlat-client dependencies
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(git) && \
    KEPT_PACKAGES+=(python3-minimal) && \
    KEPT_PACKAGES+=(python3-distutils) && \
    TEMP_PACKAGES+=(libpython3-dev) && \
    # required to run rbfeeder
    TEMP_PACKAGES+=(libjansson-dev) && \
    KEPT_PACKAGES+=(libjansson4) && \
    TEMP_PACKAGES+=(libglib2.0-dev) && \
    KEPT_PACKAGES+=(libglib2.0-0) && \
    TEMP_PACKAGES+=(protobuf-c-compiler) && \
    TEMP_PACKAGES+=(libncurses5-dev) && \
    TEMP_PACKAGES+=(libprotobuf-c-dev) && \
    KEPT_PACKAGES+=(libprotobuf-c1) && \
    TEMP_PACKAGES+=(libcurl4-openssl-dev) && \
    # TEMP_PACKAGES+=(debhelper) && \
    KEPT_PACKAGES+=(netbase) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    # build & install rbfeeder
    git clone --branch master --depth 1 --single-branch https://github.com/AirNav-Systems/rbfeeder.git /src/rbfeeder && \
    pushd /src/rbfeeder && \
    echo "rbfeeder $(git log | head -1)" >> /VERSIONS && \
    make proto && \
    make -j "$(nproc)" && \
    cp -v ./rbfeeder /usr/bin/ && \
    # get mlat-client:
    BRANCH_MLAT_CLIENT=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' 'https://github.com/mutability/mlat-client.git' | cut -d '/' -f 3 | grep '^v.*' | tail -1) && \
    git clone \
        --branch "$BRANCH_MLAT_CLIENT" \
        --depth 1 --single-branch \
        'https://github.com/mutability/mlat-client.git' \
        /src/mlat-client \
        && \
    pushd /src/mlat-client && \
    echo "mlat-client $(git log | head -1)" >> /VERSIONS && \
    python3 /src/mlat-client/setup.py build && \
    python3 /src/mlat-client/setup.py install && \
    popd && \
    # clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/* && \
    # test mlat-client
    mlat-client --help > /dev/null && \
    # test rbfeeder & get version
    /usr/bin/rbfeeder --version && \
    RBFEEDER_VERSION=$(/usr/bin/rbfeeder --no-start --version | cut -d " " -f 2,4 | tr -d ")" | tr " " "-") && \
    echo "$RBFEEDER_VERSION" > /CONTAINER_VERSION

# Expose ports
EXPOSE 32088/tcp 30105/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s  CMD /healthcheck.sh
