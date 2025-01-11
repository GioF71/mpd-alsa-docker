# mpd-alsa-docker

## References

First and foremost, the reference to the awesome projects:

[Music Player Daemon](https://www.musicpd.org/)  
[MPDScribble](https://www.musicpd.org/clients/mpdscribble/)

## Support

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/H2H7UIN5D)  
Please see the [Goal](https://ko-fi.com/giof71/goal?g=0).  
Please note that support goal is limited to cover running costs for subscriptions to music services.

## Description

A docker image for mpd with support for both Alsa and PulseAudio.  
The container image also includes `mpdscribble`. In alternative, you can use [mpd-scrobbler-docker](https://github.com/GioF71/mpd-scrobbler-docker) as the scrobbler for this image.  
User mode is now possible when using `alsa` outputs, and of course it is mandatory (enforced) when using `pulse` outputs.  
Upsampling (even in integer mode) is now available via a patched version of MPD (an unmodified version is available as well).  
Also, thanks to a [feature request](https://github.com/GioF71/mpd-alsa-docker/issues/158) by user [XxAcielxX](https://github.com/XxAcielxX), who also contributed with the necessary documentation, we have a certain degree of support for equalization.  

## Available Archs on Docker Hub

- linux/amd64
- linux/arm/v7
- linux/arm64/v8
- linux/arm/v5 (for debian-based builds)

## Links

Source: [GitHub](https://github.com/giof71/mpd-alsa-docker)  
Images: [DockerHub](https://hub.docker.com/r/giof71/mpd-alsa)

## Where is the documentation?

The README.md file has grown to exceed the size limit allowed on Docker Hub (25KB).  
Please refer to the [source code repository](https://github.com/GioF71/mpd-alsa-docker) for the complete document.
