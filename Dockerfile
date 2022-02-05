FROM ghcr.io/fredclausen/docker-baseimage:qemu

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
    # add armhf sources
    dpkg --add-architecture armhf && \
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
    # required to extract .deb file
    TEMP_PACKAGES+=(binutils) && \
    TEMP_PACKAGES+=(xz-utils) && \
    # required to run rbfeeder
    KEPT_PACKAGES+=(libc6:armhf) && \
    KEPT_PACKAGES+=(libcurl4:armhf) && \
    KEPT_PACKAGES+=(libglib2.0-0:armhf) && \
    KEPT_PACKAGES+=(libjansson4:armhf) && \
    KEPT_PACKAGES+=(libprotobuf-c1:armhf) && \
    KEPT_PACKAGES+=(librtlsdr0:armhf) && \
    KEPT_PACKAGES+=(netbase) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
        "${KEPT_PACKAGES[@]}" \
        "${TEMP_PACKAGES[@]}" \
        && \
    # import airnav gpg key
    gpg --list-keys && \
    gpg \
        --no-default-keyring \
        --keyring /usr/share/keyrings/airnav.gpg \
        --keyserver hkp://keyserver.ubuntu.com:80 \
        --recv-keys 1D043681 \
        && \
    gpg --list-keys && \
    # add airnav repo
    echo 'deb [arch=armhf signed-by=/usr/share/keyrings/airnav.gpg] https://apt.rb24.com/ bullseye main' > /etc/apt/sources.list.d/airnav.list && \
    apt-get update && \
    # get rbfeeder:
    # instead of apt-get install, we use apt-get download.
    # this is done because the package has systemd a dependency,
    # which we don't want in a container.
    # instead, we download, extract and manually install rbfeeder,
    # and install the dependencies manually.
    mkdir -p /tmp/rbfeeder && \
    pushd /tmp/rbfeeder && \
    apt-get download rbfeeder:armhf && \
    popd && \
    # extract .deb file
    ar x --output=/tmp/rbfeeder -- /tmp/rbfeeder/*.deb && \
    # extract .tar.xz files
    tar xvf /tmp/rbfeeder/data.tar.xz -C / && \
    # get mlat-client:
    BRANCH_MLAT_CLIENT=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' 'https://github.com/mutability/mlat-client.git' | cut -d '/' -f 3 | grep '^v.*' | tail -1) && \
    git clone \
        --branch "$BRANCH_MLAT_CLIENT" \
        --depth 1 --single-branch \
        'https://github.com/mutability/mlat-client.git' \
        /src/mlat-client \
        && \
    pushd /src/mlat-client && \
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
    if [[ "$(uname -m)" == "armv7l" ]]; \
        then RBFEEDER_VERSION=$(/usr/bin/rbfeeder --no-start --version | cut -d " " -f 2,4 | tr -d ")" | tr " " "-"); \
        else RBFEEDER_VERSION=$(qemu-arm-static /usr/bin/rbfeeder --no-start --version | cut -d " " -f 2,4 | tr -d ")" | tr " " "-"); \
        fi \
        && \
    echo "$RBFEEDER_VERSION" > /CONTAINER_VERSION

# Expose ports
EXPOSE 32088/tcp 30105/tcp

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s  CMD /healthcheck.sh
