#!/bin/bash

declare -A allowed_formats_presets

allowed_8x=8x
allowed_4x=4x
allowed_2x=2x

allowed_8x_nodsd=8x-nodsd
allowed_4x_nodsd=4x-nodsd
allowed_2x_nodsd=2x-nodsd

allowed_formats_presets[$allowed_8x]="352800:*:* 384000:*:* *:dsd:*"
allowed_formats_presets[$allowed_4x]="176400:*:* 192000:*:* *:dsd:*"
allowed_formats_presets[$allowed_2x]="88200:*:* 96000:*:* *:dsd:*"

allowed_formats_presets[$allowed_8x_nodsd]="352800:*:* 384000:*:*"
allowed_formats_presets[$allowed_4x_nodsd]="176400:*:* 192000:*:*"
allowed_formats_presets[$allowed_2x_nodsd]="88200:*:* 96000:*:*"
