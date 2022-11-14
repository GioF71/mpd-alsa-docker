#!/bin/bash

# error codes
# 2 Invalid output mode
# 3 Missing mandatory audio group gid for user mode with alsa
# 4 Incompatible settings

STABLE_MPD_BINARY=/app/bin/compiled/mpd
UPSAMPLING_MPD_BINARY=/app/bin/compiled/mpd-ups
REPO_MPD_BINARY=/usr/bin/mpd

mpd_binary=$STABLE_MPD_BINARY

declare -A file_dict

source build-soxr-presets.sh
source build-allowed-formats-presets.sh
source read-file.sh
source get-value.sh
source load-alsa-presets.sh

LASTFM_CREDENTIALS_FILE=/user/config/lastfm.txt
LIBREFM_CREDENTIALS_FILE=/user/config/librefm.txt
JAMENDO_CREDENTIALS_FILE=/user/config/librefm.txt

if [ -f "$LASTFM_CREDENTIALS_FILE" ]; then
    read_file $LASTFM_CREDENTIALS_FILE
    LASTFM_USERNAME=$(get_value "LASTFM_USERNAME" $PARAMETER_PRIORITY)
    LASTFM_PASSWORD=$(get_value "LASTFM_PASSWORD" $PARAMETER_PRIORITY)
fi

if [ -f "$LIBREFM_CREDENTIALS_FILE" ]; then
    read_file $LIBREFM_CREDENTIALS_FILE
    LIBREFM_USERNAME=$(get_value "LIBREFM_USERNAME" $PARAMETER_PRIORITY)
    LIBREFM_PASSWORD=$(get_value "LIBREFM_PASSWORD" $PARAMETER_PRIORITY)
fi

if [ -f "$JAMENDO_CREDENTIALS_FILE" ]; then
    read_file $JAMENDO_CREDENTIALS_FILE
    JAMENDO_USERNAME=$(get_value "JAMENDO_USERNAME" $PARAMETER_PRIORITY)
    JAMENDO_PASSWORD=$(get_value "JAMENDO_PASSWORD" $PARAMETER_PRIORITY)
fi

MPD_ALSA_CONFIG_FILE=/app/conf/mpd-alsa.conf

USE_USER_MODE="N"

if [ "${OUTPUT_MODE^^}" == "PULSE" ] || 
   [[ "${USER_MODE^^}" == "YES" || "${USER_MODE^^}" == "Y" ]]; then
    USE_USER_MODE="Y"
    echo "User mode enabled"
    echo "Creating user ...";
    DEFAULT_UID=1000
    DEFAULT_GID=1000
    if [ -z "${PUID}" ]; then
        PUID=$DEFAULT_UID;
        echo "Setting default value for PUID: ["$PUID"]"
    fi
    if [ -z "${PGID}" ]; then
        PGID=$DEFAULT_GID;
        echo "Setting default value for PGID: ["$PGID"]"
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
    if [ "${OUTPUT_MODE^^}" = "ALSA" ]; then
        if [ -z "${AUDIO_GID}" ]; then
            echo "AUDIO_GID is mandatory for user mode and alsa output"
            exit 3
        fi
        if [ $(getent group $AUDIO_GID) ]; then
            echo "Alsa Mode - Group with gid $AUDIO_GID already exists"
        else
            echo "Alsa Mode - Creating group with gid $AUDIO_GID"
            groupadd -g $AUDIO_GID mpd-audio
        fi
        echo "Alsa Mode - Adding $USER_NAME to gid $AUDIO_GID"
        AUDIO_GRP=$(getent group $AUDIO_GID | cut -d: -f1)
        echo "gid $AUDIO_GID -> group $AUDIO_GRP"
        usermod -a -G $AUDIO_GRP $USER_NAME
        echo "Alsa Mode - Successfully created $USER_NAME (group: $GROUP_NAME)";
    elif [ "${OUTPUT_MODE^^}" = "PULSE" ]; then
        echo "Pulse Mode - Adding $USER_NAME to group audio"
        usermod -a -G audio $USER_NAME
        echo "Pulse Mode - Successfully added $USER_NAME to group audio"
    else
        echo "Invalid output mode [${OUTPUT_MODE}]";
        exit 2;
    fi
    chown -R $USER_NAME:$GROUP_NAME /log
    chown -R $USER_NAME:$GROUP_NAME /db
    chown -R $USER_NAME:$GROUP_NAME /playlists
    chown -R $USER_NAME:$GROUP_NAME /app/scribble

    ## PulseAudio
    if [ "${OUTPUT_MODE^^}" = "PULSE" ]; then
        PULSE_CLIENT_CONF="/etc/pulse/client.conf"
        echo "Creating pulseaudio configuration file $PULSE_CLIENT_CONF..."
        cp /app/assets/pulse-client-template.conf $PULSE_CLIENT_CONF
        sed -i 's/PUID/'"$PUID"'/g' $PULSE_CLIENT_CONF
        cat $PULSE_CLIENT_CONF
    fi
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
echo "log_file              \"/log/mpd.log\"" >> $MPD_ALSA_CONFIG_FILE

if [ -n "${MPD_LOG_LEVEL}" ]; then
    echo "log_level             \"${MPD_LOG_LEVEL}\"" >> $MPD_ALSA_CONFIG_FILE
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

if [ "${OUTPUT_MODE^^}" = "ALSA" ]; then
    # see if user is using a preset
    if [ -n "${ALSA_PRESET}" ]; then
        echo "Using alsa preset ${ALSA_PRESET}"
        # NAME
        alsa_preset_key="${ALSA_PRESET}.name"
        alsa_preset_value="${alsa_presets[${alsa_preset_key}]}"
        if [[ -v alsa_preset_value ]]; then
            ALSA_DEVICE_NAME=${alsa_preset_value}
        fi
        # DEVICE
        alsa_preset_key="${ALSA_PRESET}.device"
        alsa_preset_value="${alsa_presets[${alsa_preset_key}]}"
        if [[ -v alsa_preset_value ]]; then
            MPD_AUDIO_DEVICE=$alsa_preset_value
        fi
        # MIXER TYPE
        alsa_preset_key="${ALSA_PRESET}.mixer-type"
        alsa_preset_value="${alsa_presets[${alsa_preset_key}]}"
        if [[ -v alsa_preset_value ]]; then
            MIXER_TYPE=$alsa_preset_value
        fi
        # MIXER DEVICE
        alsa_preset_key="${ALSA_PRESET}.mixer-device"
        alsa_preset_value="${alsa_presets[${alsa_preset_key}]}"
        if [[ -v alsa_preset_value ]]; then
            MIXER_DEVICE=$alsa_preset_value
        fi
        # MIXER CONTROL
        alsa_preset_key="${ALSA_PRESET}.mixer-control"
        alsa_preset_value="${alsa_presets[${alsa_preset_key}]}"
        if [[ -v alsa_preset_value ]]; then
            MIXER_CONTROL=$alsa_preset_value
        fi
        # MIXER INDEX
        alsa_preset_key="${ALSA_PRESET}.mixer-index"
        alsa_preset_value="${alsa_presets[${alsa_preset_key}]}"
        if [[ -v alsa_preset_value ]]; then
            MIXER_INDEX=$alsa_preset_value
        fi
    fi
    ## Add alsa output
    echo "audio_output {" >> $MPD_ALSA_CONFIG_FILE
        echo "  type               \"alsa\"" >> $MPD_ALSA_CONFIG_FILE
    if [ -n "${ALSA_DEVICE_NAME}" ]; then
        echo "  name               \"${ALSA_DEVICE_NAME}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MPD_AUDIO_DEVICE}" ]; then
        echo "  device             \"${MPD_AUDIO_DEVICE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MIXER_TYPE}" ]; then
        echo "  mixer_type         \"${MIXER_TYPE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MIXER_DEVICE}" ]; then
        echo "  mixer_device       \"${MIXER_DEVICE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MIXER_CONTROL}" ]; then
        echo "  mixer_control      \"${MIXER_CONTROL}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MIXER_INDEX}" ]; then
        echo "  mixer_index        \"${MIXER_INDEX}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${ALSA_OUTPUT_FORMAT}" ]; then
        echo "  format             \"${ALSA_OUTPUT_FORMAT}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${ALSA_ALLOWED_FORMATS_PRESET}" ]; then
        af_value="${allowed_formats_presets[${ALSA_ALLOWED_FORMATS_PRESET}]}"
        if [[ -v af_value ]]; then
            ALSA_ALLOWED_FORMATS=$af_value
        fi
    fi
    if [ -n "${ALSA_ALLOWED_FORMATS}" ]; then
        echo "  allowed_formats    \"${ALSA_ALLOWED_FORMATS}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${INTEGER_UPSAMPLING}" ]; then
        echo "  integer_upsampling \"${INTEGER_UPSAMPLING}\"" >> $MPD_ALSA_CONFIG_FILE
        mpd_binary=$UPSAMPLING_MPD_BINARY
    fi
    if [ -n "${DOP}" ]; then
        echo "  dop                \"${DOP}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    echo "}" >> $MPD_ALSA_CONFIG_FILE
elif [ "${OUTPUT_MODE^^}" = "PULSE" ]; then
    echo "audio_output {" >> $MPD_ALSA_CONFIG_FILE
    echo "  type \"pulse\"" >> $MPD_ALSA_CONFIG_FILE
    if [ -z "${PULSEAUDIO_OUTPUT_NAME}" ]; then
        PULSEAUDIO_OUTPUT_NAME="PulseAudio"
    fi
    echo "  name \"${PULSEAUDIO_OUTPUT_NAME}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "}" >> $MPD_ALSA_CONFIG_FILE
else
    echo "Invalid output mode [${OUTPUT_MODE}]";
    exit 2;
fi

if [[ "${SOXR_PLUGIN_ENABLE^^}" = "Y" || "${SOXR_PLUGIN_ENABLE^^}" = "YES" ]]; then
    if [ -n "${SAMPLERATE_CONVERTER}" ]; then
        echo "Cannot enable both soxr and samplerate_converter";
        exit 4;
    fi
    # SOXR_PRESET compatibility
    if [[ -n "${SOXR_PRESET}" && -z "${SOXR_PLUGIN_PRESET}" ]]; then
        echo "Using deprected SOXR_PRESET=[${SOXR_PRESET}], switch to SOXR_PLUGIN_PRESET asap. Support for SOXR_PRESET will be removed."
        SOXR_PLUGIN_PRESET=${SOXR_PRESET}
    fi
    if [ -n "${SOXR_PLUGIN_PRESET}" ]; then
        echo "Using soxr_preset: [${SOXR_PLUGIN_PRESET}]"
        sox_key="${SOXR_PLUGIN_PRESET}.${SOXR_PRESET_KEY_QUALITY}"
        sox_value="${soxr_plugin_presets[${sox_key}]}"
        if [[ -v sox_value ]]; then
            SOXR_PLUGIN_QUALITY=$sox_value
        fi
        sox_key="${SOXR_PLUGIN_PRESET}.${SOXR_PRESET_KEY_PRECISION}"
        sox_value="${soxr_plugin_presets[${sox_key}]}"
        if [[ -v sox_value ]]; then
            SOXR_PLUGIN_PRECISION=$sox_value
        fi
        sox_key="${SOXR_PLUGIN_PRESET}.${SOXR_PRESET_KEY_PHASE_RESPONSE}"
        sox_value="${soxr_plugin_presets[${sox_key}]}"
        if [[ -v sox_value ]]; then
            SOXR_PLUGIN_PHASE_RESPONSE=$sox_value
        fi
        sox_key="${SOXR_PLUGIN_PRESET}.${SOXR_PRESET_KEY_PASSBAND_END}"
        sox_value="${soxr_plugin_presets[${sox_key}]}"
        if [[ -v sox_value ]]; then
            SOXR_PLUGIN_PASSBAND_END=$sox_value
        fi
        sox_key="${SOXR_PLUGIN_PRESET}.${SOXR_PRESET_KEY_STOPBAND_BEGIN}"
        sox_value="${soxr_plugin_presets[${sox_key}]}"
        if [[ -v sox_value ]]; then
            SOXR_PLUGIN_STOPBAND_BEGIN=$sox_value
        fi
        sox_key="${SOXR_PLUGIN_PRESET}.${SOXR_PRESET_KEY_ATTENUATION}"
        sox_value="${soxr_plugin_presets[${sox_key}]}"
        if [[ -v sox_value ]]; then
            SOXR_PLUGIN_ATTENUATION=$sox_value
        fi
        sox_key="${SOXR_PLUGIN_PRESET}.${SOXR_PRESET_KEY_FLAGS}"
        sox_value="${soxr_plugin_presets[${sox_key}]}"
        if [[ -v sox_value ]]; then
            SOXR_PLUGIN_FLAGS=$sox_value
        fi
        sox_key="${SOXR_PLUGIN_PRESET}.${SOXR_PRESET_KEY_THREADS}"
        sox_value="${soxr_plugin_presets[${sox_key}]}"
        if [[ -v sox_value ]]; then
            SOXR_PLUGIN_THREADS=$sox_value
        fi
    fi


    echo "resampler {" >> $MPD_ALSA_CONFIG_FILE
    echo "  plugin          \"soxr\"" >> $MPD_ALSA_CONFIG_FILE
    if [ -n "${SOXR_PLUGIN_QUALITY}" ]; then
        echo "  quality         \"${SOXR_PLUGIN_QUALITY}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_THREADS}" ]; then
        echo "  threads         \"${SOXR_PLUGIN_THREADS}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_PRECISION}" ]; then
       echo "  precision       \"${SOXR_PLUGIN_PRECISION}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_PHASE_RESPONSE}" ]; then
        echo "  phase_response  \"${SOXR_PLUGIN_PHASE_RESPONSE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_PASSBAND_END}" ]; then
        echo "  passband_end    \"${SOXR_PLUGIN_PASSBAND_END}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_STOPBAND_BEGIN}" ]; then
        echo "  stopband_begin  \"${SOXR_PLUGIN_STOPBAND_BEGIN}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_ATTENUATION}" ]; then
        echo "  attenuation     \"${SOXR_PLUGIN_ATTENUATION}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_FLAGS}" ]; then
        echo "  flags           \"${SOXR_PLUGIN_FLAGS}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    echo "}" >> $MPD_ALSA_CONFIG_FILE
fi

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
if [ -n "${SAMPLERATE_CONVERTER}" ]; then
    echo "samplerate_converter \"${SAMPLERATE_CONVERTER}\"" >> $MPD_ALSA_CONFIG_FILE
fi

echo "filesystem_charset \"UTF-8\"" >> $MPD_ALSA_CONFIG_FILE

echo "About to sleep for $STARTUP_DELAY_SEC second(s)"
sleep $STARTUP_DELAY_SEC
echo "Ready to start."

## start from scratch
SCRIBBLE_CONFIG_FILE=/app/conf/scribble.conf
echo "# mpscribble configuration file" > $SCRIBBLE_CONFIG_FILE

if [[ -n "$LASTFM_USERNAME" && -n "$LASTFM_PASSWORD" ]] || 
   [[ -n "$LIBREFM_USERNAME" && -n "$LIBREFM_PASSWORD" ]] ||
   [[ -n "$JAMENDO_USERNAME" && -n "$JAMENDO_PASSWORD" ]]; then
    echo "At least one scrobbling service requested."
    MPD_HOSTNAME=localhost
    MPD_PORT=6600
    if [ -n "$SCROBBLER_MPD_HOSTNAME" ]; then
        MPD_HOSTNAME="${SCROBBLER_MPD_HOSTNAME}"
    fi
    if [ -n "$SCROBBLER_MPD_PORT" ]; then
        MPD_PORT="${SCROBBLER_MPD_PORT}"
    fi
    if [ -n "$PROXY" ]; then
        echo "proxy = $PROXY" >> $SCRIBBLE_CONFIG_FILE
    fi
    echo "log = /log/scrobbler.log" >> $SCRIBBLE_CONFIG_FILE
    if [ -n "$SCRIBBLE_VERBOSE" ]; then
        echo "verbose = $SCRIBBLE_VERBOSE" >> $SCRIBBLE_CONFIG_FILE
    fi
    echo "host = $MPD_HOSTNAME" >> $SCRIBBLE_CONFIG_FILE
    echo "port = $MPD_PORT" >> $SCRIBBLE_CONFIG_FILE
    if [ -n "$LASTFM_USERNAME" ]; then
        echo "[last.fm]" >> $SCRIBBLE_CONFIG_FILE
        echo "url = https://post.audioscrobbler.com/" >> $SCRIBBLE_CONFIG_FILE 
        echo "username = ${LASTFM_USERNAME}" >> $SCRIBBLE_CONFIG_FILE
        echo "password = ${LASTFM_PASSWORD}" >> $SCRIBBLE_CONFIG_FILE
        echo "journal = /log/mpdscribble-lastfm.journal" >> $SCRIBBLE_CONFIG_FILE
    fi
    if [ -n "$LIBREFM_USERNAME" ]; then
        echo "[libre.fm]" >> $SCRIBBLE_CONFIG_FILE
        echo "url = http://turtle.libre.fm/" >> $SCRIBBLE_CONFIG_FILE 
        echo "username = ${LIBREFM_USERNAME}" >> $SCRIBBLE_CONFIG_FILE
        echo "password = ${LIBREFM_PASSWORD}" >> $SCRIBBLE_CONFIG_FILE
        echo "journal = /log/mpdscribble-librefm.journal" >> $SCRIBBLE_CONFIG_FILE
    fi
    if [ -n "$JAMENDO_USERNAME" ]; then
        echo "[jamendo]" >> $SCRIBBLE_CONFIG_FILE
        echo "url = http://postaudioscrobbler.jamendo.com/" >> $SCRIBBLE_CONFIG_FILE 
        echo "username = ${JAMENDO_USERNAME}" >> $SCRIBBLE_CONFIG_FILE
        echo "password = ${JAMENDO_PASSWORD}" >> $SCRIBBLE_CONFIG_FILE
        echo "journal = /log/mpdscribble-jamendo.journal" >> $SCRIBBLE_CONFIG_FILE
    fi
    echo "[file]" >> $SCRIBBLE_CONFIG_FILE
    echo "file = /log/mpdscribble-file.log" >> $SCRIBBLE_CONFIG_FILE

    cat $SCRIBBLE_CONFIG_FILE
    CMD_LINE="/usr/bin/mpdscribble --conf $SCRIBBLE_CONFIG_FILE &"
    if [ $USE_USER_MODE == "Y" ]; then
        su - $USER_NAME -c "$CMD_LINE"
    else 
        eval "$CMD_LINE"
    fi
fi

cat $MPD_ALSA_CONFIG_FILE

CMD_LINE="$mpd_binary --no-daemon $MPD_ALSA_CONFIG_FILE"
echo "CMD_LINE=[$CMD_LINE]"
if [ $USE_USER_MODE == "Y" ]; then
    su - $USER_NAME -c "$CMD_LINE"
else
    eval "$CMD_LINE"
fi
