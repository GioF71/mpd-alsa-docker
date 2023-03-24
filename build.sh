#!/bin/bash

# error codes
# 2 Invalid base image
# 3 Invalid proxy parameter

declare -A base_image_tags

base_image_tags[local-bullseye]=giof71/mpd-compiler:local-bullseye
base_image_tags[local-bookworm]=giof71/mpd-compiler:local-bookworm
base_image_tags[local-jammy]=giof71/mpd-compiler:local-jammy
base_image_tags[local-kinetic]=giof71/mpd-compiler:local-kinetic
base_image_tags[bullseye]=giof71/mpd-compiler:bullseye
base_image_tags[bookworm]=giof71/mpd-compiler:bookworm
base_image_tags[jammy]=giof71/mpd-compiler:jammy
base_image_tags[kinetic]=giof71/mpd-compiler:kinetic

declare -A integer_upsampling_support_dict
integer_upsampling_support_dict[local-bookworm]=yes
integer_upsampling_support_dict[local-bullseye]=yes
integer_upsampling_support_dict[local-jammy]=yes
integer_upsampling_support_dict[local-kinetic]=yes
integer_upsampling_support_dict[bookworm]=yes
integer_upsampling_support_dict[bullseye]=yes
integer_upsampling_support_dict[jammy]=yes
integer_upsampling_support_dict[kinetic]=yes

declare -A libfmt_dict
libfmt_dict[local-bullseye]=libfmt7
libfmt_dict[bullseye]=libfmt7
libfmt_dict[local-bookworm]=libfmt9
libfmt_dict[bookworm]=libfmt9

DEFAULT_BASE_IMAGE=bullseye
DEFAULT_TAG=local-bullseye
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

integer_upsampling_support=${integer_upsampling_support_dict[$base_image_tag]}
if [ -z "${integer_upsampling_support}" ]; then
  echo "Integer upsampling support table entry missing for ["${base_image_tag}"]"
  exit 2
fi

libfmt_package_name=${libfmt_dict[$base_image_tag]}
if [ -z "${libfmt_package_name}" ]; then
  echo "LibFmt package table entry missing for ["${base_image_tag}"], probably not needed"
  #exit 2
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
echo "Package name libfmt: [$libfmt_package_name]"
echo "Build Tag: [$tag]"
echo "Proxy: [$proxy]"

docker build . \
    --build-arg BASE_IMAGE=${selected_image_tag} \
    --build-arg USE_APT_PROXY=${proxy} \
    --build-arg INTEGER_UPSAMPLING_SUPPORT=${integer_upsampling_support} \
    --build-arg LIBFMT_PACKAGE_NAME=${libfmt_package_name} \
    -t giof71/mpd-alsa:$tag
