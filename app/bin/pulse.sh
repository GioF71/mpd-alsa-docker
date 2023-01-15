#!/bin/bash

any_pulse() {
    result=0
    if [ "${OUTPUT_MODE^^}" == "PULSE" ]; then
        result=1
    fi
    if [[ $result -eq 0 ]]; then
        # if at least one additional pulse audio output is requested
        if [[ "${PULSE_AUDIO_OUTPUT_CREATE^^}" == "YES" ]]; then
            result=1
        fi
    fi
    echo $result
}
