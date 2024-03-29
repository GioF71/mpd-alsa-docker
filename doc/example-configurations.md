# Usage Examples

## Alsa Mode

### Simple Alsa Config

You can start mpd-alsa in `alsa` mode by simply typing:

```text
docker run -d \
    --name=mpd-alsa \
    --rm \
    --device /dev/snd \
    -p 6600:6600 \
    -e ALSA_OUTPUT_CREATE=yes \
    -v ${HOME}/Music:/music:ro \
    -v ${HOME}/.mpd/playlists:/playlists \
    -v ${HOME}/.mpd/db:/db \
    giof71/mpd-alsa
```

### Upsampling mode

An example with upsampling:

```text
---
version: '3.3'

services:
  mpd-s6-goldilocks:
    image: giof71/mpd-alsa:latest
    container_name: mpd-s6-goldilocks
    devices:
      - /dev/snd:/dev/snd
    ports:
      - 6600:6600/tcp
    environment:
      - USER_MODE=Y
      - PUID=1000
      - PGID=1000
      - AUDIO_GID=29
      - SOXR_PLUGIN_ENABLE=Y
      - SOXR_PLUGIN_QUALITY=custom
      - SOXR_PLUGIN_PRECISION=28
      - SOXR_PLUGIN_PHASE_RESPONSE=45
      - SOXR_PLUGIN_PASSBAND_END=95
      - SOXR_PLUGIN_STOPBAND_BEGIN=105
      - SOXR_PLUGIN_ATTENUATION=4
      - ALSA_OUTPUT_CREATE=yes
      - ALSA_OUTPUT_NAME=aune-s6
      - ALSA_OUTPUT_DEVICE=hw:DAC
      - ALSA_OUTPUT_MIXER_CONTROL=S6 USB DAC Output
      - ALSA_OUTPUT_MIXER_DEVICE=hw:DAC
      - ALSA_OUTPUT_MIXER_TYPE=hardware
      - ALSA_OUTPUT_INTEGER_UPSAMPLING=yes
      - ALSA_OUTPUT_ALLOWED_FORMATS=384000:*:* 352800:*:* *:dsd:*
    volumes:
      - ./lastfm.txt:/user/config/lastfm.txt:ro
      - ./librefm.txt:/user/config/librefm.txt:ro
    restart: unless-stopped
```

or, same configuration, using presets:

```text
---
version: '3.3'

services:
  mpd-s6-goldilocks:
    image: giof71/mpd-alsa:latest
    container_name: mpd-s6-goldilocks
    devices:
      - /dev/snd:/dev/snd
    ports:
      - 6600:6600/tcp
    environment:
      - USER_MODE=Y
      - PUID=1000
      - PGID=1000
      - AUDIO_GID=29
      - SOXR_PLUGIN_ENABLE=Y
      - SOXR_PLUGIN_PRESET=goldilocks
      - ALSA_OUTPUT_CREATE=yes
      - ALSA_OUTPUT_NAME=aune-s6
      - ALSA_OUTPUT_DEVICE=hw:DAC
      - ALSA_OUTPUT_MIXER_CONTROL=S6 USB DAC Output
      - ALSA_OUTPUT_MIXER_DEVICE=hw:DAC
      - ALSA_OUTPUT_MIXER_TYPE=hardware
      - ALSA_OUTPUT_INTEGER_UPSAMPLING=yes
      - ALSA_OUTPUT_ALLOWED_FORMATS_PRESET=8x
    volumes:
      - ./lastfm.txt:/user/config/lastfm.txt:ro
      - ./librefm.txt:/user/config/librefm.txt:ro
    restart: unless-stopped
```

This configuration uses a custom soxr resampling configuration, inspired from this article: [Archimago - MUSINGS: More fun with digital filters!](https://archimago.blogspot.com/2018/01/musings-more-fun-with-digital-filters.html).  
This particular configuration will upsample 44.1kHz, 88.2kHz, 176.4kHz streams to 352.8kHz and 48kHz, 96kHz, 192kHz to 384kHz, leaving dsd streams as they are.  
AUDIO_GID here is 29, but you will need to find the gid of the `audio` group on your specific installation as described in [user mode](https://github.com/GioF71/mpd-alsa-docker/blob/main/doc/user-mode.md).

## Requirements for alsa mode

Note that we need to allow the container to access the audio devices through `/dev/snd`. We need to give access to port `6600` so we can control the newly created mpd instance with our favourite mpd client.

## Pulse Mode

You can start mpd-alsa in `pulse` mode by simply typing:

```text
docker run -d \
    --name=mpd-alsa \
    --rm \
    --device /dev/snd \
    -p 6600:6600 \
    -e PULSE_AUDIO_OUTPUT_CREATE=yes \
    -v ${HOME}/Music:/music:ro \
    -v ${HOME}/.mpd/playlists:/playlists \
    -v ${HOME}/.mpd/db:/db \
    -v /run/user/1000/pulse:/run/user/1000/pulse \
    giof71/mpd-alsa
```

Note that we need to allow the container to access the pulseaudio by mounting `/run/user/$(id -u)/pulse`, which typically translates to `/run/user/1000/pulse`.  
