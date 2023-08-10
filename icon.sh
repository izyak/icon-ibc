#!/bin/bash

source const.sh
source utils.sh


function icon_wait_tx() {
    log_stack
    local ret=1
    local tx_hash=$1
    [[ -z $tx_hash ]] && return
    log "tx_hash : ${tx_hash}"
    while :; do
        goloop rpc \
            --uri "$ICON_NODE" \
            txresult "$tx_hash" &>/dev/null && break || sleep 1
    done
    local txr=$(goloop rpc --uri "$ICON_NODE" txresult "$tx_hash" 2>/dev/null)
    local status=$(jq <<<"$txr" -r .status)
    log "status : $status"
    [[ "$status" == 0x0 ]] && echo $txr && exit 0
    [[ "$status" == 0x1 ]] && rset=0
    return $ret1
}

function save_address() {
    log_stack
    local ret=1
    local tx_hash=$1
    local addr_loc=$2
    [[ -z $tx_hash ]] && return
    local txr=$(goloop rpc --uri "$ICON_NODE" txresult "$tx_hash" 2>/dev/null)
    local score_address=$(jq <<<"$txr" -r .scoreAddress)
    echo $score_address > $addr_loc
    log "contract address : $score_address"
}

function deploy_contract() {
	log_stack
	local jarFile=$1
    local addrLoc=$2
	requireFile $jarFile "$jarFile does not exist"
	log "deploying contract ${jarFile##*/}"

	local params=()
    for i in "${@:3}"; do params+=("--param $i"); done

    local tx_hash=$(
        goloop rpc sendtx deploy $jarFile \
	    	--content_type application/java \
	    	--to cx0000000000000000000000000000000000000000 \
	    	$ICON_COMMON_ARGS \
	    	${params[@]} | jq -r .
    )
   	icon_wait_tx "$tx_hash"
    save_address "$tx_hash" $addrLoc
}

function icon_send_tx() {
    log_stack

    local address=$1
    require_contract_addr $address

    local method=$2

    log "calling ${method}"

    local params=()
    for i in "${@:3}"; do params+=("--param $i"); done

    local tx_hash=$(
        goloop rpc sendtx call \
            --to "$address" \
            --method "$method" \
            $ICON_COMMON_ARGS \
            ${params[@]} | jq -r .
    )
    icon_wait_tx "$tx_hash"

}

function setup_contracts() {
    log_stack
    deploy_contract $CONTRACT_FILE_JAVA_IBC_CORE $CONTRACT_ADDR_JAVA_IBC_CORE

    local ibc_handler=$(cat $CONTRACT_ADDR_JAVA_IBC_CORE)
    require_contract_addr $ibc_handler

    icon_send_tx $GOVERNANCE_SCORE "openBTPNetwork" networkTypeName=eth name=eth owner=${ibc_handler}

    deploy_contract $CONTRACT_FILE_JAVA_LIGHT_CLIENT $CONTRACT_ADDR_JAVA_LIGHT_CLIENT ibcHandler=${ibc_handler}

    local tm_client=$(cat $CONTRACT_ADDR_JAVA_LIGHT_CLIENT)
    require_contract_addr $tm_client
    icon_send_tx $ibc_handler "registerClient" clientType="07-tendermint" client="${tm_client}"

    deploy_contract $CONTRACT_FILE_JAVA_XCALL $CONTRACT_ADDR_JAVA_XCALL networkId=${ICON_NETWORK_ID}

    local xcall=$(cat $CONTRACT_ADDR_JAVA_XCALL)
    require_contract_addr $xcall

    deploy_contract $CONTRACT_FILE_JAVA_XCALL_CONNECTION $CONTRACT_ADDR_JAVA_XCALL_CONNECTION _xCall=${xcall} _ibc=${ibc_handler} port=${ICON_PORT_ID}
    local xcall_connection=$(cat $CONTRACT_ADDR_JAVA_XCALL_CONNECTION)
    require_contract_addr $xcall_connection

    icon_send_tx $ibc_handler "bindPort" moduleAddress=${xcall_connection} portId=${ICON_PORT_ID}
}

function send_message() {
    log_stack
    local xcall_dapp=$(cat ${CONTRACT_ADDR_JAVA_XCALL_DAPP})
    local to="archway12pr4qremzdpwdqwn4py0dtqtm9qtnz364eldr6"
    icon_send_tx ${xcall_dapp} "sendMessage" _to=${WASM_NETWORK_ID}/${to} _data=0x7b7d _rollback=0x726f6c6c62
}

function configure_connection() {
    log_stack
    local src_chain_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.chain-id $RELAY_CFG)
    local dst_chain_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.chain-id $RELAY_CFG)
    local client_id=""
    local conn_id=""
    if [[ $src_chain_id == "ibc-icon" ]]; then
        client_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.client-id $RELAY_CFG)
        conn_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.connection-id $RELAY_CFG)
    elif [[ $dst_chain_id == "ibc-icon" ]]; then
        client_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.client-id $RELAY_CFG)
        conn_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.connection-id $RELAY_CFG)
    fi

    local dst_port_id=$ICON_PORT_ID
    local xcall_connection=$(cat $CONTRACT_ADDR_JAVA_XCALL_CONNECTION)
    icon_send_tx $xcall_connection "configureConnection" \
        connectionId=${conn_id}  counterpartyPortId=${dst_port_id} \
        counterpartyNid=${WASM_NETWORK_ID} clientId=${client_id} \
        timeoutHeight=1000000

    local xcall=$(cat $CONTRACT_ADDR_JAVA_XCALL)
    icon_send_tx $xcall "setDefaultConnection" nid=${WASM_NETWORK_ID} connection=${xcall_connection}
}

function deploy_xcall_dapp() {
    log_stack
    
    local xcall=$(cat $CONTRACT_ADDR_JAVA_XCALL)
    require_contract_addr $xcall

    deploy_contract $CONTRACT_FILE_JAVA_XCALL_DAPP $CONTRACT_ADDR_JAVA_XCALL_DAPP _callService=${xcall}

    local xcall_connection_src=$(cat ${CONTRACT_ADDR_JAVA_XCALL_CONNECTION})
    local xcall_connection_dst="hehehehe" # $(cat ${CONTRACT_ADDR_WASM_XCALL_CONNECTION})
    local xcall_dapp=$(cat ${CONTRACT_ADDR_JAVA_XCALL_DAPP})

    icon_send_tx ${xcall_dapp} "addConnection" nid=${WASM_NETWORK_ID} source=${xcall_connection_src} destination=${xcall_connection_dst}
}

SHORT=sdmc
LONG=setup,deploy-dapp,send-msg,configure-connection

options=$(getopt -o $SHORT --long $LONG -n 'icon.sh' -- "$@")
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