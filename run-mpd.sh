#!/bin/sh

sed -i 's/MPD_AUDIO_DEVICE/'"$MPD_AUDIO_DEVICE"'/g' /etc/mpd.conf
sed -i 's/ALSA_DEVICE_NAME/'"$ALSA_DEVICE_NAME"'/g' /etc/mpd.conf
sed -i 's/MIXER_TYPE/'"$MIXER_TYPE"'/g' /etc/mpd.conf
sed -i 's/MIXER_DEVICE/'"$MIXER_DEVICE"'/g' /etc/mpd.conf
sed -i 's/MIXER_CONTROL/'"$MIXER_CONTROL"'/g' /etc/mpd.conf
sed -i 's/MIXER_INDEX/'"$MIXER_INDEX"'/g' /etc/mpd.conf

cat /etc/mpd.conf

/usr/bin/mpd --no-daemon /etc/mpd.conf
