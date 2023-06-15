#!/bin/bash

# error codes
# 2 Invalid base image
# 3 Invalid proxy parameter

declare -A base_image_tags

base_image_tags[local-bookworm]=giof71/mpd-compiler:local-bookworm
base_image_tags[local-bullseye]=giof71/mpd-compiler:local-bullseye
base_image_tags[local-lunar]=giof71/mpd-compiler:local-lunar
base_image_tags[local-kinetic]=giof71/mpd-compiler:local-kinetic
base_image_tags[local-jammy]=giof71/mpd-compiler:local-jammy
base_image_tags[bullseye]=giof71/mpd-compiler:bullseye
base_image_tags[bookworm]=giof71/mpd-compiler:bookworm
base_image_tags[lunar]=giof71/mpd-compiler:lunar
base_image_tags[kinetic]=giof71/mpd-compiler:kinetic
base_image_tags[jammy]=giof71/mpd-compiler:jammy
base_image_tags[vanilla-bookworm]=debian:bookworm-slim
base_image_tags[vanilla-buster]=debian:buster-slim
base_image_tags[vanilla-bullseye]=debian:bullseye-slim
base_image_tags[vanilla-lunar]=ubuntu:lunar
base_image_tags[vanilla-kinetic]=ubuntu:kinetic
base_image_tags[vanilla-jammy]=ubuntu:jammy
base_image_tags[vanilla-focal]=ubuntu:focal
base_image_tags[vanilla-bionic]=ubuntu:bionic

declare -A local_tag
local_tag[bookworm]=local-bookworm
local_tag[bullseye]=local-bullseye
local_tag[buster]=local-buster
local_tag[lunar]=local-lunar
local_tag[kinetic]=local-kinetic
local_tag[jammy]=local-jammy
local_tag[focal]=local-focal
local_tag[bionic]=local-bionic
local_tag[local-bookworm]=local-bookworm
local_tag[local-bullseye]=local-bullseye
local_tag[local-buster]=local-buster
local_tag[local-lunar]=local-lunar
local_tag[local-kinetic]=local-kinetic
local_tag[local-jammy]=local-jammy
local_tag[local-focal]=local-focal
local_tag[local-bionic]=local-bionic
local_tag[vanilla-bookworm]=local-vanilla-bookworm
local_tag[vanilla-bullseye]=local-vanilla-bullseye
local_tag[vanilla-lunar]=local-vanilla-lunar
local_tag[vanilla-buster]=local-vanilla-buster
local_tag[vanilla-kinetic]=local-vanilla-kinetic
local_tag[vanilla-jammy]=local-vanilla-jammy
local_tag[vanilla-focal]=local-vanilla-focal
local_tag[vanilla-bionic]=local-vanilla-bionic

declare -A integer_upsampling_support_dict
integer_upsampling_support_dict[local-bookworm]=yes
integer_upsampling_support_dict[local-bullseye]=yes
integer_upsampling_support_dict[local-lunar]=yes
integer_upsampling_support_dict[local-kinetic]=yes
integer_upsampling_support_dict[local-jammy]=yes
integer_upsampling_support_dict[bookworm]=yes
integer_upsampling_support_dict[bullseye]=yes
integer_upsampling_support_dict[lunar]=yes
integer_upsampling_support_dict[kinetic]=yes
integer_upsampling_support_dict[jammy]=yes

DEFAULT_BASE_IMAGE=bookworm
DEFAULT_TAG=local
DEFAULT_USE_PROXY=N

tag=""
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

if [[ -z "${tag}" ]]; then
  echo "Selecting tag by base image ..."
  select_tag=${local_tag[$base_image_tag]}
  if [[ -n "$select_tag" ]]; then
    echo "  using tag $select_tag"
    tag=$select_tag
  else
    echo "  using default tag $DEFAULT_TAG"
    tag=$DEFAULT_TAG
  fi
fi

integer_upsampling_support=${integer_upsampling_support_dict[$base_image_tag]}
if [ -z "${integer_upsampling_support}" ]; then
  echo "Integer upsampling support table entry missing for ["${base_image_tag}"], assuming \"no\""
  integer_upsampling_support="no"
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

echo "Base Image Tag: [$selected_image_tag]"
echo "Integer Upsampling support: [$integer_upsampling_support]"
echo "Build Tag: [$tag]"
echo "Proxy: [$proxy]"

docker build . \
    --build-arg BASE_IMAGE=${selected_image_tag} \
    --build-arg USE_APT_PROXY=${proxy} \
    --build-arg INTEGER_UPSAMPLING_SUPPORT=${integer_upsampling_support} \
    -t giof71/mpd-alsa:$tag
