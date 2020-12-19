# mikenye/radarbox

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mikenye/docker-radarbox/Deploy%20to%20Docker%20Hub)](https://github.com/mikenye/docker-radarbox/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/mikenye/radarbox.svg)](https://hub.docker.com/r/mikenye/radarbox)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/radarbox/latest)](https://hub.docker.com/r/mikenye/radarbox)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running [AirNav RadarBox](https://www.radarbox.com)'s `rbfeeder`. Designed to work in tandem with [mikenye/readsb-protobuf](https://hub.docker.com/repository/docker/mikenye/readsb-protobuf). Builds and runs on `x86_64`, `arm64` and `arm32v7`.

`rbfeeder` pulls ModeS/BEAST information from a host or container providing ModeS/BEAST data, and sends data to RadarBox.

For more information on what `rbfeeder` is, see here: [sharing-data](https://www.radarbox.com/sharing-data).

## Documentation

Please [read this container's detailed and thorough documentation in the GitHub repository.](https://github.com/mikenye/docker-radarbox/blob/master/README.md)