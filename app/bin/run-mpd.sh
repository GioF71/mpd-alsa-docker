#!/bin/bash

# error codes
# 2 Invalid output mode
# 3 Missing mandatory audio group gid for user mode with alsa
# 4 Incompatible sample rate conversion settings
# 5 Incompatible database mode
# 6 Invalid auto_resample mode
# 7 Invalid thesycon_dsd_workaround mode
# 8 Invalid default type

STABLE_MPD_BINARY=/app/bin/compiled/mpd
UPSAMPLING_MPD_BINARY=/app/bin/compiled/mpd-ups
REPO_MPD_BINARY=/usr/bin/mpd

DEFAULT_MAX_OUTPUTS_BY_TYPE=5

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
source read-file.sh
source get-value.sh
source load-alsa-presets.sh
source build-additional.sh

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
    if [ "${OUTPUT_MODE^^}" == "ALSA" ]; then
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
    elif [ "${OUTPUT_MODE^^}" = "NULL" ]; then
        echo "Null Mode - No actions"
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
if [ "${DATABASE_MODE}" == "simple" ]; then
    echo "  path \"/db/tag_cache\"" >> $MPD_ALSA_CONFIG_FILE
elif [ "${DATABASE_MODE}" == "proxy" ]; then
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
echo "sticker_file \"/db/sticker\"" >> $MPD_ALSA_CONFIG_FILE
echo "bind_to_address \"${MPD_BIND_ADDRESS}\"" >> $MPD_ALSA_CONFIG_FILE
echo "port \"${MPD_PORT}\"" >> $MPD_ALSA_CONFIG_FILE
echo "log_file \"/log/mpd.log\"" >> $MPD_ALSA_CONFIG_FILE

if [ "${ZEROCONF_ENABLED^^}" == "YES" ]; then
    ZEROCONF_ENABLED=yes
else
    ZEROCONF_ENABLED=no
    ZEROCONF_NAME=""
fi

echo "zeroconf_enabled \"${ZEROCONF_ENABLED}\"" >> $MPD_ALSA_CONFIG_FILE
if [ -n "${ZEROCONF_NAME}" ]; then
    echo "zeroconf_name \"${ZEROCONF_NAME}\"" >> $MPD_ALSA_CONFIG_FILE
fi

if [ -n "${MPD_LOG_LEVEL}" ]; then
    echo "log_level \"${MPD_LOG_LEVEL}\"" >> $MPD_ALSA_CONFIG_FILE
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
if [[ "${HYBRID_DSD_ENABLED^^}" == "NO" || "${OUTPUT_MODE^^}" == "PULSE" ]]; then
    echo "decoder {" >> $MPD_ALSA_CONFIG_FILE
    echo "  plugin \"hybrid_dsd\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  enabled \"no\"" >> $MPD_ALSA_CONFIG_FILE
    echo "}" >> $MPD_ALSA_CONFIG_FILE
fi

if [ "${OUTPUT_MODE^^}" == "ALSA" ]; then
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
    else
        echo "Alsa preset has not been specified"
    fi
    # if allowed, try to find the mixer
    echo "ALSA_AUTO_FIND_MIXER=[${ALSA_AUTO_FIND_MIXER}]"
    if [ "${ALSA_AUTO_FIND_MIXER^^}" == "YES" ]; then
        if [ -z "${MIXER_CONTROL}" ]; then
            echo "Trying to find mixer ..."
            MIXER_TYPE="hardware"
            RAW_MIXER_DEVICE="$(amixer -D ${MPD_AUDIO_DEVICE} scontrols | head -n 1)"
            echo "RAW_MIXER_DEVICE = [$RAW_MIXER_DEVICE]"
            mixer=$(echo ${RAW_MIXER_DEVICE} | cut -d "'" -f 2)
            echo "Mixer=[$mixer]"
            MIXER_CONTROL=$mixer
            # assuming mixer device to be same as audio device
            MIXER_DEVICE=$MPD_AUDIO_DEVICE
        else    
            echo "MIXER_CONTROL already set to [${MIXER_CONTROL}]"
        fi
    fi
    # fallback to software mixer if MIXER_TYPE is still empty
    if [ -z "${MIXER_TYPE}" ]; then
        MIXER_TYPE="software"
        echo "Falling back to MIXER_TYPE=[$MIXER_TYPE]"
    fi
    ## Add alsa output
    echo "audio_output {" >> $MPD_ALSA_CONFIG_FILE
        echo "  type \"alsa\"" >> $MPD_ALSA_CONFIG_FILE
    if [ -n "${ALSA_DEVICE_NAME}" ]; then
        echo "  name \"${ALSA_DEVICE_NAME}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MPD_AUDIO_DEVICE}" ]; then
        echo "  device \"${MPD_AUDIO_DEVICE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${AUTO_RESAMPLE}" ]; then
        if [ "${AUTO_RESAMPLE^^}" == "YES" ]; then
            AUTO_RESAMPLE=yes
        elif [ "${AUTO_RESAMPLE^^}" == "NO" ]; then
            AUTO_RESAMPLE=no
        else
            echo "Invalid configuration for AUTO_RESAMPLE [${AUTO_RESAMPLE}]"
            exit 6
        fi
        echo "  auto_resample \"${AUTO_RESAMPLE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${THESYCON_DSD_WORKAROUND}" ]; then
        if [ "${THESYCON_DSD_WORKAROUND^^}" == "YES" ]; then
            THESYCON_DSD_WORKAROUND=yes
        elif [ "${THESYCON_DSD_WORKAROUND^^}" == "NO" ]; then
            THESYCON_DSD_WORKAROUND=no
        else
            echo "Invalid configuration for THESYCON_DSD_WORKAROUND [${THESYCON_DSD_WORKAROUND}]"
            exit 7
        fi
        echo "  thesycon_dsd_workaround \"${THESYCON_DSD_WORKAROUND}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MIXER_TYPE}" ]; then
        echo "  mixer_type \"${MIXER_TYPE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MIXER_DEVICE}" ]; then
        echo "  mixer_device \"${MIXER_DEVICE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MIXER_CONTROL}" ]; then
        echo "  mixer_control \"${MIXER_CONTROL}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${MIXER_INDEX}" ]; then
        echo "  mixer_index \"${MIXER_INDEX}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${ALSA_OUTPUT_FORMAT}" ]; then
        echo "  format \"${ALSA_OUTPUT_FORMAT}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${ALSA_ALLOWED_FORMATS_PRESET}" ]; then
        af_value="${allowed_formats_presets[${ALSA_ALLOWED_FORMATS_PRESET}]}"
        if [[ -v af_value ]]; then
            ALSA_ALLOWED_FORMATS=$af_value
        fi
    fi
    if [ -n "${ALSA_ALLOWED_FORMATS}" ]; then
        echo "  allowed_formats \"${ALSA_ALLOWED_FORMATS}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [ -n "${INTEGER_UPSAMPLING}" ]; then
        echo "  integer_upsampling \"${INTEGER_UPSAMPLING}\"" >> $MPD_ALSA_CONFIG_FILE
        mpd_binary=$UPSAMPLING_MPD_BINARY
    fi
    if [ -n "${DOP}" ]; then
        echo "  dop \"${DOP}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    echo "  enabled \"yes\"" >> $MPD_ALSA_CONFIG_FILE
    echo "}" >> $MPD_ALSA_CONFIG_FILE
elif [ "${OUTPUT_MODE^^}" == "PULSE" ]; then
    echo "audio_output {" >> $MPD_ALSA_CONFIG_FILE
    echo "  type \"pulse\"" >> $MPD_ALSA_CONFIG_FILE
    if [ -z "${PULSEAUDIO_OUTPUT_NAME}" ]; then
        PULSEAUDIO_OUTPUT_NAME="PulseAudio"
    fi
    echo "  name \"${PULSEAUDIO_OUTPUT_NAME}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  enabled \"yes\"" >> $MPD_ALSA_CONFIG_FILE
    echo "}" >> $MPD_ALSA_CONFIG_FILE
elif [ "${OUTPUT_MODE^^}" == "NULL" ]; then
    echo "audio_output {" >> $MPD_ALSA_CONFIG_FILE
    echo "  enabled \"yes\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  type \"null\"" >> $MPD_ALSA_CONFIG_FILE
    OUTPUT_NAME="Null Output"
    if [ -n "${NULL_OUTPUT_NAME}" ]; then
        OUTPUT_NAME=${NULL_OUTPUT_NAME}
    fi
    OUTPUT_SYNC="yes"
    if [ -n "${NULL_OUTPUT_SYNC}" ]; then
        OUTPUT_SYNC=${NULL_OUTPUT_SYNC}
    fi
    echo "  name \"${OUTPUT_NAME}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  sync \"${OUTPUT_SYNC}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "}" >> $MPD_ALSA_CONFIG_FILE
else
    echo "Invalid output mode [${OUTPUT_MODE}]";
    exit 2;
fi

output_by_type_limit=$((${max_outputs_by_type}-1))

## HTTPD output
for i in $( eval echo {0..$output_by_type_limit} )
do
    build_httpd $MPD_ALSA_CONFIG_FILE $i
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

CMD_LINE="$mpd_binary --no-daemon $MPD_ALSA_CONFIG_FILE"
echo "CMD_LINE=[$CMD_LINE]"
if [ $USE_USER_MODE == "Y" ]; then
    su - $USER_NAME -c "$CMD_LINE"
else
    eval "$CMD_LINE"
fi
