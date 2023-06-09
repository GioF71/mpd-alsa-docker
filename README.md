# mpd-alsa-docker

A Docker image for mpd with support for both Alsa and PulseAudio.  
It also includes `mpdscribble`. In alternative, you can use [mpd-scrobbler-docker](https://github.com/GioF71/mpd-scrobbler-docker) as the scrobbler for this image.  
User mode is now possible when using `alsa` outputs, and of course it is mandatory (enforced) when using `pulse` outputs.  
Upsampling (even in integer mode) is now available via a patched version of MPD (upstream version available as well).  
Also, thanks to a [feature request](https://github.com/GioF71/mpd-alsa-docker/issues/158) by user [XxAcielxX](https://github.com/XxAcielxX), who also contributed with the necessary documentation, we have a certain degree of support for equalization.  

## Available Archs on Docker Hub

- linux/amd64
- linux/arm/v7
- linux/arm64/v8
- linux/arm/v6 (for debian-based builds)

## References

First and foremost, the reference to the awesome projects:

[Music Player Daemon](https://www.musicpd.org/)  
[MPDScribble](https://www.musicpd.org/clients/mpdscribble/)

## Links

Source: [GitHub](https://github.com/giof71/mpd-alsa-docker)  
Images: [DockerHub](https://hub.docker.com/r/giof71/mpd-alsa)

## Why

I prepared this Dockerfile because I wanted to be able to install mpd easily on any machine (provided the architecture is amd64 or arm). Also I wanted to be able to configure and govern the parameters easily, allowing multiple output, also of different types.

## Prerequisites

See [this](https://github.com/GioF71/mpd-alsa-docker/blob/main/doc/prerequisites.md) page.

## Get the image

Here is the [repository](https://hub.docker.com/r/giof71/mpd-alsa) on DockerHub.

Getting the image from DockerHub is as simple as typing:

`docker pull giof71/mpd-alsa`

Legacy support `OUTPUT_MODE`, is still available in the `legacy` branch, as well as on the images tagged with the `legacy` prefix.  
You might want to use those releases as a stop-gap solution should you encounter issues migrating to the new configuration methods.  
Keep in mind that the `legacy` branch will not be updated with new features. Only relevant bugfix changes will be ported there.  

## MPD Source code

The source code for the patched MPD is in this GitHub [repo](https://github.com/GioF71/MPD).  
The `version-0.23.13` tag is in-line with the GitHub [upstream repo](https://github.com/MusicPlayerDaemon/MPD) at version 0.23.13.  
The `version-0.23.13-ups` tag contains a patch which is used when `INTEGER_UPSAMPLING` is set to `yes`. Use at your own risk.  
Two binaries are available in the container image:

- /app/bin/compiled/mpd (upstream version)
- /app/bin/compiled/mpd-ups (patched version)

The current mpd version is `v0.23.13` when using [giof71/mpd-compiler-docker](https://github.com/GioF71/mpd-compiler-docker) as the base image (Docker Repo [here](https://hub.docker.com/r/giof71/mpd-compiler)). The repo binary is installed also in this case.  
Vanilla versions only have the repo binary.  
The `mpdscribble` version depends on the base image. See the following table:

### Image tags

Base Image|Tags|Compiled MPD version|Repo MPD version|MPDScribble version
:---|:---|:---|:---|:---
giof71/mpd-compiler:bookworm|**edge**, bookworm|0.23.13|0.23.12 [but please check](https://packages.debian.org/bookworm/mpd)|0.24
giof71/mpd-compiler:bullseye|**latest**, **stable**, bullseye|0.23.13|0.22.6|0.22
giof71/mpd-compiler:lunar|lunar, ubuntu-current|0.23.13|0.23.12|0.24
giof71/mpd-compiler:jammy|jammy, ubuntu-current-lts|0.23.13|0.23.5|0.23
debian:bookworm-slim|**vanilla-edge**, vanilla-bookworm|-|0.23.12|0.24
debian:bullseye-slim|**vanilla-latest**, **vanilla-stable**, **vanilla**, vanilla-bullseye|-|0.22.6|0.22
ubuntu:lunar|vanilla-lunar, vanilla-ubuntu-current|-|0.23.12|0.24
ubuntu:jammy|vanilla-jammy, vanilla-ubuntu-current-lts|-|0.23.5|0.23

## Usage

### Important changes

Starting with release `2023-02-04`, you will not be able to use the deprecated `PULSE` and `ALSA` as `OUTPUT_MODE`. Refer to the next chapter for more information about how to change the configuration. Please note that Alsa and PulseAudio are still supported: you just need to slightly modify your docker configurations.  
In case of difficulties, you can fall back to the `legacy` image versions (e.g.: `giof71/mpd-alsa:legacy-latest`), as those will still work with these deprecated configurations.  

### What has changed

If you have been using this container image for a while, you might have seen that the output might contain some warnings, telling you that you are using a `deprecated` configuration. The message usually tries to suggest how to switch to a `recommended` configuration.  
This is happening because this whole project started with the idea of supporting ALSA only (hence the name `mpd-alsa-docker`). Down the road, I added PulseAudio support, and eventually HTTPD outputs, SHOUTCAST outputs, also in multiple instances.  
So now a few variables have a misleading name: the most misleading being `ALSA_DEVICE_NAME` which, despite the name, refers to the output name, and not to the device name.  
So currently, `OUTPUT_MODE` is not available anymore.  
In any case, I suggest you change the configuration as suggested, and use the variables from the appropriate sections below for [Alsa](https://github.com/GioF71/mpd-alsa-docker#alsa-additional-outputs) and [PulseAudio](https://github.com/GioF71/mpd-alsa-docker#pulseaudio-additional-outputs), otherwise, in time, your configurations will not be functional anymore.  
Please refer to the [legacy branch](https://github.com/GioF71/mpd-alsa-docker/tree/legacy) for the old documentation.  
Feel free to contact me with an issue if you need support. I cannot guarantee a timing, but I will try to help if I can.  

### User mode

See [this](https://github.com/GioF71/mpd-alsa-docker/blob/main/doc/user-mode.md) page.

### Volumes

The following tables lists the volumes:

VOLUME|DESCRIPTION
:---|:---
/db|Where the mpd database is saved
/music|Where the music is stored. You might consider to mount your directory in read-only mode (`:ro`)
/playlists|Where the playlists are stored
/log|Where all logs are written (e.g. `mpd.log`, `scrobbler.log` etc)
/user/config|Additional user-provided configuration files, see [this](#user-configuration-volume) paragraph for the details

#### User Configuration volume

Several files can be located in the user configuration (`/user/config`) volume. Here is a table of those files.

FILE|DESCRIPTION
:---|:---
lastfm.txt|LastFM Credentials
librefm.txt|LibreFM Credentials
jamendo.txt|Jamendo Credentials
additional-alsa-presets.conf|Additional alsa presets
additional-outputs.txt|Additional outputs, which will be added to the configuration file during the container startup phase
asoundrc.txt|Alsa configuration file: this will be copied to `/home/mpd-user/.asoundrc` or to `/root/.asoundrc`, depending on user mode to be enabled or not

For a reference for the structure of the credentials file, see the corresponding example file in the doc folder of the repository.

### Environment Variables

The following tables lists all the currently supported environment variables:

VARIABLE|DESCRIPTION
:---|:---
DATABASE_MODE|Can be `simple` (default) or `proxy`
DATABASE_PROXY_HOST|MPD server hostname, only used when `DATABASE_MODE` is set to `proxy`
DATABASE_PROXY_PORT|MPD server port, only used when `DATABASE_MODE` is set to `proxy`
MUSIC_DIRECTORY|Location of music files, defaults to `/music`
MPD_BIND_ADDRESS|The MPD listen address, defaults to `0.0.0.0`
MPD_PORT|The MPD port, defaults to `6600`
USER_MODE|Set to `Y` or `YES` for user mode. Case insensitive. See [User mode](#user-mode). Required when using any PulseAudio outputs (so when `PULSE_AUDIO_OUTPUT_CREATE` is set to `yes`)
PUID|User id. Defaults to `1000`. The user/group will be created when a PulseAudio output is created regardless of the `USER_MODE` variable.
PGID|Group id. Defaults to `1000`. The user/group will be created when a PulseAudio output is created regardless of the `USER_MODE` variable.
AUDIO_GID|`audio` group id from the host machine. Mandatory for `alsa` output in user mode. See [User mode](https://github.com/GioF71/mpd-alsa-docker/blob/main/doc/user-mode.md).
INPUT_CACHE_SIZE|Sets the input cache size. Example value: `1 GB`
SAMPLERATE_CONVERTER|Configure `samplerate_converter`. Example value: `soxr very high`. Note that this configuration cannot be used when `SOXR_PLUGIN_ENABLE` is set to enabled. There are some preset values for sox: `very_high` and `very-high` map to `soxr very high`, `high` maps to `soxr high`, `medium` maps to `soxr medium`, `low` maps to `soxr low` and `quick` maps to `soxr quick`. Refer to [this](https://mpd.readthedocs.io/en/stable/plugins.html#soxr) page for details.
MPD_ENABLE_LOGGING|Defaults to `yes`, set to `no` to disable
MPD_LOG_LEVEL|Can be `default` or `verbose`
ZEROCONF_ENABLED|Set to `yes` to enable. Disabled by default.
ZEROCONF_NAME|Set zeroconf name, used only if `ZEROCONF_ENABLED` is set to `yes`
HYBRID_DSD_ENABLED|Hybrid dsd is enabled by default, set to `no` to disable. Disabled when at least one PulseAudio output is created.
MAX_OUTPUT_BUFFER_SIZE|The maximum size of the output buffer to a client (maximum response size). Default is 8192 (8 MiB). Value in KBytes.
AUDIO_BUFFER_SIZE|Adjust the size of the internal audio buffer. Default is `4 MB` (4 MiB).
MAX_ADDITIONAL_OUTPUTS_BY_TYPE|The maximum number of outputs by type, defaults to `20`
RESTORE_PAUSED|If set to `yes`, then MPD is put into pause mode instead of starting playback after startup. Default is `no`.
STATE_FILE_INTERVAL|Auto-save the state file this number of seconds after each state change, defaults to `10` seconds
ENFORCE_PLAYER_STATE|If set to `yes`, it will remove player state information from the state file, so the player state will only depend on the environment variables. Defaults to `yes`
FORCE_REPO_BINARY|If set to `yes`, the binary from the distro repository will be used
DEFAULT_PERMISSIONS|Sets `default_permissions`, see [here](https://mpd.readthedocs.io/en/stable/user.html#permissions-and-passwords)
LOCAL_PERMISSIONS|Sets `local_permissions`, see [here](https://mpd.readthedocs.io/en/stable/user.html#permissions-and-passwords)
HOST_PERMISSIONS|Adds a `host_permissions`, you can add multiple (up to `MAX_PERMISSIONS`), append `_1`, `_2`, etc to the variable name for additional entries, see [here](https://mpd.readthedocs.io/en/stable/user.html#permissions-and-passwords)
PASSWORD|Adds a `password`, you can add multiple (up to `MAX_PERMISSIONS`), append `_1`, `_2`, etc to the variable name for additional entries, see [here](https://mpd.readthedocs.io/en/stable/user.html#permissions-and-passwords)
MAX_PERMISSIONS|Specify the maximum number of host_permissions and passwords, defaults to `10`
STARTUP_DELAY_SEC|Delay before starting the application in seconds, defaults to `0`.

#### SOXR Plugin

Please find here the variables used to configure the SOXR plugin.

VARIABLE|DESCRIPTION
:---|:---
SOXR_PLUGIN_ENABLE|Enable the `soxr` plugin. Do not use in conjunction with variable `SAMPLERATE_CONVERTER`
SOXR_PLUGIN_PRESET|Presets for SOXR_PLUGIN configuration. Available presets: `goldilocks` and `extremus`
SOXR_PLUGIN_THREADS|The number of libsoxr threads. `0` means automatic. The default is `1` which disables multi-threading.
SOXR_PLUGIN_QUALITY|The quality of `soxr` resampler. Possible values: `very high`, `high` (the default), `medium`, `low`, `quick`, `custom`. When set to `custom`, the additional `soxr` parameters can be set.
SOXR_PLUGIN_PRECISION|The precision in bits. Valid values `16`,`20`,`24`,`28` and `32` bits.
SOXR_PLUGIN_PHASE_RESPONSE|Between the 0-100, where `0` is MINIMUM_PHASE and `50` is LINEAR_PHASE
SOXR_PLUGIN_PASSBAND_END|The % of source bandwidth where to start filtering. Typical between the 90-99.7.
SOXR_PLUGIN_STOPBAND_BEGIN|The % of the source bandwidth Where the anti aliasing filter start. Value 100+.
SOXR_PLUGIN_ATTENUATION|Reduction in dB’s to prevent clipping from the resampling process
SOXR_PLUGIN_FLAGS|Bitmask with additional options, see soxr documentation for specific flags

#### ReplayGain Settings

Please find here the variables used to configure ReplayGain.

VARIABLE|DESCRIPTION
:---|:---
REPLAYGAIN_MODE|ReplayGain Mode, defaults to `off`
REPLAYGAIN_PREAMP|ReplayGain Preamp, defaults to `0`
REPLAYGAIN_MISSING_PREAMP|ReplayGain missing preamp, defaults to `0`
REPLAYGAIN_LIMIT|ReplayGain Limit, defaults to `yes`
VOLUME_NORMALIZATION|Volume normalization, defaults to `no`

#### Qobuz Plugin

Please find here the variables used to configure the Qobuz plugin.

VARIABLE|DESCRIPTION
:---|:---
QOBUZ_PLUGIN_ENABLED|Enables the Qobuz plugin, defaults to `no`
QOBUZ_APP_ID|Qobuz application id
QOBUZ_APP_SECRET|Your Qobuz application Secret
QOBUZ_USERNAME|Qobuz account username
QOBUZ_PASSWORD|Qobuz account password
QOBUZ_FORMAT_ID|The Qobuz format identifier, i.e. a number which chooses the format and quality to be requested from Qobuz. The default is `5` (320 kbit/s MP3).

#### Scrobbling

Please find here the variables used to configure scrobbling. All of those are of course optional.  
Credentials of course go in pairs, so in order to enable one serve, you must provide both username and password.

VARIABLE|DESCRIPTION
:---|:---
LASTFM_USERNAME|Username for Last.fm
LASTFM_PASSWORD|Password for Last.fm
LIBREFM_USERNAME|Username for Libre.fm
LIBREFM_PASSWORD|Password for Libre.fm
JAMENDO_USERNAME|Username for Jamendo
JAMENDO_PASSWORD|Password for Jamendo
SCRIBBLE_VERBOSE|How verbose `mpdscribble`'s logging should be. Default is 1.
SCROBBLER_MPD_HOSTNAME|Set when using host mode, defaults to `localhost`
SCROBBLER_MPD_PORT|Set when using host mode, defaults to `6600`
PROXY|Proxy support for `mpdscribble`. Example value: `http://the.proxy.server:3128`

#### Additional Outputs

You can define additional outputs of various types. Refer to the following paragraphs.  
For each type, that you can add up to 20 (or what is specified for the variable `MAX_ADDITIONAL_OUTPUTS_BY_TYPE`) additional outputs for each type. In order to specify distinct values, you can add `_1`, `_2` to every variable names in this set. The first output does *not* require to specify `_0`, that index is implicit.  
The output name of those outputs, if not explicitly set, is created by appending with `_1`, `_2`, ... to the defaut name, so in the case of PulseAudio, the names of output will be `PulseAudio_1`, `PulseAudio_2`, ...  

#### ALSA additional outputs

Additional alsa outputs can be configured using the following variables:

VARIABLE|DESCRIPTION
:---|:---
ALSA_OUTPUT_CREATE|Set to `yes` if you want to create an additional alsa output
ALSA_OUTPUT_ENABLED|Sets the output as enabled if set to `yes`, otherwise mpd's default behavior applies
ALSA_OUTPUT_NAME|The name of the alsa output, defaults to `alsa`
ALSA_OUTPUT_PRESET|Use an Alsa preset for easier configuration
ALSA_OUTPUT_DEVICE|The audio device. Common examples: `hw:DAC` or `hw:x20` or `hw:X20` for usb dac based on XMOS chips. Defaults to `default`
ALSA_OUTPUT_AUTO_FIND_MIXER|Allows to auto-select the mixer for easy hardware volume configuration
ALSA_OUTPUT_MIXER_TYPE|Mixer type, defaults to `hardware`
ALSA_OUTPUT_MIXER_DEVICE|Mixer device, defaults to `default`
ALSA_OUTPUT_MIXER_CONTROL|Mixer Control, defaults to `PCM`
ALSA_OUTPUT_MIXER_INDEX|Mixer Index, defaults to `0`
ALSA_OUTPUT_ALLOWED_FORMATS_PRESET|Alternative to `ALSA_OUTPUT_ALLOWED_FORMATS`. Possible values: 8x, 4x, 2x, 8x-nodsd, 4x-nodsd, 2x-nodsd
ALSA_OUTPUT_ALLOWED_FORMATS|Sets allowed formats
ALSA_OUTPUT_OUTPUT_FORMAT|Sets output format
ALSA_OUTPUT_AUTO_RESAMPLE|If set to no, then libasound will not attempt to resample. In this case, the user is responsible for ensuring that the requested sample rate can be produced natively by the device, otherwise an error will occur.
ALSA_OUTPUT_THESYCON_DSD_WORKAROUND|If enabled, enables a workaround for a bug in Thesycon USB audio receivers. On these devices, playing DSD512 or PCM causes all subsequent attempts to play other DSD rates to fail, which can be fixed by briefly playing PCM at 44.1 kHz.
ALSA_OUTPUT_INTEGER_UPSAMPLING|If one or more `ALSA_ALLOWED_FORMATS` are set and `INTEGER_UPSAMPLING` is set to `yes`, the formats which are evenly divided by the source sample rate are preferred. The `ALSA_ALLOWED_FORMATS` list is processed in order as provided to the container. So if you want to upsample, put higher sampling rates first. Using this feature causes a patched version of mpd to be run. Use at your own risk.
ALSA_OUTPUT_INTEGER_UPSAMPLING_ALLOWED|Allows selection of sample rates to be upsampled. If set, only specified values are allowed. The values should respect the same format user for `ALSA_OUTPUT_ALLOWED_FORMATS`
ALSA_OUTPUT_INTEGER_UPSAMPLING_ALLOWED_PRESET|Preset for `ALSA_OUTPUT_INTEGER_UPSAMPLING_ALLOWED`. Allowed values are `base` (for 44.1kHz and 48.0kHz) and `44` for 44.1kHz only
ALSA_OUTPUT_DOP|Enables Dsd-Over-Pcm. Possible values: `yes` or `no`. Empty by default: this it lets mpd handle dop setting.

Refer to the MPD [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#alsa-plugin) for the meaning of the variables.  

#### PulseAudio additional outputs

Remember to setup [user mode](https://github.com/GioF71/mpd-alsa-docker/blob/main/doc/user-mode.md) when using PulseAudio outputs, otherwise they won't work.  
Additional PulseAudio outputs can be configured using the following variables:

VARIABLE|DESCRIPTION
:---|:---
PULSE_AUDIO_OUTPUT_CREATE|Set to `yes` if you want to create an additional PulseAudio output
PULSE_AUDIO_OUTPUT_ENABLED|Sets the output as enabled if set to `yes`, otherwise mpd's default behavior applies
PULSE_AUDIO_OUTPUT_NAME|The name of the PulseAudio output, defaults to `PulseAudio`
PULSE_AUDIO_OUTPUT_SINK|Specifies the name of the PulseAudio sink MPD should play on
PULSE_AUDIO_OUTPUT_MEDIA_ROLE|Media role for the PulseAudio output
PULSE_AUDIO_OUTPUT_SCALING_FACTOR|Scaling factor for the PulseAudio output

Refer to the MPD [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#pulse) for the meaning of the variables.  

#### HTTPD additional outputs

Additional httpd outputs can be configured using the following variables:

VARIABLE|DESCRIPTION
:---|:---
HTTPD_OUTPUT_CREATE|Set to `yes` if you want to create an additional httpd output
HTTPD_OUTPUT_ENABLED|Sets the output as enabled if set to `yes`, otherwise mpd's default behavior applies
HTTPD_OUTPUT_NAME|The name of the httpd output, defaults to `httpd`
HTTPD_OUTPUT_PORT|The port for the httpd output stream, defaults to `8000` if not specified
HTTPD_OUTPUT_BIND_TO_ADDRESS|Allows to specify the bind address
HTTPD_OUTPUT_ENCODER|The encoder defaults to `wave`, see [here](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins) for other options
HTTPD_OUTPUT_ENCODER_BITRATE|Encoder bitrate. Refer to the encoder [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins)
HTTPD_OUTPUT_ENCODER_QUALITY|Encoder quality. Refer to the encoder [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins)
HTTPD_OUTPUT_MAX_CLIENTS|Sets a limit, number of concurrent clients. When set to 0 no limit will apply. Defaults to `0`
HTTPD_OUTPUT_ALWAYS_ON|If set to `yes`, then MPD attempts to keep this audio output always open. This may be useful for streaming servers, when you don’t want to disconnect all listeners even when playback is accidentally stopped. Defaults to `yes`
HTTPD_OUTPUT_TAGS|If set to no, then MPD will not send tags to this output. This is only useful for output plugins that can receive tags, for example the httpd output plugin. Defaults to `yes`
HTTPD_OUTPUT_FORMAT|The output format, defaults to `44100:16:2`
HTTPD_MIXER_TYPE|Set to `software` if you want to be able to change the volume of the output stream

The port number default is calculated for each index by incrementing the default (`8000`) value.  
When using multiple httpd outputs, remember to open *all* the relevant ports, not only `8000`, otherwise only the first output will work.

#### Shout additional outputs

VARIABLE|DESCRIPTION
:---|:---
SHOUT_OUTPUT_CREATE|Set to `yes` if you want to create an additional shout output
SHOUT_OUTPUT_ENABLED|Sets the output as enabled if set to `yes`, otherwise mpd's default behavior applies
SHOUT_OUTPUT_NAME|The name of the shout output, defaults to `shout`
SHOUT_OUTPUT_PROTOCOL|Specifies the protocol that wil be used to connect to the server, can be `icecast2` (default), `icecast1`, `shoutcast`
SHOUT_OUTPUT_TLS|Specifies what kind of TLS to use, can be `disabled` (default), `auto`, `auto_no_plain`, `rfc2818`, `rfc2817`
SHOUT_OUTPUT_FORMAT|The output format, defaults to `44100:16:2`
SHOUT_OUTPUT_ENCODER|The encoder defaults to `vorbis`, see [here](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins) for other options. BITRATE and QUALITY are typically alternative, so do not specify both of them.
SHOUT_OUTPUT_ENCODER_BITRATE|Encoder bitrate. Refer to the encoder [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins)
SHOUT_OUTPUT_ENCODER_QUALITY|Encoder quality. Refer to the encoder [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#encoder-plugins)
SHOUT_OUTPUT_HOST|Sets the host name of the ShoutCast / IceCast server, defaults to `icecast`, this seems a sensible default in a docker environment
SHOUT_OUTPUT_PORT|Connect to this port number on the specified host, defaults to `8000`
SHOUT_OUTPUT_MOUNT|Mounts the MPD stream in the specified URI
SHOUT_OUTPUT_USER|Sets the user name for submitting the stream to the server, defaults to `source`
SHOUT_OUTPUT_PASSWORD|Sets the password for submitting the stream to the server, defaults to `hackme`
SHOUT_OUTPUT_PUBLIC|Specifies whether the stream should be "public", defaults to `no`
SHOUT_MIXER_TYPE|Set to `software` if you want to be able to change the volume of the output stream

#### Null additional outputs

Additional Null can be configured using the following variables:

VARIABLE|DESCRIPTION
:---|:---
NULL_OUTPUT_CREATE|Set to `yes` if you want to create an additional null output
NULL_OUTPUT_ENABLED|Sets the output as enabled if set to `yes`, otherwise mpd's default behavior applies
NULL_OUTPUT_NAME|The name of the Null output, defaults to `null`
NULL_OUTPUT_SYNC|Sync mode for the `null` output, can be `yes` (default) or `no`

Refer to the MPD [documentation](https://mpd.readthedocs.io/en/stable/plugins.html#null) for the meaning of the variables.  

### Examples

See some usage examples [here](https://github.com/GioF71/mpd-alsa-docker/blob/main/doc/example-configurations.md).

## Support for Scrobbling

If at least one set of credentials for `Last.fm`, `Libre.fm` or `Jamendo` are provided, `mpdscribble` will be started and it will scrobble the songs you play.  
You can provide credential using the environment variables or using credential files stored in the volume `/user/config`.  
The relevant files are:

- lastfm.txt
- librefm.txt
- jamendo.txt

## Run as a user-level systemd

When using a desktop system with PulseAudio, running a docker-compose with a `restart=unless-stopped` is likely to cause issues to the entire PulseAudio. At least that is what is systematically happening to me on my desktop systems.  
You might want to create a user-level systemd unit. In order to do that, move to the `pulse` directory of this repo, then run the following to install the service:

```code
./install.sh
```

After that, the service can be controlled using `./start.sh`, `./stop.sh`, `./restart.sh`.  
You can completely uninstall the service by running:

```code
./uninstall.sh
```

## Equalization support

Please find documentation [here](https://github.com/GioF71/mpd-alsa-docker/blob/main/doc/alsa-eq.md).

## Build

See [this](https://github.com/GioF71/mpd-alsa-docker/blob/main/doc/build.md) document.

## Change history

See [this](https://github.com/GioF71/mpd-alsa-docker/blob/main/doc/change-history.md) document.
