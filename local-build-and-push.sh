#!/bin/bash

TODAY=$(date '+%Y-%m-%d')
MPD_VERSION=0.24.15

echo "TODAY=${TODAY}"

# regular (using mpd-compiler)
docker buildx build . \
    --platform linux/amd64,linux/arm64/v8,linux/arm/v7,linux/arm/v6,linux/arm/v5 \
    --build-arg BASE_IMAGE=giof71/mpd-compiler:trixie-${MPD_VERSION} \
    --build-arg IS_VANILLA=no \
    --build-arg INTEGER_UPSAMPLING_SUPPORT=yes \
    --tag giof71/mpd-alsa:trixie \
    --tag giof71/mpd-alsa:trixie-${MPD_VERSION} \
    --tag giof71/mpd-alsa:trixie-${MPD_VERSION}-${TODAY} \
    --tag giof71/mpd-alsa:stable \
    --tag giof71/mpd-alsa:latest \
    --push

# vanilla
docker buildx build . \
    --platform linux/amd64,linux/arm64/v8,linux/arm/v7,linux/arm/v6,linux/arm/v5 \
    --build-arg BASE_IMAGE=debian:trixie-slim \
    --build-arg IS_VANILLA=yes \
    --build-arg INTEGER_UPSAMPLING_SUPPORT=no \
    --tag giof71/mpd-alsa:vanilla-trixie \
    --tag giof71/mpd-alsa:vanilla-trixie-${MPD_VERSION} \
    --tag giof71/mpd-alsa:vanilla-trixie-${MPD_VERSION}-${TODAY} \
    --tag giof71/mpd-alsa:vanilla-stable \
    --tag giof71/mpd-alsa:vanilla-latest \
    --tag giof71/mpd-alsa:vanilla \
    --push
