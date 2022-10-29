#!/bin/bash

source files.sh

# errors

# 2 missing credentials fileq

set -e

mkdir -p $SYSTEMD_USER_DIRECTORY
cp $SYSTEMD_SERVICE_FILE $SYSTEMD_USER_DIRECTORY/

mkdir -p $MPD_PULSE_CONFIG_DIR/db
mkdir -p $MPD_PULSE_CONFIG_DIR/playlists
mkdir -p $MPD_PULSE_CONFIG_DIR/log

systemctl --user daemon-reload
systemctl --user enable mpd-pulse
