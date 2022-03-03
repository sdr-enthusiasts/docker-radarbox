# Version 0.4.3 Workarounds

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
