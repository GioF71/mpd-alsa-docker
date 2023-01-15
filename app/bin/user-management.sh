#!/bin/bash

create_audio_gid() {
    echo "Mode [${OUTPUT_MODE}] Adding $USER_NAME to group audio"
    if [ $(getent group $AUDIO_GID) ]; then
        echo "Mode [${OUTPUT_MODE}] Group with gid $AUDIO_GID already exists"
    else
        echo "Mode [${OUTPUT_MODE}] Creating group with gid $AUDIO_GID"
        groupadd -g $AUDIO_GID mpd-audio
    fi
    echo "Mode [${OUTPUT_MODE}] Adding $USER_NAME to gid $AUDIO_GID"
    AUDIO_GRP=$(getent group $AUDIO_GID | cut -d: -f1)
    echo "gid $AUDIO_GID -> group $AUDIO_GRP"
    if id -nG "$USER_NAME" | grep -qw "$AUDIO_GRP"; then
        echo "Mode [${OUTPUT_MODE}] User $USER_NAME already belongs to group audio (GID ${AUDIO_GID})"
    else
        usermod -a -G $AUDIO_GRP $USER_NAME
        echo "Mode [${OUTPUT_MODE}] AnyPulse [$ANY_PULSE] - Successfully added $USER_NAME to group audio (GID ${AUDIO_GID})"
    fi
}
