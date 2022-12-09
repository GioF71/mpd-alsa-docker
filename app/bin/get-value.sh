#!/bin/bash

get_value() {
    ARG_NAME=$1
    PRIO=$2
    RESULT=""
    if [ -z "${PRIO}" ]; then
        PRIO="file"
    fi
    #Trying file first
    if [[ -v file_dict[${ARG_NAME}] ]]; then
        FROM_DICT=${file_dict[${ARG_NAME}]};
        #echo "FROM_DICT=[$FROM_DICT]"
    fi
    #Look in variables npw
    FROM_ENV=${!ARG_NAME}
    if [[ "${PRIO}" == "file" ]]; then
        if [[ -n "${FROM_DICT}" ]]; then
            RESULT=$FROM_DICT
        else
            RESULT=$FROM_ENV
        fi
    else
        if [[ -n "${FROM_ENV}" ]]; then
            RESULT=$FROM_ENV
        else
            RESULT=$FROM_DICT
        fi
    fi
    echo ${RESULT}
}

get_named_env_name() {
    VAR_NAME=$1
    VAR_INDEX=$2
    if [[ -z "$VAR_INDEX" || $VAR_INDEX -eq 0 ]]; then
        #not appending index
        COMPOSED_NAME=${VAR_NAME}
    else
        #appending index
        COMPOSED_NAME=${VAR_NAME}_${VAR_INDEX}
    fi
    echo ${COMPOSED_NAME}
}

get_named_env() {
    VAR_NAME=$1
    VAR_INDEX=$2
    SELECT_VAR=$(get_named_env_name $VAR_NAME $VAR_INDEX)
    echo ${!SELECT_VAR}
}

get_indexed_default() {
    DEF_VALUE=$1
    VAR_INDEX=$2
    if [[ -z "$VAR_INDEX" || $VAR_INDEX -eq 0 ]]; then
        #not appending index
        INDEXED_DEFAULT=${DEF_VALUE}
    else
        #appending index
        INDEXED_DEFAULT=${DEF_VALUE}_${VAR_INDEX}
    fi
    echo ${INDEXED_DEFAULT}
}

get_indexed_default_num() {
    DEF_VALUE=$1
    VAR_INDEX=$2
    if [[ -z "$VAR_INDEX" || "$VAR_INDEX" -eq 0 ]]; then
        #return default
        INDEXED_DEFAULT=${DEF_VALUE}
    else
        #sum to default
        INDEXED_DEFAULT=$((${DEF_VALUE}+${VAR_INDEX}))
    fi
    echo ${INDEXED_DEFAULT}
}

