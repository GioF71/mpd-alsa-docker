# mpd-alsa-docker - a Docker image for mpd with alsa

## Reference

First and foremost, the reference to the awesome project:

[Music Player Daemon](https://www.musicpd.org/)

## Links
Source: [GitHub](https://github.com/giof71/mpd-alsa-docker)<br />
Images: [DockerHub](https://hub.docker.com/r/giof71/mpd-alsa)

## Why

I prepared this Dockerfile Because I wanted to be able to install mpd easily on any machine (provided the architecture is amd64 or arm). Also I wanted to be able to configure and govern the parameters easily, with particular and exclusive reference to the configuration of a single ALSA output. Configuring the container is easy through a webapp like Portainer.

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

`docker pull giof71/mpd-alsa:stable`<br />

You may want to pull the "stable" image as opposed to the "latest".

## Usage

You can start mpd-alsa by simply typing:

`docker run -d --rm --device /dev/snd -p 6600:6600 giof71/mpd-alsa:stable`

Note that we need to allow the container to access the audio devices through /dev/snd. We need to give access to port 6600 so we can control the newly created mpd instance with our favourite mpd client.

The following tables reports all the currently supported environment variables.

| VARIABLE            | DEFAULT         | NOTES                                                                                                                                                                                                                                                                                                                                                         |
| ------------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| MPD_AUDIO_DEVICE            | default       | The audio device. Common examples: hw:DAC,0 for usb dacs                                                                                                                                                                                                                                                                                                                                       |
| ALSA_DEVICE_NAME            | Alsa Device            | Name of the Alsa Device                                                                                                                                                                                                                                                                                                                                          |
| MIXER_TYPE | hardware           | Mixer type                                                                                                                                                                                                                                                                                                                                    |
| MIXER_DEVICE    | default        | Mixer device                                                                                                                                                                                                                                                                                                                          |
| MIXER_DEVICE    | default        | Mixer device                                                                                                                                                                                                                                                                                                                          |
| MIXER_CONTROL        | PCM              | Mixer Control                                                                                                                                                                                                                                                                                                                            |
| MIXER_INDEX      | 0  | Mixer Index                                                                                                                                                                                                                                                                                                                                   |
| DOP      | yes  | Enables Dsd Over Pcm                                                                                                                                                                                                                                                                                                                                   |
| QOBUZ_PLUGIN_ENABLED     | no | Enables the Qobuz plugin                                                                                                                                                                                                                                                                                                                                  |
| QOBUZ_APP_ID     | ID | Qobuz application id                                                                                                                                                                                                                                                                                                                                  |
| QOBUZ_APP_SECRET     | SECRET | Your Qobuz application Secret                                                                                                                                                                                                                                                                                                                                  |
| QOBUZ_USERNAME     | USERNAME | Qobuz account username                                                                                                                                                                                                                                                                                                                                  |
| QOBUZ_PASSWORD     | PASSWORD | Qobuz account password                                                                                                                                                                                                                                                                                                                                  |
| QOBUZ_FORMAT_ID     | 5 | The Qobuz format identifier, i.e. a number which chooses the format and quality to be requested from Qobuz. The default is “5” (320 kbit/s MP3).                                                                                                                                                                                                                                                                                                                                  |
| TIDAL_PLUGIN_ENABLED       | no             | Enables the Tidal Plugin. Note that it seems to be currently defunct. See the mpd official documentation.                                                                                                                                                                                                                                                                                                                            |
| TIDAL_APP_TOKEN     | TOKEN | The Tidal application token. Since Tidal is unwilling to assign a token to MPD, this needs to be reverse-engineered from another (approved) Tidal client. |
| TIDAL_USERNAME     | USERNAME | Tidal Username.                                                                                                                                                                                                                                                                                                                                  |
| TIDAL_PASSWORD     | PASSWORD | Tidal password.                                                                                                                                                                                                                                                                                                                                  |
| TIDAL_AUDIOQUALITY     | Q | 	The Tidal “audioquality” parameter. Possible values: HI_RES, LOSSLESS, HIGH, LOW. Default is HIGH.|
| STARTUP_DELAY_SEC   | 0               | Delay before starting the application. This can be useful if your container is set up to start automatically, so that you can resolve race conditions with mpd and with squeezelite if all those services run on the same audio device. I experienced issues with my Asus Tinkerboard, while the Raspberry Pi has never really needed this. Your mileage may vary. Feel free to report your personal experience. |

## Build

You can build (or rebuild) the image by opening a terminal from the root of the repository and issuing the following command:

`docker build . -t giof71/mpd-alsa`

It will take very little time even on a Raspberry Pi. When it's finished, you can run the container following the previous instructions.<br />
Just be careful to use the tag you have built.

