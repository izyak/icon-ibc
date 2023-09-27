#!/bin/bash

: '
This is a migration script for wasm contracts.
To migrate contract:
./migrate.sh migrate xcall_path xcall_address $migrate_args
./migrate.sh migrate xcall-connection_path xcall-connection_addr $migrate_args
./migrate.sh migrate ibc_path ibc_addr $migrate_args
./migrate.sh migrate light-client_path light_client_addr $migrate_args
'

source const.sh
source utils.sh

function migrate_contract() {
    log_stack
    local wasm_file=$1
    local contract_addr=$2
    local migrate_arg=$3
    local wasm_common_args=$WASM_XCALL_COMMON_ARGS

    log "migrating ${wasm_file##*/} to $contract_addr with args $migrate_arg"
    substring="xcall"

    if [[ $wasm_file == *$substring* ]]; then
        log "using xcall wallet to migrate"
    else
        log "using ibc wallet to migrate"
        wasm_common_args=$WASM_XCALL_COMMON_ARGS
    fi

    local res=$(${WASM_BIN} tx wasm store $wasm_file $wasm_common_args -y --output json -b block)
    local code_id=$(echo $res | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
    log "received code id ${code_id}"

    local res=$(${WASM_BIN} tx wasm migrate $contract_addr $code_id $migrate_arg $wasm_common_args -y)

    while :; do
		local addr=$(${WASM_BIN} query wasm lca "${code_id}" --node $WASM_NODE --output json | jq -r '.contracts[-1]') 
		if [ "$addr" != "null" ]; then
	        break
	    fi
	    sleep 2
	done

	local contract=$(${WASM_BIN} query wasm lca "${code_id}" --node $WASM_NODE --output json | jq -r '.contracts[-1]')
	log "${wasm_file##*/} updated at address : ${contract}"
}

if [ "$1" != "migrate" ]; then
    echo "Usage: ./migrate.sh migrate <wasm_file_path> <contract_address> <migrate_args>"
    exit 1
fi

wasm_file_path=$2
contract_address=$3
migrate_args=$4

migrate_contract "$wasm_file_path" "$contract_address" "$migrate_args"
