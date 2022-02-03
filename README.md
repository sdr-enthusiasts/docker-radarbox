# mikenye/radarbox

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/mikenye/docker-radarbox/Deploy%20to%20Docker%20Hub)](https://github.com/mikenye/docker-radarbox/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/mikenye/radarbox.svg)](https://hub.docker.com/r/mikenye/radarbox)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/mikenye/radarbox/latest)](https://hub.docker.com/r/mikenye/radarbox)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container running [AirNav RadarBox](https://www.radarbox.com)'s `rbfeeder`. Designed to work in tandem with [mikenye/readsb-protobuf](https://hub.docker.com/repository/docker/mikenye/readsb-protobuf). Builds and runs on `x86_64`, `arm64` and `arm32v7`.

`rbfeeder` pulls ModeS/BEAST information from a host or container providing ModeS/BEAST data, and sends data to RadarBox.

For more information on what `rbfeeder` is, see here: [sharing-data](https://www.radarbox.com/sharing-data).

## Supported tags and respective Dockerfiles

* `latest` (`master` branch, `Dockerfile`)
* `latest_nohealthcheck` is the same as the `latest` version above. However, this version has the docker healthcheck removed. This is done for people running platforms (such as [Nomad](https://www.nomadproject.io)) that don't support manually disabling healthchecks, where healthchecks are not wanted.
* Version and architecture specific tags available

## Multi Architecture Support

Currently, this image should pull and run on the following architectures:

* `amd64`: Linux x86-64
* `arm32v7`, `armv7l`: ARMv7 32-bit (Odroid HC1/HC2/XU4, RPi 2/3)
* `arm64`, `aarch64`: ARMv8 64-bit (RPi 4 64-bit OSes)

As RadarBox only provide `armhf` & `aarch64` binaries for Linux, `qemu-user-static` is used to allow the `armhf` binaries to execute on `amd64` (yes, I know 😕). Accordingly, there is a size discrepancy between each architecture's image. The qemu CPU/memory overhead is negligible.

The source code for `rbfeeder` is available (<https://github.com/mutability/rbfeeder>), however I haven't been able to get this to compile yet, so for the time being I'll stick with the qemu method. If you can get `rbfeeder` to compile and function correctly, please get in touch by [logging an issue](https://github.com/mikenye/docker-radarbox/issues) on the project's github.

## Workarounds for non-Raspberry Pi systems

The `rbfeeder` binary has some issues when running on non-RPi systems.

I've been able to come up with the following workarounds.

### Workaround for CPU Serial

The `rbfeeder` binary effectively greps for `serial\t\t:` in your `/proc/cpuinfo` file, to determine the RPi's serial number.

For systems that don't have a CPU serial number in `/proc/cpuinfo`, we can "fudge" this by generating a fake cpuinfo file, with a random serial number. To do this:

```bash
# make a directory to hold our fake data
mkdir -p /opt/adsb/data

# generate a fake cpuinfo file
# start by taking our current cpuinfo file
cp /proc/cpuinfo /opt/adsb/data/fake_cpuinfo

# ... and add a fake serial number to the end
echo -e "serial\t\t: $(hexdump -n 8 -e '4/4 "%08X" 1 "\n"' /dev/urandom | tr '[:upper:]' '[:lower:]')" >> /opt/adsb/data/fake_cpuinfo
```

The `hexdump...` in the command above will generate a random hexadecimal number in the format of a Raspberry Pi serial number.

You can now map this file into your container.

If using `docker run`, simply add `-v /opt/adsb/data/fake_cpuinfo:/proc/cpuinfo` to your command.

If using `docker-compose`, add the following to the `volumes:` section of your radarbox container definition:

```yaml
  - /opt/adsb/data/fake_cpuinfo:/proc/cpuinfo
```

### Workaround for Temperature Sensor

As the `rbfeeder` binary is designed to run on a Raspberry Pi, the `rbfeeder` binary expects a file `/sys/class/thermal/thermal_zone0/temp` to be present, and contain the CPU temperature. If this file doesn't exist, the `rbfeeder` binary will segfault.

We can generate a "fake" temperature sensor. To do this:

```bash
# make a directory to hold our fake data
mkdir -p /opt/adsb/data/radarbox_segfault_fix/thermal_zone0

# generate a fake temperature sensor
echo 24000 > /opt/adsb/data/radarbox_segfault_fix/thermal_zone0/temp
```

You can now map this file into your container.

If using `docker run`, simply add `-v /opt/adsb/data/fake_cpuinfo:/proc/cpuinfo` to your command.

If using `docker-compose`:

1. Create a volume definition at the top of your compose file:

```yaml
volumes:
  radarbox_segfault_fix:
    driver: local
    driver_opts:
      type: none
      device: /opt/adsb/data/radarbox_segfault_fix
      o: bind
```

1. Add the following to the `volumes:` section of your radarbox container definition:

```yaml
  - "radarbox_segfault_fix:/sys/class/thermal:ro"
```

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
| `UAT_RECEIVER_HOST`  | Optional. IP/Hostname of an external UAT decoded JSON provider (eg: dump978-fa). |
| `UAT_RECEIVER_PORT`  | Optional. TCP port number of the external UAT decoded JSON provider. | `30979` |
| `SHARING_KEY`        | Required. Radarbox Sharing Key | |
| `LAT` | Required. Latitude of the antenna | |
| `LONG` | Required. Longitude of the antenna | |
| `ALT` | Required. Altitude in *metres* | |
| `TZ`                 | Optional. Your local timezone | GMT     |
| `STATS_INTERVAL_MINUTES` | Optional. How often to print statistics, in minutes. | `5` |
| `VERBOSE_LOGGING` | Optional. Set to `true` for no filtering of `rbfeeder` logs. | `false` |
| `ENABLE_MLAT` | Option. Set to `true` to enable MLAT inside of the container. See [MLAT note](#mlat) below | `true` |

## Ports

The following TCP ports are used by this container:

* `32088` - `rbfeeder` listens on this port, however I can't find the use for this port...
* `30105` - `mlat-client` listens on this port to provide MLAT results.

## MLAT

You may find that MLAT in your container will often times spit out errors in your logs, such as

```shell
[rbfeeder] Disconnecting from mlat1.rb24.com:40900: No data (not even keepalives) received for 60 seconds
[rbfeeder] Connected to multilateration server at mlat1.rb24.com:40900, handshaking
```

This is likely, but not always, not caused by anything you are doing, but is instead caused by the Radarbox server itself and as such there isn't anything you can do to fix it. You will see in your Radarbox stats very little, if any, MLAT targets from your feeder while it is doing this.

To stop the feeder from spamming your logs you can set `ENABLE_MLAT=false` in your environment configuration for Radarbox and it will stop the MLAT service, and the log messages. Please note that if you do this, and you use [MLAT Hub](https://github.com/mikenye/docker-readsb-protobuf#advanced-usage-creating-an-mlat-hub) please remove Radarbox from your `READSB_NET_CONNECTOR` under `MLAT Hub`.

## Logging

* All processes are logged to the container's stdout, and can be viewed with `docker logs [-f] container`.

## Getting Help

You can [log an issue](https://github.com/mikenye/docker-radarbox/issues) on the project's GitHub.

I also have a [Discord channel](https://discord.gg/sTf9uYF), feel free to [join](https://discord.gg/sTf9uYF) and converse.

If you're getting continual segmentation faults inside this container, see: <https://github.com/mikenye/docker-radarbox/issues/16#issuecomment-699627387>
