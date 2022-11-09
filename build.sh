#!/bin/bash

# error codes
# 2 Invalid base image
# 3 Invalid proxy parameter

declare -A base_images

base_images[bookworm]=debian:bookworm-slim
base_images[buster]=debian:buster-slim
base_images[bullseye]=debian:bullseye-slim
base_images[jammy]=ubuntu:jammy
base_images[kinetic]=ubuntu:kinetic
base_images[focal]=ubuntu:focal
base_images[bionic]=ubuntu:bionic

DEFAULT_BASE_IMAGE=bullseye
DEFAULT_TAG=local
DEFAULT_USE_PROXY=N
DEFAULT_GIT_VERSION=master-ups

download=$DEFAULT_SOURCEFORGE_DOWNLOAD
tag=$DEFAULT_TAG
git_branch="$DEFAULT_GIT_VERSION"

while getopts b:t:p:g: flag
do
    case "${flag}" in
        b) base_image=${OPTARG};;
        t) tag=${OPTARG};;
        p) proxy=${OPTARG};;
        g) git_branch=${OPTARG};;
    esac
done

echo "base_image: $base_image";
echo "tag: $tag";
echo "proxy: [$proxy]";
echo "git_branch: [$git_branch]";

if [ -z "${base_image}" ]; then
  base_image=$DEFAULT_BASE_IMAGE
fi

expanded_base_image=${base_images[$base_image]}
if [ -z "${expanded_base_image}" ]; then
  echo "invalid base image ["${base_image}"]"
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

echo "Base Image: ["$expanded_base_image"]"
echo "Tag: ["$tag"]"
echo "Proxy: ["$proxy"]"
echo "Git Branch: ["$git_branch"]"

docker build . \
    --build-arg BASE_IMAGE=${expanded_base_image} \
    --build-arg USE_APT_PROXY=${proxy} \
    --build-arg USE_GIT_BRANCH=${git_branch} \
    -t giof71/mpd-alsa:$tag
