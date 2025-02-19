#!/bin/bash

open_output() {
    out_file=$1
    # open
    echo "audio_output {" >> $out_file
}

set_output_type() {
    out_file=$1
    output_type=$2
    # open
    echo "  type \"${output_type}\"" >> $out_file
}

close_output() {
    out_file=$1
    # open
    echo "}" >> $out_file
}

add_output_parameter() {
    out_file=$1
    idx=$2
    env_var_name=$3
    param_name=$4
    param_default=$5
    param_default_type=$6
    c_var=$(get_named_env $env_var_name $idx)
    if [ -n "${c_var}" ]; then
        final_var=${c_var}
    else
        if [ ${param_default_type} == "num" ]; then
            calc=$(get_indexed_default_num $param_default $idx)
        elif [ ${param_default_type} == "str" ]; then
            calc=$(get_indexed_default $param_default $idx)
        elif [ ${param_default_type} == "constant" ]; then
            calc=$param_default
        elif [ ${param_default_type} == "none" ]; then
            # parameter has no default
            calc=""
        else
            echo "Invalid default type [${param_default_type}]"
            exit 8
        fi
        final_var=$calc
    fi
    # only write non-empty values
    if [ -n "${final_var}" ]; then
        echo "  ${param_name} \"${final_var}\"" >> $out_file
    fi
}

add_alsa_output_parameter() {
    out_file=$1
    idx=$2
    env_var_name=$3
    param_name=$4
    param_default=$5
    param_default_type=$6
    key_name=$7
    c_var="$(alsa_get_stored_or_named $env_var_name $idx $key_name)"
    if [ -n "${c_var}" ]; then
        final_var="${c_var}"
    else
        if [ ${param_default_type} == "num" ]; then
            calc=$(get_indexed_default_num $param_default $idx)
        elif [ ${param_default_type} == "str" ]; then
            calc=$(get_indexed_default $param_default $idx)
        elif [ ${param_default_type} == "constant" ]; then
            calc=$param_default
        elif [ ${param_default_type} == "none" ]; then
            # parameter has no default
            calc=""
        else
            echo "Invalid default type [${param_default_type}]"
            exit 8
        fi
        final_var="$calc"
    fi
    # only write non-empty values
    if [ -n "${final_var}" ]; then
        echo "  ${param_name} \"${final_var}\"" >> $out_file
    fi
}

get_alsa_preset_value() {
    preset_name=$1
    preset_key=$2
    preset_value=""
    if [ -n ${preset_name} ]; then
        alsa_preset_key="${preset_name}.${preset_key}"
        alsa_preset_value="${alsa_presets[${alsa_preset_key}]}"
        if [[ -v alsa_preset_value ]]; then
            preset_value="${alsa_preset_value}"
        fi
    fi
    echo "${preset_value}"
}

declare -A alsa_out_set_values

track_alsa_out_set_value() {
    parameter_name=$1
    parameter_index=$2
    parameter_value=$3
    alsa_set_key="${parameter_name}.${parameter_index}"
    echo "track_alsa_out_set_value setting [${alsa_set_key}] to ["${parameter_value}"]"
    alsa_out_set_values[${alsa_set_key}]="${parameter_value}"
}

load_preset_alsa_param() {
    idx=$1
    parameter_name=$2
    preset_name=$3
    preset_key=$4
    echo "Searching alsa preset value for PresetName [${preset_name}] Key [${preset_key}]"
    preset_value="$(get_alsa_preset_value ${preset_name} ${preset_key})"
    if [ -n "${preset_value}" ]; then
        echo "Found alsa preset value for PresetName [${preset_name}] Key [${preset_key}] = [${preset_value}]"
        track_alsa_out_set_value "${parameter_name}" $idx "${preset_value}"
    else
        echo "Not found alsa preset value for PresetName [${preset_name}] Key [${preset_key}]"
    fi
}

alsa_get_stored_or_named() {
    VAR_NAME=$1
    VAR_INDEX=$2
    KEY_NAME=$3
    select_var=$(get_named_env $VAR_NAME $VAR_INDEX)
    if [ -z "${select_var}" ]; then
        #look in stored values
        alsa_set_key="${KEY_NAME}.${VAR_INDEX}"
        stored="${alsa_out_set_values[${alsa_set_key}]}"
        if [ -n "${stored}" ]; then
            select_var="${stored}"
        fi
    fi
    echo "${select_var}"
}

build_alsa() {
    out_file=$1
    idx=$2
    create=$(get_named_env "ALSA_OUTPUT_CREATE" $idx)
    if [[ "${create^^}" == "YES" || "${create^^}" == "Y" ]]; then
        echo "Creating Alsa output for output [$idx]"
        open_output $out_file
        set_output_type $out_file alsa
        add_output_parameter $out_file $idx ALSA_OUTPUT_NAME name alsa str
        add_output_parameter $out_file $idx ALSA_OUTPUT_ENABLED enabled "" none
        current_preset=$(get_named_env "ALSA_OUTPUT_PRESET" $idx)
        if [ -n ${current_preset} ]; then
            echo "Alsa preset for ALSA Out [$idx] is [${current_preset}]"
            # alsa name preset is not used for additional outputs
            load_preset_alsa_param $idx "device" ${current_preset} "device"
            load_preset_alsa_param $idx "mixer_type" ${current_preset} "mixer-type"
            load_preset_alsa_param $idx "mixer_device" ${current_preset} "mixer-device"
            load_preset_alsa_param $idx "mixer_control" ${current_preset} "mixer-control"
            load_preset_alsa_param $idx "mixer_index" ${current_preset} "mixer-index"
        fi
        # try auto find if mixer is not already set
        auto_find_mixer=$(get_named_env "ALSA_OUTPUT_AUTO_FIND_MIXER" $idx)
        echo "ALSA_OUTPUT_AUTO_FIND_MIXER for output [$idx] = [$auto_find_mixer]"
        mixer_device_key="mixer_device.${idx}"
        c_mixer_device="${alsa_out_set_values[$mixer_device_key]}"
        echo "c_mixer_device for output [$idx] = [$c_mixer_device]"
        if [ -z "${c_mixer_device}" ]; then
            if [[ "${auto_find_mixer^^}" == "YES" || "${auto_find_mixer^^}" == "Y" ]]; then
                echo "Trying to find mixer ..."
                # find device
                # tentative #1 explicitly declared?
                c_device="$(get_named_env "ALSA_OUTPUT_DEVICE" $idx)"
                echo "c_device for output [$idx] = [$c_device] (from config)"
                if [ -z "${c_device}" ]; then
                    # tentative 2 - look from presets
                    alsa_set_key="device.${idx}"
                    echo "Looking for c_device for output [$idx] in presets with key [${alsa_set_key}]..."
                    c_device="${alsa_out_set_values[$alsa_set_key]}"
                    echo "c_device for output [$idx] from presets is [${c_device}]"
                fi
                if [ -n "${c_device}" ]; then
                    c_raw_mixer_device="$(amixer -D ${c_device} scontrols | head -n 1)"
                    echo "c_raw_mixer_device for output [$idx] = [${c_raw_mixer_device}]"
                    c_mixer=$(echo ${c_raw_mixer_device} | cut -d "'" -f 2)
                    echo "c_mixer for output [$idx] should be [${c_mixer}]"
                    # set mixer control
                    alsa_set_key="mixer_control.${idx}"
                    alsa_out_set_values[$alsa_set_key]="${c_mixer}"
                    alsa_set_key="mixer_device.${idx}"
                    alsa_out_set_values[$alsa_set_key]="${c_device}"
                    alsa_set_key="mixer_type.${idx}"
                    alsa_out_set_values[$alsa_set_key]="hardware"
                fi
            elif [[ ! -z "${auto_find_mixer}" ]] && [[ "${auto_find_mixer^^}" != "NO" && "${auto_find_mixer^^}" != "N" ]]; then
                echo "Invalid ALSA_OUTPUT_AUTO_FIND_MIXER=[${auto_find_mixer}] for index [{$idx}]"
                exit 9
            fi
        fi
        # allowed format presets
        c_allowed_formats_preset=$(get_named_env "ALSA_OUTPUT_ALLOWED_FORMATS_PRESET" $idx)
        if [ -n "${c_allowed_formats_preset}" ]; then
            echo "Allowed formats preset set for alsa output [$idx] -> [${c_allowed_formats_preset}]"
            c_allowed_formats="${allowed_formats_presets[${c_allowed_formats_preset}]}"
            echo "  translates to [${c_allowed_formats}]"
            if [[ -n "${c_allowed_formats}" ]]; then
                alsa_set_key="allowed_formats.${idx}"
                alsa_out_set_values[$alsa_set_key]="${c_allowed_formats}"
            fi
        fi

        # integer upsampling allowed presets
        c_integer_upsampling_allowed_preset=$(get_named_env "ALSA_OUTPUT_INTEGER_UPSAMPLING_ALLOWED_PRESET" $idx)
        if [ -n "${c_integer_upsampling_allowed_preset}" ]; then
            echo "Integer Upsampling Allowed set for alsa output [$idx] -> [${c_integer_upsampling_allowed_preset}]"
            c_integer_upsampling_allowed="${integer_upsampling_allowed_presets[${c_integer_upsampling_allowed_preset}]}"
            echo "  translates to [${c_integer_upsampling_allowed}]"
            if [[ -n "${c_integer_upsampling_allowed}" ]]; then
                alsa_set_key="integer_upsampling_allowed.${idx}"
                alsa_out_set_values[$alsa_set_key]="${c_integer_upsampling_allowed}"
            fi
        fi

        old_output_format=$(get_named_env "ALSA_OUTPUT_OUTPUT_FORMAT" $idx)
        output_format=$(get_named_env "ALSA_OUTPUT_FORMAT" $idx)
        # support for old variable ALSA_OUTPUT_OUTPUT_FORMAT
        if [[ -n "${old_output_format}" && -z "${output_format}" ]]; then
            echo "Using wrong variable ALSA_OUTPUT_OUTPUT_FORMAT with value [${old_output_format}] -> use ALSA_OUTPUT_FORMAT instead!"
        fi

        # debug dump values
        ## sz=`echo "${#alsa_out_set_values[@]}"`
        ## echo "There are [$sz] available alsa_presets"
        ## for key in "${!alsa_out_set_values[@]}"; do
        ##      echo "Alsa_out_value ["$key"]=["${alsa_out_set_values[$key]}"]"
        ## done
        # end debug
        # write to config file!

        add_alsa_output_parameter $out_file $idx ALSA_OUTPUT_DEVICE device "" none "device"
        add_alsa_output_parameter $out_file $idx ALSA_OUTPUT_MIXER_TYPE mixer_type "" none "mixer_type"
        add_alsa_output_parameter $out_file $idx ALSA_OUTPUT_MIXER_DEVICE mixer_device "" none "mixer_device"
        add_alsa_output_parameter $out_file $idx ALSA_OUTPUT_MIXER_CONTROL mixer_control "" none "mixer_control"
        add_alsa_output_parameter $out_file $idx ALSA_OUTPUT_MIXER_INDEX mixer_index "" none "mixer_index"
        add_alsa_output_parameter $out_file $idx ALSA_OUTPUT_ALLOWED_FORMATS allowed_formats "" none "allowed_formats"
        if [[ -n "${old_output_format}" && -z "${output_format}" ]]; then
            add_output_parameter $out_file $idx ALSA_OUTPUT_OUTPUT_FORMAT format "" none
        else
            add_output_parameter $out_file $idx ALSA_OUTPUT_FORMAT format "" none
        fi
        add_output_parameter $out_file $idx ALSA_OUTPUT_AUTO_RESAMPLE auto_resample "" none
        add_output_parameter $out_file $idx ALSA_OUTPUT_THESYCON_DSD_WORKAROUND thesycon_dsd_workaround "" none
        add_output_parameter $out_file $idx ALSA_OUTPUT_STOP_DSD_SILENCE stop_dsd_silence "" none
        add_output_parameter $out_file $idx ALSA_OUTPUT_INTEGER_UPSAMPLING integer_upsampling "" none
        add_alsa_output_parameter $out_file $idx ALSA_OUTPUT_INTEGER_UPSAMPLING_ALLOWED integer_upsampling_allowed "" none "integer_upsampling_allowed"
        add_output_parameter $out_file $idx ALSA_OUTPUT_DOP dop "" none
        close_output $out_file
        # see if the ups version must be enforced
        c_integer_upsampling=$(get_named_env "ALSA_OUTPUT_INTEGER_UPSAMPLING" $idx)
        echo "ALSA OUTPUT [$idx] requires INTEGER_UPSAMPLING [${c_integer_upsampling}]"
        if [ ! "${FORCE_REPO_BINARY^^}" == "YES" ]; then
            if [ -n "${UPSAMPLING_MPD_BINARY}" ]; then
                if [[ "${c_integer_upsampling^^}" == "YES" || "${c_integer_upsampling^^}" == "Y" ]]; then
                    echo "Setting mpd_binary to [${UPSAMPLING_MPD_BINARY}]"
                    mpd_binary=$UPSAMPLING_MPD_BINARY
                fi
            else
                echo "MPD binary with integer upsampling support is not available"
            fi
        else
            echo "MPD binary forced to repo binary"
        fi
    fi
}

build_pulse() {
    out_file=$1
    idx=$2
    create=$(get_named_env "PULSE_AUDIO_OUTPUT_CREATE" $idx)
    if [[ "${create^^}" == "YES" || "${create^^}" == "Y" ]]; then
        echo "Creating PULSE_AUDIO output for output [$idx]"
        open_output $out_file
        set_output_type $out_file pulse
        add_output_parameter $out_file $idx PULSE_AUDIO_OUTPUT_NAME name PulseAudio str
        add_output_parameter $out_file $idx PULSE_AUDIO_OUTPUT_ENABLED enabled "" none
        add_output_parameter $out_file $idx PULSE_AUDIO_OUTPUT_SINK sink "" none
        add_output_parameter $out_file $idx PULSEAUDIO_OUTPUT_MEDIA_ROLE media_role "" none
        add_output_parameter $out_file $idx PULSEAUDIO_OUTPUT_SCALE_FACTOR scale_factor "" none
        close_output $out_file
    fi
}

build_httpd() {
    out_file=$1
    idx=$2
    create=$(get_named_env "HTTPD_OUTPUT_CREATE" $idx)
    if [[ "${create^^}" == "YES" || "${create^^}" == "Y" ]]; then
        echo "Creating HTTPD output for output [$idx]"
        open_output $out_file
        set_output_type $out_file httpd
        add_output_parameter $out_file $idx HTTPD_OUTPUT_NAME name httpd str
        add_output_parameter $out_file $idx HTTPD_OUTPUT_ENABLED enabled "" none
        add_output_parameter $out_file $idx HTTPD_OUTPUT_BIND_TO_ADDRESS bind_to_address "" none
        add_output_parameter $out_file $idx HTTPD_OUTPUT_PORT port 8000 num
        add_output_parameter $out_file $idx HTTPD_OUTPUT_ENCODER encoder wave constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_ENCODER_BITRATE bitrate "" none
        add_output_parameter $out_file $idx HTTPD_OUTPUT_ENCODER_QUALITY quality "" none
        add_output_parameter $out_file $idx HTTPD_OUTPUT_MAX_CLIENTS max_clients 0 constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_ALWAYS_ON always_on yes constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_TAGS tags yes constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_FORMAT format 44100:16:2 constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_MIXER_TYPE mixer_type "" none
        close_output $out_file
    fi
}

build_shout() {
    out_file=$1
    idx=$2
    create=$(get_named_env "SHOUT_OUTPUT_CREATE" $idx)
    if [[ "${create^^}" == "YES" || "${create^^}" == "Y" ]]; then
        echo "Creating ShoutCast output for output [$idx]"
        open_output $out_file
        set_output_type $out_file shout
        add_output_parameter $out_file $idx SHOUT_OUTPUT_NAME name shout str
        add_output_parameter $out_file $idx SHOUT_OUTPUT_ENABLED enabled "" none
        add_output_parameter $out_file $idx SHOUT_OUTPUT_FORMAT format 44100:16:2 constant
        add_output_parameter $out_file $idx SHOUT_OUTPUT_PROTOCOL protocol icecast2 constant
        add_output_parameter $out_file $idx SHOUT_OUTPUT_TLS tls disabled constant
        add_output_parameter $out_file $idx SHOUT_OUTPUT_ENCODER encoder vorbis constant
        add_output_parameter $out_file $idx SHOUT_OUTPUT_ENCODER_BITRATE bitrate "" none
        add_output_parameter $out_file $idx SHOUT_OUTPUT_ENCODER_QUALITY quality "" none
        add_output_parameter $out_file $idx SHOUT_OUTPUT_MIXER_TYPE mixer_type "" none
        add_output_parameter $out_file $idx SHOUT_OUTPUT_HOST host icecast constant
        add_output_parameter $out_file $idx SHOUT_OUTPUT_PORT port 8000 constant
        add_output_parameter $out_file $idx SHOUT_OUTPUT_MOUNT mount /mpd str
        add_output_parameter $out_file $idx SHOUT_OUTPUT_USER user "" none
        add_output_parameter $out_file $idx SHOUT_OUTPUT_PASSWORD password hackme constant
        add_output_parameter $out_file $idx SHOUT_OUTPUT_PUBLIC public no constant
        add_output_parameter $out_file $idx SHOUT_OUTPUT_ALWAYS_ON always_on yes constant
        close_output $out_file
    fi
}

build_null() {
    out_file=$1
    idx=$2
    create=$(get_named_env "NULL_OUTPUT_CREATE" $idx)
    if [[ "${create^^}" == "YES" || "${create^^}" == "Y" ]]; then
        echo "Creating Null output for output [$idx]"
        open_output $out_file
        set_output_type $out_file null
        add_output_parameter $out_file $idx NULL_OUTPUT_NAME name null str
        add_output_parameter $out_file $idx NULL_OUTPUT_ENABLED enabled "" none
        add_output_parameter $out_file $idx NULL_OUTPUT_SYNC sync yes constant
        add_output_parameter $out_file $idx NULL_OUTPUT_MIXER_TYPE mixer_type "" none
        close_output $out_file
    fi
}

build_snapcast() {
    out_file=$1
    idx=$2
    create=$(get_named_env "SNAPCAST_OUTPUT_CREATE" $idx)
    if [[ "${create^^}" == "YES" || "${create^^}" == "Y" ]]; then
        echo "Creating Snapcast output for output [$idx]"
        open_output $out_file
        set_output_type $out_file snapcast
        add_output_parameter $out_file $idx SNAPCAST_OUTPUT_NAME name snapcast str
        add_output_parameter $out_file $idx SNAPCAST_OUTPUT_ENABLED enabled "" none
        add_output_parameter $out_file $idx SNAPCAST_OUTPUT_PORT port 1704 constant
        add_output_parameter $out_file $idx SNAPCAST_OUTPUT_BIND_TO_ADDRESS bind_to_address "" constant
        add_output_parameter $out_file $idx SNAPCAST_OUTPUT_ZEROCONF zeroconf yes constant
        add_output_parameter $out_file $idx SNAPCAST_OUTPUT_MIXER_TYPE mixer_type "software" constant
        add_output_parameter $out_file $idx SNAPCAST_OUTPUT_OUTPUT_FORMAT format "44100:16:2" constant
        close_output $out_file
    fi
}

build_fifo() {
    out_file=$1
    idx=$2
    create=$(get_named_env "FIFO_OUTPUT_CREATE" $idx)
    if [[ "${create^^}" == "YES" || "${create^^}" == "Y" ]]; then
        echo "Creating Fifo output for output [$idx]"
        open_output $out_file
        set_output_type $out_file fifo
        add_output_parameter $out_file $idx FIFO_OUTPUT_NAME name fifo str
        add_output_parameter $out_file $idx FIFO_OUTPUT_ENABLED enabled "" none
        add_output_parameter $out_file $idx FIFO_OUTPUT_PATH path "" none
        add_output_parameter $out_file $idx FIFO_OUTPUT_MIXER_TYPE mixer_type "software" constant
        add_output_parameter $out_file $idx FIFO_OUTPUT_OUTPUT_FORMAT format "44100:16:2" constant
        close_output $out_file
    fi
}
