FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base as downloader

# This downloader image has the rb24 apt repo added, and allows for downloading and extracting of rbfeeder binary deb package.

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
    # install prereqs
    apt-get update && \
    apt-get install -y --no-install-recommends \
    binutils \
    gnupg \
    xz-utils \
    && \
    # add rb24 repo
    dpkg --add-architecture armhf && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 1D043681 && \
    bash -c "echo 'deb https://apt.rb24.com/ bullseye main' > /etc/apt/sources.list.d/rb24.list" && \
    apt-get update && \
    # download rbfeeder deb
    pushd /tmp && \
    apt-get download \
    rbfeeder:armhf \
    && \
    # extract rbfeeder deb
    ls -lah && \
    ar xv ./rbfeeder_*armhf.deb && \
    tar xvf ./data.tar.xz -C /

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:qemu

# This is the final image

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
COPY --from=downloader /usr/bin/rbfeeder /usr/bin/rbfeeder_armhf
COPY --from=downloader /usr/bin/dump1090-rb /usr/bin/dump1090-rb
COPY --from=downloader /usr/share/doc/rbfeeder/changelog.gz /usr/share/doc/rbfeeder/changelog.gz

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -x && \
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
    # get mlat-client
    BRANCH_MLAT_CLIENT=$(git -c 'versionsort.suffix=-' ls-remote --tags --sort='v:refname' 'https://github.com/wiedehopf/mlat-client.git' | cut -d '/' -f 3 | grep '^v.*' | tail -1) && \
    git clone \
    --branch "$BRANCH_MLAT_CLIENT" \
    --depth 1 --single-branch \
    'https://github.com/wiedehopf/mlat-client.git' \
    /src/mlat-client \
    && \
    pushd /src/mlat-client && \
    echo "mlat-client $(git log | head -1)" >> /VERSIONS && \
    python3 /src/mlat-client/setup.py build && \
    python3 /src/mlat-client/setup.py install && \
    popd && \
    # create symlink for rbfeeder wrapper
    ln -s /usr/bin/rbfeeder_wrapper.sh /usr/bin/rbfeeder && \
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
