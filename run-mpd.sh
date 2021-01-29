#!/bin/sh

sed -i 's/MPD_AUDIO_DEVICE/hw:X20,0/g' /etc/mpd.conf

cat /etc/mpd.conf

/usr/bin/mpd --no-daemon /etc/mpd.conf
