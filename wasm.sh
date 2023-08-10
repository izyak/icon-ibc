#!/bin/bash

source const.sh
source utils.sh

function deploy_contract() {
	log_stack
	local wasm_file=$1
	local addr_loc=$2
	local init_args=$3
	requireFile ${wasm_file} "${wasm_file} does not exist"
	log "deploying contract ${wasm_file##*/}"

	local res=$(${WASM_BIN} tx wasm store $wasm_file $WASM_COMMON_ARGS   -y --output json -b block)
	local code_id=$(echo $res | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
	log "received code id ${code_id}"

	local admin=$(${WASM_BIN} keys show $WASM_WALLET $WASM_EXTRA --output=json | jq -r .address)
	local init_res=$(${WASM_BIN} tx wasm instantiate $code_id $init_args $WASM_COMMON_ARGS --label "github.com/izyak/icon-ibc" --admin $admin -y)

	while :; do
		local addr=$(${WASM_BIN} query wasm lca "${code_id}" --node $WASM_NODE --output json | jq -r '.contracts[-1]') 
		if [ "$addr" != "null" ]; then
	        break
	    fi
	    sleep 2
	done

	local contract=$(${WASM_BIN} query wasm lca "${code_id}" --node $WASM_NODE --output json | jq -r '.contracts[-1]')
	log "${wasm_file##*/} deployed at : ${contract}"
	echo $contract > $2
	sleep 5
}

function check_txn_result() {
	log_stack
	local tx_hash=$1
	while :; do
		(${WASM_BIN} query tx ${tx_hash} --node $WASM_NODE --chain-id $WASM_CHAIN_ID --output json &>/dev/null) && break || sleep 2
	done

	local code=$(${WASM_BIN} query tx ${tx_hash} --node $WASM_NODE --chain-id $WASM_CHAIN_ID --output json | jq -r .code)
	if [ $code == "0" ]; then 
		log "txn successful"
	else
		log "txn failure"
	fi
}

function execute_contract() {
	log_stack
	local contract_addr=$1
	local init_args=$2
	log "method and params ${init_args}"

	local tx_hash=$(${WASM_BIN} tx wasm execute ${contract_addr} ${init_args} $WASM_COMMON_ARGS -y --output json | jq -r .txhash)
	log "tx_hash : ${tx_hash}"
	check_txn_result $tx_hash
}

function setup_contracts() {
	log_stack
	deploy_contract $CONTRACT_FILE_WASM_IBC_CORE $CONTRACT_ADDR_WASM_IBC_CORE '{}'

	local ibc_core=$(cat $CONTRACT_ADDR_WASM_IBC_CORE)
	local client_args="{\"ibc_host\":\"$ibc_core\"}"

	deploy_contract $CONTRACT_FILE_WASM_LIGHT_CLIENT $CONTRACT_ADDR_WASM_LIGHT_CLIENT ${client_args}

	local light_client=$(cat $CONTRACT_ADDR_WASM_LIGHT_CLIENT)
	local register_client_args="{\"register_client\":{\"client_type\":\"iconclient\",\"client_address\":\"$light_client\"}}"

	execute_contract ${ibc_core} ${register_client_args}

	local xcall_args="{\"network_id\":\"${WASM_NETWORK_ID}\",\"denom\":\"${WASM_TOKEN}\"}"
	deploy_contract $CONTRACT_FILE_WASM_XCALL $CONTRACT_ADDR_WASM_XCALL ${xcall_args}

	local xcall_addr=$(cat ${CONTRACT_ADDR_WASM_XCALL})

	local connection_args="{\"ibc_host\":\"${ibc_core}\",\"port_id\":\"${WASM_PORT_ID}\",\"xcall_address\":\"$xcall_addr\",\"denom\":\"$WASM_TOKEN\"}"    
	deploy_contract $CONTRACT_FILE_WASM_XCALL_CONNECTION $CONTRACT_ADDR_WASM_XCALL_CONNECTION ${connection_args}

	local xcall_connection_addr=$(cat ${CONTRACT_ADDR_WASM_XCALL_CONNECTION})

	local bind_port_args="{\"bind_port\":{\"port_id\":\"$WASM_PORT_ID\",\"address\":\"$xcall_connection_addr\"}}"
	execute_contract ${ibc_core} ${bind_port_args}
}

function deploy_xcall_dapp() {
	log_stack

	local xcall=$(cat $CONTRACT_ADDR_WASM_XCALL)
	local xcall_dapp_args="{\"address\":\"${xcall}\"}"
	deploy_contract $CONTRACT_FILE_WASM_XCALL_DAPP $CONTRACT_ADDR_WASM_XCALL_DAPP $xcall_dapp_args

	local xcall_dapp=$(cat $CONTRACT_ADDR_WASM_XCALL_DAPP)
	local xcall_connection_dst=$(cat ${CONTRACT_ADDR_JAVA_XCALL_CONNECTION})
    local xcall_connection_src=$(cat ${CONTRACT_ADDR_WASM_XCALL_CONNECTION})

	local add_connection_args="{\"add_connection\":{\"src_endpoint\":\"$xcall_connection_src\",\"dest_endpoint\":\"$xcall_connection_dst\",\"network_id\":\"$ICON_NETWORK_ID\"}}"
	execute_contract $xcall_dapp $add_connection_args
}

function configure_connection() {
	log_stack
	local src_chain_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.chain-id $RELAY_CFG)
    local dst_chain_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.chain-id $RELAY_CFG)
    local client_id=""
    local conn_id=""
    if [[ $src_chain_id == $WASM_CHAIN_ID ]]; then
        client_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.client-id $RELAY_CFG)
        conn_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.connection-id $RELAY_CFG)
    elif [[ $dst_chain_id == $WASM_CHAIN_ID ]]; then
        client_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.client-id $RELAY_CFG)
        conn_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.connection-id $RELAY_CFG)
    fi

    local dst_port_id=$ICON_PORT_ID

    local configure_args="{\"configure_connection\":{\"connection_id\":\"$conn_id\",\"counterparty_port_id\":\"$dst_port_id\",\"counterparty_nid\":\"$ICON_NETWORK_ID\",\"client_id\":\"${client_id}\",\"timeout_height\":30000}}"
    local xcall_connection=$(cat ${CONTRACT_ADDR_WASM_XCALL_CONNECTION})

    execute_contract $xcall_connection $configure_args

    local xcall=$(cat $CONTRACT_ADDR_WASM_XCALL)
    local default_conn_args="{\"set_default_connection\":{\"nid\":\"$ICON_NETWORK_ID\",\"address\":\"$xcall_connection\"}}"
    execute_contract $xcall $default_conn_args
}


function send_message() {
	log_stack
	local xcall_dapp=$(cat $CONTRACT_ADDR_WASM_XCALL_DAPP)
	local send_msg_args="{\"send_call_message\":{\"to\":\"$ICON_NETWORK_ID/hxb6b5791be0b5ef67063b3c10b840fb81514db2fd\",\"data\":[123,100,95,112,97],\"rollback\":[123,100,95,112,97]}}"
	execute_contract ${xcall_dapp} ${send_msg_args}
}


SHORT=sdmc
LONG=setup,deploy-dapp,send-msg,configure-connection

options=$(getopt -o $SHORT --long $LONG -n 'wasm.sh' -- "$@")
if [ $? -ne 0 ]; then
    echo "Usage: $0 [-s] [-d] [-m] [-c]" >&2
    exit 1
fi

eval set -- "$options"

while true; do
    case "$1" in
        -s|--setup) setup_contracts; shift ;;
        -d|--deploy-dapp) deploy_xcall_dapp; shift ;;
        -m|--send-msg) send_message; shift ;;
        -c|--configure-connection) configure_connection; shift ;;
        --) shift; break ;;
        *) echo "Internal error!"; exit 1 ;;
    esac
done
