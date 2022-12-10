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

build_httpd() {
    out_file=$1
    idx=$2
    create=$(get_named_env "HTTPD_OUTPUT_CREATE" $idx)
    if [ "${create^^}" == "YES" ]; then
        echo "Creating HTTPD output for output [$idx]"
        open_output $out_file
        set_output_type $out_file httpd
        add_output_parameter $out_file $idx HTTPD_OUTPUT_NAME name httpd str
        add_output_parameter $out_file $idx HTTPD_OUTPUT_ENABLED enabled yes constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_BIND_TO_ADDRESS bind_to_address "" none
        add_output_parameter $out_file $idx HTTPD_OUTPUT_PORT port 8000 num
        add_output_parameter $out_file $idx HTTPD_OUTPUT_ENCODER encoder wave constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_MAX_CLIENTS max_clients 0 constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_ALWAYS_ON always_on yes constant
        add_output_parameter $out_file $idx HTTPS_OUTPUT_TAGS tags yes constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_FORMAT format 44100:16:2 constant
        add_output_parameter $out_file $idx HTTPD_OUTPUT_MIXER_TYPE mixer_type "" none
        close_output $out_file
    fi
}