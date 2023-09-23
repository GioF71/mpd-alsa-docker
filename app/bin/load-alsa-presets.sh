#!/bin/bash

declare -A alsa_presets

function load_preset_file() {
    echo "Loading $2 alsa_presets..."
    while IFS= read -r line
    do
        if [[ -n "$line" && ! $line = \#* ]]; then
            key="$(cut -d '=' -f1 <<< ${line})"
            keyLen=`echo ${#key}`
            value=${line#*=}
            # strip quotes
            value=`echo $value | sed "s/\"//g"`
            echo "Loading preset [$key]=[$value]"
            alsa_presets[$key]=$value
    fi
    done < "$1"
    echo "Finished loading $2 alsa_presets"
}

# load alsa_presets
load_preset_file "/app/assets/alsa-presets.conf" "built-in"

additional_alsa_presets_file="/user/config/additional-alsa-presets.conf"
if [ -f $additional_alsa_presets_file ]; then
    load_preset_file $additional_alsa_presets_file "additional"
else
    echo "No additional preset file found"
fi

sz=`echo "${#alsa_presets[@]}"`
echo "There are [$sz] available alsa_presets"
if [[ "${DISPLAY_alsa_presets}" == "Y" || "${DISPLAY_alsa_presets}" == "y" ]]; then  
    for key in "${!alsa_presets[@]}"; do
        echo "Preset ["$key"]=["${alsa_presets[$key]}"]"
    done
fi
