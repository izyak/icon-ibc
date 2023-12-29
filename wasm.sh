#!/bin/bash

source const.sh
source utils.sh

function deploy_contract() {
	log_stack
	local wasm_file=$1
	local addr_loc=$2
	local init_args=$3
	local common_args=$4
	local admin_wallet=$5
	local code_id=$6
	if [[ "$TX_STORE_WASM" == "yes" ]];then
		requireFile ${wasm_file} "${wasm_file} does not exist"
		log "deploying contract ${wasm_file##*/}"
		local contract_name=$(echo ${wasm_file##*/} | sed 's/\.wasm//')

		local res=$(${WASM_BIN} tx wasm store $wasm_file $common_args   -y --output json -b block)
		local code_id=$(echo $res | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
		log "received code id ${code_id}"
	fi

	local admin=$(${WASM_BIN} keys show $admin_wallet $WASM_EXTRA --output=json | jq -r .address)
	local init_res=$(${WASM_BIN} tx wasm instantiate $code_id $init_args $common_args --label ${contract_name} --admin $admin -y)

	while :; do
		local addr=$(${WASM_BIN} query wasm lca "${code_id}" --node $WASM_NODE --output json | jq -r '.contracts[-1]') 
		if [ "$addr" != "null" ]; then
	        break
	    fi
	    sleep 2
	done

	local contract=$(${WASM_BIN} query wasm lca "${code_id}" --node $WASM_NODE --output json | jq -r '.contracts[-1]')
	log "${wasm_file##*/} deployed at : ${contract}"
	echo $contract>$2
	sleep 5
}

function check_txn_result() {
	log_stack
	local tx_hash=$1
	local method=$2
	while :; do
		(${WASM_BIN} query tx ${tx_hash} --node $WASM_NODE --chain-id $WASM_CHAIN_ID --output json &>/dev/null) && break || sleep 2
	done

	local code=$(${WASM_BIN} query tx ${tx_hash} --node $WASM_NODE --chain-id $WASM_CHAIN_ID --output json | jq -r .code)
	if [ $code == "0" ]; then 
		log "txn successful"
		echo 1 > $LOGS/"$WASM_CHAIN_ID"_"$method"
	else
		log "txn failure"
	fi
}

function execute_contract() {
	log_stack
	local contract_addr=$1
	local method=$2
	local init_args=$3
	local common_args=$4
	log "method and params ${init_args}"

	local tx_hash=$(${WASM_BIN} tx wasm execute ${contract_addr} ${init_args} $common_args -y --output json | jq -r .txhash)
	log "tx_hash : ${tx_hash}"
	check_txn_result $tx_hash $method
}

function set_rewards() {
	log_stack
	local contract_name=$1
	local contract_addr=$2
	local reward_addr=$3
	local common_args=$4
	log "set reward address for ${contract_name} to ${reward_addr}"

	local tx_hash=$(${WASM_BIN} tx rewards set-contract-metadata ${contract_addr} \ 
		--rewards-address ${reward_addr} $common_args -y --output json | jq -r .txhash )
	log "tx_hash : ${tx_hash}"
	check_txn_result $tx_hash "${contract_name}_rewards"
}

function setup_base_contracts() {
	log_stack

	if [ $(wordCount $CONTRACT_ADDR_WASM_IBC_CORE) -ne $COSMOS_CONTRACT_ADDR_LEN ]; then 
		deploy_contract $CONTRACT_FILE_WASM_IBC_CORE $CONTRACT_ADDR_WASM_IBC_CORE '{}' "$WASM_IBC_COMMON_ARGS" $WASM_IBC_WALLET "${INJ_CODE_ID[cw_ibc_core]}"
	fi

	local ibc_core=$(cat $CONTRACT_ADDR_WASM_IBC_CORE)
	local client_args="{\"ibc_host\":\"$ibc_core\"}"

	if [ $(wordCount $CONTRACT_ADDR_WASM_LIGHT_CLIENT) -ne $COSMOS_CONTRACT_ADDR_LEN ]; then 
		deploy_contract $CONTRACT_FILE_WASM_LIGHT_CLIENT $CONTRACT_ADDR_WASM_LIGHT_CLIENT ${client_args} "$WASM_IBC_COMMON_ARGS" $WASM_IBC_WALLET "${INJ_CODE_ID[cw_icon_light_client]}"
	fi

	local xcall_args="{\"network_id\":\"${WASM_NETWORK_ID}\",\"denom\":\"${WASM_TOKEN}\"}"
	
	if [ $(wordCount $CONTRACT_ADDR_WASM_XCALL) -ne $COSMOS_CONTRACT_ADDR_LEN ]; then 
		deploy_contract $CONTRACT_FILE_WASM_XCALL $CONTRACT_ADDR_WASM_XCALL ${xcall_args} "$WASM_XCALL_COMMON_ARGS" $WASM_XCALL_WALLET "${INJ_CODE_ID[cw_xcall]}"
	fi

	local xcall_addr=$(cat ${CONTRACT_ADDR_WASM_XCALL})
	local connection_args="{\"ibc_host\":\"${ibc_core}\",\"port_id\":\"${WASM_PORT_ID}\",\"xcall_address\":\"$xcall_addr\",\"denom\":\"$WASM_TOKEN\"}" 
	
	if [ $(wordCount $CONTRACT_ADDR_WASM_XCALL_CONNECTION) -ne $COSMOS_CONTRACT_ADDR_LEN ]; then   
		deploy_contract $CONTRACT_FILE_WASM_XCALL_CONNECTION $CONTRACT_ADDR_WASM_XCALL_CONNECTION ${connection_args} "$WASM_XCALL_COMMON_ARGS" $WASM_XCALL_WALLET "${INJ_CODE_ID[cw_xcall_ibc_connection]}"
	fi
}

function configure_ibc() {
	log_stack

	local ibc_core=$(cat $CONTRACT_ADDR_WASM_IBC_CORE)
	local light_client=$(cat $CONTRACT_ADDR_WASM_LIGHT_CLIENT)
	local register_client=register_client
	local register_client_args="{\"$register_client\":{\"client_type\":\"iconclient\",\"client_address\":\"$light_client\"}}"
	
	if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$register_client" ]; then
		execute_contract ${ibc_core} $register_client ${register_client_args} "$WASM_IBC_COMMON_ARGS"
	fi

	local xcall_connection_addr=$(cat ${CONTRACT_ADDR_WASM_XCALL_CONNECTION})
	local ibc_core=$(cat $CONTRACT_ADDR_WASM_IBC_CORE)
	local bind_port=bind_port
	local bind_port_args="{\"$bind_port\":{\"port_id\":\"$WASM_PORT_ID\",\"address\":\"$xcall_connection_addr\"}}"

	if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$bind_port" ]; then
		execute_contract ${ibc_core} $bind_port ${bind_port_args} "$WASM_IBC_COMMON_ARGS"
	fi
}

function configure_connection() {
	log_stack
	# local src_chain_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.chain-id $RELAY_CFG)
    # local dst_chain_id=$(yq -e .paths.${RELAY_PATH_NAME}.dst.chain-id $RELAY_CFG)
    # local client_id=""
    # local conn_id=""
    # if [[ $src_chain_id == $WASM_CHAIN_ID ]]; then
    #     client_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.client-id $RELAY_CFG)
    #     conn_id=$(yq -e .paths.${RELAY_PATH_NAME}.src.connection-id $RELAY_CFG)
    # elif [[ $dst_chain_id == $WASM_CHAIN_ID ]]; then
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

	    local dst_port_id=$ICON_PORT_ID
	    local configure_connection=configure_connection

	    local configure_args="{\"$configure_connection\":{\"connection_id\":\"$conn_id\",\"counterparty_port_id\":\"$dst_port_id\",\"counterparty_nid\":\"$ICON_NETWORK_ID\",\"client_id\":\"${client_id}\",\"timeout_height\":${WASM_XCALL_TIMEOUT_HEIGHT}}}"
	    local xcall_connection=$(cat ${CONTRACT_ADDR_WASM_XCALL_CONNECTION})

	    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$configure_connection" ]; then
	    	execute_contract $xcall_connection $configure_connection $configure_args "$WASM_XCALL_COMMON_ARGS"
		fi
	else
        log "Exiting"
        exit 0
    fi
}

function set_default_connection() {
	log_stack
	local xcall=$(cat $CONTRACT_ADDR_WASM_XCALL)
	local xcall_connection=$(cat ${CONTRACT_ADDR_WASM_XCALL_CONNECTION})
    local set_default_connection=set_default_connection
    local default_conn_args="{\"$set_default_connection\":{\"nid\":\"$ICON_NETWORK_ID\",\"address\":\"$xcall_connection\"}}"

    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$set_default_connection" ]; then
    	execute_contract $xcall $set_default_connection $default_conn_args "$WASM_XCALL_COMMON_ARGS"
    fi
}

function set_protocol_fee() {
	log_stack

    local xcall=$(cat $CONTRACT_ADDR_WASM_XCALL)
    local set_protocol_fee="set_protocol_fee"
    local set_protocol_fee_args="{\"$set_protocol_fee\":{\"value\":\"$WASM_XCALL_PROTOCOL_FEE\"}}"
    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$set_protocol_fee" ]; then
        execute_contract $xcall $set_protocol_fee $set_protocol_fee_args "$WASM_XCALL_COMMON_ARGS"
    fi
}

function set_protocol_fee_handler() {
	log_stack
	local fee_handler_address=$1

    local xcall=$(cat $CONTRACT_ADDR_WASM_XCALL)
    local set_protocol_fee_handle="set_protocol_fee_handler"
    local set_protocol_fee_handle_args="{\"$set_protocol_fee_handle\":{\"address\":\"$fee_handler_address\"}}"
    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$set_protocol_fee_handle" ]; then
        execute_contract $xcall $set_protocol_fee_handle $set_protocol_fee_handle_args "$WASM_XCALL_COMMON_ARGS"
    fi
}

function set_fee() {
    log_stack

    local xcall_connection=$(cat $CONTRACT_ADDR_WASM_XCALL_CONNECTION)
    local set_fees="set_fees"
    local set_fees_args="{\"$set_fees\":{\"nid\":\"$ICON_NETWORK_ID\",\"packet_fee\":\"$WASM_PACKET_FEE\",\"ack_fee\":\"$WASM_ACK_FEE\"}}"
    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$set_fees" ]; then
    	execute_contract $xcall_connection $set_fees $set_fees_args "$WASM_XCALL_COMMON_ARGS"
    fi
}

function set_admin() {
	log_stack
	local xcall_admin=$1

    local xcall=$(cat $CONTRACT_ADDR_WASM_XCALL)
    local xcall_connection=$(cat $CONTRACT_ADDR_WASM_XCALL_CONNECTION)

    local set_admin="set_admin"
    local set_admin_args="{\"$set_admin\":{\"address\":\"$xcall_admin\"}}"
    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$set_admin" ]; then
        execute_contract $xcall $set_admin $set_admin_args "$WASM_XCALL_COMMON_ARGS"
        execute_contract $xcall_connection $set_admin $set_admin_args "$WASM_XCALL_COMMON_ARGS"
    fi

}

function generate_wasm_wallets() {
	local mnemonic=$(${WASM_BIN} keys add $WASM_IBC_WALLET --output json | jq -r .mnemonic)
	echo $mnemonic > $KEYSTORE/"$WASM_IBC_WALLET"_mnemonic.txt
	archwayd keys show $WASM_IBC_WALLET --output json | jq -r '[.name, .address] | @tsv'

	mnemonic=$(${WASM_BIN} keys add $WASM_XCALL_WALLET --output json | jq -r .mnemonic)
	echo $mnemonic > $KEYSTORE/"$WASM_XCALL_WALLET"_mnemonic.txt
	archwayd keys show $WASM_XCALL_WALLET --output json | jq -r '[.name, .address] | @tsv'

}

function set_rewards_addr() {
	local reward_addr=$1
	local ibc_core=$(cat $CONTRACT_ADDR_WASM_IBC_CORE)
	local light_client=$(cat $CONTRACT_ADDR_WASM_LIGHT_CLIENT)
	local xcall=$(cat $CONTRACT_ADDR_WASM_XCALL)
    local xcall_connection=$(cat $CONTRACT_ADDR_WASM_XCALL_CONNECTION)

    if [ $COSMOS != "archway" ]; then
    	log "rewards can be set for archway only..."
    	exit
    fi

    local contract_name="ibc_core"
    local identifier="${contract_name}_rewards"
    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$identifier" ]; then
	    set_rewards ${contract_name} ${ibc_core} ${reward_addr} "$WASM_IBC_COMMON_ARGS"
	fi

	local contract_name="light_client"
    local identifier="${contract_name}_rewards"
    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$identifier" ]; then
	    set_rewards ${contract_name} ${light_client} ${reward_addr} "$WASM_IBC_COMMON_ARGS"
	fi

	local contract_name="xcall_connection"
    local identifier="${contract_name}_rewards"
    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$identifier" ]; then
	    set_rewards ${contract_name} ${xcall_connection} ${reward_addr} "$WASM_XCALL_COMMON_ARGS"
	fi

	local contract_name="xcall_multi"
    local identifier="${contract_name}_rewards"
    if [ ! -f $LOGS/"$WASM_CHAIN_ID"_"$identifier" ]; then
	    set_rewards ${contract_name} ${xcall} ${reward_addr} "$WASM_XCALL_COMMON_ARGS"
	fi
}

function migrate_contract() {
    log_stack
    local contract_name=$1
    local wasm_file=$2
    local migrate_arg=$3

    local addr_loc
    local wasm_common_args
    requireFile $wasm_file "$wasm_file does not exist"

    case "$contract_name" in
        "ibc-core")
            addr_loc=${CONTRACT_ADDR_WASM_IBC_CORE}
            wasm_common_args=${WASM_IBC_COMMON_ARGS}
            ;;
        "light-client")
            addr_loc=${CONTRACT_ADDR_WASM_LIGHT_CLIENT}
            wasm_common_args=${WASM_IBC_COMMON_ARGS}
            ;;
        "xcall")
            addr_loc=${CONTRACT_ADDR_WASM_XCALL}
            wasm_common_args=${WASM_XCALL_COMMON_ARGS}
            ;;
        "xcall-connection")
            addr_loc=${CONTRACT_ADDR_WASM_XCALL_CONNECTION}
            wasm_common_args=${WASM_XCALL_COMMON_ARGS}
            ;;
        *)
            echo "Please provide one of the following flags: "
            echo "ibc-core           <path-to-wasm> <params>      Update IBC Contract "
            echo "light-client       <path-to-wasm> <params>      Update Light Client Contract "
            echo "xcall              <path-to-wasm> <params>      Update Xcall Contract "
            echo "xcall-connection   <path-to-wasm> <params>      Update Xcall Connection Contract "
            exit
            ;;
    esac

    local contract_addr=$(cat $addr_loc)
    log "migrating ${wasm_file##*/} to $WASM_NETWORK_ID with args $migrate_arg"

    read -p "Confirm? y/N " confirm

    if [[ $confirm == "y" ]]; then 
        local res=$(${WASM_BIN} tx wasm store $wasm_file $wasm_common_args -y --output json -b block)
        echo $res
        local code_id=$(echo $res | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
        log "received code id ${code_id}"

        local res=$(${WASM_BIN} tx wasm migrate $contract_addr $code_id "$migrate_arg" $wasm_common_args -y)

        while :; do
    		local addr=$(${WASM_BIN} query wasm lca "${code_id}" --node $WASM_NODE --output json | jq -r '.contracts[-1]') 
    		if [ "$addr" != "null" ]; then
    	        break
    	    fi
    	    sleep 2
    	done

    	local contract=$(${WASM_BIN} query wasm lca "${code_id}" --node $WASM_NODE --output json | jq -r '.contracts[-1]')
    	log "${wasm_file##*/} updated on ${COSMOS} at address : ${contract}"
    else
        log "Exiting"
        exit
    fi
}


SHORT=sicdwfphar
LONG=setup,configure-ibc,configure-connection,default-connection,wallets,set-fee,set-rewards-archway,set-protocol-fee,set-protocol-fee-handler,set-admin

options=$(getopt -o $SHORT --long $LONG -n 'wasm.sh' -- "$@")
if [ $? -ne 0 ]; then
    echo "Usage: $0 [-s] [-i] [-c] [-d] [-w] [-f] [-p] [-h] [-a]" >&2
    exit 1
fi

eval set -- "$options"

while true; do
    case "$1" in
        -s|--setup) setup_base_contracts; shift ;;
        -i|--configure-ibc) configure_ibc; shift ;;
        -c|--configure-connection) configure_connection $3 $4 ; shift ;;
        -d|--default-connection) set_default_connection; shift ;;
        -w|--wallets) generate_wasm_wallets; shift ;;
        -f|--set-fee) set_fee; shift ;;
        -r|--set-rewards) set_rewards_addr $3; shift ;;
        -p|--set-protocol-fee) set_protocol_fee; shift ;;
        -h|--set-protocol-fee-handler) set_protocol_fee_handler $3; shift ;;
        -a|--set-admin) set_admin $3; shift ;;
        --) shift; break ;;
        *) echo "Internal error!"; exit 1 ;;
    esac
done
