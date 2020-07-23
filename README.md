# mikenye/radarbox

Docker container running [AirNav RadarBox](https://www.radarbox.com)'s `rbfeeder`. Designed to work in tandem with [mikenye/readsb](https://hub.docker.com/repository/docker/mikenye/readsb) or [mikenye/piaware](https://hub.docker.com/repository/docker/mikenye/piaware). Builds and runs on `x86_64`, `arm64` and `arm32v7` (see below).

`rbfeeder` pulls ModeS/BEAST information from a host or container providing ModeS/BEAST data, and sends data to RadarBox.

For more information on what `rbfeeder` is, see here: [sharing-data](https://www.radarbox.com/sharing-data).

## Supported tags and respective Dockerfiles

* `latest` (`master` branch, `Dockerfile`)
* Version and architecture specific tags available
* `development` (`dev` branch, `Dockerfile`, not recommended for production)

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* `amd64`: Linux x86-64
* `arm32v7`, `armv7l`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3)
* `arm64`, `aarch64`: ARMv8 64-bit (RPi 4 64-bit OSes)

As RadarBox only provide `armhf` binaries for Linux, `qemu-user-static` is used to allow the `armhf` binaries to execute on `amd64` (yes, I know 😕) and also `aarch64` where native `armhf` execution is unavailable. Accordingly, there is a size discrepancy between each architecture's image. The qemu overhead is negligible.

The source code for `rbfeeder` is available (<https://github.com/mutability/rbfeeder>), however I haven't been able to get this to compile yet, so for the time being I'll stick with the qemu method. If you can get `rbfeeder` to compile, please get in touch by [logging an issue](https://github.com/mikenye/docker-radarbox/issues) on the project's github.

## Obtaining a RadarBox Sharing Key

First-time users should obtain a RadarBox sharing key.

In order to obtain a RadarBox sharing key, on the first run of the container, `rbfeeder` will generate a sharing key and print this to the container log.

```shell
timeout 300s docker run \
    --rm \
    -it \
    -e BEASTHOST=YOURBEASTHOST \
    -e LAT=YOURLATITUDE \
    -e LONG=YOURLONGITUDE \
    -e ALT=YOURALTITUDE \
    mikenye/radarbox
```

This will run the container for five minutes, allowing a sharing key to be generated.

You should obviously replace `YOURBEASTHOST`, `YOURLATITUDE`, `YOURLONGITUDE` and `YOURALTITUDE` with appropriate values.

Shortly after the container launches, you should be presented with:

```
[2020-04-02 11:36:31]  Empty sharing key. We will try to create a new one for you!
[2020-04-02 11:36:32]  Your new key is g45643ab345af3c5d5g923a99ffc0de9. Please save this key for future use. You will have to know this key to link this receiver to your account in RadarBox24.com. This key is also saved in configuration file (/etc/rbfeeder.ini)
```

Take a note of the sharing key, as you'll need it when launching the container.

If you're not a first time user and are migrating from another installation, you can retrieve your sharing key using either of the following methods:

* SSH onto your existing receiver and run the command `rbfeeder --showkey --no-start`
* SSH onto your existing receiver and run the command `grep key= /etc/rbfeeder.ini`

## Up-and-Running with `docker run`

```shell
docker run \
 -d \
 --rm \
 --name rbfeeder \
 -e TZ="YOURTIMEZONE" \
 -e BEASTHOST=YOURBEASTHOST \
 -e LAT=YOURLATITUDE \
 -e LONG=YOURLONGITUDE \
 -e ALT=YOURALTITUDE \
 -e SHARING_KEY=YOURSHARINGKEY \
 mikenye/radarbox
```

You should obviously replace `YOURBEASTHOST`, `YOURLATITUDE`, `YOURLONGITUDE`, `YOURALTITUDE` and `YOURSHARINGKEY` with appropriate values.

For example:

```shell
docker run \
 -d \
 --rm \
 --name rbfeeder \
 -e TZ="Australia/Perth" \
 -e BEASTHOST=readsb \
 -e LAT=-33.33333 \
 -e LONG=111.11111 \
 -e ALT=90 \
 -e SHARING_KEY=g45643ab345af3c5d5g923a99ffc0de9 \
 mikenye/radarbox
```

Please note, the altitude figure is given in metres and no units should be specified.

## Up-and-Running with Docker Compose

```shell
version: '2.0'

services:
  rbfeeder:
    image: mikenye/radarbox:latest
    tty: true
    container_name: rbfeeder
    restart: always
    environment:
      - TZ=Australia/Perth
      - BEASTHOST=readsb
      - LAT=-33.33333
      - LONG=111.11111
      - ALT=90
      - SHARING_KEY=g45643ab345af3c5d5g923a99ffc0de9
    networks:
      - adsbnet
```

## Up-and-Running with Docker Compose, including `mikenye/readsb`

```shell
version: '2.0'

networks:
  adsbnet:

services:

  readsb:
    image: mikenye/readsb:latest
    tty: true
    container_name: readsb
    restart: always
    devices:
      - /dev/bus/usb/001/007:/dev/bus/usb/001/007
    networks:
      - adsbnet
    command:
      - --dcfilter
      - --device-type=rtlsdr
      - --fix
      - --forward-mlat
      - --json-location-accuracy=2
      - --lat=-33.33333
      - --lon=111.11111
      - --metric
      - --mlat
      - --modeac
      - --ppm=0
      - --net
      - --stats-every=3600
      - --quiet
      - --write-json=/var/run/readsb

  rbfeeder:
    image: mikenye/radarbox:latest
    tty: true
    container_name: rbfeeder
    restart: always
    environment:
      - TZ=Australia/Perth
      - BEASTHOST=readsb
      - LAT=-33.33333
      - LONG=111.11111
      - ALT=90
      - SHARING_KEY=g45643ab345af3c5d5g923a99ffc0de9
    networks:
      - adsbnet
```

For an explanation of the `mikenye/readsb` image's configuration, see that image's readme.

## Claiming Your Receiver

Once your container is up and running, you should claim your receiver.

1. Go to <https://www.radarbox.com/>
1. Create an account or sign in
1. Claim your receiver by visiting <https://www.radarbox.com/raspberry-pi/claim> and following the instructions

## Runtime Environment Variables

There are a series of available environment variables:

| Environment Variable | Purpose                         | Default |
| -------------------- | ------------------------------- | ------- |
| `BEASTHOST`          | Required. IP/Hostname of a Mode-S/BEAST provider (dump1090/readsb) | |
| `BEASTPORT`          | Optional. TCP port number of Mode-S/BEAST provider (dump1090/readsb) | 30005 |
| `SHARING_KEY`            | Required. Radarbox Sharing Key | |
| `LAT` | Required. Latitude of the antenna | |
| `LONG` | Required. Longitude of the antenna | |
| `ALT` | Required. Altitude in *metres* | |
| `TZ`                 | Optional. Your local timezone | GMT     |
| `MLAT_INPUT_TYPE`    | Optional. Sets the input receiver type. Run `docker run --rm -it --entrypoint mlat-client mikenye/radarbox --help` and see `--input-type` for valid values. | `dump1090` |
| `STATS_INTERVAL_MINUTES` | Optional. How often to print statistics, in minutes. | `5` |
| `VERBOSE_LOGGING` | Optional. Set to `true` for no filtering of `rbfeeder` logs. | `false` |

## Ports

The following TCP ports are used by this container:

* `32088` - `rbfeeder` listens on this port, however I can't find the use for this port...
* `30105` - `mlat-client` listens on this port to provide MLAT results.

## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/mikenye/docker-radarbox/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.
