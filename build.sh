#!/bin/bash

declare -A base_images

base_images[buster]=giof71/mpd-base-image:mpd-0.21.5-buster-2022-02-12
base_images[bullseye]=giof71/mpd-base-image:mpd-0.22.6-bullseye-2022-02-12
base_images[focal]=giof71/mpd-base-image:mpd-0.21.20-ubuntu-focal-2022-02-12

DEFAULT_BASE_IMAGE=bullseye
DEFAULT_TAG=latest

tag=$DEFAULT_TAG

while getopts b:d:t: flag
do
    case "${flag}" in
        b) base_image=${OPTARG};;
        t) tag=${OPTARG};;
    esac
done

if [ -z "${base_image}" ]; then
  base_image=$DEFAULT_BASE_IMAGE
fi

expanded_base_image=${base_images[$base_image]}

echo "Base Image: ["$expanded_base_image"]"
echo "Tag: ["$tag"]"

docker build . \
    --build-arg BASE_IMAGE=${expanded_base_image} \
    -t giof71/mpd-alsa:$tag
