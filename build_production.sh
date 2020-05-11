#!/usr/bin/env bash
set -xe

git checkout master

REPO=mikenye
IMAGE=radarbox
PLATFORMS="linux/amd64,linux/arm/v6,linux/arm/v7,linux/arm64"

# Colours
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'

# Save current dir
pushd .

# Firstly we need to build the mlat-client:armhf deb
echo -e "${LIGHTPURPLE}========== Building mlat-client:armhf ==========${NOCOLOR}"
docker context use arm32v7
cd ./mlat-builder
docker build . -t mlat-builder:latest

# Copy deb out of mlat-builder
echo -e "${LIGHTPURPLE}========== Copy mlat-client:armhf out of image ==========${NOCOLOR}"
mkdir -p output
rm -v ./output/*.deb || true
MLAT_BUILDER_CONTAINER_ID=$(timeout 300s docker run -d --rm mlat-builder sleep 300)
FILE_TO_COPY=$(docker exec ${MLAT_BUILDER_CONTAINER_ID} bash -c "ls /src/mlat-client*.deb")
docker cp ${MLAT_BUILDER_CONTAINER_ID}:${FILE_TO_COPY} ./output/
docker kill ${MLAT_BUILDER_CONTAINER_ID}
docker rm ${MLAT_BUILDER_CONTAINER_ID} || true

# Return to previous directory
popd 

# Return to original build contexts
docker context use x86_64
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use homecluster

# Build & push latest
echo -e "${LIGHTPURPLE}========== Building ${REPO}/${IMAGE}:latest ==========${NOCOLOR}"
docker buildx build -t "${REPO}/${IMAGE}:latest" --compress --push --platform "${PLATFORMS}" .

# Get piaware version from latest
docker pull "${REPO}/${IMAGE}:latest"
VERSION=$(docker run --rm --entrypoint cat "${REPO}/${IMAGE}:latest" /VERSIONS | grep rbfeeder | cut -d " " -f 2)

# Build & push version-specific
echo -e "${LIGHTPURPLE}========== Building ${REPO}/${IMAGE}:${VERSION} ==========${NOCOLOR}"
docker buildx build -t "${REPO}/${IMAGE}:${VERSION}" --compress --push --platform "${PLATFORMS}" .
