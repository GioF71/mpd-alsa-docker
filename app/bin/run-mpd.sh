#!/bin/bash

# error codes
# 2 Invalid output mode
# 3 Missing mandatory audio group gid for user mode with alsa
# 4 Incompatible sample rate conversion settings
# 5 Incompatible database mode
# 6 Invalid auto_resample mode
# 7 Invalid thesycon_dsd_workaround mode
# 8 Invalid default type
# 9 Invalid parameter
# 10 Missing mandatory parameter

STABLE_MPD_BINARY=/app/bin/compiled/mpd
UPSAMPLING_MPD_BINARY=/app/bin/compiled/mpd-ups
REPO_MPD_BINARY=/usr/bin/mpd

DEFAULT_MAX_OUTPUTS_BY_TYPE=20
DEFAULT_OUTPUT_MODE=alsa
DEFAULT_ALSA_DEVICE_NAME="Alsa-Device"
DEFAULT_MPD_AUDIO_DEVICE="default"

if [ -n "${MAX_ADDITIONAL_OUTPUTS_BY_TYPE}" ]; then
    max_outputs_by_type=$MAX_ADDITIONAL_OUTPUTS_BY_TYPE
else
    max_outputs_by_type=$DEFAULT_MAX_OUTPUTS_BY_TYPE
fi
echo "MAX_OUTPUTS=[$max_outputs_by_type]"

mpd_binary=$STABLE_MPD_BINARY

declare -A file_dict

source build-soxr-presets.sh
source build-allowed-formats-presets.sh
source build-integer-upsampling-allowed-presets.sh
source read-file.sh
source get-value.sh
source load-alsa-presets.sh
source build-additional.sh
source user-management.sh
source any-of.sh

declare -A samplerate_converters
samplerate_converters[very_high]="soxr very high"
samplerate_converters[high]="soxr high"
samplerate_converters[medium]="soxr medium"
samplerate_converters[low]="soxr low"
samplerate_converters[quick]="soxr quick"

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

ANY_PULSE=$(any_pulse)
ANY_ALSA=$(any_alsa)

echo "ANY_PULSE=[$ANY_PULSE]"
echo "ANY_ALSA=[$ANY_ALSA]"

if [[ "${ANY_PULSE}" -eq 1 ]] || 
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
    if [ "${ANY_ALSA}" -eq 1 ]; then
        if [ -z "${AUDIO_GID}" ]; then
            echo "AUDIO_GID is mandatory for user mode and alsa output"
            exit 3
        else
            create_audio_gid
        fi
    elif [ "${ANY_PULSE}" -eq 1 ]; then
        if [ -n "${AUDIO_GID}" ]; then
            create_audio_gid
        fi
    fi
    chown -R $USER_NAME:$GROUP_NAME /log
    chown -R $USER_NAME:$GROUP_NAME /db
    chown -R $USER_NAME:$GROUP_NAME /playlists
    chown -R $USER_NAME:$GROUP_NAME /app/scribble

    ## PulseAudio
    if [ "${ANY_PULSE}" -eq 1 ]; then
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

DEFAULT_MPD_BIND_ADDRESS=0.0.0.0
if [ -z "${MPD_BIND_ADDRESS}" ]; then
    MPD_BIND_ADDRESS=${DEFAULT_MPD_BIND_ADDRESS}
fi

DEFAULT_MPD_PORT=6600
if [ -z "${MPD_PORT}" ]; then
    MPD_PORT=${DEFAULT_MPD_PORT}
fi

DEFAULT_DATABASE_MODE="simple"

if [ -z "${DATABASE_MODE}" ]; then
    DATABASE_MODE=${DEFAULT_DATABASE_MODE}
fi

## add database
echo "database {" >> $MPD_ALSA_CONFIG_FILE
echo "  plugin \"${DATABASE_MODE}\"" >> $MPD_ALSA_CONFIG_FILE
if [ "${DATABASE_MODE^^}" == "SIMPLE" ]; then
    echo "  path \"/db/tag_cache\"" >> $MPD_ALSA_CONFIG_FILE
elif [ "${DATABASE_MODE^^}" == "PROXY" ]; then
    echo "  host \"${DATABASE_PROXY_HOST}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  port \"${DATABASE_PROXY_PORT}\"" >> $MPD_ALSA_CONFIG_FILE
else
    echo "Invalid database mode [${DATABASE_MODE}]";
    exit 5;
fi
echo "}" >> $MPD_ALSA_CONFIG_FILE

DEFAULT_MUSIC_DIRECTORY="/music"

if [ -z "${MUSIC_DIRECTORY}" ]; then
    MUSIC_DIRECTORY=${DEFAULT_MUSIC_DIRECTORY}
fi

echo "music_directory \"${MUSIC_DIRECTORY}\"" >> $MPD_ALSA_CONFIG_FILE
echo "playlist_directory \"/playlists\"" >> $MPD_ALSA_CONFIG_FILE
echo "state_file \"/db/state\"" >> $MPD_ALSA_CONFIG_FILE

if [ -n "${RESTORE_PAUSED}" ]; then
    if [[ "${RESTORE_PAUSED^^}" == "YES" || "${RESTORE_PAUSED^^}" == "Y" ]]; then
        echo "restore_paused \"yes\"" >> $MPD_ALSA_CONFIG_FILE
    elif [[ "${RESTORE_PAUSED^^}" == "NO" || "${RESTORE_PAUSED^^}" == "N" ]]; then
        echo "restore_paused \"no\"" >> $MPD_ALSA_CONFIG_FILE
    else
        echo "Invalid parameter RESTORE_PAUSED=[${RESTORE_PAUSED}]"
        exit 9
    fi
fi

state_file_interval=10
if [ -n "${STATE_FILE_INTERVAL}" ]; then
    state_file_interval=${STATE_FILE_INTERVAL}
fi
echo "state_file_interval \"${state_file_interval}\"" >> $MPD_ALSA_CONFIG_FILE

echo "sticker_file \"/db/sticker\"" >> $MPD_ALSA_CONFIG_FILE
echo "bind_to_address \"${MPD_BIND_ADDRESS}\"" >> $MPD_ALSA_CONFIG_FILE
echo "port \"${MPD_PORT}\"" >> $MPD_ALSA_CONFIG_FILE

logging_enabled=1
if [ -n "${MPD_ENABLE_LOGGING}" ]; then
    if [[ "${MPD_ENABLE_LOGGING^^}" == "NO" || 
          "${MPD_ENABLE_LOGGING^^}" == "N" ]]; then
        logging_enabled=0
    elif [[ "${MPD_ENABLE_LOGGING^^}" != "YES" && 
            "${MPD_ENABLE_LOGGING^^}" != "Y" ]]; then
        echo "Invalid MPD_ENABLE_LOGGING=[${MPD_ENABLE_LOGGING}]"
        exit 9
    fi
fi

if [ $logging_enabled -eq 1 ]; then
    echo "log_file \"/log/mpd.log\"" >> $MPD_ALSA_CONFIG_FILE
    if [ -n "${MPD_LOG_LEVEL}" ]; then
        echo "log_level \"${MPD_LOG_LEVEL}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
else
    echo "Logging is disabled because MPD_ENABLE_LOGGING is set to [${MPD_ENABLE_LOGGING}]"
fi

if [[ "${ZEROCONF_ENABLED^^}" == "YES" || "${ZEROCONF_ENABLED^^}" == "Y" ]]; then
    ZEROCONF_ENABLED=yes
else
    ZEROCONF_ENABLED=no
    ZEROCONF_NAME=""
fi

echo "zeroconf_enabled \"${ZEROCONF_ENABLED}\"" >> $MPD_ALSA_CONFIG_FILE
if [ -n "${ZEROCONF_NAME}" ]; then
    echo "zeroconf_name \"${ZEROCONF_NAME}\"" >> $MPD_ALSA_CONFIG_FILE
fi

## disable wildmidi decoder
echo "decoder {" >> $MPD_ALSA_CONFIG_FILE
echo "  plugin \"wildmidi\"" >> $MPD_ALSA_CONFIG_FILE
echo "  enabled \"no\"" >> $MPD_ALSA_CONFIG_FILE
echo "}" >> $MPD_ALSA_CONFIG_FILE

## add input curl
echo "input {" >> $MPD_ALSA_CONFIG_FILE
echo "  plugin \"curl\"" >> $MPD_ALSA_CONFIG_FILE
echo "}" >> $MPD_ALSA_CONFIG_FILE

if [ -n "${INPUT_CACHE_SIZE}" ]; then
    echo "input_cache {" >> $MPD_ALSA_CONFIG_FILE
    echo "  size \"${INPUT_CACHE_SIZE}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "}" >> $MPD_ALSA_CONFIG_FILE
fi

## Hybrid dsd plugin disabled when requested
if [[ "${HYBRID_DSD_ENABLED^^}" == "NO" || "${ANY_PULSE}" -eq 1 ]]; then
    echo "decoder {" >> $MPD_ALSA_CONFIG_FILE
    echo "  plugin \"hybrid_dsd\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  enabled \"no\"" >> $MPD_ALSA_CONFIG_FILE
    echo "}" >> $MPD_ALSA_CONFIG_FILE
fi

## Add Qobuz plugin
echo "Qobuz Plugin Enabled: [$QOBUZ_PLUGIN_ENABLED]"
if [[ "${QOBUZ_PLUGIN_ENABLED^^}" == "Y" || "${QOBUZ_PLUGIN_ENABLED^^}" == "YES" ]]; then
    if [[ -z "$QOBUZ_APP_ID" ]]; then
        echo "Missing mandatory QOBUZ_APP_ID"
        exit 10
    fi
    if [[ -z "$QOBUZ_APP_SECRET" ]]; then
        echo "Missing mandatory QOBUZ_APP_SECRET"
        exit 10
    fi
    if [[ -z "$QOBUZ_USERNAME" ]]; then
        echo "Missing mandatory QOBUZ_USERNAME"
        exit 10
    fi
    if [[ -z "$QOBUZ_PASSWORD" ]]; then
        echo "Missing mandatory QOBUZ_PASSWORD"
        exit 10
    fi
    if [[ -z "$QOBUZ_FORMAT_ID" ]]; then
        QOBUZ_FORMAT_ID=5
        echo "QOBUZ_FORMAT set to [$QOBUZ_FORMAT_ID]"
    fi
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

output_by_type_limit=$((${max_outputs_by_type}-1))

## ALSA output
for i in $( eval echo {0..$output_by_type_limit} )
do
    build_alsa $MPD_ALSA_CONFIG_FILE $i
done

## PULSE output
for i in $( eval echo {0..$output_by_type_limit} )
do
    build_pulse $MPD_ALSA_CONFIG_FILE $i
done

## HTTPD output
for i in $( eval echo {0..$output_by_type_limit} )
do
    build_httpd $MPD_ALSA_CONFIG_FILE $i
done

## SHOUTCAST output
for i in $( eval echo {0..$output_by_type_limit} )
do
    build_shout $MPD_ALSA_CONFIG_FILE $i
done

## NULL output
for i in $( eval echo {0..$output_by_type_limit} )
do
    build_null $MPD_ALSA_CONFIG_FILE $i
done

## additional outputs
ADDITIONAL_OUTPUTS_FILE=/user/config/additional-outputs.txt
if [ -f "$ADDITIONAL_OUTPUTS_FILE" ]; then
    echo "Additional outputs provided"
    echo "# Additional outputs BEGIN" >> $MPD_ALSA_CONFIG_FILE
    cat $ADDITIONAL_OUTPUTS_FILE >> $MPD_ALSA_CONFIG_FILE
    echo "# Additional outputs END" >> $MPD_ALSA_CONFIG_FILE
else
    echo "No additional outputs provided"
fi

if [[ "${SOXR_PLUGIN_ENABLE^^}" == "YES" || "${SOXR_PLUGIN_ENABLE^^}" == "Y" ]]; then
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
    echo "  plugin \"soxr\"" >> $MPD_ALSA_CONFIG_FILE
    if [ -n "${SOXR_PLUGIN_QUALITY}" ]; then
        echo "  quality \"${SOXR_PLUGIN_QUALITY}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_THREADS}" ]; then
        echo "  threads \"${SOXR_PLUGIN_THREADS}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_PRECISION}" ]; then
       echo "  precision \"${SOXR_PLUGIN_PRECISION}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_PHASE_RESPONSE}" ]; then
        echo "  phase_response \"${SOXR_PLUGIN_PHASE_RESPONSE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_PASSBAND_END}" ]; then
        echo "  passband_end \"${SOXR_PLUGIN_PASSBAND_END}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_STOPBAND_BEGIN}" ]; then
        echo "  stopband_begin \"${SOXR_PLUGIN_STOPBAND_BEGIN}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_ATTENUATION}" ]; then
        echo "  attenuation \"${SOXR_PLUGIN_ATTENUATION}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${SOXR_PLUGIN_FLAGS}" ]; then
        echo "  flags \"${SOXR_PLUGIN_FLAGS}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    echo "}" >> $MPD_ALSA_CONFIG_FILE
fi

if [ -z "${REPLAYGAIN_MODE}" ]; then
    REPLAYGAIN_MODE="off"
fi
if [ -z "${REPLAYGAIN_PREAMP}" ]; then
    REPLAYGAIN_PREAMP="0"
fi
if [ -z "${REPLAYGAIN_MISSING_PREAMP}" ]; then
    REPLAYGAIN_MISSING_PREAMP="0"
fi
if [ -z "${REPLAYGAIN_LIMIT}" ]; then
    REPLAYGAIN_LIMIT="yes"
fi
if [ -z "${VOLUME_NORMALIZATION}" ]; then
    VOLUME_NORMALIZATION="no"
fi
echo "replaygain \"${REPLAYGAIN_MODE}\"" >> $MPD_ALSA_CONFIG_FILE
echo "replaygain_preamp \"${REPLAYGAIN_PREAMP}\"" >> $MPD_ALSA_CONFIG_FILE
echo "replaygain_missing_preamp \"${REPLAYGAIN_MISSING_PREAMP}\"" >> $MPD_ALSA_CONFIG_FILE
echo "replaygain_limit \"${REPLAYGAIN_LIMIT}\"" >> $MPD_ALSA_CONFIG_FILE
echo "volume_normalization \"${VOLUME_NORMALIZATION}\"" >> $MPD_ALSA_CONFIG_FILE

if [ -n "${SAMPLERATE_CONVERTER}" ]; then
    # try lookup
    sr_lookup="${samplerate_converters[${SAMPLERATE_CONVERTER}]}"
    if [[ -v sr_lookup ]]; then
        SAMPLERATE_CONVERTER=${sr_lookup}
    fi
    echo "samplerate_converter \"${SAMPLERATE_CONVERTER}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${MAX_OUTPUT_BUFFER_SIZE}" ]; then
    echo "max_output_buffer_size \"${MAX_OUTPUT_BUFFER_SIZE}\"" >> $MPD_ALSA_CONFIG_FILE
fi
if [ -n "${AUDIO_BUFFER_SIZE}" ]; then
    echo "audio_buffer_size \"${AUDIO_BUFFER_SIZE}\"" >> $MPD_ALSA_CONFIG_FILE
fi
echo "filesystem_charset \"UTF-8\"" >> $MPD_ALSA_CONFIG_FILE

number_re="^[0-9]+$"
if [[ -n "$STARTUP_DELAY_SEC" ]]; then
    if ! [[ $STARTUP_DELAY_SEC =~ $number_re ]]; then
        echo "Invalid parameter STARTUP_DELAY_SEC"
        exit 9
    fi
    if [[ $STARTUP_DELAY_SEC -gt 0 ]]; then
        echo "About to sleep for $STARTUP_DELAY_SEC second(s)"
        sleep $STARTUP_DELAY_SEC
        echo "Ready to start."
    fi
fi

## start from scratch
SCRIBBLE_CONFIG_FILE=/app/conf/scribble.conf
echo "# mpscribble configuration file" > $SCRIBBLE_CONFIG_FILE

if [[ -n "$LASTFM_USERNAME" && -n "$LASTFM_PASSWORD" ]] || 
   [[ -n "$LIBREFM_USERNAME" && -n "$LIBREFM_PASSWORD" ]] ||
   [[ -n "$JAMENDO_USERNAME" && -n "$JAMENDO_PASSWORD" ]]; then
    echo "At least one scrobbling service requested."
    SCR_MPD_HOSTNAME=localhost
    # set scrobbler mpd port to mpd port by default
    # use MPD_PORT as the initial value
    SCR_MPD_PORT=$MPD_PORT
    if [ -n "$SCROBBLER_MPD_HOSTNAME" ]; then
        SCR_MPD_HOSTNAME="${SCROBBLER_MPD_HOSTNAME}"
    fi
    if [ -n "$SCROBBLER_MPD_PORT" ]; then
        SCR_MPD_PORT="${SCROBBLER_MPD_PORT}"
    fi
    if [ -n "$PROXY" ]; then
        echo "proxy = $PROXY" >> $SCRIBBLE_CONFIG_FILE
    fi
    echo "log = /log/scrobbler.log" >> $SCRIBBLE_CONFIG_FILE
    if [ -n "$SCRIBBLE_VERBOSE" ]; then
        echo "verbose = $SCRIBBLE_VERBOSE" >> $SCRIBBLE_CONFIG_FILE
    fi
    echo "host = $SCR_MPD_HOSTNAME" >> $SCRIBBLE_CONFIG_FILE
    echo "port = $SCR_MPD_PORT" >> $SCRIBBLE_CONFIG_FILE
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

if [[ -z "${ENFORCE_PLAYER_STATE}" || "${ENFORCE_PLAYER_STATE^^}" == "YES" || "${ENFORCE_PLAYER_STATE^^}" == "Y" ]]; then
    STATE_FILE=/db/state
    # remove player states
    if [ -f $STATE_FILE ]; then
        echo "Removing player state information from state file [$STATE_FILE]"
        # remove lines which contain audio_device_state
        sed -i '/audio_device_state/d' $STATE_FILE
    fi
elif [[ "${ENFORCE_PLAYER_STATE^^}" != "NO" && "${ENFORCE_PLAYER_STATE^^}" != "N" ]]; then
    echo "Invalid ENFORCE_PLAYER_STATE=[$ENFORCE_PLAYER_STATE]"
    exit 9
fi

CMD_LINE="$mpd_binary --no-daemon $MPD_ALSA_CONFIG_FILE"
echo "CMD_LINE=[$CMD_LINE]"
if [ $USE_USER_MODE == "Y" ]; then
    if [ -f "/user/config/asoundrc.txt" ]; then
        cp /user/config/asoundrc.txt /home/$USER_NAME/.asoundrc
        chown $USER_NAME:$GROUP_NAME /home/$USER_NAME/.asoundrc
        chmod 600 /home/$USER_NAME/.asoundrc
    fi
    su - $USER_NAME -c "$CMD_LINE"
else
    if [ -f "/user/config/asoundrc.txt" ]; then
        cp /user/config/asoundrc.txt /root/.asoundrc
        chmod 644 /root/.asoundrc
    fi
    eval "$CMD_LINE"
fi
