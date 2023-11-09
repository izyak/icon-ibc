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
        /opt/ibc/bin/goloop rpc \
            --uri "$ICON_NODE" \
            txresult "$tx_hash" &>/dev/null && break || sleep 1
    done
    local txr=$(/opt/ibc/bin/goloop rpc --uri "$ICON_NODE" txresult "$tx_hash" 2>/dev/null)
    local status=$(jq <<<"$txr" -r .status)
    [[ "$status" == 0x0 ]] && log "txn failed" && echo $txr && exit 0
    [[ "$status" == 0x1 ]] && log "txn successful" && rset=0
    return $ret1
}

function save_address() {
    log_stack
    local ret=1
    local tx_hash=$1
    local addr_loc=$2
    [[ -z $tx_hash ]] && return
    local txr=$(/opt/ibc/bin/goloop rpc --uri "$ICON_NODE" txresult "$tx_hash" 2>/dev/null)
    local score_address=$(jq <<<"$txr" -r .scoreAddress)
    echo $score_address > $addr_loc
    log "contract address : $score_address"
}

function update_contract() {
    log_stack
    local contract_name=$1
    local contract_jarfile=$2

    requireFile $jarFile "$jarFile does not exist"
    local addrLoc
    local common_args

    case "$contract_name" in
        "ibc-core")
            addrLoc=${CONTRACT_ADDR_JAVA_IBC_CORE}
            common_args=${ICON_IBC_COMMON_ARGS}
            ;;
        "light-client")
            addrLoc=${CONTRACT_ADDR_JAVA_LIGHT_CLIENT}
            common_args=${ICON_IBC_COMMON_ARGS}
            ;;
        "xcall")
            addrLoc=${CONTRACT_ADDR_JAVA_XCALL}
            common_args=${ICON_XCALL_COMMON_ARGS}
            ;;
        "xcall-connection")
            addrLoc=${CONTRACT_ADDR_JAVA_XCALL_CONNECTION}
            common_args=${ICON_XCALL_COMMON_ARGS}
            ;;
        *)
            echo "Please provide one of the following flags: "
            echo "ibc-core           <path-to-jarFile>  <params>    Update IBC Contract "
            echo "light-client       <path-to-jarFile>  <params>    Update Light Client Contract "
            echo "xcall              <path-to-jarFile>  <params>    Update Xcall Contract "
            echo "xcall-connection   <path-to-jarFile>  <params>    Update Xcall Connection Contract "
            exit
            ;;
    esac


    local contract_address=$(cat $addrLoc)
    local params=()
    for i in "${@:3}"; do params+=("--param $i"); done

    log "updating contract ${contract_jarfile##*/} with params ${params}"

    read -p "Confirm? y/N " confirm

    local walletName=$(echo $common_args | grep -oP -- '-key_store \K[^ ]*')
    echo -n "Enter keystore password for $walletName: "
    read -s password

    if [[ $confirm == "y" ]]; then 
        local tx_hash=$(
            /opt/ibc/bin/goloop rpc sendtx deploy $contract_jarfile \
                --content_type application/java \
                --to $contract_address \
                $common_args \
                --key_password $password \
                ${params[@]} | jq -r .
        )
        icon_wait_tx "$tx_hash"
        log "$contract_name updated! "
    else
        log "Exiting"
        exit
    fi
}

function deploy_contract() {
	log_stack
	local jarFile=$1
    local addrLoc=$2
    local commonArgs=$3
	requireFile $jarFile "$jarFile does not exist"
	log "deploying contract ${jarFile##*/}"

    local walletName=$(echo $commonArgs | grep -oP -- '-key_store \K[^ ]*')
    echo -n "Enter keystore password for $walletName: "
    read -s password

	local params=()
    for i in "${@:4}"; do params+=("--param $i"); done

    local tx_hash=$(
        /opt/ibc/bin/goloop rpc sendtx deploy $jarFile \
	    	--content_type application/java \
	    	--to cx0000000000000000000000000000000000000000 \
	    	$commonArgs \
            --key_password $password \
	    	${params[@]} | jq -r .
    )
   	icon_wait_tx "$tx_hash"
    save_address "$tx_hash" $addrLoc
}

function icon_send_tx() {
    log_stack

    local address=$1
    require_icon_contract_addr $address

    local method=$2
    local commonArgs=$3

    log "calling ${method}"

    local walletName=$(echo $commonArgs | grep -oP -- '-key_store \K[^ ]*')
    echo -n "Enter keystore password for $walletName: "
    read -s password

    local params=()
    for i in "${@:4}"; do params+=("--param $i"); done

    local tx_hash=$(
        /opt/ibc/bin/goloop rpc sendtx call \
            --to "$address" \
            --method "$method" \
            $commonArgs \
            --key_password $password \
            ${params[@]} | jq -r .
    )
    icon_wait_tx "$tx_hash"
    echo 1 > $LOGS/"$ICON_CHAIN_ID"_"$method"
}

function setup_base_contracts() {
    log_stack
    if [ $(wordCount $CONTRACT_ADDR_JAVA_IBC_CORE) -ne $ICON_CONTRACT_ADDR_LEN ]; then 
        deploy_contract $CONTRACT_FILE_JAVA_IBC_CORE $CONTRACT_ADDR_JAVA_IBC_CORE "$ICON_IBC_COMMON_ARGS"
    fi

    local ibc_handler=$(cat $CONTRACT_ADDR_JAVA_IBC_CORE)
    require_icon_contract_addr $ibc_handler
    log "create a network proposal to open BTP Network for the IBC Contract after setup is over..."
    
    # local openBTPNetwork=openBTPNetwork

    # if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"$openBTPNetwork" ]; then
    #     icon_send_tx $GOVERNANCE_SCORE $openBTPNetwork "$ICON_IBC_COMMON_ARGS" networkTypeName=eth name=eth owner=${ibc_handler} 
    # fi

    if [ $(wordCount $CONTRACT_ADDR_JAVA_LIGHT_CLIENT) -ne $ICON_CONTRACT_ADDR_LEN ]; then 
        deploy_contract $CONTRACT_FILE_JAVA_LIGHT_CLIENT $CONTRACT_ADDR_JAVA_LIGHT_CLIENT "$ICON_IBC_COMMON_ARGS" ibcHandler=${ibc_handler}
    fi


    if [ $(wordCount $CONTRACT_ADDR_JAVA_XCALL) -ne $ICON_CONTRACT_ADDR_LEN ]; then 
        deploy_contract $CONTRACT_FILE_JAVA_XCALL $CONTRACT_ADDR_JAVA_XCALL "$ICON_XCALL_COMMON_ARGS" networkId=${ICON_NETWORK_ID}
    fi

    local xcall=$(cat $CONTRACT_ADDR_JAVA_XCALL)
    require_icon_contract_addr $xcall

    if [ $(wordCount $CONTRACT_ADDR_JAVA_XCALL_CONNECTION) -ne $ICON_CONTRACT_ADDR_LEN ]; then 
        deploy_contract $CONTRACT_FILE_JAVA_XCALL_CONNECTION $CONTRACT_ADDR_JAVA_XCALL_CONNECTION "$ICON_XCALL_COMMON_ARGS" _xCall=${xcall} _ibc=${ibc_handler} _port=${ICON_PORT_ID}
    fi
}

function configure_ibc() {
    log_stack
    local ibc_handler=$(cat $CONTRACT_ADDR_JAVA_IBC_CORE)
    local tm_client=$(cat $CONTRACT_ADDR_JAVA_LIGHT_CLIENT)
    require_icon_contract_addr $tm_client
    local registerClient=registerClient

    if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"$registerClient" ]; then
        icon_send_tx $ibc_handler $registerClient "$ICON_IBC_COMMON_ARGS" clientType="07-tendermint" client="${tm_client}"
    fi

    local xcall_connection=$(cat $CONTRACT_ADDR_JAVA_XCALL_CONNECTION)
    require_icon_contract_addr $xcall_connection
    local bindPort=bindPort

    if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"$bindPort" ]; then
        icon_send_tx $ibc_handler $bindPort "$ICON_IBC_COMMON_ARGS" moduleAddress=${xcall_connection} portId=${ICON_PORT_ID}
    fi
}

function configure_connection() {
    log_stack
    # local src_chain_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.chain-id $RELAY_CFG)
    # local dst_chain_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.chain-id $RELAY_CFG)
    # local client_id=""
    # local conn_id=""
    # if [[ $src_chain_id == ${ICON_CHAIN_ID} ]]; then
    #     client_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.client-id $RELAY_CFG)
    #     conn_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.connection-id $RELAY_CFG)
    # elif [[ $dst_chain_id == ${ICON_CHAIN_ID} ]]; then
    #     client_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.client-id $RELAY_CFG)
    #     conn_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.connection-id $RELAY_CFG)
    # fi


    local client_id=$1
    local conn_id=$2

    echo "Client_id: " $client_id
    echo "Conn_id: " $conn_id

    read -p "Confirm? y/N " confirm

    if [[ $confirm == "y" ]]; then 
        log "confirmed params for configure connection"
        local dst_port_id=$WASM_PORT_ID
        local xcall_connection=$(cat $CONTRACT_ADDR_JAVA_XCALL_CONNECTION)
        local configureConnection="configureConnection"
        icon_send_tx $xcall_connection $configureConnection "$ICON_XCALL_COMMON_ARGS"\
            connectionId=${conn_id}  counterpartyPortId=${dst_port_id} \
            counterpartyNid=${WASM_NETWORK_ID} clientId=${client_id} \
            timeoutHeight=${ICON_XCALL_TIMEOUT_HEIGHT}
    else
        log "Exiting"
        exit 0
    fi

}

function set_default_connection() {
    log_stack
    local xcall_connection=$(cat $CONTRACT_ADDR_JAVA_XCALL_CONNECTION)

    local xcall=$(cat $CONTRACT_ADDR_JAVA_XCALL)
    local setDefaultConnection="setDefaultConnection"
    if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"$setDefaultConnection" ]; then
        icon_send_tx $xcall $setDefaultConnection "$ICON_XCALL_COMMON_ARGS" _nid=${WASM_NETWORK_ID} _connection=${xcall_connection}
    fi
}

function set_protocol_fee() {
    log_stack
    local xcall=$(cat $CONTRACT_ADDR_JAVA_XCALL)
    require_icon_contract_addr $xcall
    local setProtocolFee="setProtocolFee"
    if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"$setProtocolFee" ]; then
        icon_send_tx $xcall $setProtocolFee "$ICON_XCALL_COMMON_ARGS" _protocolFee=${ICON_XCALL_PROTOCOL_FEE}
    fi
}

function set_fee() {
    log_stack

    local xcall_connection=$(cat $CONTRACT_ADDR_JAVA_XCALL_CONNECTION)
    require_icon_contract_addr $xcall_connection

    local setFee="setFee"
    if [ ! -f $LOGS/"$ICON_CHAIN_ID"_"$setFee" ]; then
        icon_send_tx $xcall_connection $setFee "$ICON_XCALL_COMMON_ARGS" nid=${WASM_NETWORK_ID} packetFee=${ICON_PACKET_FEE} ackFee=${ICON_ACK_FEE}
    fi
}

function generate_icon_wallets() {
    local password=$(generatePassword)
    echo $password > $ICON_IBC_PASSWORD_FILE
    /opt/ibc/bin/goloop ks gen -o $ICON_IBC_WALLET -p $password
    password=$(generatePassword)
    echo $password > $ICON_XCALL_PASSWORD_FILE
    /opt/ibc/bin/goloop ks gen -o $ICON_XCALL_WALLET -p $password
}

SHORT=sicdwfp
LONG=setup,configure-ibc,configure-connection,default-connection,wallets,set-fee,set-protocol-fee

options=$(getopt -o $SHORT --long $LONG -n 'icon.sh' -- "$@")
if [ $? -ne 0 ]; then
    echo "Usage: $0 [-s] [-i] [-c] [-d] [-w] [-f] [-p]" >&2
    exit 1
fi

eval set -- "$options"

while true; do
    case "$1" in
        -s|--setup) setup_base_contracts; shift ;;
        -i|--configure-ibc) configure_ibc; shift ;;
        -c|--configure-connection) configure_connection $3 $4 ; shift ;;
        -d|--default-connection) set_default_connection; shift ;;
        -w|--wallets) generate_icon_wallets; shift ;;
        -f|--set-fee) set_fee; shift ;;
        -p|--set-protocol-fee) set_protocol_fee; shift ;;
        --) shift; break ;;
        *) echo "Internal error!"; exit 1 ;;
    esac
done