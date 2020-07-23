#!/usr/bin/env bash
set -xe

# Colours
NOCOLOR='\033[0m'
LIGHTPURPLE='\033[1;35m'

# Save current dir
pushd .

# Test build the mlat-client deb
echo -e "${LIGHTPURPLE}========== Test building mlat-client ==========${NOCOLOR}"
pushd ./mlat-builder
docker build --no-cache -t mlat-builder:latest .

# Copy deb out of mlat-builder
echo -e "${LIGHTPURPLE}========== Copy mlat-client out of image ==========${NOCOLOR}"
mkdir -p output
rm -v ./output/*.deb || true
MLAT_BUILDER_CONTAINER_ID=$(timeout 300s docker run -d --rm mlat-builder sleep 300)
FILE_TO_COPY=$(docker exec "${MLAT_BUILDER_CONTAINER_ID}" bash -c "ls /src/mlat-client*.deb")
docker cp "${MLAT_BUILDER_CONTAINER_ID}:${FILE_TO_COPY}" ./output/
docker kill "${MLAT_BUILDER_CONTAINER_ID}"
docker rm "${MLAT_BUILDER_CONTAINER_ID}" || true

# Return to previous directory
popd 

# Build & push latest
echo -e "${LIGHTPURPLE}========== Building mikenye/radarbox:testing ==========${NOCOLOR}"
docker build --no-cache -t "mikenye/radarbox:testing" .
