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

MPD_ALSA_CONFIG_FILE=/app/conf/mpd.conf

## start from scratch
echo "# mpd configuration file" > $MPD_ALSA_CONFIG_FILE

echo "music_directory       \"/music\"" >> $MPD_ALSA_CONFIG_FILE
echo "playlist_directory    \"/playlists\"" >> $MPD_ALSA_CONFIG_FILE
echo "db_file               \"/db/tag_cache\"" >> $MPD_ALSA_CONFIG_FILE
echo "state_file            \"/db/state\"" >> $MPD_ALSA_CONFIG_FILE
echo "sticker_file          \"/db/sticker\"" >> $MPD_ALSA_CONFIG_FILE
echo "bind_to_address       \"0.0.0.0\"" >> $MPD_ALSA_CONFIG_FILE

if [ -n "${MPD_LOG_LEVEL}" ]; then
    echo "log_level \"${MPD_LOG_LEVEL}\"" >> $MPD_ALSA_CONFIG_FILE
fi

## add input curl
echo "input {" >> $MPD_ALSA_CONFIG_FILE
echo "  plugin \"curl\"" >> $MPD_ALSA_CONFIG_FILE
echo "}" >> $MPD_ALSA_CONFIG_FILE

## Add Tidal plugin
echo "Tidal Plugin Enabled: [$TIDAL_PLUGIN_ENABLED]"
if [[ "${TIDAL_PLUGIN_ENABLED^^}" = "Y" || "${TIDAL_PLUGIN_ENABLED^^}" = "YES" ]]; then
    echo "input {" >> $MPD_ALSA_CONFIG_FILE
    echo "  enabled         \"yes\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  plugin          \"tidal\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  token           \"${TIDAL_APP_TOKEN}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  username        \"${TIDAL_USERNAME}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  password        \"${TIDAL_PASSWORD}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  audioquality    \"${TIDAL_AUDIOQUALITY}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "}" >> $MPD_ALSA_CONFIG_FILE
fi

## Add Qobuz plugin
echo "Qobuz Plugin Enabled: [$QOBUZ_PLUGIN_ENABLED]"
if [[ "${QOBUZ_PLUGIN_ENABLED^^}" = "Y" || "${QOBUZ_PLUGIN_ENABLED^^}" = "YES" ]]; then
    echo "input {" >> $MPD_ALSA_CONFIG_FILE
    echo "  enabled         \"yes\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  plugin          \"qobuz\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  app_id          \"${QOBUZ_APP_ID}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  app_secret      \"${QOBUZ_APP_SECRET}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  username        \"${QOBUZ_USERNAME}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  password        \"${QOBUZ_PASSWORD}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  format_id       \"${QOBUZ_FORMAT_ID}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "}" >> $MPD_ALSA_CONFIG_FILE
fi

## Add Decoder plugin
echo "decoder {" >> $MPD_ALSA_CONFIG_FILE
echo "  plugin  \"hybrid_dsd\"" >> $MPD_ALSA_CONFIG_FILE
echo "  enabled \"no\"" >> $MPD_ALSA_CONFIG_FILE
echo "}" >> $MPD_ALSA_CONFIG_FILE

## Add alsa output
echo "audio_output {" >> $MPD_ALSA_CONFIG_FILE
    echo "  type            \"alsa\"" >> $MPD_ALSA_CONFIG_FILE
if [ -n "${ALSA_DEVICE_NAME}" ]; then
    echo "  name            \"${ALSA_DEVICE_NAME}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${MPD_AUDIO_DEVICE}" ]; then
    echo "  device          \"${MPD_AUDIO_DEVICE}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${MIXER_TYPE}" ]; then
    echo "  mixer_type      \"${MIXER_TYPE}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${MIXER_DEVICE}" ]; then
    echo "  mixer_device    \"${MIXER_DEVICE}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${MIXER_CONTROL}" ]; then
    echo "  mixer_control   \"${MIXER_CONTROL}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${MIXER_INDEX}" ]; then
    echo "  mixer_index     \"${MIXER_INDEX}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${DOP}" ]; then
    echo "  dop             \"${DOP}\"" >> $MPD_ALSA_CONFIG_FILE
fi
echo "}" >> $MPD_ALSA_CONFIG_FILE

if [ -n "${REPLAYGAIN_MODE}" ]; then
    echo "replaygain \"${REPLAYGAIN_MODE}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${REPLAYGAIN_PREAMP}" ]; then
    echo "replaygain_preamp \"${REPLAYGAIN_PREAMP}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${REPLAYGAIN_MISSING_PREAMP}" ]; then
    echo "replaygain_missing_preamp \"${REPLAYGAIN_MISSING_PREAMP}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${REPLAYGAIN_LIMIT}" ]; then
    echo "replaygain_limit \"${REPLAYGAIN_LIMIT}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${VOLUME_NORMALIZATION}" ]; then
    echo "volume_normalization \"${VOLUME_NORMALIZATION}\"" >> $MPD_ALSA_CONFIG_FILE
fi

echo "filesystem_charset \"UTF-8\"" >> $MPD_ALSA_CONFIG_FILE

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

cat $MPD_ALSA_CONFIG_FILE

CMD_LINE="/usr/bin/mpd --no-daemon $MPD_ALSA_CONFIG_FILE"
if [ $USE_USER_MODE == "Y" ]; then
    su - $USER_NAME -c "$CMD_LINE"
else
    eval "$CMD_LINE"
fi
