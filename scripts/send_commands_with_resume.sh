#!/bin/bash

set -eu

function send_command {
    local cmd=$1
    local json=$2
    local fifo=$3

    if [ ! -f "${json}" ]; then
        json file ${json} does not exist
        return
    fi

    if [ ! -p "${fifo}" ]; then
        fifo ${fifo} does not exist
        return
    fi

    echo Sending command $cmd from file $json to fifo $fifo
    jq '.[] | select(.id =="'${cmd}'")' "${json}" > "${fifo}"
}

json=$1
fifo=$2
sleep=5
if [ $# = 3 ]; then
    sleep=$3
fi

send_command init  $json $fifo
send_command conf  $json $fifo
send_command start $json $fifo
echo Sleeping before sending resume
sleep 3
echo Resuming...
send_command resume $json $fifo
echo Sleeping for ${sleep} seconds before sending stop
sleep ${sleep}
send_command stop  $json $fifo

