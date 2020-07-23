#!/usr/bin/env bash
set -xe

git checkout dev

REPO=mikenye
IMAGE=radarbox
PLATFORMS="linux/amd64,linux/arm/v7,linux/arm64"

# Colours
NOCOLOR='\033[0m'
LIGHTPURPLE='\033[1;35m'

# Firstly we need to build the mlat-client:armhf deb
echo -e "${LIGHTPURPLE}========== Building mlat-client:armhf ==========${NOCOLOR}"
pushd ./mlat-builder
docker --context=arm32v7 build . -t mlat-builder:latest

# Copy deb out of mlat-builder
echo -e "${LIGHTPURPLE}========== Copy mlat-client:armhf out of image ==========${NOCOLOR}"
mkdir -p output
rm -v ./output/*.deb || true
MLAT_BUILDER_CONTAINER_ID=$(timeout 300s docker --context=arm32v7 run -d --rm mlat-builder sleep 300)
FILE_TO_COPY=$(docker --context=arm32v7 exec "${MLAT_BUILDER_CONTAINER_ID}" bash -c "ls /src/mlat-client*.deb")
docker --context=arm32v7 cp "${MLAT_BUILDER_CONTAINER_ID}:${FILE_TO_COPY}" ./output/
docker --context=arm32v7 kill "${MLAT_BUILDER_CONTAINER_ID}"
docker --context=arm32v7 rm "${MLAT_BUILDER_CONTAINER_ID}" || true

# Return to previous directory
popd 

# Return to original build contexts
docker context use x86_64
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use homecluster

# Build & push development
echo -e "${LIGHTPURPLE}========== Building ${REPO}/${IMAGE}:latest ==========${NOCOLOR}"
docker buildx build -t "${REPO}/${IMAGE}:development" --compress --push --platform "${PLATFORMS}" .
