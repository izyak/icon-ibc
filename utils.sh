#!/bin/bash

# change to disable stack logs
export PRINT_LOG_STACK=1 # [ 0 , 1 ]

function log_stack() {
	if [[ $PRINT_LOG_STACK == 1 ]];then
	    local cmd=${FUNCNAME[1]}
	    local file=${BASH_SOURCE[1]}
	    if [[ $# > 0 ]]; then cmd="$@"; fi
	    local prefix="$(date '+%Y-%m-%d %H:%M:%S')"
	    awk -v file="$file" -v date="$prefix" -v line=${BASH_LINENO[1]} -v funct=$cmd '
		    BEGIN {
		        printf "\033[0;34m%-20s\033[0;33m%-10s\033[0;36m%-4s\033[0;31m%-25s\n", date, file, line, funct;
		    }
		'
	fi
}

function log() {
	local FILE=${BASH_SOURCE[1]}
	local DATE=$(date +"%Y-%m-%d %H:%M:%S")
	local LINE=$BASH_LINENO
	local FUNC=${FUNCNAME[1]}
	awk -v file="$FILE" -v date="$DATE" -v line=$LINE -v funct=$FUNC -v logx="$1" '
	    BEGIN {
	        printf "\033[0;34m%-20s\033[0;33m%-10s\033[0;36m%-4s\033[0;31m%-25s\033[0m%-50s\n", date, file, line, funct, logx;
	    }
	'
}

function hex2dec() {
    hex=${@#0x}
    echo "obase=10; ibase=16; ${hex^^}" | bc
}

function requireFile() {
	local errorMsg=$2
    if [ ! -f "$1" ]; then
    	log $errorMsg
    fi
}

function require_icon_contract_addr() {
	local addr=$1
	if ! [[ $1 =~ ^cx[a-fA-F0-9]{40}$ ]]; then
	    log "invalid contract address $addr"
	    exit 1
	fi
}

function wordCount() {
	if [ -f $1 ];then
		tr -d '[:space:]' < $1 | wc -c
	else
		echo 0
	fi
}

function generatePassword() {
	tr -dc '[:alnum:]' < /dev/urandom | head -c 25
}