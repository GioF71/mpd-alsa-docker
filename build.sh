#!/bin/bash

# error codes
# 2 Invalid base image
# 3 Invalid proxy parameter

declare -A base_image_tags

base_image_tags[bookworm]=bookworm-slim
base_image_tags[buster]=buster-slim
base_image_tags[bullseye]=bullseye-slim
base_image_tags[jammy]=jammy
base_image_tags[kinetic]=kinetic
base_image_tags[focal]=focal
base_image_tags[bionic]=bionic

DEFAULT_BASE_IMAGE=bullseye
DEFAULT_TAG=local
DEFAULT_USE_PROXY=N

tag=$DEFAULT_TAG
git_branch="$DEFAULT_GIT_VERSION"

while getopts b:t:p: flag
do
    case "${flag}" in
        b) base_image_tag=${OPTARG};;
        t) tag=${OPTARG};;
        p) proxy=${OPTARG};;
    esac
done

echo "base_image_tag: $base_image_tag";
echo "tag: $tag";
echo "proxy: [$proxy]";

if [ -z "${base_image_tag}" ]; then
  base_image_tag=$DEFAULT_BASE_IMAGE
fi

selected_image_tag=${base_image_tags[$base_image_tag]}
if [ -z "${selected_image_tag}" ]; then
  echo "invalid base image ["${base_image_tag}"]"
  exit 2
fi

if [ -z "${proxy}" ]; then
  proxy="N"
fi
if [[ "${proxy}" == "Y" || "${proxy}" == "y" ]]; then  
  proxy="Y"
elif [[ "${proxy}" == "N" || "${proxy}" == "n" ]]; then  
  proxy="N"
else
  echo "invalid proxy parameter ["${proxy}"]"
  exit 3
fi

if [ -z "${git_branch}" ]; then
  git_branch="${DEFAULT_GIT_VERSION}"
fi

echo "Base Image Tag: ["$selected_image_tag"]"
echo "Build Tag: ["$tag"]"
echo "Proxy: ["$proxy"]"

docker build . --no-cache \
    --build-arg BASE_IMAGE_TAG=${selected_image_tag} \
    --build-arg USE_APT_PROXY=${proxy} \
    -t giof71/mpd-alsa:$tag
