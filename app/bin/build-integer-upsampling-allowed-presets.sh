#!/bin/bash

declare -A integer_upsampling_allowed_presets

integer_upsampling_allowed_44=44
integer_upsampling_allowed_base=base

integer_upsampling_allowed_presets[$integer_upsampling_allowed_44]="44100:*:*"
integer_upsampling_allowed_presets[$integer_upsampling_allowed_base]="44100:*:* 48000:*:*"

