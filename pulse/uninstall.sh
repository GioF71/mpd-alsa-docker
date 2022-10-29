#!/bin/bash

systemctl --user stop mpd-pulse
systemctl --user disable mpd-pulse

source files.sh

env_file_toremove=$SERVICE_DIRECTORY/SERVICE_ENV_FILE
if [ -f $env_file_toremove ]; then
    echo "removing $env_file_toremove"
    rm $env_file_toremove
fi

systemctl --user reset-failed
systemctl --user daemon-reload


