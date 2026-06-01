#!/bin/bash

# error codes
# 2 Invalid base image

declare -A base_image_tags

base_image_tags[local-trixie]=giof71/mpd-compiler:local-trixie
base_image_tags[local-bookworm]=giof71/mpd-compiler:local-bookworm
base_image_tags[local-bullseye]=giof71/mpd-compiler:local-bullseye
base_image_tags[local-resolute]=giof71/mpd-compiler:local-resolute
base_image_tags[local-noble]=giof71/mpd-compiler:local-noble
base_image_tags[trixie]=giof71/mpd-compiler:trixie
base_image_tags[bookworm]=giof71/mpd-compiler:bookworm
base_image_tags[bullseye]=giof71/mpd-compiler:bullseye
base_image_tags[resolute]=giof71/mpd-compiler:resolute
base_image_tags[noble]=giof71/mpd-compiler:noble
base_image_tags[vanilla-sid]=debian:sid-slim
base_image_tags[vanilla-trixie]=debian:trixie-slim
base_image_tags[vanilla-bookworm]=debian:bookworm-slim
base_image_tags[vanilla-bullseye]=debian:bullseye-slim
base_image_tags[vanilla-resolute]=ubuntu:resolute
base_image_tags[vanilla-noble]=ubuntu:noble

declare -A local_tag
local_tag[trixie]=local-trixie
local_tag[bookworm]=local-bookworm
local_tag[bullseye]=local-bullseye
local_tag[resolute]=local-resolute
local_tag[noble]=local-noble
local_tag[local-trixie]=local-trixie
local_tag[local-bookworm]=local-bookworm
local_tag[local-bullseye]=local-bullseye
local_tag[local-resolute]=local-resolute
local_tag[local-noble]=local-noble
local_tag[vanilla-sid]=local-vanilla-sid
local_tag[vanilla-trixie]=local-vanilla-trixie
local_tag[vanilla-bookworm]=local-vanilla-bookworm
local_tag[vanilla-bullseye]=local-vanilla-bullseye
local_tag[vanilla-resolute]=local-vanilla-resolute
local_tag[vanilla-noble]=local-vanilla-noble

declare -A integer_upsampling_support_dict
integer_upsampling_support_dict[local-trixie]=yes
integer_upsampling_support_dict[local-bookworm]=yes
integer_upsampling_support_dict[local-bullseye]=yes
integer_upsampling_support_dict[local-resolute]=yes
integer_upsampling_support_dict[local-noble]=yes
integer_upsampling_support_dict[local-lunar]=yes
integer_upsampling_support_dict[trixie]=yes
integer_upsampling_support_dict[bookworm]=yes
integer_upsampling_support_dict[bullseye]=yes
integer_upsampling_support_dict[resolute]=yes
integer_upsampling_support_dict[noble]=yes

DEFAULT_BASE_IMAGE=trixie
DEFAULT_TAG=local
DEFAULT_USE_PROXY=N
DEFAULT_BUILD_MODE=full

tag=""
git_branch="$DEFAULT_GIT_VERSION"

while getopts b:t:m:p: flag
do
    case "${flag}" in
        b) base_image_tag=${OPTARG};;
        t) tag=${OPTARG};;
        m) build_mode=${OPTARG};;
    esac
done

echo "base_image_tag: $base_image_tag";
echo "tag: $tag";
echo "build_mode: [$build_mode]";

if [ -z "${base_image_tag}" ]; then
  base_image_tag=$DEFAULT_BASE_IMAGE
fi

if [ -z "${build_mode}" ]; then
  build_mode=$DEFAULT_BUILD_MODE
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

if [[ "${base_image_tag}" == *"vanilla"* ]]; then
  is_vanilla="yes"
else
  is_vanilla="no"
fi

echo "Vanilla build: [$is_vanilla]"

if [ -z "${git_branch}" ]; then
  git_branch="${DEFAULT_GIT_VERSION}"
fi

echo "Base Image Tag: [$selected_image_tag]"
echo "Integer Upsampling support: [$integer_upsampling_support]"
echo "Build Mode: [$build_mode]"
echo "Build Tag: [$tag]"

docker build . \
    --build-arg BASE_IMAGE=${selected_image_tag} \
    --build-arg BUILD_MODE=${build_mode} \
    --build-arg IS_VANILLA=${is_vanilla} \
    --build-arg INTEGER_UPSAMPLING_SUPPORT=${integer_upsampling_support} \
    -t giof71/mpd-alsa:$tag
