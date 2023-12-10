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
# 11 Missing binaries

add_simple_parameter() {
    out_file=$1
    idx=$2
    env_var_name=$3
    param_name=$4
    p_val=$(get_named_env $env_var_name $idx)
    echo "${env_var_name} at index $i is set to ${p_val}"
    if [ -n "${p_val}" ]; then
        echo "${param_name} \"${p_val}\"" >> $out_file
    fi
}

build_mode=`cat /app/conf/build_mode.txt`
mpd_installed=`cat /app/conf/mpd_installed.txt`
alsa_packages_installed=`cat /app/conf/alsa_packages_installed.txt`
pulse_packages_installed=`cat /app/conf/pulse_packages_installed.txt`

echo "Build mode: [${build_mode}]"

CONF_INTEGER_UPSAMPLING_SUPPORT_FILE="/app/conf/integer_upsampling_support.txt"
COMPILED_MPD_PATH="/app/conf/mpd-compiled-path.txt"
COMPILED_UPS_MPD_PATH="/app/conf/mpd-compiled-ups-path.txt"
INTEGER_UPSAMPLING_SUPPORTED="no"

REPO_MPD_BINARY="/usr/bin/mpd"
REPO_MPD_BINARY_AVAILABLE="no"
COMPILED_MPD_BINARY=""
COMPILED_UPS_MPD_BINARY=""

MPDSCRIBBLE_BINARY="/usr/bin/mpdscribble"

DEFAULT_MAX_PERMISSIONS=10
max_permissions=$DEFAULT_MAX_PERMISSIONS

DEFAULT_MAX_BIND_ADDRESSES=10
max_bind_addresses=$DEFAULT_MAX_BIND_ADDRESSES


if [[ -n "${MAX_PERMISSIONS}" ]]; then
    max_permissions=${MAX_PERMISSIONS}
fi

if [ -f "$CONF_INTEGER_UPSAMPLING_SUPPORT_FILE" ]; then
    INTEGER_UPSAMPLING_SUPPORTED=`cat $CONF_INTEGER_UPSAMPLING_SUPPORT_FILE`
    if [ -f "$COMPILED_MPD_PATH" ]; then
        COMPILED_MPD_BINARY=`cat $COMPILED_MPD_PATH`
    fi
    if [[ "${INTEGER_UPSAMPLING_SUPPORTED^^}" == "YES" ]]; then
        if [ -f "$COMPILED_UPS_MPD_PATH" ]; then
            COMPILED_UPS_MPD_BINARY=`cat $COMPILED_UPS_MPD_PATH`
        fi
    fi
fi

if [ -f "${REPO_MPD_BINARY}" ]; then
    echo "MPD from repo is available at [${REPO_MPD_BINARY}]"
    REPO_MPD_BINARY_AVAILABLE="yes"
else
    echo "MPD from repo is not available"
fi

echo "Integer upsampling supported: [${INTEGER_UPSAMPLING_SUPPORTED}]"
echo "Compiled mpd binary: [${COMPILED_MPD_BINARY}]"
echo "Compiled mpd ups binary: [${COMPILED_UPS_MPD_BINARY}]"

if [[ ! "${REPO_MPD_BINARY_AVAILABLE}" == "yes" && -z "${COMPILED_MPD_BINARY}" ]]; then
    echo "NO BINARIES AVAILABLE, exiting"
    exit 11
fi

STABLE_MPD_BINARY=${COMPILED_MPD_BINARY}
UPSAMPLING_MPD_BINARY=${COMPILED_UPS_MPD_BINARY}

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

if [[ ! "${FORCE_REPO_BINARY^^}" == "YES" ]]; then
    if [ -n "${STABLE_MPD_BINARY}" ]; then
        mpd_binary=$STABLE_MPD_BINARY
    else
        mpd_binary=$REPO_MPD_BINARY
    fi
else
    # binary repo must be available
    if [ "${REPO_MPD_BINARY_AVAILABLE^^}" == "YES" ]; then
        mpd_binary=$REPO_MPD_BINARY
    else
        echo "Repo binary forced but not available!"
        exit 11
    fi
fi

echo "Selected binary: [${mpd_binary}]"

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

if [ "${ANY_ALSA}" -eq 1 ]; then
    if [ $alsa_packages_installed != "yes" ]; then
        echo "Alsa packages installation ..."
        apt-get update
        apt-get install -y --no-install-recommends alsa-utils libasound2-plugin-equal
        echo "yes" > /app/conf/alsa_packages_installed.txt
        echo ". done."
    fi
else
    echo "Alsa packages not needed."
fi

if [ "${ANY_PULSE}" -eq 1 ]; then
    if [ $pulse_packages_installed != "yes" ]; then
        echo "Pulse packages installation ..."
        apt-get update
        apt-get install -y --no-install-recommends pulseaudio-utils libasound2-plugin-equal
        echo "yes" > /app/conf/pulse_packages_installed.txt
        echo ". done."
    fi
else
    echo "Pulse packages not needed."
fi

DEFAULT_UID=1000
DEFAULT_GID=1000

DEFAULT_USER_NAME=mpd-user
DEFAULT_GROUP_NAME=mpd-user
DEFAULT_HOME_DIR=/home/$DEFAULT_USER_NAME

USER_NAME=$DEFAULT_USER_NAME
GROUP_NAME=$DEFAULT_GROUP_NAME
HOME_DIR=$DEFAULT_HOME_DIR

echo "USER_MODE=[${USER_MODE}]"

if [[ ! (${USER_MODE^^} == "NO" || ${USER_MODE^^} == "N") ]]; then
    if [[ "${ANY_PULSE}" -eq 1 ]] || 
    [[ "${USER_MODE^^}" == "YES" || "${USER_MODE^^}" == "Y" ]]; then
        USE_USER_MODE="Y"
        echo "User mode enabled"
        echo "Creating user ...";
        if [ -z "${PUID}" ]; then
            PUID=$DEFAULT_UID;
            echo "Setting default value for PUID: ["$PUID"]"
        fi
        if [ -z "${PGID}" ]; then
            PGID=$DEFAULT_GID;
            echo "Setting default value for PGID: ["$PGID"]"
        fi
        echo "Ensuring user with uid:[$PUID] gid:[$PGID] exists ...";
        ### create group if it does not exist
        if [ ! $(getent group $PGID) ]; then
            echo "Group with gid [$PGID] does not exist, creating..."
            groupadd -g $PGID $GROUP_NAME
            echo "Group [$GROUP_NAME] with gid [$PGID] created."
        else
            GROUP_NAME=$(getent group $PGID | cut -d: -f1)
            echo "Group with gid [$PGID] name [$GROUP_NAME] already exists."
        fi

        ### create user if it does not exist
        if [ ! $(getent passwd $PUID) ]; then
            echo "User with uid [$PUID] does not exist, creating..."
            useradd -g $PGID -u $PUID -M $USER_NAME
            echo "User [$USER_NAME] with uid [$PUID] created."
        else
            USER_NAME=$(getent passwd $PUID | cut -d: -f1)
            echo "user with uid [$PUID] name [$USER_NAME] already exists."
            HOME_DIR="/home/$USER_NAME"
        fi

        ### create home directory
        if [ ! -d "$HOME_DIR" ]; then
            echo "Home directory [$HOME_DIR] not found, creating."
            mkdir -p $HOME_DIR
            echo ". done."
        fi

        chown -R $PUID:$PGID $HOME_DIR
        ls -la $HOME_DIR -d
        ls -la $HOME_DIR

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
fi

MPD_ALSA_CONFIG_FILE=/tmp/mpd.conf

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

NEED_STORAGE=1
## add database
echo "database {" >> $MPD_ALSA_CONFIG_FILE
if [ "${DATABASE_MODE^^}" == "SIMPLE" ]; then
    echo "  plugin \"simple\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  path \"/db/tag_cache\"" >> $MPD_ALSA_CONFIG_FILE
elif [ "${DATABASE_MODE^^}" == "PROXY" ]; then
    echo "  plugin \"proxy\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  host \"${DATABASE_PROXY_HOST}\"" >> $MPD_ALSA_CONFIG_FILE
    echo "  port \"${DATABASE_PROXY_PORT}\"" >> $MPD_ALSA_CONFIG_FILE
    if [[ -n "${DATABASE_PROXY_PASSWORD}" ]]; then
        echo "  password \"${DATABASE_PROXY_PASSWORD}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    if [[ -n "${DATABASE_PROXY_KEEPALIVE}" ]]; then
        echo "  keepalive \"${DATABASE_PROXY_KEEPALIVE}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
elif [ "${DATABASE_MODE^^}" == "UPNP" ]; then
    NEED_STORAGE=0
    echo "  plugin \"upnp\"" >> $MPD_ALSA_CONFIG_FILE
else
    echo "Invalid database mode [${DATABASE_MODE}]";
    exit 5;
fi
echo "}" >> $MPD_ALSA_CONFIG_FILE

DEFAULT_MUSIC_DIRECTORY="/music"

if [ -z "${MUSIC_DIRECTORY}" ]; then
    MUSIC_DIRECTORY=${DEFAULT_MUSIC_DIRECTORY}
fi

if [[ $NEED_STORAGE -eq 1 ]]; then
    echo "music_directory \"${MUSIC_DIRECTORY}\"" >> $MPD_ALSA_CONFIG_FILE
fi

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

#  multiple bind addresses (issue #357)
for i in $( eval echo {0..$max_bind_addresses} )
do
    echo "Processing MPD_BIND_ADDRESS index $i"
    add_simple_parameter $MPD_ALSA_CONFIG_FILE $i "MPD_BIND_ADDRESS" "bind_to_address" 
done

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

## permissions
if [[ -n "${DEFAULT_PERMISSIONS}" ]]; then
    echo "default_permissions \"${DEFAULT_PERMISSIONS}\"" >> $MPD_ALSA_CONFIG_FILE
fi

# local_permissions
if [[ -n "${LOCAL_PERMISSIONS}" ]]; then
    echo "local_permissions \"${LOCAL_PERMISSIONS}\"" >> $MPD_ALSA_CONFIG_FILE
fi

# host_permissions
for i in $( eval echo {0..$max_permissions} )
do
    echo "Processing HOST_PERMISSIONS index $i"
    add_simple_parameter $MPD_ALSA_CONFIG_FILE $i "HOST_PERMISSIONS" "host_permissions" 
done

# passwords
for i in $( eval echo {0..$max_permissions} )
do
    echo "Processing PASSWORD index $i"
    add_simple_parameter $MPD_ALSA_CONFIG_FILE $i "PASSWORD" "password" 
done

## disable wildmidi decoder
echo "decoder {" >> $MPD_ALSA_CONFIG_FILE
echo "  plugin \"wildmidi\"" >> $MPD_ALSA_CONFIG_FILE
echo "  enabled \"no\"" >> $MPD_ALSA_CONFIG_FILE
echo "}" >> $MPD_ALSA_CONFIG_FILE

## add input curl
if [[ -z "${CURL_ENABLED}" || "${CURL_ENABLED^^}" == "YES" || "${CURL_ENABLED^^}" == "Y" ]]; then
    echo "input {" >> $MPD_ALSA_CONFIG_FILE
    echo "  plugin \"curl\"" >> $MPD_ALSA_CONFIG_FILE
    if [[ "${CURL_PROXY^^}" == "YES" || "${CURL_PROXY^^}" == "Y" ]]; then
        echo "  proxy \"${CURL_PROXY}\"" >> $MPD_ALSA_CONFIG_FILE
        if [[ -n "${CURL_PROXY_USER^^}" ]]; then
            echo "  proxy_user \"${CURL_PROXY_USER}\"" >> $MPD_ALSA_CONFIG_FILE
        fi
        if [[ -n "${CURL_PROXY_PASSWORD^^}" ]]; then
            echo "  proxy_password \"${CURL_PROXY_PASSWORD}\"" >> $MPD_ALSA_CONFIG_FILE
        fi
    fi
    if [[ -n "${CURL_VERIFY_PEER}" ]]; then
        if [[ "${CURL_VERIFY_PEER^^}" == "YES" || "${CURL_VERIFY_PEER^^}" == "Y" ]]; then
            echo "  verify_peer \"yes\"" >> $MPD_ALSA_CONFIG_FILE
        elif [[ "${CURL_VERIFY_PEER^^}" == "NO" || "${CURL_VERIFY_PEER^^}" == "N" ]]; then
            echo "  verify_peer \"no\"" >> $MPD_ALSA_CONFIG_FILE
        else
            echo "Invalid parameter CURL_VERIFY_PEER"
            exit 9
        fi
    fi
    if [[ -n "${CURL_VERIFY_HOST}" ]]; then
        if [[ "${CURL_VERIFY_HOST^^}" == "YES" || "${CURL_VERIFY_HOST^^}" == "Y" ]]; then
            echo "  verify_host \"yes\"" >> $MPD_ALSA_CONFIG_FILE
        elif [[ "${CURL_VERIFY_HOST^^}" == "NO" || "${CURL_VERIFY_HOST^^}" == "N" ]]; then
            echo "  verify_host \"no\"" >> $MPD_ALSA_CONFIG_FILE
        else
            echo "Invalid parameter CURL_VERIFY_HOST"
            exit 9
        fi
    fi
    if [[ -n "${CURL_CACERT}" ]]; then
        echo "  cacert \"${CURL_CACERT}\"" >> $MPD_ALSA_CONFIG_FILE
    fi
    echo "}" >> $MPD_ALSA_CONFIG_FILE
fi

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
SCRIBBLE_CONFIG_FILE=/tmp/scribble.conf
echo "# mpscribble configuration file" > $SCRIBBLE_CONFIG_FILE

if [[ -n "$LASTFM_USERNAME" && -n "$LASTFM_PASSWORD" ]] || 
   [[ -n "$LIBREFM_USERNAME" && -n "$LIBREFM_PASSWORD" ]] ||
   [[ -n "$JAMENDO_USERNAME" && -n "$JAMENDO_PASSWORD" ]]; then
    echo "At least one scrobbling service requested."

    if [ ! -f $MPDSCRIBBLE_BINARY ]; then
        echo "MPDScribble not installed, installing ..."
        apt-get update
        apt-get install -y mpdscribble
        echo ". done"
    fi

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

CMD_LINE="$mpd_binary"

if [[ -z "${STDERR_ENABLED}" || "${STDERR_ENABLED}" == "YES" || "${STDERR_ENABLED}" == "Y" ]]; then
    CMD_LINE="$CMD_LINE --stderr"
elif [[ "${STDERR_ENABLED}" != "NO" && "${STDERR_ENABLED}" != "N" ]]; then
    echo "Invalid STDERR_ENABLED=[$STDERR_ENABLED]"
    exit 9
fi

if [ -f "/user/config/override.mpd.conf" ]; then
    echo "Overriding generated mpd configuration file, use this feature at your own risk!"
    MPD_ALSA_CONFIG_FILE=/user/config/override.mpd.conf
fi

CMD_LINE="$CMD_LINE --no-daemon $MPD_ALSA_CONFIG_FILE"
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
