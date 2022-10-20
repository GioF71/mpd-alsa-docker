#!/bin/bash

MPD_ALSA_CONFIG_FILE=/app/conf/mpd-alsa.conf

sed -i 's/MPD_AUDIO_DEVICE/'"$MPD_AUDIO_DEVICE"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/ALSA_DEVICE_NAME/'"$ALSA_DEVICE_NAME"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/MIXER_TYPE/'"$MIXER_TYPE"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/MIXER_DEVICE/'"$MIXER_DEVICE"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/MIXER_CONTROL/'"$MIXER_CONTROL"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/MIXER_INDEX/'"$MIXER_INDEX"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/DOP/'"$DOP"'/g' $MPD_ALSA_CONFIG_FILE

sed -i 's/QOBUZ_PLUGIN_ENABLED/'"$QOBUZ_PLUGIN_ENABLED"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/QOBUZ_APP_ID/'"$QOBUZ_APP_ID"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/QOBUZ_APP_SECRET/'"$QOBUZ_APP_SECRET"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/QOBUZ_USERNAME/'"$QOBUZ_USERNAME"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/QOBUZ_PASSWORD/'"$QOBUZ_PASSWORD"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/QOBUZ_FORMAT_ID/'"$QOBUZ_FORMAT_ID"'/g' $MPD_ALSA_CONFIG_FILE

sed -i 's/TIDAL_PLUGIN_ENABLED/'"$TIDAL_PLUGIN_ENABLED"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/TIDAL_APP_TOKEN/'"$TIDAL_APP_TOKEN"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/TIDAL_USERNAME/'"$TIDAL_USERNAME"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/TIDAL_PASSWORD/'"$TIDAL_PASSWORD"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/TIDAL_AUDIOQUALITY/'"$TIDAL_AUDIOQUALITY"'/g' $MPD_ALSA_CONFIG_FILE

sed -i 's/REPLAYGAIN_MODE/'"$REPLAYGAIN_MODE"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/REPLAYGAIN_PREAMP/'"$REPLAYGAIN_PREAMP"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/REPLAYGAIN_MISSING_PREAMP/'"$REPLAYGAIN_MISSING_PREAMP"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/REPLAYGAIN_LIMIT/'"$REPLAYGAIN_LIMIT"'/g' $MPD_ALSA_CONFIG_FILE
sed -i 's/VOLUME_NORMALIZATION/'"$VOLUME_NORMALIZATION"'/g' $MPD_ALSA_CONFIG_FILE

cat $MPD_ALSA_CONFIG_FILE

echo "About to sleep for $STARTUP_DELAY_SEC second(s)"
sleep $STARTUP_DELAY_SEC
echo "Ready to start."

if [[ -n LASTFM_USERNAME && -n LASTFM_PASSWORD ]] || 
   [[ -n LIBREFM_USERNAME && -n LIBREFM_PASSWORD ]] ||
   [[ -n JAMENDO_USERNAME && -n JAMENDO_PASSWORD ]]; then
    echo "At least one scrobbling service requested."
    MPD_HOSTNAME=$(hostname -I)
    SCROBBLE_CONFIG_FILE=/app/conf/scribble.conf
    touch $SCROBBLE_CONFIG_FILE
    echo "log = /app/scribble/scribble.log" >> $SCROBBLE_CONFIG_FILE
    if [ -n $SCRIBBLE_VERBOSE ]; then
        echo "verbose = $SCRIBBLE_VERBOSE" >> $SCROBBLE_CONFIG_FILE
    fi
    echo "host = $MPD_HOSTNAME" >> $SCROBBLE_CONFIG_FILE
    if [ -n "$LASTFM_USERNAME" ]; then
        echo "[last.fm]" >> $SCROBBLE_CONFIG_FILE
        echo "url = https://post.audioscrobbler.com/" >> $SCROBBLE_CONFIG_FILE 
        echo "username = ${LASTFM_USERNAME}" >> $SCROBBLE_CONFIG_FILE
        echo "password = ${LASTFM_PASSWORD}" >> $SCROBBLE_CONFIG_FILE
        echo "journal = /app/scribble/lastfm.journal" >> $SCROBBLE_CONFIG_FILE
    fi
    if [ -n "$LIBREFM_USERNAME" ]; then
        echo "[libre.fm]" >> $SCROBBLE_CONFIG_FILE
        echo "url = http://turtle.libre.fm/" >> $SCROBBLE_CONFIG_FILE 
        echo "username = ${LIBREFM_USERNAME}" >> $SCROBBLE_CONFIG_FILE
        echo "password = ${LIBREFM_PASSWORD}" >> $SCROBBLE_CONFIG_FILE
        echo "journal = /app/scribble/librefm.journal" >> $SCROBBLE_CONFIG_FILE
    fi
    if [ -n "$JAMENDO_USERNAME" ]; then
        echo "[jamendo]" >> $SCROBBLE_CONFIG_FILE
        echo "url = http://postaudioscrobbler.jamendo.com/" >> $SCROBBLE_CONFIG_FILE 
        echo "username = ${JAMENDO_USERNAME}" >> $SCROBBLE_CONFIG_FILE
        echo "password = ${JAMENDO_PASSWORD}" >> $SCROBBLE_CONFIG_FILE
        echo "journal = /app/scribble/jamendo.journal" >> $SCROBBLE_CONFIG_FILE
    fi
    echo "[file]" >> $SCROBBLE_CONFIG_FILE
    echo "file = /app/scribble/file.log" >> $SCROBBLE_CONFIG_FILE

    cat $SCROBBLE_CONFIG_FILE
    /usr/bin/mpdscribble --conf $SCROBBLE_CONFIG_FILE &
fi

/usr/bin/mpd --no-daemon $MPD_ALSA_CONFIG_FILE
