#!/bin/bash

MPD_ALSA_CONFIG_FILE=/app/conf/mpd-alsa.conf

USE_USER_MODE="N"

if [[ "${USER_MODE^^}" == "YES" || "${USER_MODE^^}" ]]; then
    USE_USER_MODE="Y"
    echo "User mode enabled"
    echo "Creating user ...";
    DEFAULT_UID=1000
    DEFAULT_GID=1000
    DEFAULT_AUDIO_GID=995
    if [ -z "${PUID}" ]; then
        PUID=$DEFAULT_UID;
        echo "Setting default value for PUID: ["$PUID"]"
    fi
    if [ -z "${PGID}" ]; then
        PGID=$DEFAULT_GID;
        echo "Setting default value for PGID: ["$PGID"]"
    fi
    if [ -z "${AUDIO_GID}" ]; then
        AUDIO_GID=$DEFAULT_AUDIO_GID;
        echo "Setting default value for AUDIO_GID: ["$AUDIO_GID"]"
    fi
    USER_NAME=mpd-user
    GROUP_NAME=mpd-user
    HOME_DIR=/home/$USER_NAME
    ### create home directory and ancillary directories
    if [ ! -d "$HOME_DIR" ]; then
    echo "Home directory [$HOME_DIR] not found, creating."
    mkdir -p $HOME_DIR
    chown -R $PUID:$PGID $HOME_DIR
    ls -la $HOME_DIR -d
    ls -la $HOME_DIR
    fi
    ### create group
    if [ ! $(getent group $GROUP_NAME) ]; then
        echo "group $GROUP_NAME does not exist, creating..."
        groupadd -g $PGID $GROUP_NAME
    else
        echo "group $GROUP_NAME already exists."
    fi
    ### create user
    if [ ! $(getent passwd $USER_NAME) ]; then
        echo "user $USER_NAME does not exist, creating..."
        useradd -g $PGID -u $PUID -s /bin/bash -M -d $HOME_DIR $USER_NAME
        id $USER_NAME
        echo "user $USER_NAME created."
    else
        echo "user $USER_NAME already exists."
    fi
    if [ $(getent group $AUDIO_GID) ]; then
        echo "Group with gid $AUDIO_GID already exists"
    else
        echo "Creating group with gid $AUDIO_GID"
        groupadd -g $AUDIO_GID mpd-audio
    fi
    echo "Adding $USER_NAME to gid $AUDIO_GID"
    AUDIO_GRP=$(getent group $AUDIO_GID | cut -d: -f1)
    echo "gid $AUDIO_GID -> group $AUDIO_GRP"
    usermod -a -G $AUDIO_GRP $USER_NAME
    echo "Successfully created $USER_NAME (group: $GROUP_NAME)";

    chown -R $USER_NAME:$GROUP_NAME /log
    chown -R $USER_NAME:$GROUP_NAME /db
    chown -R $USER_NAME:$GROUP_NAME /playlists
    chown -R $USER_NAME:$GROUP_NAME /app/scribble
else 
    echo "User mode disabled"
fi

if [ -n "$MPD_LOG_LEVEL" ]; then
    sed -i 's/#log_level/'log_level'/g' $MPD_ALSA_CONFIG_FILE
    sed -i 's/MPD_LOG_LEVEL/'"$MPD_LOG_LEVEL"'/g' $MPD_ALSA_CONFIG_FILE
fi

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

if [[ -n "$LASTFM_USERNAME" && -n "$LASTFM_PASSWORD" ]] || 
   [[ -n "$LIBREFM_USERNAME" && -n "$LIBREFM_PASSWORD" ]] ||
   [[ -n "$JAMENDO_USERNAME" && -n "$JAMENDO_PASSWORD" ]]; then
    echo "At least one scrobbling service requested."
    MPD_HOSTNAME=$(hostname -I)
    SCRIBBLE_CONFIG_FILE=/app/conf/scribble.conf
    touch $SCRIBBLE_CONFIG_FILE
    if [ -n "$PROXY" ]; then
        echo "proxy = $PROXY" >> $SCRIBBLE_CONFIG_FILE
    fi
    echo "log = /app/scribble/scribble.log" >> $SCRIBBLE_CONFIG_FILE
    if [ -n "$SCRIBBLE_VERBOSE" ]; then
        echo "verbose = $SCRIBBLE_VERBOSE" >> $SCRIBBLE_CONFIG_FILE
    fi
    echo "host = $MPD_HOSTNAME" >> $SCRIBBLE_CONFIG_FILE
    if [ -n "$LASTFM_USERNAME" ]; then
        echo "[last.fm]" >> $SCRIBBLE_CONFIG_FILE
        echo "url = https://post.audioscrobbler.com/" >> $SCRIBBLE_CONFIG_FILE 
        echo "username = ${LASTFM_USERNAME}" >> $SCRIBBLE_CONFIG_FILE
        echo "password = ${LASTFM_PASSWORD}" >> $SCRIBBLE_CONFIG_FILE
        echo "journal = /app/scribble/lastfm.journal" >> $SCRIBBLE_CONFIG_FILE
    fi
    if [ -n "$LIBREFM_USERNAME" ]; then
        echo "[libre.fm]" >> $SCRIBBLE_CONFIG_FILE
        echo "url = http://turtle.libre.fm/" >> $SCRIBBLE_CONFIG_FILE 
        echo "username = ${LIBREFM_USERNAME}" >> $SCRIBBLE_CONFIG_FILE
        echo "password = ${LIBREFM_PASSWORD}" >> $SCRIBBLE_CONFIG_FILE
        echo "journal = /app/scribble/librefm.journal" >> $SCRIBBLE_CONFIG_FILE
    fi
    if [ -n "$JAMENDO_USERNAME" ]; then
        echo "[jamendo]" >> $SCRIBBLE_CONFIG_FILE
        echo "url = http://postaudioscrobbler.jamendo.com/" >> $SCRIBBLE_CONFIG_FILE 
        echo "username = ${JAMENDO_USERNAME}" >> $SCRIBBLE_CONFIG_FILE
        echo "password = ${JAMENDO_PASSWORD}" >> $SCRIBBLE_CONFIG_FILE
        echo "journal = /app/scribble/jamendo.journal" >> $SCRIBBLE_CONFIG_FILE
    fi
    echo "[file]" >> $SCRIBBLE_CONFIG_FILE
    echo "file = /app/scribble/file.log" >> $SCRIBBLE_CONFIG_FILE

    cat $SCRIBBLE_CONFIG_FILE
    CMD_LINE="/usr/bin/mpdscribble --conf $SCRIBBLE_CONFIG_FILE &"
    if [ $USE_USER_MODE == "Y" ]; then
        su - $USER_NAME -c "$CMD_LINE"
    else 
        eval "$CMD_LINE"
    fi
fi

CMD_LINE="/usr/bin/mpd --no-daemon $MPD_ALSA_CONFIG_FILE"
if [ $USE_USER_MODE == "Y" ]; then
    su - $USER_NAME -c "$CMD_LINE"
else
    eval "$CMD_LINE"
fi
