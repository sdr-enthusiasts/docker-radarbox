#!/usr/bin/env sh
#shellcheck shell=sh

set -x

REPO=mikenye
IMAGE=radarbox
PLATFORMS="linux/amd64,linux/arm/v7,linux/arm64"

docker context use x86_64
export DOCKER_CLI_EXPERIMENTAL="enabled"
docker buildx use homecluster

# Build latest
docker buildx build -t "${REPO}/${IMAGE}:latest" --compress --push --platform "${PLATFORMS}" .

# Get version
docker pull "${REPO}/${IMAGE}:latest"
VERSION=$(docker run --rm --entrypoint cat "${REPO}"/"${IMAGE}":latest /VERSIONS | grep -i RBFeeder | tr -s ' ' | cut -d ' ' -f 2- | tr -d '(' | tr -d ')' | tr ' ' '_')

# Build version specific
docker buildx build -t "${REPO}/${IMAGE}:${VERSION}" --compress --push --platform "${PLATFORMS}" .
