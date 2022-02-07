# mikenye/radarbox

[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/radarbox/latest)](https://hub.docker.com/r/mikenye/radarbox)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running [AirNav RadarBox](https://www.radarbox.com)'s `rbfeeder`. Designed to work in tandem with [sdr-enthusiasts/readsb-protobuf](https://github.com/sdr-enthusiasts/docker-readsb-protobuf). Builds and runs on `x86_64`, `arm64` and `arm32v7`.

`rbfeeder` pulls ModeS/BEAST information from a host or container providing ModeS/BEAST data, and sends data to RadarBox.

For more information on what `rbfeeder` is, see here: [sharing-data](https://www.radarbox.com/sharing-data).

## Documentation

Please [read this container's detailed and thorough documentation in the GitHub repository.](https://github.com/sdr-enthusiasts/docker-radarbox/blob/main/README.md)