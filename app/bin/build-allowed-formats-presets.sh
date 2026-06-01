#!/bin/bash

declare -A allowed_formats_presets

allowed_16x=16x
allowed_8x=8x
allowed_4x=4x
allowed_2x=2x

allowed_16x_nodsd=16x-nodsd
allowed_8x_nodsd=8x-nodsd
allowed_4x_nodsd=4x-nodsd
allowed_2x_nodsd=2x-nodsd

allowed_16x_32bit=16x-32bit
allowed_8x_32bit=8x-32bit
allowed_4x_32bit=4x-32bit
allowed_2x_32bit=2x-32bit

allowed_16x_nodsd_32bit=16x-nodsd-32bit
allowed_8x_nodsd_32bit=8x-nodsd-32bit
allowed_4x_nodsd_32bit=4x-nodsd-32bit
allowed_2x_nodsd_32bit=2x-nodsd-32bit

allowed_formats_presets[$allowed_16x]="705600:*:* 768000:*:* *:dsd:*"
allowed_formats_presets[$allowed_8x]="352800:*:* 384000:*:* *:dsd:*"
allowed_formats_presets[$allowed_4x]="176400:*:* 192000:*:* *:dsd:*"
allowed_formats_presets[$allowed_2x]="88200:*:* 96000:*:* *:dsd:*"

allowed_formats_presets[$allowed_16x_32bit]="705600:32:* 768000:32:* *:dsd:*"
allowed_formats_presets[$allowed_8x_32bit]="352800:32:* 384000:32:* *:dsd:*"
allowed_formats_presets[$allowed_4x_32bit]="176400:32:* 192000:32:* *:dsd:*"
allowed_formats_presets[$allowed_2x_32bit]="88200:32:* 96000:32:* *:dsd:*"

allowed_formats_presets[$allowed_16x_nodsd]="705600:*:* 768000:*:*"
allowed_formats_presets[$allowed_8x_nodsd]="352800:*:* 384000:*:*"
allowed_formats_presets[$allowed_4x_nodsd]="176400:*:* 192000:*:*"
allowed_formats_presets[$allowed_2x_nodsd]="88200:*:* 96000:*:*"

allowed_formats_presets[$allowed_16x_nodsd_32bit]="705600:32:* 768000:32:*"
allowed_formats_presets[$allowed_8x_nodsd_32bit]="352800:32:* 384000:32:*"
allowed_formats_presets[$allowed_4x_nodsd_32bit]="176400:32:* 192000:32:*"
allowed_formats_presets[$allowed_2x_nodsd_32bit]="88200:32:* 96000:32:*"
