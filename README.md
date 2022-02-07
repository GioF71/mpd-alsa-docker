# mpd-alsa-docker - a Docker image for mpd with ALSA

## Reference

First and foremost, the reference to the awesome project:

[Music Player Daemon](https://www.musicpd.org/)

## Links

Source: [GitHub](https://github.com/giof71/mpd-alsa-docker)  
Images: [DockerHub](https://hub.docker.com/r/giof71/mpd-alsa)

## Why

I prepared this Dockerfile because I wanted to be able to install mpd easily on any machine (provided the architecture is amd64 or arm). Also I wanted to be able to configure and govern the parameters easily, with particular and exclusive reference to the configuration of a single ALSA output. Configuring the container is easy through a webapp like Portainer.

## Prerequisites

You need to have Docker up and running on a Linux machine, and the current user must be allowed to run containers (this usually means that the current user belongs to the "docker" group).

You can verify whether your user belongs to the "docker" group with the following command:

`getent group | grep docker`

This command will output one line if the current user does belong to the "docker" group, otherwise there will be no output.

The Dockerfile and the included scripts have been tested on the following distros:

- Manjaro Linux with Gnome (amd64)
- Asus Tinkerboard
- Raspberry Pi 3 (but I have no reason to doubt it will also work on a Raspberry Pi 4/400)

As I test the Dockerfile on more platforms, I will update this list.

## Get the image

Here is the [repository](https://hub.docker.com/repository/docker/giof71/mpd-alsa) on DockerHub.

Getting the image from DockerHub is as simple as typing:

`docker pull giof71/mpd-alsa:stable`  

You may want to pull the "stable" image as opposed to the "latest".

## Usage

You can start mpd-alsa by simply typing:

```text
docker run -d \
    --name=mpd-alsa \
    --rm \
    --device /dev/snd \
    -p 6600:6600 \
    -v ${HOME}/Music:/music:ro \
    -v ${HOME}/.mpd/playlists:/playlists \
    -v ${HOME}/.mpd/db:/db \
    giof71/mpd-alsa:stable`
```

Note that we need to allow the container to access the audio devices through `/dev/snd`. We need to give access to port `6600` so we can control the newly created mpd instance with our favourite mpd client.

The following tables lists the volumes:

VOLUME|DESCRIPTION
---|---
/db|Where the mpd database is saved
/music|Where the music is stored. you might consider to mount your directory in read-only mode (`:ro`)
/playlists|Where the playlists are stored

The following tables lists all the currently supported environment variables:

VARIABLE|DEFAULT|NOTES
---|---|---
MPD_AUDIO_DEVICE|default|The audio device. Common examples: `hw:DAC,0` or `hw:x20,0` or `hw:X20,0` for usb dac based on XMOS
ALSA_DEVICE_NAME|Alsa Device|Name of the Alsa Device
MIXER_TYPE|hardware|Mixer type
MIXER_DEVICE|default|Mixer device
MIXER_CONTROL|PCM|Mixer Control
MIXER_INDEX|0|Mixer Index
DOP|yes|Enables Dsd-Over-Pcm
REPLAYGAIN_MODE|0|ReplayGain Mode
REPLAYGAIN_PREAMP|0|ReplayGain Preamp
REPLAYGAIN_MISSING_PREAMP|0|ReplayGain mising preamp
REPLAYGAIN_LIMIT|yes|ReplayGain Limit
VOLUME_NORMALIZATION|no|Volume normalization
QOBUZ_PLUGIN_ENABLED|no|Enables the Qobuz plugin
QOBUZ_APP_ID|ID|Qobuz application id
QOBUZ_APP_SECRET|SECRET|Your Qobuz application Secret
QOBUZ_USERNAME|USERNAME|Qobuz account username
QOBUZ_PASSWORD|PASSWORD|Qobuz account password
QOBUZ_FORMAT_ID|5|The Qobuz format identifier, i.e. a number which chooses the format and quality to be requested from Qobuz. The default is “5” (320 kbit/s MP3)
TIDAL_PLUGIN_ENABLED|no|Enables the Tidal Plugin. Note that it seems to be currently defunct: see the mpd official documentation.
TIDAL_APP_TOKEN|TOKEN|The Tidal application token. Since Tidal is unwilling to assign a token to MPD, this needs to be reverse-engineered from another (approved) Tidal client.
TIDAL_USERNAME|USERNAME|Tidal Username
TIDAL_PASSWORD|PASSWORD|Tidal password
TIDAL_AUDIOQUALITY|Q|The Tidal “audioquality” parameter. Possible values: HI_RES, LOSSLESS, HIGH, LOW. Default is HIGH.
STARTUP_DELAY_SEC|0|Delay before starting the application. This can be useful if your container is set up to start automatically, so that you can resolve race conditions with mpd and with squeezelite if all those services run on the same audio device. I experienced issues with my Asus Tinkerboard, while the Raspberry Pi has never really needed this. Your mileage may vary. Feel free to report your personal experience.

## Build

You can build (or rebuild) the image by opening a terminal from the root of the repository and issuing the following command:

`docker build . -t giof71/mpd-alsa`

It will take very little time even on a Raspberry Pi. When it's finished, you can run the container following the previous instructions.  
Just be careful to use the tag you have built.
