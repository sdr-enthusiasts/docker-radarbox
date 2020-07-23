FROM ubuntu:bionic
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        ca-certificates \
        git \
        build-essential \
        debhelper \
        python3-dev \
        && \
    git clone https://github.com/adsbxchange/mlat-client.git /src/mlat-client && \
    pushd /src/mlat-client && \
    sed -i '/dh $@ --with python3/ s/$/ --buildsystem=pybuild/' ./debian/rules && \
    dpkg-buildpackage -b -uc && \
    popd 
